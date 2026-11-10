#!/usr/bin/env bash
# env-sync.sh - align every .env* file to the .env.example key layout.
#
# Guarantees:
#   * .env.example is the reference: each of its keys lands on the SAME line
#     number in every target file.
#   * No value is ever modified. Values are compared by SHA-256 before and
#     after every write; any mismatch aborts and restores the backups.
#   * Keys that exist only in a target file are preserved, appended in one
#     shared block so they also align across files.
#   * A key missing from a target file becomes a comment placeholder
#     (`# env-sync: KEY not set in this file`) - never an empty assignment,
#     which would change runtime semantics from "unset" to "empty".
#   * Nothing is printed from a value; status/verify only report line,
#     presence and same/diff fingerprints.
#
# Usage:
#   bash scripts/env-sync.sh status [--dir PATH] [--ref FILE] [--files "A B"]
#   bash scripts/env-sync.sh verify [--dir PATH] [--ref FILE] [--files "A B"]
#   bash scripts/env-sync.sh apply  [--dir PATH] [--ref FILE] [--files "A B"]
#                                   [--backup-dir PATH] [--dry-run]
#   bash scripts/env-sync.sh verify --backup DIR [--dir PATH]
#
# Exit codes: 0 pass, 1 drift / aborted / restored, 2 usage or reference error.
#
# bash >= 3.2 clean (stock macOS). No associative arrays, no mapfile.
# ASCII only. LF only.

set -euo pipefail

REPO_DIR="."
REF_ARG=""
FILES_ARG=""
BACKUP_ARG=""
DRY_RUN=0
MODE=""

PLACEHOLDER_PREFIX="# env-sync: "
PLACEHOLDER_SUFFIX=" not set in this file"

usage() {
  cat <<'EOF'
env-sync - align every .env* file to the .env.example key layout (values untouched)

Usage:
  env-sync.sh status [--dir PATH] [--ref FILE] [--files "A B"]   side-by-side compare (read-only)
  env-sync.sh verify [--dir PATH] [--ref FILE] [--files "A B"]   strict check, exit 1 on drift
  env-sync.sh apply  [--dir PATH] [--ref FILE] [--files "A B"]   rewrite layout (backup + verify)
                     [--backup-dir PATH] [--dry-run]
  env-sync.sh verify --backup DIR [--dir PATH]                   prove values survived an apply

Aliases: compare, diff -> status; check -> verify; sync, fix -> apply.

Reference: <dir>/.env.example unless --ref is given. Targets: every regular
<dir>/.env* file except the reference and backup/temp suffixes, or the exact
basenames listed with --files.

Safety: apply backs up every target outside the repo, verifies key/value
fingerprints before and after the atomic replace, and restores all backups if
any check fails. Values are never printed.
EOF
}

die() {
  echo "env-sync: $*" >&2
  exit 2
}

say() { printf '%s\n' "$*"; }

# --- hashing ----------------------------------------------------------------
HASH_IMPL=""
detect_hash() {
  if command -v sha256sum >/dev/null 2>&1; then HASH_IMPL="sha256sum"
  elif command -v shasum >/dev/null 2>&1; then HASH_IMPL="shasum"
  elif command -v openssl >/dev/null 2>&1; then HASH_IMPL="openssl"
  else die "no SHA-256 tool found (need sha256sum, shasum or openssl)"
  fi
}

value_hash() {
  case "${HASH_IMPL}" in
    sha256sum) printf '%s' "$1" | sha256sum | cut -d' ' -f1 ;;
    shasum)    printf '%s' "$1" | shasum -a 256 | cut -d' ' -f1 ;;
    openssl)   printf '%s' "$1" | openssl dgst -sha256 | sed 's/^.*= //' ;;
  esac
}

file_hash() {
  case "${HASH_IMPL}" in
    sha256sum) sha256sum "$1" | cut -d' ' -f1 ;;
    shasum)    shasum -a 256 "$1" | cut -d' ' -f1 ;;
    openssl)   openssl dgst -sha256 "$1" | sed 's/^.*= //' ;;
  esac
}

file_mode() {
  if stat -c '%a' "$1" >/dev/null 2>&1; then
    stat -c '%a' "$1"
  else
    stat -f '%Lp' "$1"
  fi
}

