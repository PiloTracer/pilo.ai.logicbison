#!/usr/bin/env bash
# sister-discovery.sh — shared sister-framework discovery for Agent OS deploy scripts.
#
# Framework IDs are stable (`.ai.ui` = UI Design OS, `.ai.biz` = Business OS,
# `.ai.cto` = CTO Professor OS, `.ai.flutter` = Flutter Agent OS, `.ai.mlt` =
# MLT Agent OS, `.ai.soc` = Social OS). The on-disk DIRECTORY NAME of a sister
# framework may follow either convention:
#   - family naming:  source basename with `<fw>` inserted before its last
#                     dot-segment — e.g. source `pilo.ai.logicbison` → sister
#                     `pilo.ai.ui.logicbison`; when the second-to-last segment
#                     is itself a known framework slot (see FRAMEWORK_SLOTS),
#                     the source is a sister framework and its siblings REPLACE
#                     that slot: `pilo.ai.ui.logicbison` → `pilo.ai.biz.logicbison`
#   - legacy naming:  `.ai.<fw>` (original convention). Sources whose name
#                     starts with `.ai` (e.g. `.ai`, `.ai.biz`) resolve
#                     `.ai.<fw>` directly — they carry no family prefix/tail.
#
# Non-standard source dir names (e.g. `my-framework`): candidates fall back to
# `<name>.<fw>` + legacy `.ai.<fw>`; if the sister lives under an unrelated
# name, fill the `REPLACE:AI_*_PATH` cell manually (deploy output lists what
# it checked — see .cursorrules § Frameworks registry path resolution).
#
# Sourced by scripts/deploy-basic.sh and scripts/cursorrules-verify.sh.
# scripts/install-opencode-config.sh mirrors this logic in python — keep in sync.
#
# Functions (pure; no side effects):
#   sister_names <fw> <ai-root>   → candidate dir names, preferred first
#   find_sister_dir <ai-root> <fw> [parent...] → first existing dir with
#                                  skills/README.md (exit 1 when none)
#   agent_os_names <ai-root>      → candidate dir names for the Agent OS root
#   find_agent_os_dir <ai-root> [parent...] → first existing Agent OS root
#                                  (exit 1 when none — caller asks the user)
set -euo pipefail

# The six sibling framework slots (framework IDs). Order also drives the
# deploy-time registry fill loops and the slot-replace rule.
FRAMEWORK_SLOTS="ui biz soc cto flutter mlt"

# sister_names <fw> <ai-root> — most-preferred candidate first.
#   pilo.ai.logicbison, ui     → pilo.ai.ui.logicbison / .ai.ui
#   pilo.ai.ui.logicbison, biz → pilo.ai.biz.logicbison / .ai.biz  (slot replace)
#   .ai.biz, ui                → .ai.ui                             (legacy source)
#   .ai, ui                    → .ai.ui (deduped)
#   agent-os, ui               → agent-os.ui / .ai.ui
sister_names() {
  local fw="$1" root="$2" name stem tail stem2 last
  name="$(basename "$root")"
  if [[ "$name" == .ai || "$name" == .ai.* ]]; then
    # Legacy-named source (`.ai`, `.ai.biz`, …): sisters are `.ai.<fw>` only —
    # the name carries no family prefix/tail to derive family naming from.
    printf '.ai.%s\n' "$fw"
    return 0
  fi
  if [[ "$name" == *.*.* ]]; then
    # ≥3 dot-segments: insert <fw> before the last segment (org-suffix pattern).
    stem="${name%.*}"
    tail="${name##*.}"
    stem2="${stem%.*}"
    last="${stem##*.}"
    case " $FRAMEWORK_SLOTS " in
      *" $last "*) stem="$stem2" ;;   # source is a sister framework → replace slot
    esac
    printf '%s.%s.%s\n' "$stem" "$fw" "$tail"
  else
    # ≤2 dot-segments (family `pilo.ai`, no-dot names): append.
    printf '%s.%s\n' "$name" "$fw"
  fi
  # Legacy fallback candidate.
  printf '.ai.%s\n' "$fw"
}

# find_sister_dir <ai-root> <fw> [parent...] — prints the first existing framework
# dir (must contain skills/README.md) among candidate names × candidate parents.
# Default parents: the source's parent, then the caller's parent.
find_sister_dir() {
  local root="$1" fw="$2"
  shift 2
  local name p p2 d
  local parents=()
  if [[ $# -gt 0 ]]; then
    parents=("$@")
  else
    parents=("$(cd "$root/.." && pwd)" "$(cd "$PWD/.." && pwd)")
  fi
  while IFS= read -r name; do
    for p in "${parents[@]}"; do
      p2="$(cd "$p" 2>/dev/null && pwd)" || continue
      d="${p2}/${name}"
      if [[ -f "${d}/skills/README.md" ]]; then
        printf '%s' "$d"
        return 0
      fi
    done
  done < <(sister_names "$fw" "$root")
  return 1
}

# agent_os_names <ai-root> — candidate dir names for the Agent OS root (the
# "big brother" orchestrator framework, registry row `.ai`), most-preferred
# first: the family name derived from the source basename with its framework
# slot removed (`pilo.ai.biz.logicbison` → `pilo.ai.logicbison`,
# `.ai.biz` → `.ai`), then the well-known family root `pilo.ai.logicbison`,
# then legacy `.ai`.
agent_os_names() {
  local root="$1" name stem tail stem2 last fam=""
  name="$(basename "$root")"
  # Family-named sources (≥3 dot segments, e.g. pilo.ai.biz.logicbison): the
  # derived family root is the strongest candidate. Legacy `.ai.*` sources
  # carry no family prefix to derive from — they fall through to the two
  # well-known names below (family root preferred over the legacy `.ai`).
  if [[ "$name" == *.*.* && "$name" != .ai* ]]; then
    stem="${name%.*}"; tail="${name##*.}"; stem2="${stem%.*}"; last="${stem##*.}"
    case " $FRAMEWORK_SLOTS " in
      *" $last "*) fam="${stem2}.${tail}" ;;   # source is a sister → drop its slot
    esac
  fi
  [[ -n "$fam" && "$fam" != "$name" ]] && printf '%s\n' "$fam"
  printf 'pilo.ai.logicbison\n.ai\n'
}

# find_agent_os_dir <ai-root> [parent...] — first existing Agent OS root among
# agent_os_names × parents (must contain skills/README.md). Empty output +
# exit 1 when neither `../.ai` nor the family root exists — the caller must ask
# the user for the correct path rather than guess.
find_agent_os_dir() {
  local root="$1"
  shift
  local name p p2 d seen=""
  local parents=()
  if [[ $# -gt 0 ]]; then
    parents=("$@")
  else
    parents=("$(cd "$root/.." && pwd)" "$(cd "$PWD/.." && pwd)")
  fi
  while IFS= read -r name; do
    [[ "$name" == "$seen" ]] && continue; seen="$name"
    for p in "${parents[@]}"; do
      p2="$(cd "$p" 2>/dev/null && pwd)" || continue
      d="${p2}/${name}"
      if [[ -f "${d}/skills/README.md" ]]; then
        printf '%s' "$d"
        return 0
      fi
    done
  done < <(agent_os_names "$root")
  return 1
}
