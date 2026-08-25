#!/usr/bin/env bash
# deploy-files.sh — Deploy .ai (Agent OS) files into a target project
#
# Copies ONLY files git considers (tracked + untracked-not-ignored): anything
# in .gitignore — credentials, private context, tmp/ — is never deployed.
# This makes "files excluded in .git are never copied" an invariant enforced
# by construction, not a hand-maintained exclude list.
#
# Then strips skill-level intentional omissions (.github/, .gitignore,
# .gitattributes, .cursorrules, deploy scripts, agent.os.framework.md) — these
# ARE tracked but are omitted from files-only deploy. The framework source
# marker agent.os.framework.md must never reach a consumer project.
#
# Default = NO-OVERWRITE: existing files in the target are skipped (target-side
# customizations are preserved by construction). Use --force for the legacy
# idempotent-overwrite behavior, or --update to additionally emit a candidate
# list of existing-but-differing files for agent-driven rules-aware merge.
#
# Source resolution: AI_ROOT is derived from this script's location, so the
# script can be invoked from a TARGET directory using an external source framework root:
#   bash /mnt/work/Projects/pilo.ai.logicbison/scripts/deploy-files.sh .
# Override the source with AI_SOURCE=/abs/path/to/source-root if needed.
#
# Usage:
#   bash scripts/deploy-files.sh <target-path>              # no-overwrite (skip existing)
#   bash scripts/deploy-files.sh [copy] [-] <target-path>   # same (explicit outbound copy)
#   bash scripts/deploy-files.sh <target-path> [--force]    # overwrite existing (legacy)
#   bash scripts/deploy-files.sh <target-path> [--update]   # no-overwrite + emit merge candidates + verify
#   bash scripts/deploy-files.sh [status] [target-path]     # read-only report (+ .cursorrules verify)
#   AI_SOURCE=/path/to/source-root bash scripts/deploy-files.sh <target-path>
#
# Argument forms are equivalent: verbs accept the '--' prefix or bare form
# (`update` ≡ `--update`, `status` ≡ `--status`), '-' / '--' separators are
# ignored, and the target path may appear in any position.
#
set -euo pipefail

# ── Argument normalization ─────────────────────────────────────────────
# Verbs with or without '--', in any position relative to the target path;
# '-' and '--' (skill parse-table separators) are ignored.
MODE=""
RAW_TARGET=""
for arg in "$@"; do
  [[ "$arg" == "-" || "$arg" == "--" ]] && continue
  tok="${arg#--}"
  case "$tok" in
    copy|skip) : ;;   # explicit copy verb = default copy mode
    update|force|status) MODE="$tok" ;;
    /*|./*|../*|~*|*/*|.)
      if [[ -z "$RAW_TARGET" ]]; then RAW_TARGET="$arg"
      else echo "ERROR: multiple target paths: '$RAW_TARGET' and '$arg'" >&2; exit 2; fi ;;
    *) echo "ERROR: unknown argument: $arg" >&2
       echo "Usage: $0 [status] [copy] [-] <target-path> [--force|--update] (path must contain '/'; use ./name for local dirs)" >&2
       exit 2 ;;
  esac
done
MODE="${MODE:-skip}"
if [[ -z "$RAW_TARGET" ]]; then
  if [[ "$MODE" == "status" ]]; then
    RAW_TARGET="."
  else
    echo "Usage: $0 [status] [copy] [-] <target-path> [--force|--update]" >&2
    exit 2
  fi
fi

# Source .ai root: explicit override wins, else derive from script location.
if [[ -n "${AI_SOURCE:-}" ]]; then
  AI_ROOT="$(cd "$AI_SOURCE" && pwd)"
else
  AI_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

# ── Status mode (read-only) ───────────────────────────────────────────
if [[ "$MODE" == "status" ]]; then
  if [[ "$RAW_TARGET" == "." || "$RAW_TARGET" == "$PWD" ]]; then
    DEST_ROOT="$(pwd)"
  else
    DEST_ROOT="$(cd "$RAW_TARGET" && pwd)"
  fi
  echo "=== deploy-files status → $DEST_ROOT ==="
  if [[ -d "${DEST_ROOT}/.ai/skills" ]]; then
    skill_n="$(find "${DEST_ROOT}/.ai/skills" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"
    echo "  .ai/skills: present ($skill_n skill dirs — fat-client)"
  else
    echo "  .ai/skills: missing (no fat-client copy at this target)"
  fi
  status_rc=0
  if [[ -f "${DEST_ROOT}/.cursorrules" ]]; then
    AI_SOURCE="$AI_ROOT" bash "$AI_ROOT/scripts/cursorrules-verify.sh" "$DEST_ROOT" || status_rc=$?
  else
    echo "  .cursorrules: absent (nothing to verify — run @project-bootstrap init there)"
  fi
  if [[ -f "${DEST_ROOT}/opencode.json" ]]; then
    echo "  opencode.json: present"
  else
    echo "  opencode.json: missing"
  fi
  exit "$status_rc"
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
#   .github/      — CI/VCS, not consumer concern
#   .gitignore    — framework-repo hygiene, not consumer concern
#   .gitattributes — same
#   .cursorrules  — created in target by @project-bootstrap init from template
#   scripts/deploy-files.sh — the deploy script itself (run from source repo,
#                   not consumer concern)
#   agent.os.framework.md — framework source marker; never deployed (a consumer
#                   carrying it would be misdetected as framework source)
SKILL_EXCLUDE_REGEX='^(\.github/|\.gitignore$|\.gitattributes$|\.cursorrules$|scripts/deploy-files\.sh$|agent\.os\.framework\.md$)'

