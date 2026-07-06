#!/usr/bin/env bash
# deploy-basic.sh — Thin-client bootstrap of Agent OS into a target project.
#
# Copies ONLY the minimal scaffold into the target:
#   - .cursorrules (from templates/cursorrules.template, with AGENT_OS_SOURCE
#     token substituted to the absolute path of THIS source .ai)
#   - .work/ skeleton (HANDOFF, NEXT, UNKNOWNS, plans dirs, READMEs)
#   - DOCS_TECH_STACK.md
#
# Framework assets (skills/, standards/, concepts/, docs/, scripts/, templates/)
# are NOT copied — the target's .cursorrules carries an AGENT_OS_SOURCE pointer so
# the agent resolves them from the source .ai at runtime (thin-client mode).
#
# Default = NO-OVERWRITE: existing target files are preserved by construction.
# --update: no-overwrite + re-syncs the source pointer + lists existing-but-
# differing local-surface files (.cursorrules, .work/*.template outputs,
# DOCS_TECH_STACK.md) as merge candidates for agent rules-aware merge.
# --force: idempotent overwrite of the local scaffold surface only.
#
# Source resolution: AI_ROOT is derived from this script's location, so the
# script can be invoked from a TARGET using an external source .ai:
#   bash /mnt/work/Projects/.ai/scripts/deploy-basic.sh /mnt/work/Projects/tools-project
# Override the source with AI_SOURCE=/abs/path/.ai if needed.
#
# Usage:
#   bash scripts/deploy-basic.sh <target-path>              # no-overwrite (skip existing)
#   bash scripts/deploy-basic.sh --status [target-path]   # read-only report
#   bash scripts/deploy-basic.sh <target-path> --update    # no-overwrite + merge candidate list
#   bash scripts/deploy-basic.sh <target-path> --force     # overwrite local scaffold (legacy)
#   AI_SOURCE=/path/.ai bash scripts/deploy-basic.sh <target-path>
#
set -euo pipefail

# ── Status mode (read-only) ───────────────────────────────────────────
if [[ "${1:-}" == "--status" ]]; then
  shift
  RAW_TARGET="${1:-.}"
  if [[ "$RAW_TARGET" == "." || "$RAW_TARGET" == "$PWD" ]]; then
    DEST_ROOT="$(pwd)"
  else
    DEST_ROOT="$(cd "$RAW_TARGET" && pwd)"
  fi
  CURS_DEST="${DEST_ROOT}/.cursorrules"
  OC_DEST="${DEST_ROOT}/opencode.json"

  echo "=== deploy-basic status → $DEST_ROOT ==="

  if [[ -f "$CURS_DEST" ]]; then
    echo "  .cursorrules: present"
    src="$(grep -E '^AGENT_OS_SOURCE=' "$CURS_DEST" 2>/dev/null | head -1 | cut -d= -f2- || true)"
    if [[ -z "$src" ]]; then
      src="$(grep -oE 'AGENT_OS_SOURCE=[^[:space:]`]+' "$CURS_DEST" 2>/dev/null | head -1 | cut -d= -f2- || true)"
    fi
    if [[ -n "$src" && "$src" != "REPLACE_BASICSOURCE" ]]; then
      if [[ -d "$src" ]]; then
        echo "  AGENT_OS_SOURCE: $src (reachable)"
      else
        echo "  AGENT_OS_SOURCE: $src (UNREACHABLE)"
      fi
    elif grep -q 'AGENT_OS_SOURCE=' "$CURS_DEST"; then
      echo "  AGENT_OS_SOURCE: <unset token>"
    else
      echo "  AGENT_OS_SOURCE: missing (fat-client template?)"
    fi
    replace_count="$(grep -c 'REPLACE:' "$CURS_DEST" 2>/dev/null || true)"
    replace_count="${replace_count:-0}"
    echo "  REPLACE: tokens in .cursorrules: $replace_count (excludes filled AGENT_OS_SOURCE)"
  else
    echo "  .cursorrules: MISSING"
    src=""
  fi

  if [[ -d "${DEST_ROOT}/.work/context" ]]; then
    echo "  .work/: present"
  else
    echo "  .work/: missing"
  fi

  if [[ -d "${DEST_ROOT}/.ai/skills" ]]; then
    echo "  local .ai/skills/: present (WARN — fat-client leak / mixed state)"
  else
    echo "  local .ai/skills/: absent (thin-client ok)"
  fi

  if [[ -f "$OC_DEST" ]]; then
    echo "  opencode.json: present"
    if [[ -n "${src:-}" && "$src" != "REPLACE_BASICSOURCE" && -d "$src" ]]; then
      export REPO_ROOT="$DEST_ROOT" AI_SOURCE="$src"
      python3 << 'PYEOF' || echo "  opencode.json: could not validate paths"