# --- work dir / cleanup -----------------------------------------------------
WORK_DIR=""
WRITE_DIR=""
cleanup() {
  [ -n "${WORK_DIR}" ] && [ -d "${WORK_DIR}" ] && rm -rf "${WORK_DIR}" || true
  [ -n "${WRITE_DIR}" ] && [ -d "${WRITE_DIR}" ] && rm -rf "${WRITE_DIR}" || true
}
trap cleanup EXIT INT TERM

# --- parsing ----------------------------------------------------------------
# parse_env FILE MAP
#   MAP:              LINE<TAB>KEY<TAB>VALUESHA<TAB>set|empty
#   MAP.issues:       KIND<TAB>LINE<TAB>MESSAGE
#   MAP.placeholders: LINE<TAB>KEY  (our own placeholder comments)
#   Exit 0 valid, 1 issues found.
parse_env() {
  local file="$1" map="$2" line trimmed work key val first last
  local n=0 invalid=0 seen="" h state crlf=0 rest nbs=0 idx=0 dq sq
  : > "${map}"
  : > "${map}.issues"
  : > "${map}.placeholders"

  while IFS= read -r line || [ -n "${line}" ]; do
    n=$((n + 1))
    if [ "${line%$'\r'}" != "${line}" ]; then
      line="${line%$'\r'}"
      crlf=1
    fi
    trimmed="${line#"${line%%[![:space:]]*}"}"
    case "${trimmed}" in
      '') continue ;;
      '#'*)
        rest="${trimmed#"${PLACEHOLDER_PREFIX}"}"
        if [ "${rest}" != "${trimmed}" ]; then
          case "${rest}" in
            *"${PLACEHOLDER_SUFFIX}")
              key="${rest%"${PLACEHOLDER_SUFFIX}"}"
              if [[ "${key}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
                printf '%s\t%s\n' "${n}" "${key}" >> "${map}.placeholders"
              fi
              ;;
          esac
        fi
        continue
        ;;
    esac

    work="${trimmed}"
    case "${work}" in
      export[[:space:]]*)
        work="${work#export}"
        work="${work#"${work%%[![:space:]]*}"}"
        ;;
    esac

    case "${work}" in
      *=*) key="${work%%=*}"; val="${work#*=}" ;;
      *)
        printf 'unparsed\t%s\tline is not KEY=value\n' "${n}" >> "${map}.issues"
        invalid=1
        continue
        ;;
    esac

    if ! [[ "${key}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
      printf 'bad-key\t%s\tkey has characters outside [A-Za-z0-9_]\n' "${n}" >> "${map}.issues"
      invalid=1
      continue
    fi
    case ",${seen}," in
      *",${key},"*)
        printf 'duplicate\t%s\tduplicate key %s\n' "${n}" "${key}" >> "${map}.issues"
        invalid=1
        continue
        ;;
    esac
    seen="${seen:+${seen},}${key}"

    if [ -n "${val}" ]; then
      first="${val:0:1}"
      # A trailing run of an ODD number of backslashes is a line continuation.
      nbs=0
      idx=${#val}
      while [ "${idx}" -gt 0 ]; do
        [ "${val:$((idx - 1)):1}" = "\\" ] || break
        nbs=$((nbs + 1))
        idx=$((idx - 1))
      done
      if [ $((nbs % 2)) -eq 1 ]; then
        printf 'multiline\t%s\tline continuation (trailing backslash) is unsupported\n' "${n}" >> "${map}.issues"
        invalid=1
        continue
      fi
      # Quoted value: require the opening quote to be closed somewhere on the
      # line (a trailing inline comment after the closing quote is fine).
      if [ "${first}" = '"' ]; then
        dq="${val//[!\"]/}"
        if [ "${#dq}" -lt 2 ]; then
          printf 'multiline\t%s\tunterminated double-quoted value\n' "${n}" >> "${map}.issues"
          invalid=1
          continue
        fi
      elif [ "${first}" = "'" ]; then
        sq="${val//[!\']/}"
        if [ "${#sq}" -lt 2 ]; then
          printf 'multiline\t%s\tunterminated single-quoted value\n' "${n}" >> "${map}.issues"
          invalid=1
          continue
        fi
      fi
    fi

    if [ "${val}" = "" ]; then state="empty"; else state="set"; fi
    h="$(value_hash "${val}")"
    printf '%s\t%s\t%s\t%s\n' "${n}" "${key}" "${h}" "${state}" >> "${map}"
  done < "${file}"

  if [ "${crlf}" -eq 1 ]; then
    printf 'crlf\t0\tCRLF line endings found (convert to LF first)\n' >> "${map}.issues"
    invalid=1
  fi
  return "${invalid}"
}

print_issues() {
  local map="$1" base="$2" kind ln msg
  if [ -s "${map}.issues" ]; then
    while IFS=$'\t' read -r kind ln msg; do
      case "${ln}" in 0) say "  ${base}: ${msg}" ;; *) say "  ${base}:${ln} ${msg}" ;; esac
    done < "${map}.issues"
  fi
}

