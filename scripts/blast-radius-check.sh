#!/usr/bin/env bash
# Mechanical blast-radius analysis for AI-assisted diffs.
# Usage:
#   bash scripts/blast-radius-check.sh              # unstaged + staged vs HEAD
#   bash scripts/blast-radius-check.sh --cached     # staged only
#   bash scripts/blast-radius-check.sh HEAD~1..HEAD # explicit range
#   bash scripts/blast-radius-check.sh --self-test  # framework-verify hook
#
# Exit: 0 ok | 1 fail (blocking) | 2 warn only (--warn-exit-0)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[[ -n "${CHANGE_SAFETY_ROOT:-}" ]] && REPO_ROOT="${CHANGE_SAFETY_ROOT}"
cd "${REPO_ROOT}"

SURFACES="${REPO_ROOT}/standards/PROTECTED_SURFACES.json"
[[ -f "${SURFACES}" ]] || SURFACES="${REPO_ROOT}/.work/PROTECTED_SURFACES.json"
WARN_EXIT0=0
DIFF_RANGE=""
CACHED_ONLY=0

usage() {
  echo "Usage: bash scripts/blast-radius-check.sh [--cached] [--warn-exit-0] [<git-range>]" >&2
  echo "       bash scripts/blast-radius-check.sh --self-test" >&2
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --self-test) DIFF_RANGE="__SELFTEST__"; shift ;;
    --cached) CACHED_ONLY=1; shift ;;
    --warn-exit-0) WARN_EXIT0=1; shift ;;
    -h|--help) usage ;;
    *) DIFF_RANGE="$1"; shift ;;
  esac
done

# --- self-test (framework-verify) ---
if [[ "${DIFF_RANGE}" == "__SELFTEST__" ]]; then
  TMP="$(mktemp -d)"
  trap 'rm -rf "${TMP}"' EXIT
  git init -q "${TMP}/r"
  (
    cd "${TMP}/r"
    mkdir -p skills scripts templates
    git config user.email "t@t.com"
    git config user.name "t"
    echo a > skills/x.md
    echo b > scripts/y.sh
    echo c > templates/z.template
    git add .
    git commit -q -m "init"
    echo change >> skills/x.md
    echo change >> scripts/y.sh
    echo change >> templates/z.template
    OUT="$(CHANGE_SAFETY_ROOT="${TMP}/r" bash "${REPO_ROOT}/scripts/blast-radius-check.sh" 2>&1 || true)"
    echo "${OUT}"
    echo "${OUT}" | grep -q "areas_crossed=3" || { echo "FAIL: expected 3 areas" >&2; exit 1; }
    echo "${OUT}" | grep -q "risk: high" || { echo "FAIL: expected high risk" >&2; exit 1; }
  )
  echo "blast-radius-check self-test: PASS"
  exit 0
fi

# --- thresholds from PROTECTED_SURFACES.json ---
MAX_LINES_WARN=150
MAX_LINES_FAIL=400
MAX_AREAS_WARN=2
MAX_AREAS_FAIL=3
if [[ -f "${SURFACES}" ]] && command -v python3 >/dev/null 2>&1; then
  eval "$(python3 -c "
import json
with open('${SURFACES}') as f:
    t = json.load(f).get('thresholds', {})
print(f'MAX_LINES_WARN={t.get(\"max_lines_warn\", 150)}')
print(f'MAX_LINES_FAIL={t.get(\"max_lines_fail\", 400)}')
print(f'MAX_AREAS_WARN={t.get(\"max_areas_warn\", 2)}')
print(f'MAX_AREAS_FAIL={t.get(\"max_areas_fail\", 3)}')
")"
fi

# --- collect changed files (includes untracked for parity with touch-scope-verify) ---
UNTACKED="$(git ls-files --others --exclude-standard 2>/dev/null || true)"
if [[ -n "${DIFF_RANGE}" ]]; then
  FILES="$( { git diff --name-only "${DIFF_RANGE}" 2>/dev/null; echo "${UNTACKED}"; } | sort -u | sed '/^$/d')"
  STAT="$(git diff --stat "${DIFF_RANGE}" 2>/dev/null | tail -1 || true)"
elif [[ "${CACHED_ONLY}" -eq 1 ]]; then
  FILES="$( { git diff --cached --name-only 2>/dev/null; echo "${UNTACKED}"; } | sort -u | sed '/^$/d')"
  STAT="$(git diff --cached --stat 2>/dev/null | tail -1 || true)"
