#!/usr/bin/env bash
# cursorrules-verify.sh — verify (optionally repair) a deployed target's
# .cursorrules against the CURRENT Agent OS source location and the sister
# frameworks installed on disk (.ai.ui / .ai.biz / .ai.soc).
#
# Read-only by default. --fix applies safe mechanical repairs (idempotent;
# preserves target customizations and filled REPLACE: tokens):
#   thin-client: re-sync AGENT_OS_SOURCE to the current source; re-bake
#                Change-safety gate-table script paths (old absolute prefix
#                first, then un-prefixed `.ai/scripts/` literals)
#   both:        fill open sister cells (REPLACE:AI_*_PATH) when the sister is
#                installed on disk; rewrite stale baked sister absolute paths
#                when the sister moved together with the source
#
# Usage:
#   bash scripts/cursorrules-verify.sh <target-root> [--fix] [--thin|--fat]
#   AI_SOURCE=/abs/path/.ai bash scripts/cursorrules-verify.sh <target-root>
#
# Flags accept the '--' prefix or bare form; the target path may appear in any
# position. <target-root> = consumer repo root (the dir holding .cursorrules).
#
# Exit: 0 = no FAIL findings · 1 = FAIL findings remain (after --fix when given)
#       2 = usage error. WARN/INFO findings never fail the run.

set -euo pipefail

# ── Argument normalization (bare verb ≡ --flag, path in any position) ──
FIX=0
LAYOUT=""
RAW_TARGET=""
for arg in "$@"; do
  [[ "$arg" == "-" || "$arg" == "--" ]] && continue
  tok="${arg#--}"
  case "$tok" in
    fix) FIX=1 ;;
    thin|fat) LAYOUT="$tok" ;;
    /*|./*|../*|~*|*/*|.)
      if [[ -z "$RAW_TARGET" ]]; then RAW_TARGET="$arg"
      else echo "ERROR: multiple target paths: '$RAW_TARGET' and '$arg'" >&2; exit 2; fi ;;
    *) echo "ERROR: unknown argument: $arg" >&2
       echo "Usage: $0 [--fix] [--thin|--fat] <target-root> (path must contain '/'; use ./name for local dirs)" >&2
       exit 2 ;;
  esac
done
[[ -n "$RAW_TARGET" ]] || { echo "Usage: $0 [--fix] [--thin|--fat] <target-root>" >&2; exit 2; }

# Source .ai root: explicit override wins, else derive from script location.
if [[ -n "${AI_SOURCE:-}" ]]; then
  AI_ROOT="$(cd "$AI_SOURCE" && pwd)"
else
  AI_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

if [[ "$RAW_TARGET" == "." || "$RAW_TARGET" == "$PWD" ]]; then
  DEST_ROOT="$(pwd)"
else
  DEST_ROOT="$(cd "$RAW_TARGET" 2>/dev/null && pwd)" || {
    echo "ERROR: target directory does not exist: $RAW_TARGET" >&2; exit 2; }
fi
CURS_DEST="${DEST_ROOT}/.cursorrules"

FAILS=0
fail() { echo "  [FAIL] $1"; FAILS=$((FAILS+1)); }
warn() { echo "  [warn] $1"; }
ok()   { echo "  [ok] $1"; }
note() { echo "  [info] $1"; }

get_source() {
  [[ -f "$CURS_DEST" ]] || { printf ''; return 0; }
  local s
  s="$(grep -E '^AGENT_OS_SOURCE=' "$CURS_DEST" 2>/dev/null | head -1 | cut -d= -f2- || true)"
  if [[ -z "$s" ]]; then
    s="$(grep -oE 'AGENT_OS_SOURCE=[^[:space:]`]+' "$CURS_DEST" 2>/dev/null | head -1 | cut -d= -f2- || true)"
  fi
  printf '%s' "$s"
}

# Sister lookup: canonical thin-client parent first ($AGENT_OS_SOURCE/..), then
# the consumer's own parent / root (fat-client / co-located layouts).
find_sister() {
  local fw="$1" p d
  for p in "$AI_ROOT/.." "$(dirname "$DEST_ROOT")" "$DEST_ROOT"; do
    d="$(cd "$p" 2>/dev/null && pwd)/.ai.${fw}" || continue
    if [[ -f "${d}/skills/README.md" ]]; then printf '%s' "$d"; return 0; fi
  done
  return 1
}

