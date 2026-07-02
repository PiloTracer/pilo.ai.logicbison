# Changelog

All notable changes to Agent OS are documented here. Format inspired by [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html) once tagged.

## [Unreleased]

### Added
- **`opencode.json.template`** — portable opencode config with `REPLACE:AGENT_OS_ROOT` tokens (copy and customize per host).
- **`.github/task-registry.json`** — example registry so `@session-control start` can resolve task refs in this framework repo.
- **`.work/context/MCP_REGISTRY.md`** — records approved MCP registration for tools-project.

### Changed
- **`opencode.json`** — absolute `/mnt/work/Projects/...` paths replaced with repo-relative and sibling `../.ai.*` paths.
- **`README.md`** — skill count and “Skills at a glance” table updated to all 22 registered skills.
- **`skills/project-query-setup/skill.md`** — standard YAML frontmatter (`name:` matches folder).
- **`skills/session-control/skill.md`** — commit task-ref rule aligned with M4/C4 (ask once; warn if using `type:` without ref).
- **`CONTRIBUTING.md`** — verification is local-only; GitHub Actions CI disabled.

### Fixed
- **`scripts/framework-verify.sh`** — `set -e` no longer exits early when prose-count or intake guards fail (all checks now run).
- **`skills/README.md`** — removed stale “18-skill registry” wording.

### Removed
- **GitHub Actions CI** — deleted `.github/workflows/framework-verify.yml` (run `bash scripts/framework-verify.sh` locally instead).

## [0.4.2] - 2026-07-01

### Added
- **`deploy-basic` skill** — thin-client bootstrap (`.cursorrules` + `.work/` + `DOCS_TECH_STACK.md` only; skills loaded via `AGENT_OS_SOURCE`).
- **`session-control` `context` mode** — read-only full context load with uncommitted-aware dirty-tree summary.
- **`deploy-files` in-place bootstrap** — no-overwrite merge for fat-client deploys.

### Changed
- **`deploy-files`** — rules-aware merge on `update` (preserve target customizations).
- Registries, templates, `.quick/` refs, and `PROCESS_ROUTER.md` updated for deploy-basic and context mode.

## [0.3.2] - 2026-06-29

### Added
- **Cross-framework Confirm gate** on `@ai-director` and `@x-director` — both directors now render a **routing plan** (classified bucket, `Routing confidence: high|med|low`, the skills/directors about to invoke, and a list of non-reversible writes) and wait for explicit `y`/`yes` before any execute or HANDOFF write. Flags: `- <free-text> -y` skips the gate (trust-mode); `- <free-text> --dry-run` renders the plan and stops. Confidence `low` with no ack falls back to one clarifying question. Prevents misclassification from firing writes across 2–3 frameworks' `.work/` trees before the operator notices.
- **`@ai-director review-routing`** mode — read-only feedback-loop aggregate over the last N `## Latest action (@ai-director)` HANDOFF blocks. Per bucket: counts `low`-confidence entries, non-empty `User correction` entries, and aborts at the Confirm gate; emits a `tighten / split / ok` verdict and lists signal strings to revise. Never edits the bucket table — surfaces the change request only.
- **Frameworks registry in `.cursorrules`** — new section (template + self-hosted) listing `.ai` / `.ai.ui` / `.ai.biz` with their directors and bootstrap-artifact paths. Resolves a long-standing gap: target projects had **no documented mechanism** for x-director to discover sibling frameworks; it previously hardcoded `/mnt/work/Projects/...` absolute paths.
- **Framework preflight (mandatory)** — `@ai-director` (when redirecting outside `.ai`) and `@x-director` (always) must now resolve sibling framework roots in this exact order: `.cursorrules` § Frameworks registry → sibling auto-discovery from `.ai/` parent → read `<framework>/skills/README.md`. Absent framework → one-line `framework not installed here` message and stop. Never route into the void.
- **`Routing confidence` + `User correction` HANDOFF fields** — record schema extended on both directors so routing quality becomes observable signal. Aborts at the Confirm gate still write a record (`Executed: aborted at confirm gate` + correction note) so misroutes feed back into `review-routing`.
- **SKILL_DEPENDENCIES § Frameworks registry resolution (mandatory)** — portable sibling-framework root resolution table, mirrored from `.cursorrules`.
- **Existing `[Unreleased]` work** shipped in this cut: `scripts/gate-verify.sh` completion gate; `skill.md` context-budget guard (24 KB soft / 42 KB hard ratchet); toolchain preflight (exit 3 on missing POSIX tool); `@feature-spec intake - <free sentence>` free-text feature-intake orchestrator with `force=<class>` override; free-text `@feature-spec create -`; `feature-request` routing bucket in `process-router`; skill-count prose guard; traceability pre-check in `@session-control close`; `CONTRIBUTING.md § Cutting a release`.

