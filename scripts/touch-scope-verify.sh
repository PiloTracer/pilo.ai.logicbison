#!/usr/bin/env bash
# Verify git diff stays within declared touch scope.
# Sources (union): .work/touch-scope (JSON), NEXT.md ## Current iteration task Files column.
#
# Usage:
#   bash scripts/touch-scope-verify.sh
#   bash scripts/touch-scope-verify.sh --strict          # fail/warn on undeclared scope
#   bash scripts/touch-scope-verify.sh --strict-fail     # fail (exit 1) on undeclared scope
#   bash scripts/touch-scope-verify.sh --self-test
#
# Exit: 0 in-scope or no scope declared (non-strict) | 1 out-of-scope files | 2 undeclared scope (strict)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[[ -n "${CHANGE_SAFETY_ROOT:-}" ]] && REPO_ROOT="${CHANGE_SAFETY_ROOT}"
cd "${REPO_ROOT}"

TOUCH_SCOPE="${REPO_ROOT}/.work/touch-scope"
NEXT="${REPO_ROOT}/.work/plans/NEXT.md"

STRICT=0
STRICT_FAIL=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --strict) STRICT=1; shift ;;
    --strict-fail) STRICT=1; STRICT_FAIL=1; shift ;;
    --self-test) break ;;
    *) shift ;;
  esac
done

if [[ "${1:-}" == "--self-test" ]]; then
  TMP="$(mktemp -d)"
  trap 'rm -rf "${TMP}"' EXIT
  mkdir -p "${TMP}/.work/plans"
  echo '{"allowed_paths":["allowed.txt"],"allowed_patterns":[]}' > "${TMP}/.work/touch-scope"
  (
    cd "${TMP}"
    git init -q
    git config user.email "t@t.com"
    git config user.name "t"
    echo ok > allowed.txt
    echo bad > rogue.txt
    git add .
    git commit -q -m "init"
    echo x >> rogue.txt
    if CHANGE_SAFETY_ROOT="${TMP}" bash "${REPO_ROOT}/scripts/touch-scope-verify.sh" >/dev/null 2>&1; then
      echo "FAIL: should reject out-of-scope rogue.txt" >&2
      exit 1
    fi
    git checkout -q rogue.txt 2>/dev/null || true
    echo y >> allowed.txt
    CHANGE_SAFETY_ROOT="${TMP}" bash "${REPO_ROOT}/scripts/touch-scope-verify.sh" >/dev/null || {
      echo "FAIL: should accept in-scope allowed.txt" >&2
      exit 1
    }
  )
  echo "touch-scope-verify self-test: PASS"
  exit 0
fi

FILES_LIST="$(mktemp)"
trap 'rm -f "${FILES_LIST}"' EXIT
{ git diff --name-only; git diff --cached --name-only; git ls-files --others --exclude-standard; } 2>/dev/null | sort -u > "${FILES_LIST}"

if [[ ! -s "${FILES_LIST}" ]]; then
  echo "touch-scope: clean (no changed files)"
  exit 0
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "touch-scope: skip (python3 required)" >&2
  exit 0
fi

RESULT="$(python3 << PY || true
import json, re, sys, fnmatch
from pathlib import Path

root = Path("${REPO_ROOT}")
allowed = set()
patterns = []

ts = root / ".work" / "touch-scope"
if ts.is_file():
    try:
        data = json.loads(ts.read_text())
        allowed.update(data.get("allowed_paths", []))
        patterns.extend(data.get("allowed_patterns", []))
    except json.JSONDecodeError as e:
        print(f"ERROR: invalid .work/touch-scope JSON: {e}", file=sys.stderr)
        sys.exit(1)

next_md = root / ".work" / "plans" / "NEXT.md"
if next_md.is_file():
    text = next_md.read_text()
    in_iter = False
    in_tasks = False
    for line in text.splitlines():
        if line.strip().startswith("## Current iteration"):
            in_iter = True
            continue
        if in_iter and line.startswith("## ") and "Current iteration" not in line:
            break
        if in_iter and "### Tasks" in line:
            in_tasks = True
            continue
        if in_tasks and line.startswith("###"):
            break
        if in_tasks and "|" in line and "-T" in line:
            parts = [p.strip().strip("\`") for p in line.split("|")]
            # Table: | ID | Description | Files | Status | Notes |  -> Files at index 3
            if len(parts) >= 5 and parts[1] and re.match(r"^[A-Za-z0-9][A-Za-z0-9-]*-T\d+$", parts[1], re.I):
                files_cell = parts[3]
                for chunk in re.split(r"[,;]", files_cell):
                    chunk = chunk.strip().strip("\`")
                    if chunk and chunk not in ("…", "...", "done", "pending", "in-progress", "complete"):
                        allowed.add(chunk)

files = [l.strip() for l in Path("${FILES_LIST}").read_text().splitlines() if l.strip()]

def in_scope(path):
    if path in allowed:
        return True
    for a in allowed:
        if path.startswith(a.rstrip("/") + "/"):
            return True
    for pat in patterns:
        if fnmatch.fnmatch(path, pat):
            return True
    return False

if not allowed and not patterns:
    print("NO_SCOPE")
    sys.exit(0)

out = [f for f in files if not in_scope(f)]
if out:
    print("OUT_OF_SCOPE")
    for f in out:
        print(f)
    sys.exit(1)

print("IN_SCOPE")
PY
)"

if [[ "${RESULT}" == "NO_SCOPE" ]]; then
  if [[ "${STRICT}" -eq 1 ]]; then
    echo "touch-scope: FAIL (strict) — undeclared scope with dirty tree"
    echo "Declare scope in .work/touch-scope or NEXT.md ## Current iteration task Files"
    [[ "${STRICT_FAIL}" -eq 1 ]] && exit 1
    exit 2
  fi
  echo "touch-scope: no scope declared (set .work/touch-scope or NEXT iteration Files)"
  exit 0
fi

if echo "${RESULT}" | head -1 | grep -q "OUT_OF_SCOPE"; then
  echo "touch-scope: FAIL — out-of-scope files:"
  echo "${RESULT}" | tail -n +2 | sed 's/^/  /'
  echo "Fix: narrow the diff or update .work/touch-scope / NEXT.md task Files"
  exit 1
fi

echo "touch-scope: pass (all changed files in declared scope)"
exit 0
