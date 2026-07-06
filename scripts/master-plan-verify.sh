#!/usr/bin/env bash
# Agent OS master-plan-verify - mechanically enforce MASTER_PLAN_STANDARD.md
# (.ai/standards/20260519-MASTER_PLAN_STANDARD.md) so a plan cannot be treated
# as complete/Approved by narrative alone.
#
# Checks:
#   1. Section completeness - all 25 mandatory "## N. <title>" H2 headings
#      (N=1..25) are present, in order (a later section may not appear before
#      an earlier one). This is the single most common drift: templates or
#      fast-forwarded plans silently drop mid-numbered sections (§9-18, §22-25
#      are the ones agents skip most often because early sections front-load
#      the roadmap).
#   2. Approval gate consistency - if the header declares `Status: Approved`,
#      the plan's own Integrity/P5 field must NOT read "pending" (turns
#      MASTER_PLAN_STANDARD §4.3 "integrity check passes" into a test instead
#      of a narrative claim).
#
# Usage:
#   bash master-plan-verify.sh                 # scan .work/plans/full/*-full-plan.md (latest by name)
#   bash master-plan-verify.sh path/to/plan.md [more...]
#
# Exit 0 = conformant (or no master plan found - planning optional);
# exit 1 = at least one violation.
set -euo pipefail

failures=0
note() { echo "==> $*"; }
ok()   { echo "    OK: $*"; }
die()  { echo "    FAIL: $*" >&2; failures=$((failures + 1)); }

files=()
if [[ $# -gt 0 ]]; then
  files=("$@")
else
  plan="$(find .work/plans/full -name '*-full-plan.md' 2>/dev/null | sort | tail -1 || true)"
  if [[ -z "${plan}" ]]; then
    note "master-plan-verify: no master plan found (planning optional) - nothing to check"
    exit 0
  fi
  files=("${plan}")
fi

note "Agent OS master-plan-verify (${#files[@]} file(s))"

for f in "${files[@]}"; do
  if [[ ! -f "${f}" ]]; then
    die "${f}: not found"
    continue
  fi

  result="$(awk '
    BEGIN{ max_seen=0 }
    # Mandatory H2: "## N. Title" or "## N - Title" (allow . or - after the number)
    /^##[ \t]+[0-9]+[.\-]/ {
      line=$0
      sub(/^##[ \t]+/, "", line)
      n=line+0
      if (n>=1 && n<=25) {
        seen[n]=1
        if (n < max_seen) print "OUT_OF_ORDER:" n
        if (n > max_seen) max_seen=n
      }
    }
    /^\*\*Status:\*\*/ {
      s=$0
      if (s ~ /Approved/) approved=1
    }
    /Integrity[ \t]*\(P5\):/ || /P5[ \t]+integrity/ {
      if (tolower($0) ~ /pending/) integrity_pending=1
      if (tolower($0) ~ /pass/) integrity_pass=1
    }
    END{
      for (n=1; n<=25; n++) if (!(n in seen)) print "MISSING:" n
      printf "SUMMARY: approved=%d integrity_pending=%d integrity_pass=%d\n", approved+0, integrity_pending+0, integrity_pass+0
    }
  ' "${f}")"

  file_fail=0
  missing=()
  out_of_order=()
  approved=0
  integrity_pending=0
  integrity_pass=0
  while IFS= read -r line; do
    case "${line}" in
      MISSING:*) missing+=("${line#MISSING:}") ;;
      OUT_OF_ORDER:*) out_of_order+=("${line#OUT_OF_ORDER:}") ;;
      SUMMARY:*)
        # shellcheck disable=SC2086
        set -- ${line#SUMMARY: }
        approved="${1#approved=}"; integrity_pending="${2#integrity_pending=}"; integrity_pass="${3#integrity_pass=}"
        ;;
    esac
  done <<< "${result}"

  if [[ "${#missing[@]}" -gt 0 ]]; then
    die "${f}: missing mandatory H2 section(s) (MASTER_PLAN_STANDARD §2): ${missing[*]}"
    file_fail=1
  fi
  if [[ "${#out_of_order[@]}" -gt 0 ]]; then
    die "${f}: section(s) out of order vs MASTER_PLAN_STANDARD §2 ordering: ${out_of_order[*]}"
    file_fail=1
  fi
  if [[ "${approved}" -eq 1 && "${integrity_pending}" -eq 1 && "${integrity_pass}" -eq 0 ]]; then
    die "${f}: Status: Approved but Integrity (P5) still reads 'pending' - Approval gate (§4.3) requires integrity pass or documented waivers before Approved"
    file_fail=1
  fi

  [[ "${file_fail}" -eq 0 ]] && ok "${f}: all 25 mandatory H2 sections present and ordered; Approval/integrity consistent"
done

if [[ "${failures}" -gt 0 ]]; then
  echo ""
  echo "master-plan-verify: ${failures} violation(s)" >&2
  exit 1
fi

echo ""
echo "master-plan-verify: standard conformance satisfied"
