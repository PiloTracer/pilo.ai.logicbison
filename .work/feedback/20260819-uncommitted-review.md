# Uncommitted-change review — 2026-08-19

**Reviewed:** working tree vs `32af9f5` (AIOS-1 human commit lane). Branch `main`.
**Change set:** 21 modified files + 6 new untracked entries (Spring Boot stack pack + Terraform/IaC support, "initial basic support" per HANDOFF goal).
**Verifiers (run 2026-08-19):** `framework-verify` exit 0 · `skill-functional-verify` PASS (`infra-terraform` in `ANCHOR_CLEAN`, `scripts/skill-functional-verify.py:33`) · `touch-scope-verify` pass · `blast-radius-check` high-risk **warn** (protected hits `skills/SKILL_DEPENDENCIES.md`, `templates/cursorrules.template` — both in declared scope).
**Disposition:** quality of content is good; process/orchestration has 3 gaps, 6 inconsistencies, 5 orchestration faults. Fixes listed in §7.

---

## 1. Gaps

| # | Gap | Evidence |
|---|-----|----------|
| G1 | **NEXT.md silent** — Terraform/Spring Boot work appears nowhere in the planning carrier: no Done row, no iteration registry, no Recommended next. Pipeline bookkeeping skipped. | grep for `Terraform\|Spring Boot\|infra-terraform` in `.work/plans/NEXT.md` → zero hits |
| G2 | **HANDOFF stale** — only the Open goal line was updated (`.work/context/HANDOFF.md:6-7`); §Repository state (`.work/context/HANDOFF.md:13`) still says "21 skills", v0.6.0, no in-flight WIP note. A next session reads a 2026-08-14 picture of the repo. | `.work/context/HANDOFF.md:13` |
| G3 | **No Terraform/IaC workflow guide** — the v0.7 expansion plan called for `docs/guides/workflows/` guides (terraform-iac, aws-deploy, github-actions-ci); zero added. | `ls docs/guides/workflows/` → no infra guide |
| G4 | **No vendor integration cache** — `.work/docs/integration/` empty. The §External integration docs rule requires caching vendor docs (Terraform state backends, provider behavior is version-specific) + `MANIFEST.txt` entries; `infra-terraform/reference.md` documents S3+DynamoDB backends without cached vendor references. | `ls .work/docs/integration/` → empty |
| G5 | **Spring Boot pack unverified** — MOD-06 tags Docker/Maven specifics `assumption (not built/run — no project code exists)` (`.work/analysis/20260819-mod06-spring-boot-terraform-support.md:44-45`) while the CHANGELOG "Added" entry reads as shipped. No smoke build / dogfood (dev-stack P4) was run. | analysis `:44-45`; `CHANGELOG.md:9` |
| G6 | **Stack packs are inert** — `templates/README.md` says "apply after bootstrap… never wholesale-replace" (manual copy-paste); no script or skill automates applying a pack, unlike `dev-stack`'s `bin/start.sh` precedent. | `templates/README.md:131-141` |
| G7 | **Remaining plan rows untracked** — infra-aws, infra-ansible, cicd-github, node-react/python packs from the v0.7 plan are unimplemented and appear in no planning artifact. | `.work/plans/NEXT.md` (no mention) |

## 2. Inconsistencies

| # | Inconsistency | Evidence |
|---|---------------|----------|
| I1 | **MOD-06 output contradicts the final diff.** It claims `SKILL_DEPENDENCIES.md` was not edited ("the dependency matrix there does not yet list `infra-terraform`") — but it *is* modified (gate-graph rows `skills/SKILL_DEPENDENCIES.md:169-173`, verbs rows `:274-279`). It claims `START_HERE.md`/`PROCESS_ROUTER.md`/`FEATURE_STANDARD.md`/`feature-spec` were "not touched" — all four *are* modified. The follow-up sweep ran; the analysis was never refreshed. `mod06-output-check.sh` checks existence, not accuracy. | `.work/analysis/20260819-mod06-spring-boot-terraform-support.md:23,29-30` vs `git diff --stat` |
| I2 | **Skill-count drift** — HANDOFF says "21 skills" while README + `ai-director/reference.md` say 22 and the tree has 22. | `.work/context/HANDOFF.md:13` vs `README.md:33` |
| I3 | **`drift` verb overload** — one canonical row now means two unrelated things: "NEXT vs master plan consistency" (plan-verify/plan-repair) and "infra state vs config drift" (infra-terraform). Ambiguous for agents and for `@process-router`. | `skills/SKILL_DEPENDENCIES.md:274` |
| I4 | **touch-scope granularity regression** — blanket `".work/"` allowed path (`.work/touch-scope:29`) and emptied `allowed_patterns` replace the previous exact-file list; the scope gate is weakened for this session (any `.work/` change passes). | `.work/touch-scope:29` |
| I5 | **Dangling plan pointer** — HANDOFF goal cites "v0.7 draft-plan rows 10 and 7" (`.work/context/HANDOFF.md:6`); that plan exists only as a chat-transcript dump (`.work/prompts/session-20260819-121803.md`). No `.work/plans/` artifact resolves the reference. | `.work/context/HANDOFF.md:6` |
| I6 | **Changelog vs evidence** — `CHANGELOG.md:9` "Added" states registrations as shipped facts while the MOD-06 tags Docker/Maven specifics as unbuilt assumptions (G5). | `CHANGELOG.md:9`; analysis `:44-45` |