# --- target discovery -------------------------------------------------------
TARGETS=()
discover_targets() {
  local p b
  TARGETS=()
  if [ -n "${FILES_ARG}" ]; then
    # Deliberate word splitting: --files is a space-separated basename list.
    # shellcheck disable=SC2086
    for b in ${FILES_ARG}; do
      [ -f "${DIR}/${b}" ] || die "--files entry not found: ${b}"
      [ "${b}" = "$(basename "${REF}")" ] && die "--files must not include the reference: ${b}"
      TARGETS+=("${b}")
    done
    return 0
  fi
  while IFS= read -r p; do
    b="${p##*/}"
    [ "${b}" = "$(basename "${REF}")" ] && continue
    case "${b}" in
      *.bak|*.orig|*.rej|*.swp|*.tmp|*~) continue ;;
      .env-sync.*|.env-sync-*) continue ;;
    esac
    TARGETS+=("${b}")
  done < <(find "${DIR}" -maxdepth 1 -type f -name '.env*' | LC_ALL=C sort)
}

# --- reference metadata -----------------------------------------------------
REF_COUNT=0
REF_LINES=0
REF_BASE=""
EXTRAS_COUNT=0

# KEY<TAB>CANONICAL_LINE for every reference key, then every extra key
build_expected() {
  local extras="$1" i=0 key
  : > "${WORK_DIR}/expected.tsv"
  awk -F'\t' '{ print $2 "\t" $1 }' "${WORK_DIR}/ref.map" > "${WORK_DIR}/expected.tsv"
  if [ -s "${extras}" ]; then
    while IFS= read -r key; do
      [ -z "${key}" ] && continue
      i=$((i + 1))
      printf '%s\t%s\n' "${key}" "$((REF_LINES + 2 + i))" >> "${WORK_DIR}/expected.tsv"
    done < "${extras}"
  fi
}

line_of_key() { # MAP KEY -> line or empty
  awk -F'\t' -v k="$2" '$2 == k { print $1; exit }' "$1"
}

# file_aligned TARGET MAP -> 0 aligned, 1 needs rewrite
file_aligned() {
  local target="$1" map="$2" key exp got actual
  while IFS=$'\t' read -r key exp; do
    got="$(line_of_key "${map}" "${key}")"
    if [ -n "${got}" ]; then
      [ "${got}" = "${exp}" ] || return 1
    else
      actual="$(sed -n "${exp}p" "${target}")"
      [ "${actual}" = "${PLACEHOLDER_PREFIX}${key}${PLACEHOLDER_SUFFIX}" ] || return 1
    fi
  done < "${WORK_DIR}/expected.tsv"

  while IFS=$'\t' read -r ln key _h _st; do
    exp="$(awk -F'\t' -v k="${key}" '$1 == k { print $2; exit }' "${WORK_DIR}/expected.tsv")"
    [ -n "${exp}" ] || return 1
    [ "${ln}" = "${exp}" ] || return 1
  done < "${map}"
  return 0
}

