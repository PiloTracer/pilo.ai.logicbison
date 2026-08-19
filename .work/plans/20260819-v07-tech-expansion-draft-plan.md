# v0.7 technology expansion — draft plan (persisted from session transcript 20260819-121803)

**Status:** Draft — partially implemented. Row 7 (Terraform) and row 10 (Spring Boot, descoped to basic stack pack) shipped 2026-08-19 (see `NEXT.md` Done). Remaining rows tracked as follow-ups in `NEXT.md` § Recommended next.
**Source:** session transcript below, verbatim.

---

## User

Analyze the following linkedin recommendations, determine what technologies can be properly made part of this Agent OS Framework, throughout the application building process, analyze if you need to add new standards or concepts or technical documentation in order to implement them, and then present a plan that covers from the foundation planning to running in development and deploying on production.  Some of the technologies are already implemented and have been properly put to the test.
[Pasted text #2 · 11 lines]

--- Begin [Pasted text #2 · 11 lines] ---
This is merely a suggestion. To best position yourself for the Expert Engineer - Full-Stack role at Jimdo, consider the following:

Highlight your extensive experience in software architecture, payment systems, and e-commerce platforms.

in AWS, Docker, Python, React.js, Node.js, and SQL.

Update your profile to include any experience with Spring Boot, Terraform, Github Actions, and AI-assisted development tools.

Remember, these are general suggestions. Please adapt them to fit your unique experiences and qualifications.

include Ansible
--- End [Pasted text #2 · 11 lines] --- 
GOAL: TO IMPROVE THE AGENT OS FRAMEWORK, AND TAKE IT TO THE NEXT LEVEL OF PROFESSIONALISM, ADDING ADDITIONAL TECHNOLOGIES AND PROVIDING MORE OPTIONS TO THE PROGRAMMER. 
CRITICAL: DO NOT BLOAT SKILLS, PROPERLY MODULARIZE YOUR IMPLEMENTATION PLAN IN ORDER TO KEEP THE SKILLS EFFICIENT, SLIM, EFFICIENT, AND PROFESSIONAL.
PRESENT FULL VISUAL MATRIX ON THE PLAN, TO MAKE IT CLEAR WHAT IS VALUABLE AND WHAT IS NOT, WHAT IS EASY TO IMPLEMENT AND WHAT IS NOT.

## Assistant

Goal captured. Before building the plan, I need evidence of what the framework already covers — reading the skill registry, concepts, standards/templates inventory, and scanning for existing AWS/Terraform/Ansible/CI footprint:

Evidence gathered. One quick check on what the tech-stack template already documents, and updating the HANDOFF goal line with the now-known session goal:

HANDOFF goal updated, then the full analysis. Evidence base: skills registry (21 skills, no infra/CI family), `standards/` (8 templates, no cloud/IaC/CI), concepts MOD-01–07 only, grep confirms zero AWS/Terraform/Ansible footprint, `gate-verify.sh` + `release.sh` already exist (CI-ready), stack grill already lists `aws` as a stack option (`plan-foundation/reference.md:565`), `DOCS_TECH_STACK.md.template:55` already has a `REPLACE:CI_PLATFORM` slot.

# Agent OS Framework — Technology Expansion Plan (v0.7)

## 1. Technology assessment (11 from the LinkedIn suggestion)

| # | Tech | In framework today (evidence) | Verdict | Action |
|---|------|-------------------------------|---------|--------|
| 1 | **Docker** | ✅ Implemented — `dev-stack` skill, `.cursorrules` §Docker, compose isolation | **Keep + deepen** | Extend dev-stack: healthchecks, multi-stage builds, compose secrets |
| 2 | **Python** | ✅ Implemented — verifier toolchain (`skill-functional-verify.py`, `framework-verify.sh`) | **Keep + package** | Add `templates/stacks/python/` pack (FastAPI/Django options) |
| 3 | **SQL** | ✅ Implemented — `db-migration` (idempotent numbered migrations) | **Keep + deepen** | Add SQL review checklist (indexing, `EXPLAIN`, lock discipline) to db-migration reference |
| 4 | **AI-assisted tools** | ✅ Core of the framework — MOD-06/07, cross-LLM verification, adoption orchestrator (last commit `0a7cd7f`) | **Keep, ongoing** | Positioning guide; no new artifact needed this cycle |
| 5 | **GitHub Actions** | ◐ Partial — `gate-verify.sh`, `release.sh`, `readiness-verify.sh` exist; `REPLACE:CI_PLATFORM` slot in `DOCS_TECH_STACK.md.template:55`; **no skill, no workflows** | **Adopt as skill** | New `cicd-github` skill + workflow templates wired to existing gates |
| 6 | **AWS** | ✗ None (only stack-grill option `aws`, `plan-foundation/reference.md:565`) | **Adopt as skill** | New `infra-aws` skill + `cloud-security-baseline` standard |
| 7 | **Terraform** | ✗ None | **Adopt as skill** | New `infra-terraform` skill + `IAC_CONVENTIONS` standard + MOD-08 |
| 8 | **Ansible** | ✗ None | **Adopt (slim)** | New `infra-ansible` skill (explicitly requested — "include Ansible") |
| 9 | **Node.js / React.js** | ✗ None | **Template pack, not skill** | `templates/stacks/node-react/` — app-stack guidance belongs in per-project standards, not a skill (anti-bloat) |
| 10 | **Spring Boot** | ✗ None | **Defer** | `templates/stacks/spring-boot/` in a later release — lowest framework ROI |
| 11 | **SQL/Docker/Python/Node "for Jimdo"** | see rows 1–3, 9 | n/a | The framework gains options; Jimdo positioning is a resume concern, not a framework change |

## 2. Full visual matrix — value vs effort

```
                              H I G H   V A L U E
                                    ▲
       STRATEGIC  (do 2nd)          │   QUICK WINS  (do 1st)
                                    │
   AWS          ██  high effort     │   GitHub Actions  ◐  low-med
   Terraform    ██  med-high        │   Docker depth    ●  low
                                    │   SQL depth       ●  low
                                    │   Python pack     ●  low
                                    │
────────────────────────────────────┼──────────────────────────────▶  EFFORT
                                    │
       DEFER  (skip for v0.7)       │   OPTIONAL  (if capacity)
                                    │
   Spring Boot  ◐  low-med value    │   Ansible     ◐  med value
   (needs JVM ecosystem depth)      │   Node/React  ◐  med value
                                    │   pack (both med effort)
                                    ▼
                            L O W   V A L U E

   ● = already implemented (enhance)    ◐ = new addition    ██ = new, heavy
```

**Reading:** quick wins ship first (CI is the highest value/effort ratio — the gate scripts already exist). AWS + Terraform are the strategic core (the "cloud professional" tier). Ansible + Node/React are the optional tier. Spring Boot is the only genuine **skip** for this cycle — a Java stack pack without ecosystem depth is bloat, and nothing in the framework's own dogfooding needs it.

## 3. New framework artifacts needed (exactly what, no more)

| Artifact | Type | For | Bloat control |
|----------|------|-----|---------------|
| `infra-aws` | skill | AWS: SSO/profiles, regions, core services (ECS/Fargate, S3, RDS, VPC), Secrets Manager, cost check (MOD-03 hook) | 1 `skill.md` + 1 `reference.md`; links shared engine docs |
| `infra-terraform` | skill | IaC lifecycle: init/plan/apply, remote state + locking, modules, drift; destroy discipline → `.cursorrules` destructive-ops hard stop | same |
| `infra-ansible` | skill | inventory, playbooks, roles, vault, idempotency (mirrors db-migration discipline) | same |
| `cicd-github` | skill | workflow authoring, matrix, environments + approval gates, secrets, release; wires `gate-verify.sh` → PR CI | same |
| `20260819-cloud-security-baseline.md` | standard template | IAM least privilege, SSO, secrets-vs-`.env`, region/billing guardrails, cost tags | 1 dated standard (`standards/` convention) |
| `20260819-IAC_CONVENTIONS.md` | standard template | Terraform layout, state, plan approval, drift | 1 dated standard |
| `20260819-CICD_CONVENTIONS.md` | standard template | stages: lint/test (framework-verify, touch-scope, blast-radius) → build → dev→prod, rollback | 1 dated standard |
| MOD-08 `declarative-infra` | concept | IaC state/drift/immutability/plan-review gate — trigger table entry | README + prompt.md, registered in `concepts/README.md` |
| MOD-09 `release-pipeline` | concept | env promotion, CI gates, rollback — trigger table entry | README + prompt.md |
| `templates/stacks/{node-react,python,spring-boot}/` | template pack | CONVENTIONS + compose + DOCS_TECH_STACK fragments — **options for the programmer** without new skills | spring-boot deferred |
| `templates/cicd/github-actions-ci.yml.template` | template | PR + release workflows calling existing `gate-verify.sh`/`framework-verify.sh`/`blast-radius-check.sh` | 1 file |
| 3 workflow guides | docs | `docs/guides/workflows/`: aws-deploy, terraform-iac, github-actions-ci | follow existing guide conventions |
| `.work/docs/integration/` | vendor cache | AWS / Terraform / GitHub Actions docs + `MANIFEST.txt` entries | per §External integration rules |
| Wiring | registries | `.cursorrules` §Skills + `skills/README.md` + `ai-director/reference.md` registry + `framework-verify.sh` self-tests + `ANCHOR_CLEAN` set | **mandatory** — registry parity was audit debt in 2026-08-14 |

**Total: 4 new skills, 3 standards, 2 concepts, 3 stack packs, 1 CI template, 3 guides.** The existing 21 skills stay untouched except `db-migration`/`dev-stack` depth rows — that's the "no bloat, properly modularized" answer.

## 4. Phased roadmap — foundation → development → production

| Phase | Framework tool | Scope | Entry gate | Exit gate (evidence) |
|-------|---------------|-------|-----------|----------------------|
| **P0 Foundation** | `@plan-foundation greenfield` | Scope decision (tiers above), stack grills for AWS/Terraform/Ansible/GitHub Actions, registries (ASSUMPTIONS/RISK/UNKNOWNS), P0 intent doc 01 + docs 02–04 | your scope answer (Q1 below) | `certify plan-master-ready` |
| **P1 Master plan** | `@plan-master greenfield` | Milestones M1–M8 below, integrity + traceability | P0 certified | `implementation-ready: yes` |
| **P2 Implementation** | `@code-implementation` | **M1** infra family (`infra-aws`, `infra-terraform`, `infra-ansible` + 2 standards) · **M2** `cicd-github` + `CICD_CONVENTIONS` + workflow template · **M3** stack packs (node-react, python) · **M4** MOD-08/09 + integration caches + guides · **M5** depth (dev-stack, db-migration) · **M6** wiring (registries, `.cursorrules`, verify self-tests, MOD-06 outputs per milestone) | per-milestone task gates in NEXT.md | `@code-verify milestone` per M |
| **P3 Verification** | `@code-verify` + `@plan-verify` | `framework-verify.sh` · `skill-functional-verify.py` (ANCHOR_CLEAN incl. 4 new skills) · `touch-scope-verify.sh` · `blast-radius-check.sh` (expect high-risk warn: protected surfaces — owner-approved plan) | M6 done | all verifiers exit 0; coverage audit clean |
| **P4 Development / dogfood** | `@dev-stack` + `smoke-consumer.sh` | Scratch consumer project: greenfield via new stack pack → `dev-stack` up → `infra-terraform` plan/apply against **sandbox AWS account** → `cicd-github` workflow run | verifiers green | live smoke log; golden-deploy-verify pass |
| **P5 Production** | `release.sh` + `deploy-files`/`deploy-basic` | Tag `v0.7.0`, changelog, GitHub Actions CI green on the framework repo itself; propagate to consumers (`tools-project`, `tools-rfp`) — requires your approval per HANDOFF §Open owner actions #1 | dogfood pass | release published; consumer deploy verified; HANDOFF/NEXT close |

**Milestones:** M1 infra family → M2 CI/CD → M3 stack packs → M4 concepts+docs → M5 depth → M6 wiring+verify → M7 dogfood → M8 release+propagate.

## 5. Assumption ledger

- **Confirmed:** no AWS/Terraform/Ansible/CI skill or standard exists (grep across `skills/`, `standards/`, `templates/`, `concepts/`); gate/release scripts exist and are CI-ready; stack grill already knows `aws`; CI platform slot already in tech-stack template.
- **Inferred:** "properly part of framework" = skills for tool-agnostic workflows, template packs for app stacks, dated standards for guardrails; Ansible included per explicit request despite medium value.
- **Unknown:** AWS sandbox account availability (blocks P4 dogfood); final scope (all tiers vs subset); target release version.

---

**Needs your answer:**
1. Scope: implement **all tiers** (quick wins + strategic + optional incl. Ansible), or quick-wins + strategic only for v0.7?
2. Do you have an AWS sandbox account available for the P4 dogfood phase?
3. Persist this as the foundation plan under `.work/plans/` and run `@plan-foundation greenfield` now?

**Next step:**
`@plan-foundation greenfield` (after your scope answer — P0 foundation)