### Changed
- **x-director is now a delegator, not a re-classifier.** The 13 duplicated sub-bucket rows (`engineering-bootstrap`, `ui-design`, `business-strategy`, …) dropped from `skills/x-director/skill.md`. x-director now classifies **only the coarse framework** and forwards the user's verbatim request to the chosen director, which owns its fine-grained bucket table as the single source of truth. Removes the two-bucket-tables-drift hazard and shrinks the skill's prose footprint.
- **`.cursorrules` skills tables** (template + self-hosted) list `ai-director` / `x-director` rows that the template previously omitted.

### Fixed
- **x-director hardcoded absolute paths** (`/mnt/work/Projects/.ai.ui/`, `/mnt/work/Projects/.ai.biz/`) replaced with `.cursorrules`-driven resolution + sibling auto-discovery. The skill is now portable to any host layout.
- **Markdown link scan was a silent no-op** — `framework-verify.sh` extracted links with `rg` (ripgrep) guarded by `|| true`, so on any host without `rg` it checked nothing while reporting `OK`, and its `sed` stripping never removed the `](` prefix. Rewritten with portable `grep -oE` + correct stripping (no `ripgrep` dependency). The now-functional scan exposed and fixed **4 broken relative links** (`plan-foundation/skill.md` → `plan-master`, `process-router/reference.md` → `PROCESS_ROUTER.md`, and two workflow guides → `skills/README.md`).
- **`README.md`** stale prose count — "(11 in total)" corrected to "(14 skills in total)" and now covered by the prose guard above.


## [0.4.0] - 2026-06-29

### Added
- **`.work/docs/` documentation tree** — new standard location for human-readable project documentation under `.work/docs/`. Subdirectories: `guides/` (how-to guides), `tutorials/` (walkthroughs), `reference/` (API/reference docs), `features/<slug>/` (per-feature user docs). Distinct from formal SPECs in `.work/features/`.
- **`@docs` skill** — new skill for creating and managing project documentation. Modes: `create guide`, `create tutorial`, `create reference`, `status`. Writes to `.work/docs/` from templates.
- **`@feature-spec document - <slug>` mode** — brownfield-friendly feature documentation. Creates `.work/docs/features/<slug>/README.md` with purpose, usage, entry points, and key files — no formal SPEC lifecycle required. Scans codebase for surface (routes, modules, screens); links to existing SPEC if one exists.
- **`docs` and `feature-doc` buckets** in `@ai-director` routing table — free-text documentation requests now route to `@docs` or `@feature-spec document` instead of falling through to `unsure`.
- **`{DOCS_ROOT}` placeholder** — resolves to `.work/docs/`. Registered in `.cursorrules`, `SKILL_DEPENDENCIES.md`, `.work/README.md`, and bootstrap template.
- **`.work/docs/` templates** in `templates/work/docs/` — README, guide, tutorial, reference, and feature-doc templates shipped with bootstrap.
- **`bootstrap.sh` creates `.work/docs/` tree** — `guides/`, `tutorials/`, `reference/` subdirectories created on init.
- **Documentation signals in `@x-director`** — `documentation`, `guide`, `tutorial`, `how-to`, `feature doc` added to `engineering` framework classification so docs requests route to `@ai-director` instead of `unsure`.

### Fixed
- **Feature SPEC signal collision** — `feature-spec-create` bucket in `@ai-director` no longer lists "document feature Y" (that signal now belongs to `feature-doc`). Prevents routing ambiguity between SPEC creation and brownfield feature docs.

## [0.3.1] - 2026-05-29

### Fixed
- **`scripts/smoke-consumer.sh`** asserted a stale skill count (11) after the registry grew to 14 in 0.2.0, silently failing the CI `Consumer smoke` job since that release. Both `smoke-consumer.sh` and `framework-verify.sh` now **derive** the count and cross-check that every skill folder is registered in `skills/README.md` and `SKILL_DEPENDENCIES.md` with matching frontmatter — eliminating hardcoded-count drift.

### Added
- **`scripts/traceability-verify.sh`** — machine-checks that every FR id in a master plan maps to a task `M{N}-T{N}` (MASTER_PLAN_STANDARD Phase 4 gate as a test); NFRs reported not failed; exits 0 when no plan. Self-tested in `framework-verify.sh`; referenced by `plan-verify master` and `plan-master` Gate P4; runs in CI (no-op without a plan).
- **`scripts/release.sh <version>`** — release preflight that runs every verifier, asserts the CHANGELOG has the version section and a clean tree, and only then creates the annotated tag (never pushes). A tag can no longer ship while verification is red.
- **CI** now also triggers on `v*` tag pushes and runs `traceability-verify`, so released tags are verified.