import json, os
repo = os.environ["REPO_ROOT"]
src = os.environ["AI_SOURCE"].rstrip("/")
with open(os.path.join(repo, "opencode.json")) as f:
    cfg = json.load(f)
paths = (cfg.get("skills") or {}).get("paths") or []
first = (paths[0] if paths else "").rstrip("/")
expected = src + "/skills"
if first.startswith("./") or first == ".ai/skills":
    ok = first in (".ai/skills", "./.ai/skills")
else:
    ok = first == expected
if ok:
    print(f"  opencode skills.paths[0]: {first!r}  ok")
else:
    print(f"  opencode skills.paths[0]: {first!r}  STALE (expected {expected!r})")
PYEOF
    else
      echo "  opencode.json: present (AGENT_OS_SOURCE unavailable — cannot check path drift)"
    fi
  else
    echo "  opencode.json: missing (run install-opencode-config.sh to create)"
  fi
  exit 0
fi

RAW_TARGET="${1:?Usage: $0 [--status] <target-path> [--force|--update]}"
shift || true
MODE="skip"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)  MODE="force" ;;
    --update) MODE="update" ;;
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

# Target = repo root of the consumer (the dir that will hold .cursorrules + .work/).
if [[ "$RAW_TARGET" == "." || "$RAW_TARGET" == "$PWD" ]]; then
  DEST_ROOT="$(cd "$RAW_TARGET" && pwd)"
else
  DEST_ROOT="$(cd "$RAW_TARGET" && pwd)"
fi

if [[ ! -d "$DEST_ROOT" ]]; then
  echo "ERROR: target directory does not exist: $DEST_ROOT" >&2
  exit 1
fi

# .cursorrules template + .work/ skeleton templates come from source.
TPL_CURS="${AI_ROOT}/templates/cursorrules.template"
if [[ ! -f "$TPL_CURS" ]]; then
  echo "ERROR: source .ai missing templates/cursorrules.template at $AI_ROOT" >&2
  exit 1
fi

# Scaffold file set (the thin-client local surface).
CURS_DEST="${DEST_ROOT}/.cursorrules"
STACK_DEST="${DEST_ROOT}/DOCS_TECH_STACK.md"
WORK_FILES=(
  "README.md" "context/HANDOFF.md" "plans/NEXT.md" "plans/ASSUMPTIONS.md"
  "plans/RISK_REGISTRY.md" "plans/UNKNOWNS.md" "decisions/README.md"
  "prompts/README.md" "features/README.md" "docs/README.md" "docs/features/README.md"
)
WORK_DIRS=(
  "plans/foundation" "plans/full" "plans/operations" "plans/proposals"
  "plans/archives" "analysis" "scripts" "docs/guides" "docs/tutorials" "docs/reference"
)

echo "=== deploy-basic → $DEST_ROOT (thin-client bootstrap) ==="
echo "  source: $AI_ROOT"
echo "  mode:   $MODE (no-overwrite by default)"

# ── Pre-check: fat-client leak ───────────────────────────────────────
# If the target already has a local .ai/skills/ directory, warn and block
# (thin-client would create a mixed state; skills resolve locally first).
# --force skips the block (operator explicitly confirmed).
if [[ -d "${DEST_ROOT}/.ai/skills" ]]; then
  echo "  WARN: target has local .ai/skills/ directory (fat-client leak)"
  echo "    Thin-client bootstrap would create a mixed state where skills"
  echo "    resolve locally first instead of from \$AGENT_OS_SOURCE."
  if [[ "$MODE" != "force" ]]; then
    echo "  BLOCKED: use --force to confirm you want thin-client on a fat-client target,"
    echo "    or remove the local .ai/ directory first."
    exit 1
  else
    echo "  --force: proceeding (mixed state accepted by operator)"
  fi
