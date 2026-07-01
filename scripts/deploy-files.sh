#!/usr/bin/env bash
# deploy-files.sh — Deploy .ai (Agent OS) files into a target project
#
# Copies ONLY files git considers (tracked + untracked-not-ignored): anything
# in .gitignore — credentials, private context, tmp/ — is never deployed.
# This makes "files excluded in .git are never copied" an invariant enforced
# by construction, not a hand-maintained exclude list.
#
# Then strips skill-level intentional omissions (.github/, .gitignore,
# .gitattributes, .cursorrules, deploy scripts) — these ARE tracked but are
# omitted from files-only deploy; deploy-repo covers the full-repo case.
#
# Default = NO-OVERWRITE: existing files in the target are skipped (target-side
# customizations are preserved by construction). Use --force for the legacy
# idempotent-overwrite behavior, or --update to additionally emit a candidate
# list of existing-but-differing files for agent-driven rules-aware merge.
#
# Source resolution: AI_ROOT is derived from this script's location, so the
# script can be invoked from a TARGET directory using an external source .ai:
#   bash /mnt/work/Projects/.ai/scripts/deploy-files.sh .
# Override the source with AI_SOURCE=/abs/path/.ai if needed.
#
# Usage:
#   bash scripts/deploy-files.sh <target-path>              # no-overwrite (skip existing)
#   bash scripts/deploy-files.sh <target-path> --force      # overwrite existing (legacy)
#   bash scripts/deploy-files.sh <target-path> --update     # no-overwrite + emit merge candidates
#   AI_SOURCE=/path/.ai bash scripts/deploy-files.sh <target-path>
#
set -euo pipefail

RAW_TARGET="${1:?Usage: $0 <target-path> [--force|--update]}"
shift || true
MODE="skip"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)   MODE="force" ;;
    --update)  MODE="update" ;;
    *) echo "ERROR: unknown flag: $1" >&2; exit 1 ;;
  esac
  shift
done

# Source .ai root: explicit override wins, else derive from script location.
if [[ -n "${AI_SOURCE:-}" ]]; then
  AI_ROOT="$(cd "$AI_SOURCE" && pwd)"
else
  AI_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

# ── Resolve target ──────────────────────────────────────────────────
# If path ends with .ai, use as-is; otherwise append .ai
if [[ "$RAW_TARGET" == *.ai ]]; then
  DEST_DIR="$RAW_TARGET"
else
  DEST_DIR="${RAW_TARGET}/.ai"
fi

# Ensure parent exists
PARENT="$(dirname "$DEST_DIR")"
if [[ ! -d "$PARENT" ]]; then
  echo "ERROR: parent directory does not exist: $PARENT" >&2
  exit 1
fi

if [[ -e "$DEST_DIR" ]] && [[ ! -d "$DEST_DIR" ]]; then
  echo "ERROR: $DEST_DIR exists but is not a directory" >&2
  exit 1
fi

# ── Source must be a git repo so the tracked/not-ignored set is authoritative ──
if ! (cd "$AI_ROOT" && git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
  echo "ERROR: source $AI_ROOT is not a git repo." >&2
  echo "  deploy-files copies only git-tracked / non-ignored files (never .gitignored content)." >&2
  exit 1
fi

GIT_TOP="$(cd "$AI_ROOT" && git rev-parse --show-toplevel)"
if [[ "$GIT_TOP" != "$AI_ROOT" ]]; then
  echo "ERROR: $AI_ROOT is not the git repo root (root is $GIT_TOP)." >&2
  echo "  deploy-files expects the .ai directory to be the repository root." >&2
  exit 1
fi

echo "=== deploy-files → $DEST_DIR ==="
echo "  source: $AI_ROOT"
echo "  mode:   $MODE (no-overwrite by default)"
if [[ -d "$DEST_DIR" ]]; then
  echo "  exists: $DEST_DIR — re-copying (no-overwrite; preserves existing target files)"
fi

# ── Build copy list: files git sees (tracked + untracked-not-ignored) ──
# --cached            : tracked files (committed + staged)
# --others            : untracked files
# --exclude-standard  : skip untracked files that .gitignore excludes
# Net set = every file not excluded by .git → enforces the invariant.
# Skill-level excludes are intentional omissions of otherwise-tracked files:
#   .github/      — CI/VCS, shipped via @deploy-repo (full-repo mode) only
#   .gitignore    — framework-repo hygiene, not consumer concern
#   .gitattributes — same
#   .cursorrules  — created in target by @project-bootstrap init from template
#   scripts/deploy-files.sh, scripts/deploy-repo.sh — the deploy scripts
#                   themselves (run from source repo, not consumer concern)
SKILL_EXCLUDE_REGEX='^(\.github/|\.gitignore$|\.gitattributes$|\.cursorrules$|scripts/deploy-files\.sh$|scripts/deploy-repo\.sh$)'

TMP_LIST="$(mktemp)"
MERGE_CANDS="$(mktemp)"
trap 'rm -f "$TMP_LIST" "$MERGE_CANDS"' EXIT

( cd "$AI_ROOT" \
  && git ls-files --cached --others --exclude-standard \
  | grep -vE "$SKILL_EXCLUDE_REGEX" \
) > "$TMP_LIST"

COUNT="$(wc -l < "$TMP_LIST" | tr -d ' ')"

mkdir -p "$DEST_DIR"

# Pre-rscan: for no-overwrite modes, count files already present in target
# (BEFORE rsync) so "skipped" reflects pre-existing target files, not files
# rsync just wrote. For --update, also collect differing existing files as
# merge candidates (target keeps its old version; agent merges later).
SKIPPED=0
if [[ "$MODE" != "force" ]]; then
  while IFS= read -r rel; do
    [[ -z "$rel" ]] && continue
    if [[ -f "$DEST_DIR/$rel" ]]; then
      SKIPPED=$((SKIPPED+1))
      if [[ "$MODE" == "update" ]] && ! cmp -s "$AI_ROOT/$rel" "$DEST_DIR/$rel"; then
        echo "$rel" >> "$MERGE_CANDS"
      fi
    fi
  done < "$TMP_LIST"
fi

if [[ "$MODE" == "force" ]]; then
  # Legacy: idempotent overwrite of existing files (still no --delete).
  rsync -a --files-from="$TMP_LIST" "$AI_ROOT"/ "$DEST_DIR"/
else
  # No-overwrite (default + --update): skip files already present in target.
  rsync -a --ignore-existing --files-from="$TMP_LIST" "$AI_ROOT"/ "$DEST_DIR"/
fi

COPIED=$((COUNT - SKIPPED))
echo "  copied: $COPIED files (git-ignored content excluded by policy)"
echo "  skipped (exists): $SKIPPED files"

if [[ "$MODE" == "update" ]] && [[ -s "$MERGE_CANDS" ]]; then
  MERGE_N="$(wc -l < "$MERGE_CANDS" | tr -d ' ')"
  echo ""
  echo "=== update merge candidates ($MERGE_N existing-but-differing files) ==="
  while IFS= read -r rel; do
    echo "  merge: $rel"
  done < "$MERGE_CANDS"
  echo "  (agent performs rules-aware merge: append new rules, update shared"
  echo "   sections, preserve target customizations + REPLACE: tokens; never"
  echo "   wholesale-replace. See skill deploy-files § update-merge protocol.)"
fi

echo ""
echo "=== Done: files deployed to $DEST_DIR ==="
echo ""
echo "Next steps in target project:"
echo "  1. Run @project-bootstrap init (creates .cursorrules + .work/ from templates)"
echo "  2. Edit .cursorrules — fill every REPLACE: token"
echo "  3. Run @session-control start"