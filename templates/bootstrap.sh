#!/usr/bin/env bash
# Bootstrap Agent OS into a repository root (run from repo root, not from inside .ai/ only).
set -euo pipefail

AI_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TPL="${AI_ROOT}/templates/work"

# Repo root: git root containing .ai/, or AI_ROOT itself when this repository *is* the Agent OS tree.
# Honor an explicit REPO_ROOT env override so scaffold can write into a TARGET
# directory when bootstrap.sh is invoked from an external source .ai
# (in-place bootstrap via @deploy-files). e.g.
#   REPO_ROOT=/mnt/work/Projects/tools-project bash /mnt/work/Projects/.ai/templates/bootstrap.sh
if [[ -n "${REPO_ROOT:-}" ]]; then
  REPO_ROOT="$(cd "$REPO_ROOT" && pwd)"
elif [[ -d "${AI_ROOT}/.git" ]]; then
  REPO_ROOT="${AI_ROOT}"
elif [[ -d "${AI_ROOT}/../.git" ]] && [[ -d "${AI_ROOT}/templates" ]]; then
  REPO_ROOT="$(cd "${AI_ROOT}/.." && pwd)"
else
  REPO_ROOT="${AI_ROOT}"
fi

WORK="${REPO_ROOT}/.work"

copy_if_missing() {
  local src="$1" dest="$2"
  if [[ -e "${dest}" ]]; then
    echo "skip (exists): ${dest}"
  else
    mkdir -p "$(dirname "${dest}")"
    cp "${src}" "${dest}"
    echo "created: ${dest}"
  fi
}

echo "Agent OS bootstrap"
echo "  AI_ROOT=${AI_ROOT}"
echo "  REPO_ROOT=${REPO_ROOT}"
echo ""

mkdir -p "${WORK}"

copy_if_missing "${TPL}/README.md.template" "${WORK}/README.md"
copy_if_missing "${TPL}/context/HANDOFF.md.template" "${WORK}/context/HANDOFF.md"
copy_if_missing "${TPL}/plans/NEXT.md.template" "${WORK}/plans/NEXT.md"
copy_if_missing "${TPL}/plans/ASSUMPTIONS.md.template" "${WORK}/plans/ASSUMPTIONS.md"
copy_if_missing "${TPL}/plans/RISK_REGISTRY.md.template" "${WORK}/plans/RISK_REGISTRY.md"
copy_if_missing "${TPL}/plans/UNKNOWNS.md.template" "${WORK}/plans/UNKNOWNS.md"
copy_if_missing "${TPL}/touch-scope.template" "${WORK}/touch-scope"
copy_if_missing "${TPL}/PROTECTED_SURFACES.template" "${WORK}/PROTECTED_SURFACES.json"
copy_if_missing "${TPL}/decisions/README.md.template" "${WORK}/decisions/README.md"
copy_if_missing "${TPL}/prompts/README.md.template" "${WORK}/prompts/README.md"
copy_if_missing "${TPL}/features/README.md.template" "${WORK}/features/README.md"
copy_if_missing "${TPL}/docs/README.md.template" "${WORK}/docs/README.md"
copy_if_missing "${TPL}/docs/features/README.md.template" "${WORK}/docs/features/README.md"

for dir in foundation full operations proposals archives; do
  mkdir -p "${WORK}/plans/${dir}"
  touch "${WORK}/plans/${dir}/.gitkeep"
done

# Create output-sink dirs (not populated by bootstrap; appear when work runs)
for dir in analysis scripts; do
  mkdir -p "${WORK}/${dir}"
  touch "${WORK}/${dir}/.gitkeep"
done

# Create docs subdirectories (populated by @docs skill)
for dir in guides tutorials reference; do
  mkdir -p "${WORK}/docs/${dir}"
  touch "${WORK}/docs/${dir}/.gitkeep"
done

if [[ -n "${BOOTSTRAP_SKIP_CURSERRULES:-}" ]]; then
  echo "skip (.cursorrules owned by caller): ${REPO_ROOT}/.cursorrules"
elif [[ ! -f "${REPO_ROOT}/.cursorrules" ]]; then
  if [[ -f "${AI_ROOT}/templates/cursorrules.template" ]]; then
    cp "${AI_ROOT}/templates/cursorrules.template" "${REPO_ROOT}/.cursorrules"
    echo "created: ${REPO_ROOT}/.cursorrules (from template — edit all REPLACE: tokens)"
  fi
else
  echo "skip (exists): ${REPO_ROOT}/.cursorrules"
fi

if [[ -f "${AI_ROOT}/templates/DOCS_TECH_STACK.md.template" ]]; then
  dest="${REPO_ROOT}/DOCS_TECH_STACK.md"
  if [[ ! -f "${dest}" ]]; then
    cp "${AI_ROOT}/templates/DOCS_TECH_STACK.md.template" "${dest}"
    echo "created: ${dest}"
  else
    echo "skip (exists): ${dest}"
  fi
fi

echo ""
echo "Next steps:"
echo "  1. Edit ${REPO_ROOT}/.cursorrules — replace every REPLACE: token"
echo "  2. Customize ${AI_ROOT}/standards/20260517-*.md (or copy/rename)"
echo "  3. Run @plan-foundation greenfield (creates foundation docs 01–04)"
echo "  4. Run @session-control start"
echo "  5. Using opencode? opencode.json is created from template when missing (see scripts/install-opencode-config.sh)"
echo ""

bash "${AI_ROOT}/scripts/install-git-hooks.sh" 2>/dev/null || true

REPO_ROOT="${REPO_ROOT}" AI_SOURCE="${AI_ROOT}" bash "${AI_ROOT}/scripts/install-opencode-config.sh" 2>/dev/null || true

echo "Templates for foundation/full/SPEC/ADR: ${AI_ROOT}/templates/work/"