## 3. Bad orchestration

1. **O1 — Pipeline bypass.** Implementation started without persisting the plan: no foundation docs 01–04, no master plan, no NEXT iteration, no ADR for the "initial basic support" scope decision. Only MOD-06 + touch-scope were honored. The framework's own gated pipeline (`plan-foundation` → `plan-master` → `code-implementation`) was skipped for the work that *expands* the framework — the dogfood itself violates the dogfood.
2. **O2 — Split session bookkeeping.** The parallel session overwrote the HANDOFF Open goal line without recording the prior goal in "What this cycle produced" (S5 "note prior goal" skipped); no `@session-control close` ran, so HANDOFF/NEXT bookends were never written and the WIP sits untracked with stale state.
3. **O3 — Artifact type misuse.** `.work/prompts/session-20260819-121803.md` stores a chat *transcript* of the plan as a "session prompt"; `{PROMPTS_ROOT}` is for questionnaires. The plan belongs in `.work/plans/` (draft or foundation doc). Mislabeled + wrong location.
4. **O4 — Stale gate output.** The MOD-06 analysis documents a change set different from the one on disk (I1) — the review artifact no longer reflects what it approves.
5. **O5 — Commit hygiene.** The eventual commit bundles ~27 paths (skill + standard + concept + stack pack + 21 registry edits) under one ref; the framework's own "suggest split with multiple message blocks" guidance (session-control C4) applies: skill+standard+concept / stack pack / registry wiring are separable.

## 4. What's good (keep)

- **Additive, self-contained new directories** — deleting them reverts the feature with zero residue (MOD-06 reviewability claim is accurate for the dirs).
- **Slim skill** — `infra-terraform` 187+185 lines, under the 24576B soft budget, in `ANCHOR_CLEAN`; hard rules are right (plan-review gate, destroy hard-stop per CP8, no secrets in `.tf`, provider pinning, no hand-editing state).
- **Registry discipline** — `.cursorrules` + `templates/cursorrules.template` + `skills/README.md` + `ai-director/reference.md` + `concept-run` + `FEATURE_STANDARD` + `START_HERE` + `PROCESS_ROUTER` updated consistently; `framework-verify` count check passes.
- **MOD-08 trigger semantics** — "Required before first apply to shared infra" (`concepts/README.md:64`) is the right gate placement.
- **Dated standard + honest pack labeling** — `standards/20260819-IAC_CONVENTIONS.md` follows convention; Spring Boot pack self-describes as "Basic support… not a generator".

## 5. Recommended next actions (priority order)

1. Refresh `.work/analysis/20260819-mod06-spring-boot-terraform-support.md` to match the final diff (or add a "superseded" note) — I1/O4.
2. Update HANDOFF §Repository state (22 skills, WIP in flight) + add NEXT.md Done/iteration rows — G1/G2/O2.
3. Persist the v0.7 plan as a draft under `.work/plans/` so "rows 10 and 7" resolves — I5/O1.
4. Decide the commit split before `close commit` (skill+standard+concept / stack pack / registry wiring) — O5.
5. Schedule follow-ups: Terraform workflow guide + vendor cache (G3/G4), Spring Boot smoke build via `@dev-stack` (G5), stack-pack application helper (G6).
6. Track remaining plan rows (aws, ansible, cicd-github, node-react, python) in NEXT.md — G7.
