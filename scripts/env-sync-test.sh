#!/usr/bin/env bash
# env-sync-test.sh - regression suite for scripts/env-sync.sh.
#
# Proves the 1-to-1 contract end to end, using dummy values only:
#   * status detects key and comment/blank-line drift
#   * apply aligns keys AND comments, preserves values, keeps the file mode
#   * verify fails on comment-only drift and on missing/extra lines
#   * apply converges (second run writes nothing) and normalizes comments
#   * target-only keys abort apply with no writes
#   * duplicate reference keys / CRLF / missing reference fail closed
#   * verify --backup catches value drift
#
# Usage: bash scripts/env-sync-test.sh
# Exit codes: 0 pass, 1 any check failed.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_SYNC="${SCRIPT_DIR}/env-sync.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/env-sync-test.XXXXXX")"
PROJ="${TMP}/proj"
BACKUP="${TMP}/backup"
OUT="${TMP}/out"
SECRET="sk-test-not-a-real-key"
CHECKS=0
FAILURES=0

cleanup() { rm -rf "${TMP}"; }
trap cleanup EXIT INT TERM

say() { printf '%s\n' "$*"; }

ok() {
  CHECKS=$((CHECKS + 1))
  printf 'ok - %s\n' "$*"
}

bad() {
  CHECKS=$((CHECKS + 1))
  FAILURES=$((FAILURES + 1))
  printf 'FAIL - %s\n' "$*"
  if [ -s "${OUT}" ]; then sed -n '1,14p' "${OUT}" | sed 's/^/    /'; fi
}

expect_rc() { # WANT LABEL CMD...
  local want="$1" label="$2" got
  shift 2
  set +e
  "$@" >"${OUT}" 2>&1
  got=$?
  set -e
  if [ "${got}" -eq "${want}" ]; then
    ok "${label} (rc ${got})"
  else
    bad "${label} (expected rc ${want}, got ${got})"
  fi
}

expect_out() { # NEEDLE LABEL
  if grep -qF -- "$1" "${OUT}"; then ok "$2"; else bad "$2 (missing: $1)"; fi
}

expect_no_out() { # NEEDLE LABEL
  if grep -qF -- "$1" "${OUT}"; then bad "$2 (unexpected: $1)"; else ok "$2"; fi
}

hash_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -d' ' -f1
  else
    shasum -a 256 "$1" | cut -d' ' -f1
  fi
}

file_mode() {
  if stat -c '%a' "$1" >/dev/null 2>&1; then
    stat -c '%a' "$1"
  else
    stat -f '%Lp' "$1"
  fi
}

line_count() { awk 'END { print NR }' "$1"; }

# Mask the text after "=" so a skeleton diff never renders a value.
mask_values() {
  sed -E 's/^([[:space:]]*export[[:space:]]+)?[A-Za-z_][A-Za-z0-9_]*=.*/\1<ASSIGNMENT>/' "$1"
}

assert_skeleton() { # A B LABEL
  if diff -u <(mask_values "$1") <(mask_values "$2") >"${TMP}/skeleton.diff"; then
    ok "$3"
  else
    bad "$3 (skeleton differs)"
    sed -n '1,20p' "${TMP}/skeleton.diff" | sed 's/^/    /'
  fi
}

assert_value() { # KEY EXPECTED LABEL
  if grep -qxF "$1" "$2"; then
    ok "$3"
  else
    bad "$3"
  fi
}

# --- fixture ---------------------------------------------------------------
mkdir -p "${PROJ}"
cat >"${PROJ}/.env.example" <<'EOF'
# stack identity
COMPOSE_PROJECT_NAME=demo
APP_ENV=development
AI_API_KEY=
# The hard ceiling for every provider call this stack makes, in USD. The
# default is 1: a demo budget. Raise it deliberately.
AI_MONTHLY_BUDGET_USD=1
# DeepSeek peak windows are UTC; every other hour is half price.
AI_OFFPEAK_ONLY=false
AI_PEAK_WINDOWS=01:00-04:00
# Retired with ADR 015; kept commented for reference.
# CADDY_HTTP_PORT=
EOF
cat >"${PROJ}/.env.prd" <<EOF
COMPOSE_PROJECT_NAME=prod
APP_ENV=production
AI_API_KEY=${SECRET}
AI_MONTHLY_BUDGET_USD=1
AI_OFFPEAK_ONLY=true
AI_PEAK_WINDOWS=01:00-04:00
EOF
chmod 600 "${PROJ}/.env.prd"
REF_HASH="$(hash_file "${PROJ}/.env.example")"
PRD_HASH="$(hash_file "${PROJ}/.env.prd")"

say "env-sync-test: fixture ${PROJ}"