fi

# Build the substituted .cursorrules content.
# Substitutes:
#   1. AGENT_OS_SOURCE=REPLACE_BASICSOURCE → absolute AI_ROOT
#   2. REPLACE:AI_UI_PATH → absolute path if .ai.ui/ exists as sibling, else leave token
#   3. REPLACE:AI_BIZ_PATH → absolute path if .ai.biz/ exists as sibling, else leave token
#   4. REPLACE:AI_SOC_PATH → absolute path if .ai.soc/ exists as sibling, else leave token
#   5. `.ai/scripts/<name>` → `<AI_ROOT>/scripts/<name>` (Change-safety gate table +
#      Co-authored-by hook install line). These commands live inside .cursorrules
#      itself, not inside a skill doc, so the general "any .ai/<x> inside a skill
#      resolves to $AGENT_OS_SOURCE/<x>" rule doesn't unambiguously cover them —
#      bake the resolved absolute path here instead of relying on read-time
#      interpretation (this is what a prior false "scripts not present" report
#      against a thin-client target traced back to).
subst_cursorrules() {
  local AI_ROOT_ESC="${AI_ROOT//\//\\/}"
  local SIBLING_PARENT
  SIBLING_PARENT="$(cd "$AI_ROOT/.." && pwd)"
  local tmpfile
  tmpfile="$(mktemp)"

  # Step 1: substitute AGENT_OS_SOURCE
  perl -pe "s/AGENT_OS_SOURCE=REPLACE_BASICSOURCE/AGENT_OS_SOURCE=${AI_ROOT_ESC}/" "$TPL_CURS" > "$tmpfile"

  # Step 2: discover and fill sister framework paths at bootstrap time.
  # If a sister exists on disk, write its absolute path. If absent, leave the
  # REPLACE: token — the Frameworks registry thin-client fallback (step 2) will
  # auto-discover from $AGENT_OS_SOURCE/.. at runtime.
  for fw in ui biz soc; do
    local fw_dir_abs="${SIBLING_PARENT}/.ai.${fw}"
    local token_upper
    token_upper="$(echo "$fw" | tr '[:lower:]' '[:upper:]')"
    local token="REPLACE:AI_${token_upper}_PATH"
    if [[ -d "$fw_dir_abs" ]] && [[ -f "${fw_dir_abs}/skills/README.md" ]]; then
      local fw_esc="${fw_dir_abs//\//\\/}"
      perl -i -pe "s{${token} \\(default: \\\`[^)]*\\)}{${fw_esc} (discovered at deploy time)}" "$tmpfile"
      echo "  frameworks: resolved ${token} → ${fw_dir_abs}" >&2
    else
      echo "  frameworks: ${token} not found on disk — leaving for runtime auto-discover" >&2
    fi
  done

  # Step 3: bake resolved script paths (Change-safety gate table + Co-authored-by
  # hook install line) — see comment above subst_cursorrules() for why this can't
  # be left to read-time interpretation.
  perl -i -pe "s{\.ai/scripts/}{${AI_ROOT_ESC}/scripts/}g" "$tmpfile"

  cat "$tmpfile"
  rm -f "$tmpfile"
}

write_cursorrules() {
  # $1 = force | skip
  if [[ "$1" == "force" ]] || [[ ! -f "$CURS_DEST" ]]; then
    subst_cursorrules > "$CURS_DEST"
    echo "  cursorrules: wrote (subst AGENT_OS_SOURCE=$AI_ROOT)"
  else
    echo "  cursorrules: skip (exists) — keeping existing target .cursorrules"
  fi
}

# Pre-scan: detect whether target already has a thin-client pointer set, so the
# report can flag a stale source path (e.g. source moved) for --update.
existing_source=""
if [[ -f "$CURS_DEST" ]]; then
  existing_source="$(grep -E '^AGENT_OS_SOURCE=' "$CURS_DEST" 2>/dev/null | head -1 | cut -d= -f2- || true)"
fi

# Step 1: .cursorrules (no-overwrite by default; --force overwrites).
if [[ "$MODE" == "force" ]]; then
  write_cursorrules force