else
  FILES="$( { git diff --name-only; git diff --cached --name-only; echo "${UNTACKED}"; } 2>/dev/null | sort -u | sed '/^$/d')"
  STAT="$( { git diff --stat; git diff --cached --stat; } 2>/dev/null | tail -1 || true)"
fi

if [[ -z "${FILES// }" ]]; then
  echo "blast-radius: clean (no changed files)"
  exit 0
fi

# --- line count (approx from stat summary) ---
LINES_CHANGED=0
if [[ -n "${STAT}" ]]; then
  LINES_CHANGED="$(echo "${STAT}" | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+' | head -1 || echo 0)"
  DEL="$(echo "${STAT}" | grep -oE '[0-9]+ deletion' | grep -oE '[0-9]+' | head -1 || echo 0)"
  LINES_CHANGED=$((LINES_CHANGED + DEL))
fi
[[ "${LINES_CHANGED}" -eq 0 ]] && LINES_CHANGED="$(echo "${FILES}" | wc -l | tr -d ' ')"

# --- top-level areas ---
AREAS="$(echo "${FILES}" | awk -F/ '{print ($1=="" ? "." : $1)}' | sort -u)"
AREA_COUNT="$(echo "${AREAS}" | grep -c . || echo 0)"

# --- protected surface hits ---
PROTECTED_HITS=""
if [[ -f "${SURFACES}" ]] && command -v python3 >/dev/null 2>&1; then
  PROTECTED_HITS="$(echo "${FILES}" | python3 -c "
import json, sys, fnmatch
files = [l.strip() for l in sys.stdin if l.strip()]
with open('${SURFACES}') as f:
    cfg = json.load(f)
hits = []
for path in files:
    for p in cfg.get('paths', []):
        if path == p or path.endswith('/' + p):
            hits.append(path)
            break
    else:
        for pat in cfg.get('patterns', []):
            if fnmatch.fnmatch(path, pat):
                hits.append(path)
                break
for h in sorted(set(hits)):
    print(h)
")"
fi

# --- risk classification ---
RISK="low"
BLOCK=0
WARN=0

if [[ "${AREA_COUNT}" -ge "${MAX_AREAS_FAIL}" ]]; then
  RISK="high"
  BLOCK=1
elif [[ "${AREA_COUNT}" -ge "${MAX_AREAS_WARN}" ]]; then
  RISK="medium"
  WARN=1
fi

if [[ "${LINES_CHANGED}" -ge "${MAX_LINES_FAIL}" ]]; then
  RISK="high"
  BLOCK=1
elif [[ "${LINES_CHANGED}" -ge "${MAX_LINES_WARN}" ]]; then
  [[ "${RISK}" == "low" ]] && RISK="medium"
  WARN=1
fi

if [[ -n "${PROTECTED_HITS// }" ]]; then
  [[ "${RISK}" != "high" ]] && RISK="medium"
  WARN=1
fi

# templates + skills + scripts in one diff = high
if echo "${AREAS}" | grep -qE '^(skills|scripts|templates)$' && [[ "${AREA_COUNT}" -ge 3 ]]; then
  RISK="high"
  BLOCK=1
fi

# --- output ---
echo "blast-radius: files=$(echo "${FILES}" | grep -c . || echo 0) lines~=${LINES_CHANGED} areas_crossed=${AREA_COUNT}"
echo "areas: $(echo "${AREAS}" | tr '\n' ' ' | sed 's/ $//')"
if [[ -n "${PROTECTED_HITS// }" ]]; then
  echo "protected_hits:"
  echo "${PROTECTED_HITS}" | sed 's/^/  /'
fi
echo "risk: ${RISK}"
if [[ "${BLOCK}" -eq 1 ]]; then
  # When every changed file is in declared scope, downgrade blocking high risk to warn.
  if [[ -x "${REPO_ROOT}/scripts/touch-scope-verify.sh" ]]; then
    if bash "${REPO_ROOT}/scripts/touch-scope-verify.sh" >/dev/null 2>&1; then
      BLOCK=0
      WARN=1
      echo "verdict: warn — high blast radius but all files in declared scope (touch-scope pass)"
      [[ "${WARN_EXIT0}" -eq 1 ]] && exit 0
      exit 2
    fi
  fi
  echo "verdict: fail — cross-area or large diff; narrow scope or get owner approval"
  exit 1
fi
if [[ "${WARN}" -eq 1 ]]; then
  echo "verdict: warn — review blast radius; run @concept-run - MOD-06"
  [[ "${WARN_EXIT0}" -eq 1 ]] && exit 0
  exit 2
fi
echo "verdict: ok"
exit 0
