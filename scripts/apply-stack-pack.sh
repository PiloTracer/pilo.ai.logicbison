#!/usr/bin/env bash
# Copy a templates/stacks/<pack>/ fragment tree into a consumer repo (non-destructive).
#
# Usage:
#   bash scripts/apply-stack-pack.sh <pack> <target-repo-root>
#   bash scripts/apply-stack-pack.sh --list
#
# Never overwrites existing files unless APPLY_STACK_OVERWRITE=1.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STACKS_ROOT="${REPO_ROOT}/templates/stacks"

list_packs() {
  local d name
  if [[ ! -d "${STACKS_ROOT}" ]]; then
    echo "No stacks directory: ${STACKS_ROOT}" >&2
    exit 1
  fi
  for d in "${STACKS_ROOT}"/*/; do
    [[ -d "${d}" ]] || continue
    name="${d%/}"
    printf '%s\n' "${name##*/}"
  done | sort
}

usage() {
  echo "Usage: bash scripts/apply-stack-pack.sh <pack> <target-repo-root>" >&2
  echo "       bash scripts/apply-stack-pack.sh --list" >&2
  exit 2
}

if [[ "${1:-}" == "--list" ]]; then
  list_packs
  exit 0
fi

PACK="${1:-}"
TARGET="${2:-}"
[[ -n "${PACK}" && -n "${TARGET}" ]] || usage

PACK_DIR="${STACKS_ROOT}/${PACK}"
if [[ ! -d "${PACK_DIR}" ]]; then
  echo "Unknown pack '${PACK}'. Available:" >&2
  list_packs >&2
  exit 1
fi

TARGET="$(cd "${TARGET}" && pwd)"
mkdir -p "${TARGET}/.work/standards"

copied=0
skipped=0
while IFS= read -r -d '' src; do
  rel="${src#"${PACK_DIR}/"}"
  dest="${TARGET}/${rel}"
  mkdir -p "$(dirname "${dest}")"
  if [[ -e "${dest}" ]]; then
    if [[ "${APPLY_STACK_OVERWRITE:-0}" == "1" ]]; then
      cp "${src}" "${dest}"
      copied=$((copied + 1))
    else
      echo "skip (exists): ${rel}"
      skipped=$((skipped + 1))
    fi
  else
    cp "${src}" "${dest}"
    echo "copied: ${rel}"
    copied=$((copied + 1))
  fi
done < <(find "${PACK_DIR}" -type f -print0)

echo "apply-stack-pack: pack=${PACK} target=${TARGET} copied=${copied} skipped=${skipped}"
echo "Next: merge fragments per templates/stacks/${PACK}/README.md (do not blind-replace CONVENTIONS or compose)."