# generate_canonical TARGET OUT
generate_canonical() {
  local target="$1" out="$2"
  awk -v reffile="${REF}" -v extras="${WORK_DIR}/extras" -v refbase="${REF_BASE}" '
    function is_assign(l,  t,p,k) {
      t = l
      sub(/^[ \t]+/, "", t)
      if (t == "" || t ~ /^#/) return ""
      sub(/^export[ \t]+/, "", t)
      p = index(t, "=")
      if (p == 0) return ""
      k = substr(t, 1, p - 1)
      if (k !~ /^[A-Za-z_][A-Za-z0-9_]*$/) return ""
      return k
    }
    BEGIN {
      nref = 0
      while ((getline l < reffile) > 0) {
        sub(/\r$/, "", l)
        nref++
        refline[nref] = l
      }
      close(reffile)
      nextras = 0
      while ((getline k < extras) > 0) {
        sub(/\r$/, "", k)
        if (k != "") extra[++nextras] = k
      }
      close(extras)
    }
    {
      sub(/\r$/, "", $0)
      k = is_assign($0)
      if (k != "") raw[k] = $0
    }
    END {
      for (i = 1; i <= nref; i++) {
        l = refline[i]
        k = is_assign(l)
        if (k != "" && (k in raw)) print raw[k]
        else if (k != "") print "# env-sync: " k " not set in this file"
        else print l
      }
      if (nextras > 0) {
        print ""
        print "# --- env-sync: keys not in " refbase " (preserved; keep aligned) ---"
        for (i = 1; i <= nextras; i++) {
          k = extra[i]
          if (k in raw) print raw[k]
          else print "# env-sync: " k " not set in this file"
        }
      }
    }
  ' "${target}" > "${out}"
}

# compare_maps ORIG NEW -> 0 when the same keys carry the same fingerprints
compare_maps() {
  local orig="$1" new="$2"
  [ "$(awk 'END { print NR }' "${orig}")" = "$(awk 'END { print NR }' "${new}")" ] || return 1
  awk -F'\t' 'NR == FNR { h[$2] = $3; next }
               !($2 in h) || h[$2] != $3 { bad = 1 }
               END { exit bad }' "${orig}" "${new}"
}

# --- status / verify --------------------------------------------------------
render_report() {
  local mode="$1" i=0 name key idx
  : > "${WORK_DIR}/records.tsv"

  while IFS=$'\t' read -r idx key _h _st; do
    printf 'R\t%s\t%s\n' "${idx}" "${key}" >> "${WORK_DIR}/records.tsv"
  done < "${WORK_DIR}/ref.map"

  i=0
  if [ -s "${WORK_DIR}/extras" ]; then
    while IFS= read -r key; do
      [ -z "${key}" ] && continue
      i=$((i + 1))
      printf 'E\t%s\t%s\n' "${i}" "${key}" >> "${WORK_DIR}/records.tsv"
    done < "${WORK_DIR}/extras"
  fi
  EXTRAS_COUNT="${i}"

  i=0
  for name in ${TARGETS[@]+"${TARGETS[@]}"}; do
    i=$((i + 1))
    printf 'F\t%s\t%s\n' "${i}" "${name}" >> "${WORK_DIR}/records.tsv"
    awk -F'\t' -v i="${i}" '{ printf "K\t%s\t%s\t%s\t%s\t%s\n", i, $1, $2, $3, $4 }' \
      "${WORK_DIR}/maps/${name}" >> "${WORK_DIR}/records.tsv"
    while IFS=$'\t' read -r ln key; do
      printf 'P\t%s\t%s\t%s\n' "${i}" "${ln}" "${key}" >> "${WORK_DIR}/records.tsv"
    done < "${WORK_DIR}/maps/${name}.placeholders"
  done

  local rc=0
  awk -F'\t' -v mode="${mode}" -v refbase="${REF_BASE}" -v dir="${DIR}" \
      -v reflines="${REF_LINES}" '
    $1 == "R" { nr++; rline[$3] = $2; rorder[nr] = $3 }
    $1 == "E" { nextras++; extra[nextras] = $3 }
    $1 == "F" { nf++; fname[$2] = $3 }
    $1 == "K" { tline[$2, $4] = $3; tstate[$2, $4] = $6; thash[$2, $4] = $5 }
    $1 == "P" { ph[$2, $4] = $3 }
    END {
      for (i = 1; i <= nextras; i++) extraline[extra[i]] = reflines + 2 + i
      nkeys = nr + nextras

      kw = 3
      for (i = 1; i <= nr; i++) if (length(rorder[i]) > kw) kw = length(rorder[i])
      for (i = 1; i <= nextras; i++) if (length(extra[i]) > kw) kw = length(extra[i])
      fw = 17

      if (mode == "status") {
        printf "env-sync status - %s\n", dir
        printf "reference: %s (%d keys)  targets: %d  extra keys: %d\n\n", refbase, nr, nf, nextras
        printf "%-*s  %-4s", kw, "KEY", "REF"
        for (f = 1; f <= nf; f++) printf "  %-*s", fw, fname[f]
        printf "  %-6s\n", "VALUES"
        for (i = 0; i < kw; i++) printf "-"
        printf "  ----"
        for (f = 1; f <= nf; f++) { printf "  "; for (i = 0; i < fw; i++) printf "-" }
        printf "  ------\n"

        for (i = 1; i <= nkeys; i++) {
          if (i <= nr) { key = rorder[i]; refcell = rline[key] "" }
          else { key = extra[i - nr]; refcell = "--" }
          printf "%-*s  %-4s", kw, key, refcell
          present = 0; first = ""; same = 1
          for (f = 1; f <= nf; f++) {
            if ((f, key) in tline) {
              ln = tline[f, key]
              canon = (i <= nr) ? rline[key] : extraline[key]
              pre = (ln == canon) ? "ok:" : "at:"
              cell = pre ln " " tstate[f, key]
              present++
              if (first == "") first = thash[f, key]
              else if (thash[f, key] != first) same = 0
            } else {
              cell = "--"
            }
            printf "  %-*s", fw, cell
          }
          if (present < 2) vals = "n/a"
          else if (same) vals = "same"
          else vals = "diff"
          printf "  %-6s\n", vals
        }
        printf "\n"
      }

      bad = 0
      for (f = 1; f <= nf; f++) {
        drift = 0; misplaced = 0; ph_ok = 0; extras_n = 0
        for (i = 1; i <= nr; i++) {
          key = rorder[i]
          if ((f, key) in tline) {
            if (tline[f, key] != rline[key]) misplaced++
          } else if ((f, key) in ph && ph[f, key] + 0 == rline[key] + 0) {
            ph_ok++
          } else {
            drift++
          }
        }
        for (i = 1; i <= nextras; i++) {
          key = extra[i]
          if ((f, key) in tline) {
            extras_n++
            if (tline[f, key] != extraline[key]) misplaced++
          } else if ((f, key) in ph && ph[f, key] + 0 == extraline[key] + 0) {
            ph_ok++
          } else {
            drift++
          }
        }
        if (drift || misplaced) { bad = 1; status = "DRIFT" } else { status = "ALIGNED" }
        if (mode == "status")
          printf "  %-18s %-7s missing %d (placeholder), %d misplaced, %d extra keys\n", \
                 fname[f], status, ph_ok, misplaced, extras_n
        else
          printf "  %-18s %-7s (%d placeholder, %d misplaced, %d extra keys)\n", \
                 fname[f], status, ph_ok, misplaced, extras_n
      }
      if (mode == "verify") {
        if (bad) { printf "verify: FAIL\n"; exit 1 }
        printf "verify: PASS\n"
      }
    }
  ' "${WORK_DIR}/records.tsv" || rc=$?
  return "${rc}"
}

# --- apply ------------------------------------------------------------------
CHANGED=()
BACKUP_DIR=""

apply_run() {
  local name target new key exp got before_missing=0 before_misplaced=0
  local planned=0 total_values=0 mode failed manifest_hash manifest_name

  for name in ${TARGETS[@]+"${TARGETS[@]}"}; do
    file_aligned "${DIR}/${name}" "${WORK_DIR}/maps/${name}" || planned=$((planned + 1))
  done

  if [ "${planned}" -eq 0 ]; then
    say "apply: all ${#TARGETS[@]} target file(s) already aligned - nothing to write"
    say "RESULT: PASS"
    return 0
  fi

  for name in ${TARGETS[@]+"${TARGETS[@]}"}; do
    file_aligned "${DIR}/${name}" "${WORK_DIR}/maps/${name}" && continue
    before_missing=0; before_misplaced=0
    while IFS=$'\t' read -r key exp; do
      got="$(line_of_key "${WORK_DIR}/maps/${name}" "${key}")"
      if [ -z "${got}" ]; then
        before_missing=$((before_missing + 1))
      else
        [ "${got}" = "${exp}" ] || before_misplaced=$((before_misplaced + 1))
      fi
    done < "${WORK_DIR}/expected.tsv"
    say "  ${name}: rewrite (missing ${before_missing}, misplaced ${before_misplaced})"
  done

  if [ "${DRY_RUN}" -eq 1 ]; then
    say "apply: DRY RUN - ${planned} file(s) would be rewritten; no files written"
    say "RESULT: PASS (dry run)"
    return 0
  fi

  # --- backup (outside the repo by default) ---
  if [ -n "${BACKUP_ARG}" ]; then
    BACKUP_DIR="${BACKUP_ARG}"
    mkdir -p "${BACKUP_DIR}" || die "cannot create backup dir: ${BACKUP_DIR}"
  else
    BACKUP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/env-sync-backup.XXXXXX")" \
      || die "cannot create temporary backup dir"
  fi
  chmod 700 "${BACKUP_DIR}" 2>/dev/null || true
  : > "${BACKUP_DIR}/manifest.txt"
  for name in ${TARGETS[@]+"${TARGETS[@]}"}; do
    cp -p "${DIR}/${name}" "${BACKUP_DIR}/${name}" || die "backup failed for ${name}"
    printf '%s\t%s\n' "$(file_hash "${DIR}/${name}")" "${name}" >> "${BACKUP_DIR}/manifest.txt"
  done

  # --- generate + verify before touching a single file ---
  for name in ${TARGETS[@]+"${TARGETS[@]}"}; do
    file_aligned "${DIR}/${name}" "${WORK_DIR}/maps/${name}" && continue
    new="${WORK_DIR}/new.${name}"
    generate_canonical "${DIR}/${name}" "${new}"
    if ! parse_env "${new}" "${WORK_DIR}/maps/new.${name}"; then
      say "apply: ABORTED - generated layout for ${name} is not parseable (nothing written)"
      print_issues "${WORK_DIR}/maps/new.${name}" "${name} (generated)"
      return 1
    fi
    if ! compare_maps "${WORK_DIR}/maps/${name}" "${WORK_DIR}/maps/new.${name}"; then
      say "apply: ABORTED - value fingerprint mismatch for ${name} (nothing written)"
      return 1
    fi
    if ! file_aligned "${new}" "${WORK_DIR}/maps/new.${name}"; then
      say "apply: ABORTED - generated layout for ${name} failed alignment (nothing written)"
      return 1
    fi
  done

  # --- atomic replace in the same directory, preserving mode ---
  WRITE_DIR="${DIR}/.env-sync-tmp.$$"
  mkdir -p "${WRITE_DIR}" || die "cannot create ${WRITE_DIR}"
  local replace_failed=0
  for name in ${TARGETS[@]+"${TARGETS[@]}"}; do
    file_aligned "${DIR}/${name}" "${WORK_DIR}/maps/${name}" && continue
    mode="$(file_mode "${DIR}/${name}")"
    if ! cp "${WORK_DIR}/new.${name}" "${WRITE_DIR}/${name}"; then
      say "apply: staging failed for ${name}"
      replace_failed=1
      break
    fi
    if ! chmod "${mode}" "${WRITE_DIR}/${name}" 2>/dev/null; then
      say "apply: cannot set mode ${mode} on ${name}"
      replace_failed=1
      break
    fi
    if ! mv -f "${WRITE_DIR}/${name}" "${DIR}/${name}"; then
      say "apply: replace failed for ${name}"
      replace_failed=1
      break
    fi
    CHANGED+=("${name}")
  done

  if [ "${replace_failed}" -ne 0 ]; then
    say "apply: restoring all targets from ${BACKUP_DIR}"
    for name in ${TARGETS[@]+"${TARGETS[@]}"}; do
      cp -p "${BACKUP_DIR}/${name}" "${DIR}/${name}" \
        || say "RESTORE FAILED: ${name} (copy from ${BACKUP_DIR})"
    done
    say "RESULT: FAIL (restored)"
    return 1
  fi

  # --- post-write verify ---
  failed=0
  for name in ${CHANGED[@]+"${CHANGED[@]}"}; do
    if ! parse_env "${DIR}/${name}" "${WORK_DIR}/maps/after.${name}"; then
      say "apply: FAIL - ${name} no longer parses after rewrite"
      failed=1
      continue
    fi
    if ! compare_maps "${WORK_DIR}/maps/${name}" "${WORK_DIR}/maps/after.${name}"; then
      say "apply: FAIL - value fingerprint changed in ${name}"
      failed=1
      continue
    fi
    if ! file_aligned "${DIR}/${name}" "${WORK_DIR}/maps/after.${name}"; then
      say "apply: FAIL - ${name} is not aligned after rewrite"
      failed=1
      continue
    fi
    total_values=$((total_values + $(awk 'END { print NR }' "${WORK_DIR}/maps/after.${name}")))
  done

  if [ "${failed}" -ne 0 ]; then
    say "apply: restoring ${#CHANGED[@]} file(s) from ${BACKUP_DIR}"
    for name in ${CHANGED[@]+"${CHANGED[@]}"}; do
      cp -p "${BACKUP_DIR}/${name}" "${DIR}/${name}" || say "RESTORE FAILED: ${name} (copy from ${BACKUP_DIR})"
    done
    say "RESULT: FAIL (restored)"
    return 1
  fi

  # backup integrity proof: the file copied before the write still hashes to
  # the value recorded in the manifest.
  while IFS=$'\t' read -r manifest_hash manifest_name; do
    [ -z "${manifest_name}" ] && continue
    [ "$(file_hash "${BACKUP_DIR}/${manifest_name}")" = "${manifest_hash}" ] \
      || say "WARNING: backup hash drift for ${manifest_name} (${BACKUP_DIR})"
  done < "${BACKUP_DIR}/manifest.txt"

  say "apply: rewrote ${#CHANGED[@]} file(s); ${total_values} key values verified unchanged"
  say "backup: ${BACKUP_DIR}"
  say "RESULT: PASS"
  return 0
}

# --- verify against a backup dir -------------------------------------------
verify_backup() {
  local bdir="$1" file base bad=0
  [ -f "${bdir}/manifest.txt" ] || die "--backup dir has no manifest.txt: ${bdir}"
  for file in "${bdir}"/.env*; do
    [ -f "${file}" ] || continue
    base="${file##*/}"
    if [ ! -f "${DIR}/${base}" ]; then
      say "  ${base}: MISSING in ${DIR}"
      bad=1
      continue
    fi
    if ! parse_env "${file}" "${WORK_DIR}/backup.${base}" || \
       ! parse_env "${DIR}/${base}" "${WORK_DIR}/current.${base}"; then
      say "  ${base}: cannot parse (backup or current)"
      bad=1
      continue
    fi
    if ! compare_maps "${WORK_DIR}/backup.${base}" "${WORK_DIR}/current.${base}"; then
      say "  ${base}: VALUE DRIFT (backup vs current)"
      bad=1
      continue
    fi
    if ! file_aligned "${DIR}/${base}" "${WORK_DIR}/current.${base}"; then
      say "  ${base}: values preserved but layout is not aligned"
      bad=1
      continue
    fi
    say "  ${base}: values preserved, layout aligned"
  done
  if [ "${bad}" -ne 0 ]; then say "verify --backup: FAIL"; return 1; fi
  say "verify --backup: PASS"
  return 0
}

# --- main -------------------------------------------------------------------
main() {
  while [ $# -gt 0 ]; do
    case "$1" in
      status|compare|diff) MODE="status"; shift ;;
      verify|check) MODE="verify"; shift ;;
      apply|sync|fix) MODE="apply"; shift ;;
      help|--help|-h) usage; exit 0 ;;
      --dir) [ $# -ge 2 ] || die "--dir needs a value"; REPO_DIR="$2"; shift 2 ;;
      --ref) [ $# -ge 2 ] || die "--ref needs a value"; REF_ARG="$2"; shift 2 ;;
      --files) [ $# -ge 2 ] || die "--files needs a value"; FILES_ARG="$2"; shift 2 ;;
      --backup-dir|--backup) [ $# -ge 2 ] || die "$1 needs a value"; BACKUP_ARG="$2"; shift 2 ;;
      --dry-run) DRY_RUN=1; shift ;;
      --) shift; break ;;
      *) die "unknown argument: $1 (see --help)" ;;
    esac
  done

  [ -n "${MODE}" ] || MODE="status"
  [ -d "${REPO_DIR}" ] || die "not a directory: ${REPO_DIR}"
  DIR="$(cd "${REPO_DIR}" && pwd)"

  if [ -n "${REF_ARG}" ]; then
    case "${REF_ARG}" in
      /*) REF="${REF_ARG}" ;;
      *) REF="${DIR}/${REF_ARG}" ;;
    esac
  else
    REF="${DIR}/.env.example"
  fi
  [ -f "${REF}" ] || die "reference not found: ${REF} (pass --ref)"
  REF_BASE="$(basename "${REF}")"

  detect_hash
  WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/env-sync-work.XXXXXX")" \
    || die "cannot create temporary work dir"
  mkdir -p "${WORK_DIR}/maps"

  discover_targets

  # parse reference first (needed by every mode)
  if ! parse_env "${REF}" "${WORK_DIR}/ref.map"; then
    say "env-sync: reference ${REF_BASE} has issues:"
    print_issues "${WORK_DIR}/ref.map" "${REF_BASE}"
    return 2
  fi
  REF_COUNT="$(awk 'END { print NR }' "${WORK_DIR}/ref.map")"
  [ "${REF_COUNT}" -gt 0 ] || die "reference has no KEY=value lines: ${REF}"
  REF_LINES="$(awk 'END { print NR }' "${REF}")"

  local name invalid_targets=0
  for name in ${TARGETS[@]+"${TARGETS[@]}"}; do
    if ! parse_env "${DIR}/${name}" "${WORK_DIR}/maps/${name}"; then
      invalid_targets=$((invalid_targets + 1))
    fi
  done

  # extras union, first-seen order across sorted targets
  awk -F'\t' '{ print $2 }' "${WORK_DIR}/ref.map" | LC_ALL=C sort -u > "${WORK_DIR}/refkeys"
  : > "${WORK_DIR}/extras"
  if [ "${#TARGETS[@]}" -gt 0 ]; then
    for name in ${TARGETS[@]+"${TARGETS[@]}"}; do
      awk -F'\t' '{ print $2 }' "${WORK_DIR}/maps/${name}"
    done | awk -v rf="${WORK_DIR}/refkeys" '
      BEGIN { while ((getline k < rf) > 0) ref[k] = 1 }
      !($0 in ref) && !($0 in seen) { seen[$0] = 1; print }
    ' > "${WORK_DIR}/extras"
  fi
  build_expected "${WORK_DIR}/extras"

  if [ "${#TARGETS[@]}" -eq 0 ]; then
    say "env-sync ${MODE} - ${DIR}"
    say "reference: ${REF_BASE} (${REF_COUNT} keys); no .env* target files found"
    case "${MODE}" in
      verify) say "verify: PASS (no targets)" ;;
      apply) say "RESULT: PASS (no targets to write)" ;;
    esac
    return 0
  fi

  if [ "${invalid_targets}" -gt 0 ]; then
    say "env-sync: target issue(s) - values will not be touched:"
    for name in ${TARGETS[@]+"${TARGETS[@]}"}; do
      print_issues "${WORK_DIR}/maps/${name}" "${name}"
    done
    if [ "${MODE}" = "status" ]; then
      say "  (fix these or pass --files to exclude the file)"
      return 0
    fi
    say "RESULT: FAIL (invalid input)"
    return 1
  fi

  if [ "${MODE}" = "verify" ] && [ -n "${BACKUP_ARG}" ]; then
    verify_backup "${BACKUP_ARG}"
    return $?
  fi

  if [ "${MODE}" = "status" ] || [ "${MODE}" = "verify" ]; then
    render_report "${MODE}"
    return $?
  fi

  if [ "${MODE}" = "apply" ]; then
    apply_run
    return $?
  fi
}

main "$@"