# ── Layout detection (unless forced) ──────────────────────────────────
SRC_VALUE="$(get_source)"
if [[ -z "$LAYOUT" ]]; then
  if [[ -n "$SRC_VALUE" && "$SRC_VALUE" != "REPLACE_BASICSOURCE" ]]; then
    LAYOUT="thin"
  elif [[ -d "${DEST_ROOT}/.ai/skills" ]]; then
    LAYOUT="fat"
  else
    LAYOUT="thin"   # no local skills → thin-client (or not yet configured)
  fi
fi

# ── --fix: mechanical repairs (before checks so verdict reflects them) ──
if [[ "$FIX" -eq 1 && -f "$CURS_DEST" ]]; then
  if [[ "$LAYOUT" == "thin" ]] && grep -q 'AGENT_OS_SOURCE=' "$CURS_DEST"; then
    AI_ESC="${AI_ROOT//\//\\/}"
    # 1. Re-sync the source pointer in place (all other lines untouched).
    if [[ "$SRC_VALUE" != "$AI_ROOT" ]]; then
      if [[ -n "$SRC_VALUE" ]]; then
        perl -i -pe "s{AGENT_OS_SOURCE=\Q${SRC_VALUE}\E}{AGENT_OS_SOURCE=${AI_ESC}}" "$CURS_DEST" 2>/dev/null || \
          perl -i -pe "s/AGENT_OS_SOURCE=[^\n]*/AGENT_OS_SOURCE=${AI_ESC}/" "$CURS_DEST"
      else
        perl -i -pe "s/AGENT_OS_SOURCE=[^\n]*/AGENT_OS_SOURCE=${AI_ESC}/" "$CURS_DEST"
      fi
      echo "  [fix] AGENT_OS_SOURCE → $AI_ROOT (was: ${SRC_VALUE:-<unset>})"
    fi
    # 2. Re-bake gate-table script paths: old absolute prefix first (so the
    #    lookbehind below can't re-match inside it), then bare literals.
    before="$(mktemp)"; cp "$CURS_DEST" "$before"
    if [[ -n "$SRC_VALUE" && "$SRC_VALUE" != "$AI_ROOT" && "$SRC_VALUE" != "REPLACE_BASICSOURCE" ]]; then
      perl -i -pe "s{\Q${SRC_VALUE}\E/scripts/}{${AI_ESC}/scripts/}g" "$CURS_DEST"
    fi
    perl -i -pe "s{(?<!/)\.ai/scripts/}{${AI_ESC}/scripts/}g" "$CURS_DEST"
    cmp -s "$before" "$CURS_DEST" || echo "  [fix] re-baked script paths → $AI_ROOT/scripts/"
    rm -f "$before"
  fi
  # 3. Sister framework cells (both layouts).
  for fw in ui biz soc; do
    FWU="$(echo "$fw" | tr '[:lower:]' '[:upper:]')"
    token="REPLACE:AI_${FWU}_PATH"
    sister_dir="$(find_sister "$fw" || true)"
    if grep -q "$token" "$CURS_DEST"; then
      if [[ -n "$sister_dir" ]]; then
        fw_esc="${sister_dir//\//\\/}"
        perl -i -pe "s{${token} \\(default:? \\\`[^)]*\\)}{${fw_esc} (discovered at deploy time)}" "$CURS_DEST"
        echo "  [fix] sister .ai.${fw}: filled ${token} → ${sister_dir}"
      fi
      continue
    fi
    while IFS= read -r old; do
      [[ -z "$old" ]] && continue
      if [[ ! -d "$old" && -n "$sister_dir" && "$old" != "$sister_dir" ]]; then
        perl -i -pe "s{\Q${old}\E}{${sister_dir}}g" "$CURS_DEST"
        echo "  [fix] sister .ai.${fw}: re-pointed ${old} → ${sister_dir}"
      fi
    done < <(grep -oE "/[^ |]+/\.ai\.${fw}\b" "$CURS_DEST" | sort -u)
  done
fi

# ── Checks ─────────────────────────────────────────────────────────────
echo "cursorrules-verify → $DEST_ROOT (layout: ${LAYOUT}, source: $AI_ROOT)"

if [[ ! -f "$CURS_DEST" ]]; then
  fail ".cursorrules: MISSING (run @deploy-basic / @deploy-files / @project-bootstrap init)"
  echo "cursorrules-verify: FAIL ($FAILS)"
  exit 1
fi
ok ".cursorrules: present"