# --- 1. read-only drift detection -----------------------------------------
expect_rc 0 "status renders drift" bash "${ENV_SYNC}" status --dir "${PROJ}"
expect_out "DRIFT" "status reports DRIFT"
expect_out "layout" "status reports the layout dimension"
expect_no_out "${SECRET}" "status never prints a value"
if [ "$(hash_file "${PROJ}/.env.prd")" = "${PRD_HASH}" ]; then
  ok "status is read-only"
else
  bad "status changed the target"
fi

expect_rc 1 "verify fails before apply" bash "${ENV_SYNC}" verify --dir "${PROJ}"
expect_out "verify: FAIL" "verify prints FAIL"

# --- 2. apply, values, mode, reference immutability ------------------------
expect_rc 0 "apply aligns the target" bash "${ENV_SYNC}" apply --dir "${PROJ}" --backup-dir "${BACKUP}"
expect_out "RESULT: PASS" "apply reports PASS"
expect_out "layout" "apply reports the layout summary"

if [ "$(line_count "${PROJ}/.env.example")" = "$(line_count "${PROJ}/.env.prd")" ]; then
  ok "line counts are identical after apply"
else
  bad "line counts differ after apply"
fi
assert_skeleton "${PROJ}/.env.example" "${PROJ}/.env.prd" "comments and blanks are 1-to-1 after apply"
assert_value "AI_API_KEY=${SECRET}" "${PROJ}/.env.prd" "secret value survived byte-for-byte"
assert_value "AI_OFFPEAK_ONLY=true" "${PROJ}/.env.prd" "environment value survived"
assert_value "AI_MONTHLY_BUDGET_USD=1" "${PROJ}/.env.prd" "reference default survived"

if [ "$(file_mode "${PROJ}/.env.prd")" = "600" ]; then
  ok "file mode preserved"
else
  bad "file mode changed ($(file_mode "${PROJ}/.env.prd"))"
fi
if [ "$(hash_file "${PROJ}/.env.example")" = "${REF_HASH}" ]; then
  ok "reference was not modified"
else
  bad "reference was modified"
fi

# --- 3. verify + backup proof + idempotency --------------------------------
expect_rc 0 "verify passes after apply" bash "${ENV_SYNC}" verify --dir "${PROJ}"
expect_out "verify: PASS" "verify prints PASS"
expect_rc 0 "verify --backup proves values survived" bash "${ENV_SYNC}" verify --backup "${BACKUP}" --dir "${PROJ}"
expect_out "verify --backup: PASS" "backup audit prints PASS"

AFTER_HASH="$(hash_file "${PROJ}/.env.prd")"
expect_rc 0 "second apply is a no-op" bash "${ENV_SYNC}" apply --dir "${PROJ}"
expect_out "already aligned - nothing to write" "second apply reports no writes"
if [ "$(hash_file "${PROJ}/.env.prd")" = "${AFTER_HASH}" ]; then
  ok "second apply left the file byte-identical"
else
  bad "second apply changed the file"
fi

# --- 4. comment-only drift is real drift -----------------------------------
awk '
  BEGIN { done = 0 }
  !done && /^# The hard ceiling/ { print "# TAMPERED COMMENT"; done = 1; next }
  { print }
' "${PROJ}/.env.prd" >"${TMP}/prd.tampered" && mv "${TMP}/prd.tampered" "${PROJ}/.env.prd"
expect_rc 1 "verify catches comment-only drift" bash "${ENV_SYNC}" verify --dir "${PROJ}"
expect_out "layout 1" "comment drift is counted as layout 1"
expect_rc 0 "apply normalizes comment-only drift" bash "${ENV_SYNC}" apply --dir "${PROJ}" --backup-dir "${TMP}/backup2"
assert_skeleton "${PROJ}/.env.example" "${PROJ}/.env.prd" "comments are restored from the reference"
assert_value "AI_API_KEY=${SECRET}" "${PROJ}/.env.prd" "value untouched by comment normalization"

# --- 5. commented-out assignment drift -------------------------------------
awk '
  BEGIN { done = 0 }
  !done && /^# CADDY_HTTP_PORT=/ { print "# CADDY_HTTP_PORT=46133"; done = 1; next }
  { print }
' "${PROJ}/.env.prd" >"${TMP}/prd.tampered" && mv "${TMP}/prd.tampered" "${PROJ}/.env.prd"
expect_rc 1 "verify catches commented-out assignment drift" bash "${ENV_SYNC}" verify --dir "${PROJ}"
expect_rc 0 "apply restores the reference comment" bash "${ENV_SYNC}" apply --dir "${PROJ}" --backup-dir "${TMP}/backup3"
assert_skeleton "${PROJ}/.env.example" "${PROJ}/.env.prd" "commented-out values are not copied around"

# --- 6. missing/extra trailing lines ---------------------------------------
printf '\n' >>"${PROJ}/.env.prd"
expect_rc 1 "verify catches an extra trailing line" bash "${ENV_SYNC}" verify --dir "${PROJ}"
expect_rc 0 "apply removes the extra line" bash "${ENV_SYNC}" apply --dir "${PROJ}" --backup-dir "${TMP}/backup4"
if [ "$(line_count "${PROJ}/.env.prd")" = "$(line_count "${PROJ}/.env.example")" ]; then
  ok "line count restored after trailing drift"
