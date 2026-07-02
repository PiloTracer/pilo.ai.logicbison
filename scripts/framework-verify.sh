#!/usr/bin/env bash
# Agent OS framework verification - run locally or in CI.
# Usage: bash scripts/framework-verify.sh   (from repo root)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_ROOT}"

failures=0
note() { echo "==> $*"; }
ok() { echo "    OK: $*"; }
die() { echo "    FAIL: $*" >&2; failures=$((failures + 1)); }

# Skill context budget (bytes) - the file an agent loads first must stay cheap.
# SOFT = reported as tech debt (non-failing); HARD = ratchet ceiling (fails).
# HARD sits just above today's largest skill so the ceiling can only move DOWN.
SKILL_SOFT_BUDGET=24576   # 24 KB
SKILL_HARD_CEILING=42000  # ~41 KB

# --- 0. Portability preflight (the verifiers assume a POSIX+GNU toolchain) ---
# Fail fast with an actionable message instead of a confusing mid-run error on a
# host (e.g. bare Windows/PowerShell or a minimal container) that lacks a tool.
note "Toolchain preflight"
missing_tools=()
for t in git rsync awk sed grep find; do
  command -v "${t}" >/dev/null 2>&1 || missing_tools+=("${t}")
done
if [[ ${#missing_tools[@]} -gt 0 ]]; then
  echo "    FAIL: missing required tool(s): ${missing_tools[*]}" >&2
  echo "          Agent OS shell verifiers need: bash, git, rsync, awk, sed, grep, find (all POSIX/common)." >&2
  echo "          Install them, or run verification from a POSIX shell with these on PATH." >&2
  exit 3
fi
ok "required tools present (git, rsync, awk, sed, grep, find)"

note "Agent OS framework-verify (root=${REPO_ROOT})"

# --- 1. Self-hosted layout (this repo IS the .ai tree) ---
note "Self-hosted layout"
for f in START_HERE.md README.md skills/README.md skills/SKILL_DEPENDENCIES.md templates/bootstrap.sh; do
  if [[ -f "${REPO_ROOT}/${f}" ]]; then
    ok "${f}"
  else
    die "missing ${f}"
  fi
done

# Derived count + registry cross-check (no hardcoded magic number - prevents
# the silent drift that left smoke-consumer asserting a stale count).
skill_dirs=()
while IFS= read -r d; do skill_dirs+=("$(basename "${d}")"); done \
  < <(find skills -mindepth 1 -maxdepth 1 -type d ! -name '.*' | sort)
skill_count="${#skill_dirs[@]}"
[[ "${skill_count}" -ge 1 ]] || die "no skill directories found under skills/"
for n in "${skill_dirs[@]}"; do
  s="skills/${n}/skill.md"
  if [[ ! -f "${s}" ]]; then die "missing ${s}"; continue; fi
  grep -Eq "^name: ${n}[[:space:]]*$" "${s}" || die "${s}: frontmatter name does not match folder '${n}'"
  grep -q "${n}" skills/README.md || die "skill '${n}' not registered in skills/README.md"
  grep -q "${n}" skills/SKILL_DEPENDENCIES.md || die "skill '${n}' not in SKILL_DEPENDENCIES.md matrix"
done
ok "${skill_count} skills: skill.md + matching frontmatter + README + DEPS rows (derived)"

# Prose drift guard: any "<N> skill(s)" mention in landing docs must match the derived count.
prose_before="${failures}"
for doc in README.md START_HERE.md skills/README.md; do
  while IFS= read -r num; do
    [[ -z "${num}" ]] && continue
    if [[ "${num}" -ne "${skill_count}" ]]; then
      die "${doc} mentions '${num} skills' but ${skill_count} skill dirs exist (stale prose count)"
    fi
  done < <(sed 's/[*`]//g' "${doc}" | grep -oE '[0-9]+ skills?' | grep -oE '^[0-9]+' || true)
done
if [[ "${failures}" -eq "${prose_before}" ]]; then
  ok "skill-count prose matches derived count in landing docs"
fi

# --- 1c. Trimmed skill integrity (reference links + moved content) ---
note "skill-functional-verify (trim integrity)"
if python3 "${REPO_ROOT}/scripts/skill-functional-verify.py" >/dev/null; then
  ok "trimmed skills: reference anchors + required protocol sections"
else
  die "skill-functional-verify failed - run: python3 scripts/skill-functional-verify.py"
fi

# Intake contract guard: classification is agent-judged (no executable classifier),
# so we structurally assert the feature-spec intake table keeps all 4 classes + the
# force override - preventing the routing contract from being silently gutted.
intake_md="skills/feature-spec/skill.md"
intake_before="${failures}"
for cls in local cross-cutting brownfield underspecified; do
  grep -qE "\*\*${cls}\*\*" "${intake_md}" || die "feature-spec intake table missing class '${cls}'"
done
grep -qE 'force=<class>' "${intake_md}" || die "feature-spec intake missing 'force=<class>' override"
if [[ "${failures}" -eq "${intake_before}" ]]; then
  ok "feature-spec intake contract: 4 classes + force override present"
fi

# --- 1b. Skill context budget (dogfood the framework's own context discipline) ---
# A skill.md is the first thing an agent loads to act; an oversized one burns the
# very context budget Agent OS exists to protect. HARD ceiling fails (ratchet);
# SOFT budget is reported as tracked debt without failing the build.
note "Skill context budget (soft ${SKILL_SOFT_BUDGET}B / hard ${SKILL_HARD_CEILING}B)"
over_soft=0
for n in "${skill_dirs[@]}"; do
  s="skills/${n}/skill.md"
  [[ -f "${s}" ]] || continue
  bytes="$(wc -c < "${s}" | tr -d ' ')"
  if [[ "${bytes}" -gt "${SKILL_HARD_CEILING}" ]]; then
    die "${s} is ${bytes}B > hard ceiling ${SKILL_HARD_CEILING}B - move examples/edge cases to skills/${n}/reference.md"
  elif [[ "${bytes}" -gt "${SKILL_SOFT_BUDGET}" ]]; then
    echo "    DEBT: ${s} is ${bytes}B > soft budget ${SKILL_SOFT_BUDGET}B (trim toward reference.md)"
    over_soft=$((over_soft + 1))
  fi
done
ok "no skill.md over hard ceiling ${SKILL_HARD_CEILING}B (${over_soft} over soft budget, tracked as debt)"

# --- 2. Consumer bootstrap smoke ---
note "Consumer bootstrap smoke"
SMOKE_ROOT="$(mktemp -d)"
trap 'rm -rf "${SMOKE_ROOT}"' EXIT

mkdir -p "${SMOKE_ROOT}/.ai"
rsync -a \
  --exclude='.git' \
  --exclude='.work' \
  --exclude='.github' \
  --exclude='.private' \
  --exclude='.credentials' \
  --exclude='scripts/smoke-consumer.sh' \
  "${REPO_ROOT}/" "${SMOKE_ROOT}/.ai/"

(
  cd "${SMOKE_ROOT}"
  git init -q
  bash .ai/templates/bootstrap.sh >/dev/null
  for f in .work/context/HANDOFF.md .work/plans/NEXT.md .cursorrules DOCS_TECH_STACK.md; do
    if [[ -f "${f}" ]]; then
      ok "consumer created ${f}"
    else
      die "consumer missing ${f}"
    fi
  done
  if [[ -d .ai/.work ]]; then
    die "bootstrap placed .work inside .ai/ (expected repo root)"
  fi
)

# --- 2b. deploy-files in-place must create .cursorrules ---
note "deploy-files in-place scaffold"
DF_SMOKE="$(mktemp -d)"
mkdir -p "${DF_SMOKE}"
(
  cd "${DF_SMOKE}"
  bash "${REPO_ROOT}/scripts/deploy-files.sh" . >/dev/null
  if [[ ! -f .cursorrules ]]; then
    die "deploy-files in-place did not create .cursorrules (BOOTSTRAP_SKIP_CURSERRULES leak?)"
  fi
  if [[ ! -f .work/context/HANDOFF.md ]]; then
    die "deploy-files in-place did not create .work/context/HANDOFF.md"
  fi
)
ok "deploy-files in-place creates .cursorrules + .work/"

# --- 2b2. deploy-repo --status (read-only) ---
note "deploy-repo --status"
bash "${REPO_ROOT}/scripts/deploy-repo.sh" --status >/dev/null
bash "${REPO_ROOT}/scripts/deploy-repo.sh" --status "${DF_SMOKE}" >/dev/null
ok "deploy-repo --status reports source + optional target"

# --- 2c. install-opencode-config via deploy-basic (thin-client) ---
note "install-opencode-config (thin-client via deploy-basic)"
OC_SMOKE="$(mktemp -d)"
bash "${REPO_ROOT}/scripts/deploy-basic.sh" "${OC_SMOKE}" >/dev/null
if [[ ! -f "${OC_SMOKE}/opencode.json" ]]; then
  die "deploy-basic did not create opencode.json"
fi
python3 -c "
import json
c=json.load(open('${OC_SMOKE}/opencode.json'))
paths=c.get('skills',{}).get('paths',[])
assert any('${REPO_ROOT}' in p for p in paths), paths
"
ok "deploy-basic creates thin-client opencode.json with AGENT_OS_SOURCE paths"
rm -rf "${OC_SMOKE}"

# --- 2d. install-opencode-config --sync-paths (source moved) ---
note "install-opencode-config --sync-paths"
FW_ROOT="${REPO_ROOT}"
SYNC_SMOKE="$(mktemp -d)"
bash "${FW_ROOT}/scripts/deploy-basic.sh" "${SYNC_SMOKE}" >/dev/null
OLD_SRC="/tmp/old-agent-os-path"
python3 << PY
import json
p = "${SYNC_SMOKE}/opencode.json"
with open(p) as f:
    c = json.load(f)
for i, path in enumerate(c["skills"]["paths"]):
    if "${FW_ROOT}" in path:
        c["skills"]["paths"][i] = path.replace("${FW_ROOT}", "${OLD_SRC}")
with open(p, "w") as f:
    json.dump(c, f, indent=2)
    f.write("\n")
PY
REPO_ROOT="${SYNC_SMOKE}" AI_SOURCE="${FW_ROOT}" OLD_SOURCE="${OLD_SRC}" \
  bash "${FW_ROOT}/scripts/install-opencode-config.sh" --sync-paths >/dev/null
python3 -c "
import json
c=json.load(open('${SYNC_SMOKE}/opencode.json'))
assert any('${FW_ROOT}' in p for p in c['skills']['paths']), c['skills']['paths']
assert 'tools-project' in c.get('mcp', {}), 'mcp block must be preserved'
"
bash "${FW_ROOT}/scripts/deploy-basic.sh" --status "${SYNC_SMOKE}" 2>&1 | grep -q "skills.paths\[0\].*ok"
ok "install-opencode-config --sync-paths realigns stale paths and preserves mcp"
rm -rf "${SYNC_SMOKE}"

# --- 2e. install-opencode-config --sync-paths (fat-client) ---
note "install-opencode-config --sync-paths (fat-client)"
FC_SMOKE="$(mktemp -d)"
(
  cd "${FC_SMOKE}"
  bash "${REPO_ROOT}/scripts/deploy-files.sh" . >/dev/null
  python3 << PY
import json
p = "opencode.json"
bad = f".ai\n${REPO_ROOT}"
with open(p, "w") as f:
    json.dump({
        "\$schema": "https://opencode.ai/config.json",
        "instructions": [f"{bad}/START_HERE.md", ".cursorrules"],
        "references": {"ai": {"path": bad, "description": "Agent OS"}},
        "skills": {"paths": [f"{bad}/skills"]},
        "mcp": {"custom-block": {"enabled": True}},
    }, f, indent=2)
    f.write("\n")
PY
  REPO_ROOT="$(pwd)" bash "${REPO_ROOT}/scripts/install-opencode-config.sh" --sync-paths >/dev/null
  python3 -c "
import json
c=json.load(open('opencode.json'))
p0=c['skills']['paths'][0]
assert p0 == '.ai/skills', p0
assert all(chr(10) not in x for x in c['instructions']), c['instructions']
assert c['references']['ai']['path'] == '.ai'
assert 'custom-block' in c.get('mcp', {}), 'mcp must be preserved'
"
)
ok "install-opencode-config --sync-paths repairs fat-client paths"
rm -rf "${FC_SMOKE}" "${DF_SMOKE}"

# --- 3. Removed vendor integration paths ---
note "No stale vendor integration paths"
if grep -rqE 'docs/integration/(hacienda|oidc|xades)' --include='*.md' . 2>/dev/null; then
  die "found reference to removed docs/integration vendor paths"
else
  ok "no hacienda/oidc/xades integration paths in markdown"
fi

# --- 4. Template placeholders present ---
note "REPLACE: token hygiene"
if grep -rq 'REPLACE:PROJECT_NAME' templates/cursorrules.template templates/work/ 2>/dev/null; then
  ok "REPLACE:PROJECT_NAME in templates"
else
  die "REPLACE:PROJECT_NAME missing from templates/"
fi
if grep -rq 'REPLACE:' standards/ 2>/dev/null; then
  ok "REPLACE: tokens in standards/"
else
  die "REPLACE: tokens missing from standards/"
fi

# --- 5. Markdown relative link check ---
note "Markdown relative links"
while IFS= read -r -d '' md; do
  dir="$(dirname "${md}")"
  while IFS= read -r link; do
    [[ -z "${link}" ]] && continue
    [[ "${link}" =~ ^https?:// ]] && continue
    [[ "${link}" =~ ^# ]] && continue
    target="${link%%#*}"
    target="${target%%\?*}"
    [[ -z "${target}" ]] && continue
    # A real relative link target has no whitespace or backticks; anything that
    # does is prose containing a literal "](" (e.g. inside inline code), not a link.
    [[ "${target}" =~ [[:space:]\`] ]] && continue
    resolved="${dir}/${target}"
    if [[ ! -e "${resolved}" ]]; then
      die "broken link in ${md}: (${link}) -> ${resolved}"
    fi
  done < <(grep -oE '\]\([^)]+\)' "${md}" 2>/dev/null | sed -E 's/^\]\(//; s/\)$//' | grep -v '^https\?://' | grep -v '^#' || true)
done < <(find . -name '*.md' ! -path './.git/*' ! -path './.work/*' -print0 2>/dev/null)

ok "markdown link scan complete"

# --- 6. readiness-verify self-test (exercise the probe-ledger linter) ---
note "readiness-verify self-test"
RV_ROOT="$(mktemp -d)"
RV_LEDGER="${RV_ROOT}/PROBE_LEDGER.md"

# Honest ledger: D1 confirmed/high with a cite; computed = claimed = 100%.
cat > "${RV_LEDGER}" <<'EOF'
**Coverage:** 100% (target 85%)

| Dim | Topic | Status | Conf | Evidence / source | Iter |
|-----|-------|--------|------|-------------------|------|
| D1 ★ | Intent | confirmed | high | doc01 §scope | 1 |
EOF
if bash "${REPO_ROOT}/scripts/readiness-verify.sh" "${RV_LEDGER}" >/dev/null 2>&1; then
  ok "readiness-verify accepts an honest ledger"
else
  die "readiness-verify rejected an honest ledger"
fi

# Dishonest ledger: confirmed/high with no evidence -> must exit non-zero.
cat > "${RV_LEDGER}" <<'EOF'
**Coverage:** 100% (target 85%)

| Dim | Topic | Status | Conf | Evidence / source | Iter |
|-----|-------|--------|------|-------------------|------|
| D1 ★ | Intent | confirmed | high | — | 1 |
EOF
if bash "${REPO_ROOT}/scripts/readiness-verify.sh" "${RV_LEDGER}" >/dev/null 2>&1; then
  die "readiness-verify accepted a dishonest ledger (confirmed/high, no cite)"
else
  ok "readiness-verify rejects an uncited confirmed/high dimension"
fi
rm -rf "${RV_ROOT}"

# --- 7. traceability-verify self-test (exercise the FR->task linter) ---
note "traceability-verify self-test"
TV_ROOT="$(mktemp -d)"
TV_PLAN="${TV_ROOT}/x-full-plan.md"
# Orphan: FR-02 never on a task line -> must fail.
printf '## reqs\n- FR-01 - FR-02\n| signup | FR-01 | M2-T1 |\n' > "${TV_PLAN}"
if bash "${REPO_ROOT}/scripts/traceability-verify.sh" "${TV_PLAN}" >/dev/null 2>&1; then
  die "traceability-verify missed an orphan FR (FR-02 not on any task line)"
else
  ok "traceability-verify catches an FR with no task"
fi
# Fully mapped -> must pass.
printf '## reqs\n| signup | FR-01 | M2-T1 |\n| reset | FR-02 | M2-T2 |\n' > "${TV_PLAN}"
if bash "${REPO_ROOT}/scripts/traceability-verify.sh" "${TV_PLAN}" >/dev/null 2>&1; then
  ok "traceability-verify passes a fully-mapped plan"
else
  die "traceability-verify rejected a fully-mapped plan"
fi
rm -rf "${TV_ROOT}"

# --- 8. gate-verify self-test (exercise the completion-gate evidence linter) ---
note "gate-verify self-test"
GV_ROOT="$(mktemp -d)"
GV_NEXT="${GV_ROOT}/NEXT.md"
hdr='## Current iteration\n\n### Tasks\n| ID | Description | Files | Status | Notes |\n|----|-------------|-------|--------|-------|\n'
# Dishonest: a done task with empty Notes -> must fail.
printf "${hdr}| M1-T1 | do | a.py | done | |\n" > "${GV_NEXT}"
if bash "${REPO_ROOT}/scripts/gate-verify.sh" "${GV_NEXT}" >/dev/null 2>&1; then
  die "gate-verify accepted a done task with no recorded gate evidence"
else
  ok "gate-verify rejects a done task with empty Notes"
fi
# Honest: done task records gate evidence -> must pass.
printf "${hdr}| M1-T1 | do | a.py | done | tests pass; lint ok; exit 0 |\n" > "${GV_NEXT}"
if bash "${REPO_ROOT}/scripts/gate-verify.sh" "${GV_NEXT}" >/dev/null 2>&1; then
  ok "gate-verify accepts a done task that cites evidence"
else
  die "gate-verify rejected a done task that cites gate evidence"
fi
rm -rf "${GV_ROOT}"

# --- 9. prepare-commit-msg co-authored strip self-test ---
note "prepare-commit-msg co-authored strip"
PCM="${REPO_ROOT}/hooks/prepare-commit-msg"
pcm_before="${failures}"
if [[ ! -x "${PCM}" ]]; then
  die "missing or non-executable ${PCM}"
else
  PCM_TMP="$(mktemp)"
  printf 'feat: test subject\n\nCo-authored-by: Cursor <cursoragent@cursor.com>\n' > "${PCM_TMP}"
  sh "${PCM}" "${PCM_TMP}" message
  if grep -qiE '^[[:space:]]*Co-authored-by:' "${PCM_TMP}"; then
    die "prepare-commit-msg failed to strip Co-authored-by trailer"
  else
    ok "prepare-commit-msg strips Co-authored-by trailers"
  fi
  rm -f "${PCM_TMP}"
fi

if [[ "${failures}" -gt 0 ]]; then
  echo ""
  echo "framework-verify: ${failures} check(s) failed" >&2
  exit 1
fi

echo ""
echo "framework-verify: all checks passed"