# Thin-client: source pointer + baked executable paths.
if [[ "$LAYOUT" == "thin" ]]; then
  SRC_NOW="$(get_source)"
  if ! grep -q 'AGENT_OS_SOURCE=' "$CURS_DEST"; then
    fail "AGENT_OS_SOURCE: line missing (fat-client template? → Source-resolution section is a merge candidate)"
  elif [[ -z "$SRC_NOW" || "$SRC_NOW" == "REPLACE_BASICSOURCE" ]]; then
    fail "AGENT_OS_SOURCE: unfilled (${SRC_NOW:-<empty>}) — run @deploy-basic update"
  elif [[ ! -d "$SRC_NOW" ]]; then
    fail "AGENT_OS_SOURCE: $SRC_NOW UNREACHABLE (source moved? run @deploy-basic update)"
  else
    ok "AGENT_OS_SOURCE: $SRC_NOW (reachable)"
    [[ "$SRC_NOW" == "$AI_ROOT" ]] || note "AGENT_OS_SOURCE differs from this source ($AI_ROOT) — target tracks another source"
  fi

  # Gate-table executables must be baked to absolute paths that exist. Only the
  # known framework command basenames are checked (prose examples like
  # `/abs/source/scripts/deploy-basic.sh` are intentionally not validated).
  literal_n="$(perl -ne '$c++ if /(?<!\/)\.ai\/scripts\//; END{print $c+0}' "$CURS_DEST")"
  if [[ "$literal_n" -gt 0 ]]; then
    fail "script paths: ${literal_n} line(s) still literal .ai/scripts/ (unbaked — run @deploy-basic update)"
  else
    ok "script paths: no unbaked .ai/scripts/ literals"
  fi
  while IFS= read -r p; do
    [[ -z "$p" || "$p" == "$AI_ROOT" ]] && continue
    if [[ -d "$p" ]]; then
      note "script paths baked to $p (differs from this source)"
    else
      fail "script paths baked to stale prefix $p (missing — run @deploy-basic update)"
    fi
  done < <(grep -oE '/[^ `|"]+/scripts/(touch-scope-verify|blast-radius-check|install-git-hooks|mod06-output-check|master-plan-verify|framework-verify|skill-functional-verify)\.(sh|py)' "$CURS_DEST" 2>/dev/null | sed 's#/scripts/[^/]*$##' | sort -u || true)

  grep -q 'Source resolution' "$CURS_DEST" \
    && ok "Source-resolution section: present" \
    || warn "Source-resolution section: missing (merge candidate on @deploy-basic update)"
else
  # Fat-client: vendored copy must be intact.
  if [[ -d "${DEST_ROOT}/.ai/skills" ]]; then
    ok "local .ai/skills/: present (fat-client)"
  else
    fail "local .ai/skills/: missing — broken fat-client copy (re-run @deploy-files)"
  fi
  if [[ -n "$SRC_VALUE" && "$SRC_VALUE" != "REPLACE_BASICSOURCE" ]]; then
    warn "mixed state: AGENT_OS_SOURCE set AND local .ai/skills present (fat-client resolves first)"
  fi
fi

# Sister framework cells (both layouts).
for fw in ui biz soc; do
  FWU="$(echo "$fw" | tr '[:lower:]' '[:upper:]')"
  token="REPLACE:AI_${FWU}_PATH"
  if grep -q "$token" "$CURS_DEST"; then
    sister_dir="$(find_sister "$fw" || true)"
    if [[ -n "$sister_dir" ]]; then
      warn ".ai.${fw}: installed at ${sister_dir} but cell unfilled (${token}) — run deploy update"
    else
      note ".ai.${fw}: not installed (runtime auto-discover reports degraded)"
    fi
    continue
  fi
  baked="$(grep -oE "/[^ |]+/\.ai\.${fw}\b" "$CURS_DEST" 2>/dev/null | sort -u || true)"
  if [[ -z "$baked" ]]; then
    note ".ai.${fw}: custom cell value (non-standard — verify manually)"
    continue
  fi
  while IFS= read -r b; do
    [[ -z "$b" ]] && continue
    if [[ -d "$b" && -f "${b}/skills/README.md" ]]; then
      ok ".ai.${fw} → ${b} (reachable)"
    else
      fail ".ai.${fw} → ${b} STALE (not a valid framework dir — run deploy update)"
    fi
  done <<< "$baked"
done

replace_count="$(grep -c 'REPLACE:' "$CURS_DEST" 2>/dev/null || true)"
note "REPLACE: tokens remaining: ${replace_count:-0} (operator fills project tokens; AGENT_OS_SOURCE excluded)"

echo "cursorrules-verify: $([ "$FAILS" -eq 0 ] && echo PASS || echo "FAIL ($FAILS)")"
exit "$([ "$FAILS" -eq 0 ] && echo 0 || echo 1)"
