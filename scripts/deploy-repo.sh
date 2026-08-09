#!/usr/bin/env bash
# deploy-repo.sh — Full git-based deploy of Agent OS into a target
#
# Two modes:
#   clone   — git clone with full history into target dir (requires origin remote)
#   archive — git archive + extract into target dir (no git history, but includes
#             .github/, .gitignore, and root .cursorrules)
#
# "clone" is the default when the source has an origin remote and the target
# does not exist yet. "archive" is the fallback when there's no remote or the
# target exists and needs a partial update.
#
# Usage:
#   bash scripts/deploy-repo.sh [--status [target-path]]
#   bash scripts/deploy-repo.sh [clone|archive] [-] <target-path>
#   AI_SOURCE=/path/.ai bash scripts/deploy-repo.sh clone <target-path>
#
# Argument forms are equivalent: verbs accept the '--' prefix or bare form
# (`clone` ≡ `--clone`), '-' / '--' separators are ignored, and the target
# path may appear in any position. Default (no verb) = status.
#
set -euo pipefail

if [[ -n "${AI_SOURCE:-}" ]]; then
  AI_ROOT="$(cd "$AI_SOURCE" && pwd)"
else
  AI_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

# ── Argument normalization ─────────────────────────────────────────────
# Verbs with or without '--', in any position relative to the target path;
# '-' and '--' (skill parse-table separators) are ignored — a '-' must never
# become the target directory.
MODE=""
RAW_TARGET=""
for arg in "$@"; do
  [[ "$arg" == "-" || "$arg" == "--" ]] && continue
  tok="${arg#--}"
  case "$tok" in
    status|clone|archive) MODE="$tok" ;;
    /*|./*|../*|~*|*/*|.)
      if [[ -z "$RAW_TARGET" ]]; then RAW_TARGET="$arg"
      else echo "ERROR: multiple target paths: '$RAW_TARGET' and '$arg'" >&2; exit 2; fi ;;
    *) echo "ERROR: unknown argument: $arg (verbs: status clone archive)" >&2
       exit 2 ;;
  esac
done
MODE="${MODE:-status}"

# ── Status mode (read-only) ───────────────────────────────────────────
if [[ "$MODE" == "status" ]]; then
  TARGET="$RAW_TARGET"
  echo "=== deploy-repo status (Agent OS) ==="
  echo "  source: $AI_ROOT"
  REMOTE="$(cd "$AI_ROOT" && git remote get-url origin 2>/dev/null || true)"
  if [[ -n "$REMOTE" ]]; then
    echo "  origin: $REMOTE (clone available)"
  else
    echo "  origin: none (use archive mode)"
  fi
  echo "  branch: $(cd "$AI_ROOT" && git branch --show-current 2>/dev/null || echo '?')"
  echo "  head: $(cd "$AI_ROOT" && git rev-parse --short HEAD 2>/dev/null || echo '?')"
  echo "  modes: clone | archive"
  if [[ -n "$TARGET" ]]; then
    if [[ "$TARGET" == "." || "$TARGET" == "$PWD" ]]; then
      T="$(pwd)"
    else
      T="$(cd "$TARGET" 2>/dev/null && pwd || echo "$TARGET")"
    fi
    echo ""
    echo "=== target: $T ==="
    if [[ ! -e "$T" ]]; then
      echo "  exists: no"
    else
      echo "  exists: yes"
      [[ -d "$T/.git" ]] && echo "  .git/: present" || echo "  .git/: absent"
      [[ -f "$T/.cursorrules" ]] && echo "  .cursorrules: present" || echo "  .cursorrules: missing"
      [[ -d "$T/.github" ]] && echo "  .github/: present" || echo "  .github/: missing"
      [[ -d "$T/skills" ]] && echo "  skills/: present" || echo "  skills/: missing"
    fi
  fi
  exit 0
fi

if [[ -z "$RAW_TARGET" ]]; then
  echo "Usage: $0 [--status [path]] | <clone|archive> [-] <target-path>" >&2
  exit 2
fi

# ── Resolve target ──────────────────────────────────────────────────
# Always use as-is (unlike deploy-files, this is a full repo deploy)
DEST_DIR="$RAW_TARGET"

# Ensure parent exists
PARENT="$(dirname "$DEST_DIR")"
if [[ ! -d "$PARENT" ]]; then
  echo "ERROR: parent directory does not exist: $PARENT" >&2
  exit 1
fi

echo "=== deploy-repo: $MODE → $DEST_DIR ==="

# ── Mode: clone ─────────────────────────────────────────────────────
if [[ "$MODE" == "clone" ]]; then
  if [[ -d "$DEST_DIR/.git" ]]; then
    echo "  exists: $DEST_DIR (already a git repo — use 'archive' for partial update)" >&2
    exit 1
  fi

  REMOTE="$(cd "$AI_ROOT" && git remote get-url origin 2>/dev/null || true)"
  if [[ -z "$REMOTE" ]]; then
    echo "ERROR: no git remote 'origin' in source repo $AI_ROOT" >&2
    echo "  Cannot clone without a remote URL. Use 'archive' mode instead." >&2
    exit 1
  fi

  if [[ -e "$DEST_DIR" ]]; then
    echo "ERROR: $DEST_DIR already exists. Clone requires a non-existent or empty target." >&2
    exit 1
  fi

  git clone "$REMOTE" "$DEST_DIR"
  echo ""
  echo "=== Done: full repo cloned to $DEST_DIR ==="
  echo "Branch: $(cd "$DEST_DIR" && git branch --show-current)"
  echo "Origin: $REMOTE"
  exit 0
fi

# ── Mode: archive ───────────────────────────────────────────────────
if [[ "$MODE" != "archive" ]]; then
  echo "ERROR: unknown mode '$MODE'. Use 'clone' or 'archive'." >&2
  exit 1
fi

mkdir -p "$DEST_DIR"
# Resolve to absolute BEFORE cd (a relative target would otherwise re-resolve
# against $AI_ROOT after the cd, and tar would extract into a missing dir).
DEST_DIR="$(cd "$DEST_DIR" && pwd)"
cd "$AI_ROOT"

git archive --format=tar HEAD | tar xf - -C "$DEST_DIR"

echo ""
echo "=== Done: repo archive deployed to $DEST_DIR ==="
echo "Includes: .github/, .gitignore, .cursorrules (full tree, no .git history)"
echo ""
echo "Next steps in target project:"
echo "  1. Initialize git: git init && git add . && git commit -m 'init: Agent OS'"
echo "  2. Set origin remote if needed"
echo "  3. Edit .cursorrules — fill every REPLACE: token"
