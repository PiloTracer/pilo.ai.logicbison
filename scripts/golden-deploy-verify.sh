#!/usr/bin/env bash
# Golden manifest checks for deploy/bootstrap outputs (behavioral regression).
# Called from framework-verify.sh after deploy smokes create fixture trees.
#
# Usage: bash scripts/golden-deploy-verify.sh <fixture-dir> <profile>
# Profiles: deploy-files-inplace | deploy-basic-thin
set -euo pipefail

FIXTURE="${1:-}"
PROFILE="${2:-}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GOLDEN="${REPO_ROOT}/scripts/fixtures/golden"

if [[ -z "${FIXTURE}" || -z "${PROFILE}" || ! -d "${FIXTURE}" ]]; then
  echo "Usage: bash scripts/golden-deploy-verify.sh <fixture-dir> <profile>" >&2
  exit 2
fi

MANIFEST="${GOLDEN}/${PROFILE}.manifest"
if [[ ! -f "${MANIFEST}" ]]; then
  echo "golden-deploy: skip — no manifest for ${PROFILE}" >&2
  exit 0
fi

failures=0
while IFS= read -r rel; do
  [[ -z "${rel}" || "${rel}" =~ ^# ]] && continue
  if [[ ! -e "${FIXTURE}/${rel}" ]]; then
    echo "    FAIL golden ${PROFILE}: missing ${rel}" >&2
    failures=$((failures + 1))
  fi
done < "${MANIFEST}"

case "${PROFILE}" in
  deploy-files-inplace)
    if [[ -f "${FIXTURE}/.cursorrules" ]]; then
      grep -q "Core Principles" "${FIXTURE}/.cursorrules" || {
        echo "    FAIL golden: .cursorrules missing Core Principles" >&2
        failures=$((failures + 1))
      }
      # Deep: verify key sections present (not just file exists)
      for section in "Identity" "Protected Files" "Commit Message Format" "Skills" "Change safety"; do
        grep -q "${section}" "${FIXTURE}/.cursorrules" || {
          echo "    FAIL golden: .cursorrules missing section '${section}'" >&2
          failures=$((failures + 1))
        }
      done
    fi
    # Deep: verify .work/ scaffolding has required files with content
    for f in HANDOFF.md; do
      if [[ -f "${FIXTURE}/.work/context/${f}" ]]; then
        [[ -s "${FIXTURE}/.work/context/${f}" ]] || {
          echo "    FAIL golden: .work/context/${f} is empty" >&2
          failures=$((failures + 1))
        }
      fi
    done
    if [[ -f "${FIXTURE}/.work/plans/NEXT.md" ]]; then
      [[ -s "${FIXTURE}/.work/plans/NEXT.md" ]] || {
        echo "    FAIL golden: .work/plans/NEXT.md is empty" >&2
        failures=$((failures + 1))
      }
    fi
    # Deep: verify skills/ under .ai/ (deploy-files target is <repo>/.ai/)
    SKILL_ROOT="${FIXTURE}/.ai/skills"
    [[ -d "${SKILL_ROOT}" ]] || SKILL_ROOT="${FIXTURE}/skills"
    SKILL_COUNT=$(ls -d "${SKILL_ROOT}"/*/ 2>/dev/null | wc -l)
    if [[ "${SKILL_COUNT}" -lt 14 ]]; then
      echo "    FAIL golden: skills/ has ${SKILL_COUNT} dirs (expected ≥14)" >&2
      failures=$((failures + 1))
    fi
    ;;
  deploy-basic-thin)
    if [[ -f "${FIXTURE}/opencode.json" ]] && command -v python3 >/dev/null 2>&1; then
      python3 -c "
import json, sys
c = json.load(open('${FIXTURE}/opencode.json'))
assert 'skills' in c and 'paths' in c['skills'], c
assert len(c['skills']['paths']) >= 1
" || { echo "    FAIL golden: opencode.json structure" >&2; failures=$((failures + 1)); }
      # Deep: verify each skill path entry is non-empty
      python3 -c "
import json
c = json.load(open('${FIXTURE}/opencode.json'))
for p in c['skills']['paths']:
    assert p.strip(), f'empty path in skills.paths: {c[\"skills\"][\"paths\"]}'
assert 'mcp' in c or 'agent' in c, 'neither mcp nor agent block in opencode.json'
" || { echo "    FAIL golden: opencode.json keys validation" >&2; failures=$((failures + 1)); }
    fi
    ;;
esac

if [[ "${failures}" -gt 0 ]]; then
  echo "golden-deploy-verify: ${failures} failure(s)" >&2
  exit 1
fi
echo "    OK golden ${PROFILE}"
exit 0