else
  if [[ -f "$CURS_DEST" ]]; then
    echo "  cursorrules: skip (exists) — keeping existing target .cursorrules"
  else
    write_cursorrules skip  # creates it (no existing → fallthrough to write)
  fi
fi
# Re-sync the source pointer when --update AND the existing .cursorrules had a
# stale non-empty path. Skip when existing_source is empty (fresh write above).
if [[ "$MODE" == "update" ]] && [[ -n "$existing_source" ]] && [[ "$existing_source" != "$AI_ROOT" ]]; then
  if [[ -f "$CURS_DEST" ]] && grep -q 'AGENT_OS_SOURCE=' "$CURS_DEST"; then
    # Substitute just the source line in-place (preserve all other target edits).
    AI_ROOT_ESC="${AI_ROOT//\//\\/}"
    OLD_ESC="${existing_source//\//\\/}"
    perl -i -pe "s{AGENT_OS_SOURCE=\Q${existing_source}\E}{AGENT_OS_SOURCE=${AI_ROOT_ESC}}" "$CURS_DEST" 2>/dev/null || \
      perl -i -pe "s/AGENT_OS_SOURCE=[^\n]*/AGENT_OS_SOURCE=${AI_ROOT_ESC}/" "$CURS_DEST"
    echo "  cursorrules: re-synced AGENT_OS_SOURCE → $AI_ROOT (was: ${existing_source:-<unset>})"
  fi
fi
# Re-bake script paths (Change-safety gate table + Co-authored-by hook install
# line) whenever they're still unresolved or point at a since-moved source.
# Handles two cases: (a) baked to a source that has since moved — replace the
# OLD absolute prefix first, so case (b) below can't re-match inside it; (b)
# never baked — target bootstrapped before this fix, still shows literal
# `.ai/scripts/...` (lookbehind excludes any occurrence already prefixed by a
# real path, e.g. inside an old source's own `.../.ai/scripts/` — without it,
# case (b) would wrongly re-match text that case (a) just fixed, or an old
# source path ending in `.ai`, and double-prefix it). No-op if already correct.
if [[ "$MODE" == "update" ]] && [[ -f "$CURS_DEST" ]] && grep -q 'AGENT_OS_SOURCE=' "$CURS_DEST"; then
  AI_ROOT_ESC="${AI_ROOT//\//\\/}"
  tmp_before_bake="$(mktemp)"
  cp "$CURS_DEST" "$tmp_before_bake"
  if [[ -n "$existing_source" ]] && [[ "$existing_source" != "$AI_ROOT" ]]; then
    perl -i -pe "s{\Q${existing_source}\E/scripts/}{${AI_ROOT_ESC}/scripts/}g" "$CURS_DEST"
  fi
  perl -i -pe "s{(?<!/)\.ai/scripts/}{${AI_ROOT_ESC}/scripts/}g" "$CURS_DEST"
  if ! cmp -s "$tmp_before_bake" "$CURS_DEST"; then
    echo "  cursorrules: re-baked script paths → $AI_ROOT/scripts/ (Change-safety gate table + hook install line)"
  fi
  rm -f "$tmp_before_bake"
fi
# If --update AND existing .cursorrules came from a fat-client template (no
# AGENT_OS_SOURCE line at all), flag it — the source-resolution section is a
# merge candidate, handled by the agent (see skill § update-merge protocol).
if [[ "$MODE" == "update" ]] && [[ -f "$CURS_DEST" ]] && ! grep -q 'AGENT_OS_SOURCE=' "$CURS_DEST"; then
  echo "  cursorrules: MERGE CANDIDATE — existing .cursorrules lacks the Source-resolution section"
  echo "    (agent merges the section from the current template; preserves target REPLACE tokens)"
fi

# Step 2: .work/ skeleton + DOCS_TECH_STACK.md via bootstrap.sh (no-overwrite).
# Tell bootstrap.sh not to write .cursorrules (we did it ourselves with the
# AGENT_OS_SOURCE substitution).
BOOTSTRAP_SKIP_CURSERRULES=1 REPO_ROOT="$DEST_ROOT" bash "$AI_ROOT/templates/bootstrap.sh" \
  > /tmp/deploy-basic-bootstrap.$$.log 2>&1 || { cat /tmp/deploy-basic-bootstrap.$$.log; rm -f /tmp/deploy-basic-bootstrap.$$.log; exit 1; }
