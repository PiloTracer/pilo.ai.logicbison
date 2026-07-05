#!/usr/bin/env bash
# Install Agent OS git hooks into the target repository's .git/hooks/.
#
# Usage (from application repo root):
#   bash .ai/scripts/install-git-hooks.sh
#   bash scripts/install-git-hooks.sh              # self-hosted Agent OS
#   REPO_ROOT=/path/to/app AI_SOURCE=/path/.ai bash .ai/scripts/install-git-hooks.sh
#
# Hook sources resolve in order:
#   1. AI_SOURCE env (explicit)
#   2. REPO_ROOT/.ai/hooks (fat-client)
#   3. AGENT_OS_SOURCE from .cursorrules (thin-client)
#   4. Script parent dir when REPO_ROOT is the Agent OS git root (self-hosted)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -n "${REPO_ROOT:-}" ]]; then
  REPO_ROOT="$(cd "$REPO_ROOT" && pwd)"
elif git rev-parse --show-toplevel >/dev/null 2>&1; then
  REPO_ROOT="$(git rev-parse --show-toplevel)"
else
  echo "skip: not inside a git repository (no .git/ to install hooks)" >&2
  exit 0
fi

resolve_ai_root() {
  if [[ -n "${AI_SOURCE:-}" ]]; then
    echo "$(cd "$AI_SOURCE" && pwd)"
    return 0
  fi
  if [[ -d "${REPO_ROOT}/.ai/hooks" ]]; then
    echo "${REPO_ROOT}/.ai"
    return 0
  fi
  if [[ -f "${REPO_ROOT}/.cursorrules" ]]; then
    local src
    src="$(grep -oE 'AGENT_OS_SOURCE=[^[:space:]]+' "${REPO_ROOT}/.cursorrules" 2>/dev/null | head -1 | cut -d= -f2- || true)"
    if [[ -n "$src" && -d "${src}/hooks" ]]; then
      echo "$src"
      return 0
    fi
  fi
  if [[ -d "${REPO_ROOT}/hooks" && -f "${REPO_ROOT}/skills/README.md" ]]; then
    echo "$REPO_ROOT"
    return 0
  fi
  if [[ -d "${SCRIPT_DIR}/../hooks" ]]; then
    echo "$(cd "${SCRIPT_DIR}/.." && pwd)"
    return 0
  fi
  return 1
}

AI_ROOT="$(resolve_ai_root)" || {
  echo "skip: could not locate Agent OS hooks source under ${REPO_ROOT}" >&2
  exit 0
}

HOOK_SRC="${AI_ROOT}/hooks"
GIT_HOOKS="${REPO_ROOT}/.git/hooks"

if [[ ! -d "${REPO_ROOT}/.git" ]]; then
  echo "skip: ${REPO_ROOT} has no .git/ directory" >&2
  exit 0
fi

mkdir -p "${GIT_HOOKS}"

installed=0
for name in prepare-commit-msg commit-msg pre-commit post-commit; do
  src="${HOOK_SRC}/${name}"
  dest="${GIT_HOOKS}/${name}"
  if [[ ! -f "$src" ]]; then
    continue
  fi
  cp "$src" "$dest"
  chmod +x "$dest"
  echo "installed: .git/hooks/${name} (from ${AI_ROOT}/hooks/${name})"
  installed=$((installed + 1))
done

if [[ "$installed" -eq 0 ]]; then
  echo "skip: no hook files found in ${HOOK_SRC}" >&2
  exit 0
fi

echo "Agent OS git hooks: ${installed} installed into ${REPO_ROOT}"