else
  bad "line count still differs after trailing drift"
fi

# --- 7. dry-run writes nothing ---------------------------------------------
printf '# dry-run tamper\n' >>"${PROJ}/.env.prd"
DRY_HASH="$(hash_file "${PROJ}/.env.prd")"
expect_rc 0 "apply --dry-run plans without writing" bash "${ENV_SYNC}" apply --dir "${PROJ}" --dry-run
expect_out "DRY RUN" "dry-run reports no writes"
if [ "$(hash_file "${PROJ}/.env.prd")" = "${DRY_HASH}" ]; then
  ok "dry-run left the file unchanged"
else
  bad "dry-run wrote the file"
fi
bash "${ENV_SYNC}" apply --dir "${PROJ}" >/dev/null

# --- 8. target-only key aborts with no writes ------------------------------
printf 'ONLY_IN_PRD=1\n' >>"${PROJ}/.env.prd"
GUARD_HASH="$(hash_file "${PROJ}/.env.prd")"
expect_rc 1 "verify fails on an undeclared key" bash "${ENV_SYNC}" verify --dir "${PROJ}"
expect_out "Undeclared keys" "verify names the undeclared key"
expect_rc 1 "apply aborts on an undeclared key" bash "${ENV_SYNC}" apply --dir "${PROJ}"
expect_out "ABORTED" "apply reports ABORTED"
if [ "$(hash_file "${PROJ}/.env.prd")" = "${GUARD_HASH}" ]; then
  ok "aborted apply wrote nothing"
else
  bad "aborted apply changed the target"
fi
sed '$d' "${PROJ}/.env.prd" >"${TMP}/prd.restore" && mv "${TMP}/prd.restore" "${PROJ}/.env.prd"

# --- 9. duplicate reference key fails closed ------------------------------
cp -p "${PROJ}/.env.example" "${TMP}/ref.save"
printf 'APP_ENV=again\n' >>"${PROJ}/.env.example"
expect_rc 2 "duplicate reference key is rejected" bash "${ENV_SYNC}" status --dir "${PROJ}"
expect_out "duplicate" "duplicate finding is reported"
mv "${TMP}/ref.save" "${PROJ}/.env.example"

# --- 10. value tamper is caught by the backup audit -----------------------
cp -p "${PROJ}/.env.prd" "${TMP}/prd.save"
awk -v k="AI_API_KEY" '
  index($0, k "=") == 1 { print k "=sk-tampered"; next }
  { print }
' "${PROJ}/.env.prd" >"${TMP}/prd.tampered" && mv "${TMP}/prd.tampered" "${PROJ}/.env.prd"
expect_rc 1 "verify --backup catches value drift" bash "${ENV_SYNC}" verify --backup "${BACKUP}" --dir "${PROJ}"
expect_out "VALUE DRIFT" "value drift is named"
mv "${TMP}/prd.save" "${PROJ}/.env.prd"

# --- 11. CRLF target fails closed -----------------------------------------
cp -p "${PROJ}/.env.prd" "${TMP}/prd.save"
awk '{ printf "%s\r\n", $0 }' "${TMP}/prd.save" >"${PROJ}/.env.prd"
expect_rc 1 "verify rejects CRLF" bash "${ENV_SYNC}" verify --dir "${PROJ}"
expect_out "CRLF" "CRLF finding is reported"
expect_rc 1 "apply rejects CRLF before writing" bash "${ENV_SYNC}" apply --dir "${PROJ}"
expect_out "invalid input" "apply reports invalid input"
mv "${TMP}/prd.save" "${PROJ}/.env.prd"

# --- 12. missing reference fails closed -----------------------------------
expect_rc 2 "missing reference is rejected" bash "${ENV_SYNC}" status --dir "${PROJ}" --ref "${TMP}/nope.env"
expect_out "reference not found" "missing reference is named"

# --- 13. final state -------------------------------------------------------
expect_rc 0 "final verify passes" bash "${ENV_SYNC}" verify --dir "${PROJ}"
if find "${PROJ}" -maxdepth 1 -name '.env-sync-tmp.*' | grep -q .; then
  bad "staging directory leaked into the project"
else
  ok "no staging directory leaked into the project"
fi
if [ "$(hash_file "${PROJ}/.env.example")" = "${REF_HASH}" ]; then
  ok "reference unchanged across the whole suite"
else
  bad "reference changed during the suite"
fi

say ""
if [ "${FAILURES}" -ne 0 ]; then
  say "env-sync-test: FAIL (${CHECKS} checks, ${FAILURES} failures)"
  exit 1
fi
say "env-sync-test: PASS (${CHECKS} checks)"