# Surface a trimmed version of bootstrap output (created/skip lines).
grep -E '^(created:|skip |scaffold:|removed )' /tmp/deploy-basic-bootstrap.$$.log | sed 's/^/  work: /'
rm -f /tmp/deploy-basic-bootstrap.$$.log

# Patch stale repo-root standards/docs paths in existing .cursorrules (pre-v0.5.2 layout).
# Preserves filled REPLACE: tokens and AGENT_OS_SOURCE; only rewrites known path literals.
patch_cursorrules_project_paths() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  local tmp
  tmp="$(mktemp)"
  cp "$f" "$tmp"
  perl -i -pe '
    s{\| `standards/|\| `.work/standards/|g;
    s{\| `docs/integration/|\| `.work/docs/integration/|g;
    s/\{BOUNDARY_MAP\}` \| standards\//{BOUNDARY_MAP}` | .work\/standards\//;
    s/under `docs\/integration\`/under `.work\/docs\/integration\`/g;
    s/log every download in `docs\/integration\/MANIFEST/log every download in `.work\/docs\/integration\/MANIFEST/g;
    s/- \*\*`standards\/\*\* and \*\*`docs\/integration\/\*\* \(project root, sibling of `\.work\/`\):/- **`.work\/standards\/`** and **`.work\/docs\/integration\/`** (under `.work\/`):/;
    s/\| `standards\/` \| This project.s own binding/\| `.work\/standards\/` | This project.s own binding/;
    s/\| `docs\/integration\/` \| This project.s vendor/\| `.work\/docs\/integration\/` | This project.s vendor/;
    s/## Documentation layout \(`\.ai\/` vs `\.work\/` vs project root\)/## Documentation layout (`.ai\/` vs `.work\/`)/;
    s/- \*\*`\.work\/`\:\*\* project-specific — plans/- **`.work\/`:** **all project-specific memory and customization** — plans/;
  ' "$f" 2>/dev/null || true
  if ! grep -q '{STANDARDS_ROOT}' "$f"; then
    perl -i -0777 -pe 's/(\| `\{TOUCH_SCOPE\}` \| `\.work\/touch-scope` \|\n)/$1| `{STANDARDS_ROOT}` | `.work\/standards\/` |\n| `{INTEGRATION_ROOT}` | `.work\/docs\/integration\/` |\n/s' "$f" 2>/dev/null || true
  fi
  if ! cmp -s "$tmp" "$f"; then
    echo "  cursorrules: patched deprecated repo-root standards/docs paths → .work/"
  fi
  rm -f "$tmp"
}
patch_cursorrules_project_paths "$CURS_DEST"

REPO_ROOT="$DEST_ROOT" bash "$AI_ROOT/scripts/install-git-hooks.sh" 2>/dev/null || true
REPO_ROOT="$DEST_ROOT" AI_SOURCE="$AI_ROOT" bash "$AI_ROOT/scripts/install-opencode-config.sh" 2>/dev/null || true

# --update: surgical opencode path sync when AGENT_OS_SOURCE moved (preserves mcp + custom entries).
if [[ "$MODE" == "update" ]]; then
  sync_rc=0
  REPO_ROOT="$DEST_ROOT" AI_SOURCE="$AI_ROOT" OLD_SOURCE="${existing_source}" \
    bash "$AI_ROOT/scripts/install-opencode-config.sh" --sync-paths 2>/dev/null || sync_rc=$?
  if [[ "$sync_rc" -eq 0 ]]; then
    :
  elif [[ "$sync_rc" -eq 2 ]]; then
    echo "  opencode.json: paths still stale after --sync-paths (listed under merge candidates)"
  fi
fi

# Step 3: --update — list existing-but-differing local-surface files as merge candidates.
if [[ "$MODE" == "update" ]]; then
  echo ""
  echo "=== update merge candidates ==="
  # .cursorrules vs the freshly-substituted template
  if [[ -f "$CURS_DEST" ]]; then
    tmp_cur="$(mktemp)"
    subst_cursorrules > "$tmp_cur"
    if ! cmp -s "$tmp_cur" "$CURS_DEST"; then
      echo "  merge: .cursorrules  (differs from current template-with-source)"
    fi
    rm -f "$tmp_cur"
  fi
  # .work/ skeleton files vs source templates (strip .template suffix)
  TPL_WORK="${AI_ROOT}/templates/work"
  for f in "${WORK_FILES[@]}"; do
    src="${TPL_WORK}/${f}.template"
    dest="${DEST_ROOT}/.work/${f}"
    [[ -f "$src" && -f "$dest" ]] || continue
    if ! cmp -s "$src" "$dest"; then
      echo "  merge: .work/${f}  (target has user content — agent appends new template sections only; preserves user edits)"
    fi
  done
  # DOCS_TECH_STACK.md vs source template
  if [[ -f "${AI_ROOT}/templates/DOCS_TECH_STACK.md.template" && -f "$STACK_DEST" ]] && \
     ! cmp -s "${AI_ROOT}/templates/DOCS_TECH_STACK.md.template" "$STACK_DEST"; then
    echo "  merge: DOCS_TECH_STACK.md  (preserve target stack pins)"
  fi
  # opencode.json — stale framework paths vs current AGENT_OS_SOURCE
  if [[ -f "${DEST_ROOT}/opencode.json" && -f "$CURS_DEST" ]]; then
    export REPO_ROOT="$DEST_ROOT" AI_SOURCE="$AI_ROOT"
    if ! python3 << 'PYEOF' 2>/dev/null; then
import json, os, sys
repo = os.environ["REPO_ROOT"]
src = os.environ["AI_SOURCE"].rstrip("/")
with open(os.path.join(repo, "opencode.json")) as f:
    cfg = json.load(f)
paths = (cfg.get("skills") or {}).get("paths") or []
first = (paths[0] if paths else "").rstrip("/")
expected = src + "/skills"
if first.startswith("./") or first == ".ai/skills":
    sys.exit(0 if first in (".ai/skills", "./.ai/skills") else 1)
sys.exit(0 if first == expected else 1)
PYEOF
      echo "  merge: opencode.json  (skills.paths stale vs AGENT_OS_SOURCE — run install-opencode-config.sh --sync-paths or edit manually)"
    fi
  fi
  echo "  (agent performs rules-aware merge — append new sections, preserve target"
  echo "   customizations + REPLACE tokens + AGENT_OS_SOURCE. See skill deploy-basic § update-merge.)"
fi

echo ""
echo "=== Done: thin-client bootstrap → $DEST_ROOT ==="
echo "  .cursorrules: $([ -f "$CURS_DEST" ] && echo present || echo MISSING)"
echo "  AGENT_OS_SOURCE: $(grep -oE 'AGENT_OS_SOURCE=[^ ]*' "$CURS_DEST" 2>/dev/null | head -1 | cut -d= -f2- || echo '<unset — fat-client>')"
echo "  .work/: $([ -d "${DEST_ROOT}/.work" ] && echo present || echo MISSING)"
echo "  skills (local): $([ -d "${DEST_ROOT}/.ai/skills" ] && echo "present — fat-client (deploy-basic does NOT create this; use @deploy-files if intentional)" || echo 'absent — thin-client (correct; skills load from source)')"
if [[ -d "${DEST_ROOT}/.ai" ]] && [[ ! -d "${DEST_ROOT}/.ai/skills" ]]; then
  echo "  WARN: .ai/ exists but lacks skills/ — unexpected; review target layout"
fi
echo ""
echo "Next steps in target project:"
echo "  1. Edit ${DEST_ROOT}/.cursorrules — fill every REPLACE: token EXCEPT AGENT_OS_SOURCE (deploy-basic set it)"
echo "  2. Verify source is reachable:  test -d \"\$(grep -oE 'AGENT_OS_SOURCE=[^ ]*' $CURS_DEST | cut -d= -f2-)\""
echo "  3. Run @session-control start  (skill loads from \$AGENT_OS_SOURCE/skills/session-control/skill.md)"
echo "  4. First skill besides session-control? Just invoke it — e.g. @plan-foundation status"
echo "  5. Using opencode? Review opencode.json (created from template if missing) — paths must match thin-client (\$AGENT_OS_SOURCE) layout"