## [0.3.0] - 2026-05-29

### Added
- **`probe` mode** for `@plan-foundation` and `@plan-master` — adaptive, gap-driven interrogation loop. Scores knowledge/plan coverage across fixed dimensions, asks ≤5 targeted questions per iteration, records answers into the canonical registries + doc 01 / plan body, and loops to a confidence target (default 85%). Sub-modes: `probe`, `probe - until ready`, `probe - status`.
- **`skills/probe-protocol.md`** — single-source-of-truth engine (loop, Coverage Score, ledger, ease-of-use rules) reused by both probe modes; skills supply only a coverage profile. New canonical verb `probe` registered in `SKILL_DEPENDENCIES.md`. Not a skill folder (14-skill count unchanged).
- **`plan-foundation` § Foundation coverage map** (D1–D10) → exit gate S4 plan-master-ready; **`plan-master` § Master coverage map** (M-D1…M-D7, the interactive front-end to `integrity`) → exit gate implementation-ready.
- **`templates/work/plans/foundation/PROBE_LEDGER.md.template`** — resumable, auditable probe state (`{PLANS_ROOT}/foundation/PROBE_LEDGER.md` · `{PLANS_ROOT}/full/PROBE_LEDGER.md`).
- **`scripts/readiness-verify.sh`** — machine-checkable honesty linter for probe ledgers (CI-ready). Fails when a `confirmed/high` dimension cites no evidence, when the header Coverage % disagrees with the table-computed value (tol 2 pts), or when coverage ≥ target while a gate-blocking (★) dimension is still `unknown`. Exits 0 when no ledger exists (probe is optional). **Self-tested in `framework-verify.sh`** (asserts accept-honest + reject-uncited, so CI exercises the linter even with no real ledger present).
- **`plan-verify` probe awareness** — foundation and master verify matrices + reports surface `PROBE_LEDGER` Coverage % (via `readiness-verify.sh`) and route thin coverage to `@plan-foundation probe` / `@plan-master probe`.
- **`docs/guides/workflows/20260529-tutorial-probe-project.md`** — operator tutorial for `probe` mode; registered in the workflows matrix and process-router probe bucket.
- **`@plan-verify coverage`** (alias `registry`) — read-only code-to-SPEC parity audit; surfaces vs `{FEATURE_SPEC_ROOT}` Implementation map and DIRECTORY_MAP.
- **`@plan-repair repair - from coverage`** — register unmapped surfaces via `@feature-spec create` + DIRECTORY_MAP (no parallel `feature.yml` canon).
- **FEATURE_STANDARD §14 Implementation map** (optional) — primary code paths for brownfield locate-ability.

### Changed
- **Docs DRY (safe class):** removed redundant readiness-state representations where they added no information — `plan-foundation/skill.md` collapsed the escalation ASCII + lifecycle table into the canonical state table (842→820); `plan-foundation/reference.md` dropped the ASCII duplicating its readiness table; `process-router/reference.md` and root `PROCESS_ROUTER.md` readiness blocks replaced with one-line pointers to `SKILL_DEPENDENCIES.md`. Newcomer explainers (`README.md`, `START_HERE.md`) and the canonical `SKILL_DEPENDENCIES.md` diagram kept intact; per-skill drift guardrails intentionally preserved.
- **CI + `@session-control close`** now run `scripts/readiness-verify.sh` — `.github/workflows/framework-verify.yml` adds a probe-ledger honesty step (no-op without a ledger); session-control close C2 adds a probe-ledger pre-check that routes failures to `@plan-foundation probe` / `@plan-master probe`.
- **`.cursorrules` / `cursorrules.template` § Host hygiene** — container-first package installs; anti-pattern for host `npm`/`pip` on Compose projects; frontend `npm ci` in-container example.

## [0.2.0] - 2026-05-21