TMP_LIST="$(mktemp)"
MERGE_CANDS="$(mktemp)"
trap 'rm -f "$TMP_LIST" "$MERGE_CANDS"' EXIT

( cd "$AI_ROOT" \
  && git ls-files --cached --others --exclude-standard \
  | grep -vE "$SKILL_EXCLUDE_REGEX" \
  | while IFS= read -r f; do test -f "$AI_ROOT/$f" && echo "$f"; done \
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

# --update: refresh opencode.json framework paths for fat-client (.ai/ layout).
if [[ "$MODE" == "update" ]]; then
  CONSUMER_ROOT="$(dirname "$DEST_DIR")"
  sync_rc=0
  REPO_ROOT="$CONSUMER_ROOT" AI_SOURCE="$AI_ROOT" \
    bash "$AI_ROOT/scripts/install-opencode-config.sh" --sync-paths 2>/dev/null || sync_rc=$?
  if [[ "$sync_rc" -eq 2 ]]; then
    echo "  opencode.json: paths still stale after --sync-paths (review manually or merge)"
  fi
fi

# ── In-place scaffold (when target is the current directory) ──────────
# Chain bootstrap.sh so the target gets .work/ + .cursorrules + DOCS_TECH_STACK.md
# in the same invocation (per skill.md § I2). Outbound mode (different target)
# leaves next-step instructions.
if [[ "$RAW_TARGET" == "." || "$RAW_TARGET" == "$PWD" ]]; then
  REPO_ROOT="$(cd "$PARENT" && pwd)"
  REPO_ROOT="$REPO_ROOT" bash "$AI_ROOT/templates/bootstrap.sh" \
    > /tmp/deploy-files-bootstrap.$$.log 2>&1 || { cat /tmp/deploy-files-bootstrap.$$.log; rm -f /tmp/deploy-files-bootstrap.$$.log; exit 1; }
  grep -E '^(created:|skip )' /tmp/deploy-files-bootstrap.$$.log | sed 's/^/  scaffold: /'
  rm -f /tmp/deploy-files-bootstrap.$$.log
  SCAFFOLD_DONE=1
fi

echo ""
echo "=== Done: files deployed to $DEST_DIR ==="
echo ""
if [[ -n "${SCAFFOLD_DONE:-}" ]]; then
  echo "  Scaffold created (.work/, .cursorrules, DOCS_TECH_STACK.md)"
  echo "  Next: edit .cursorrules — fill every REPLACE: token"
else
  echo "Next steps in target project:"
  echo "  1. Run @project-bootstrap init (creates .cursorrules + .work/ from templates)"
  echo "  2. Edit .cursorrules — fill every REPLACE: token"
fi
echo "  3. Run @session-control start"
echo "  4. Using opencode? Review opencode.json (created from template if missing) — paths must match fat (.ai/) or thin (\$AGENT_OS_SOURCE) layout"

# ── Post-deploy .cursorrules verification ─────────────────────────────
# Consumer root = parent of the deployed .ai dir (in-place: cwd). update
# repairs via --fix (sister cells; thin-client only for source pointer/script
# paths); default mode verifies read-only.
CONSUMER_ROOT="$(cd "$PARENT" && pwd)"
if [[ -f "${CONSUMER_ROOT}/.cursorrules" ]]; then
  echo ""
  echo "=== post-deploy verification ==="
  vr_rc=0
  if [[ "$MODE" == "update" ]]; then
    AI_SOURCE="$AI_ROOT" bash "$AI_ROOT/scripts/cursorrules-verify.sh" --fix "$CONSUMER_ROOT" || vr_rc=$?
  else
    AI_SOURCE="$AI_ROOT" bash "$AI_ROOT/scripts/cursorrules-verify.sh" "$CONSUMER_ROOT" || vr_rc=$?
  fi
  if [[ "$vr_rc" -ne 0 ]]; then
    if [[ "$MODE" == "update" ]]; then
      echo "  update could not auto-repair all findings — review [FAIL] lines above"
      exit "$vr_rc"
    fi
    echo "  (findings are pre-existing; run @deploy-files update to repair)"
  fi
else
  echo ""
  echo "  note: no .cursorrules at ${CONSUMER_ROOT} yet — verify after @project-bootstrap init (deploy-files status)"
fi