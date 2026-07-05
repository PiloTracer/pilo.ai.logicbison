#!/usr/bin/env bash
# Validate MOD-06 output against required sections from concepts/ai-amplification/prompt.md.
# Usage:
#   bash scripts/mod06-output-check.sh <output-file>
#   bash scripts/mod06-output-check.sh --self-test
#
# Exit: 0 valid | 1 missing sections | 2 file not found
set -euo pipefail

if [[ "${1:-}" == "--self-test" ]]; then
  TMP="$(mktemp -d)"
  trap 'rm -rf "${TMP}"' EXIT

  # valid output
  cat > "${TMP}/valid.md" << 'EOF'
## AI change risk summary
- AI-assisted: yes
- Blast radius: if broken, users can't log in.

## Recommendation
merge_ok

## Conditions if merge_with_conditions
EOF

  # missing blast radius
  cat > "${TMP}/no-blast.md" << 'EOF'
## AI change risk summary
- AI-assisted: yes

## Recommendation
merge_ok
EOF

  # missing recommendation
  cat > "${TMP}/no-reco.md" << 'EOF'
## AI change risk summary
- AI-assisted: yes
- Blast radius: something breaks
EOF

  PASS=0
  FAIL=0

  REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  if bash "${REPO}/scripts/mod06-output-check.sh" "${TMP}/valid.md" >/dev/null 2>&1; then
    PASS=$((PASS + 1))
  else
    echo "FAIL: valid should pass" >&2
    FAIL=$((FAIL + 1))
  fi

  if bash "${REPO}/scripts/mod06-output-check.sh" "${TMP}/no-blast.md" >/dev/null 2>&1; then
    echo "FAIL: no-blast should fail" >&2
    FAIL=$((FAIL + 1))
  else
    PASS=$((PASS + 1))
  fi

  if bash "${REPO}/scripts/mod06-output-check.sh" "${TMP}/no-reco.md" >/dev/null 2>&1; then
    echo "FAIL: no-reco should fail" >&2
    FAIL=$((FAIL + 1))
  else
    PASS=$((PASS + 1))
  fi

  # file not found
  if bash "${REPO}/scripts/mod06-output-check.sh" "${TMP}/nope.md" >/dev/null 2>&1; then
    echo "FAIL: missing file should fail" >&2
    FAIL=$((FAIL + 1))
  else
    PASS=$((PASS + 1))
  fi

  echo "mod06-output-check self-test: ${PASS}/4 PASS, ${FAIL}/4 FAIL"
  [[ "${FAIL}" -eq 0 ]] && exit 0 || exit 1
fi

FILE="${1:-}"
if [[ -z "${FILE}" ]]; then
  echo "Usage: bash scripts/mod06-output-check.sh <output-file>" >&2
  exit 2
fi

if [[ ! -f "${FILE}" ]]; then
  echo "mod06-output: FAIL — file not found: ${FILE}"
  exit 2
fi

CONTENT="$(cat "${FILE}")"
MISSING=()

# Required section 1: AI change risk summary with blast radius
if ! echo "${CONTENT}" | grep -q "## AI change risk summary"; then
  MISSING+=("## AI change risk summary")
elif ! echo "${CONTENT}" | grep -qi "blast radius"; then
  MISSING+=("Blast radius paragraph (in ## AI change risk summary)")
fi

# Required section 2: Recommendation
if ! echo "${CONTENT}" | grep -q "## Recommendation"; then
  MISSING+=("## Recommendation")
fi

# Required section 3: Conditions (only when recommendation is merge_with_conditions)
if echo "${CONTENT}" | grep -qi "merge_with_conditions"; then
  if ! echo "${CONTENT}" | grep -q "## Conditions"; then
    MISSING+=("## Conditions (required when Recommendation is merge_with_conditions)")
  fi
fi

if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo "mod06-output: FAIL — missing required sections:"
  for m in "${MISSING[@]}"; do
    echo "  - ${m}"
  done
  echo "Reference: concepts/ai-amplification/prompt.md § Output (required sections)"
  exit 1
fi

echo "mod06-output: pass (all required sections present)"
exit 0