### Added
- **`plan-verify`** and **`plan-repair`** skills — symmetric planning verify/repair; brownfield framework alignment without formal `@plan-foundation` / `@plan-master`; open-language Request interpretation and R0-free alignment maps.
- **`code-repair`** skill — remediate verifier, migration, and SPEC findings with mandatory re-verify.
- **`code-verify`** / **`code-repair`** — open-language free requests: Request interpretation (verify), Implementation alignment map R0-free (repair); `code-verify status` mode.
- **`code-implementation continue` batch targets:** `- N` (e.g. `- 5`), `- until blocked`, `- M{N}-T{a}..T{b}`; default `continue` = 1 task. All modes stop on task gate fail or blocker; progress lines `Batch k/N: M4-T4 done`; mandatory batch summary.
- **Framework CI** - `.github/workflows/framework-verify.yml` runs `scripts/framework-verify.sh` and `scripts/smoke-consumer.sh` on push/PR.
- **`scripts/framework-verify.sh`** - self-hosted layout, consumer bootstrap smoke, stale integration path grep, template `REPLACE:` check, markdown relative link scan (expects **14** skill directories).
- **`scripts/smoke-consumer.sh`** - local consumer adoption smoke with next-step hints.
- **`docs/adoption/minimal-adoption.md`** - lite vs full adoption paths.
- **README / START_HERE / templates/README** - path convention table (nested `.ai/` vs self-hosted git root).
- `README.md` discoverability: hook rewrite, badges, comparison table, "Skills at a glance" (**14** skills).
- `LICENSE` (MIT).
- `CONTRIBUTING.md` and this `CHANGELOG.md`.
- "Template - your repo's HANDOFF.md will be filled by `@session-control`" notes on demo `.work/` artifacts so visitors don't mistake them for real project content.
- **`SKILL_DEPENDENCIES.md § Canonical command vocabulary`** - single source of truth for shared verbs (`status`, `init`, `start`, `continue`, `plan`, `complete`, `verify`, `repair`, …).
- **`SKILL_DEPENDENCIES.md § Blocked report shape`** - uniform "blocked (prerequisite)" report that every skill emits when a gate stops execution.
- **`dev-stack`** gains `status` and `init` modes plus a brownfield gate that refuses to silently overwrite an existing `bin/start.sh`.
- **G1** `code-implementation plan` (was `plan-iteration`) PI1 stops with the unified blocked-report shape on missing/Draft plan without HANDOFF waiver.
- **G2** `feature-spec create` adds CR0: hard-stops on existing slug folder; warns (and proceeds on confirm) when `plan-master-ready: no`.
- **G3** `db-migration create`/`add`/`run`/`verify` now require `db-migration init` to have run (runner + `001_init.sql` baseline).
- **G4** `code-verify milestone` M0 gate stops if the requested milestone is not defined in master plan §19 or active in `NEXT.md`.
- **B1** `project-bootstrap init` adds B0 brownfield detection (overwrite-all / overwrite-missing / keep / abort).
- **B2** `db-migration init` adds IB0 brownfield detection (keep / overwrite-runner / overwrite-all / abort).
- **`dev-stack`** `status` mode for `bin/start.sh` health-check.

### Changed
- **Invocation punctuation:** Skills, workflows, and command examples use ASCII hyphen `-` (not em dash `—`) between verb and argument (e.g. `@code-implementation plan - M1`).
- **`code-implementation`** mode renamed: **`plan-iteration` → `plan`** (legacy alias retained).
- **`plan-master`** mode renamed: **`task` → `show`** (legacy alias retained).
- **`process-router`** documents explicit **`route`** token.
- **Unified "blocked (prerequisite)" report shape** across plan-foundation, plan-master, code-implementation, code-verify, feature-spec, db-migration.
- **`db-migration`** I5 long FastAPI lifespan code blocks moved from `skill.md` to `reference.md`.
- **Canonical migration policy** in `.cursorrules` / `cursorrules.template`.

## [0.1.0] - 2026-05-19

First public-ready cut of Agent OS as a portable framework.

### Added
- **`project-bootstrap`** skill plus `templates/bootstrap.sh` + `templates/work/` skeleton (one-command adoption into any repo).
- **`skills/SKILL_DEPENDENCIES.md`** registry: explicit prerequisite gates between skills (foundation → certify → master plan → status → implementation).
- **Prerequisite-gate enforcement** in `plan-foundation`, `plan-master`, `code-implementation`, `session-control` - agents now **stop** with a redirect if an upstream step was skipped.
- **README bird's-eye flow** (`@project-bootstrap init` → … → `@code-implementation continue`) and "Skills at a glance" table covering all 11 skills.
- **Standards templates** (`20260517-CONVENTIONS`, `FEATURE_STANDARD`, `DIRECTORY_MAP`, `observability-spec`, `api-style-guide`, `threat-model`, `data-classification`) generalized with `REPLACE:` tokens.
- **Demo `.work/` skeleton** at repo root so pointer links resolve when Agent OS is the git root.

### Changed
- Skill/router invocation syntax standardized to hyphen (e.g. `@feature-spec create - <slug>`) instead of em dash.
- Workflow guides under `docs/guides/workflows/` generalized; vendor specifics removed.

### Removed
- All project-specific integration artifacts under `docs/integration/` (Costa Rica Hacienda, OIDC, XAdES bundles) - replaced with agnostic `MANIFEST.template.txt` + `README.md`.

[Unreleased]: https://github.com/PiloTracer/.ai/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/PiloTracer/.ai/releases/tag/v0.2.0
[0.1.0]: https://github.com/PiloTracer/.ai/releases/tag/v0.1.0
