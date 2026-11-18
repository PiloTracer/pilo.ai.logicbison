#!/usr/bin/env bash
# Smoke: templates/bootstrap.sh in a clean temp repo — required scaffolding exists.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/aos-bootstrap-smoke.XXXXXX")"
trap 'rm -rf "${TMP}"' EXIT

mkdir -p "${TMP}/.git"
git -C "${TMP}" init -q

# Self-hosted layout: copy bootstrap entrypoint path consumers use.
if [[ -f "${REPO_ROOT}/templates/bootstrap.sh" ]]; then
  BS="${REPO_ROOT}/templates/bootstrap.sh"
else
  echo "bootstrap-smoke: missing templates/bootstrap.sh" >&2
  exit 1
fi

# Run as if nested .ai (simulate consumer with copied template tree).
mkdir -p "${TMP}/.ai"
rsync -a --exclude='.git' "${REPO_ROOT}/templates/" "${TMP}/.ai/templates/" 2>/dev/null || cp -a "${REPO_ROOT}/templates" "${TMP}/.ai/"
export AGENT_OS_SOURCE="${REPO_ROOT}"
( cd "${TMP}" && bash .ai/templates/bootstrap.sh )

for f in .work/context/HANDOFF.md .work/plans/NEXT.md .cursorrules; do
  [[ -s "${TMP}/${f}" ]] || { echo "bootstrap-smoke: missing or empty ${f}" >&2; exit 1; }
done

echo "bootstrap-smoke: OK (${TMP})"