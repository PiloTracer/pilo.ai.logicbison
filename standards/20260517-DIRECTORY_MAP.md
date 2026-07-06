# Directory Map — template

**Status:** Customize for your repo, then treat as binding before first application code.
**Bootstrap:** Copy to project-root `standards/YYYYMMDD-DIRECTORY_MAP.md` (sibling of `.work/`, never under `.ai/`), replace `REPLACE:` tokens, align with foundation doc 04 and `.cursorrules`. (`@plan-foundation greenfield` P3 normally generates this directly — see [reference](../skills/plan-foundation/reference.md).)

---

## Repository roots

| Path | Purpose |
|------|---------|
| `.ai/` | **Agnostic:** skills, concepts, workflow guides, `START_HERE.md`, `PROCESS_ROUTER.md`, framework-wide standards contracts |
| `.work/` | **Project:** plans, SPECs, ADRs, prompts, session `HANDOFF.md` |
| `standards/` | **Project:** this repo's own binding engineering standards (generated, not vendored — this file's destination) |
| `docs/integration/` | Optional vendor mirror + `MANIFEST.txt` (see `docs/integration/README.md`) |
| `.work/plans/` | Foundation, full plan, registries, `NEXT.md` |
| `.work/features/<slug>/` | Feature SPECs per FEATURE_STANDARD |
| `.work/decisions/` | ADRs |
| `.work/context/` | `HANDOFF.md` |
| `.work/analysis/` | Generated investigation / audit markdown (gap analyses, session postmortems, parity reports) |
| `.work/scripts/` | Markdown runbooks for one-off operational scripts; code lives in application tree |
| `REPLACE:APP_ROOT/` | Primary application (backend, monolith, or service tree) |
| `REPLACE:FRONTEND_ROOT/` | Optional UI (if any) |
| `REPLACE:WORKER_ROOT/` | Optional async workers (if any) |
| `REPLACE:TECH_STACK_DOC` | Pinned stack versions |
| `.cursorrules` | Agent + engineering rules (repo root) |

---

## Application layout (example — adapt)

```
REPLACE:APP_ROOT/
├── pyproject.toml | package.json | go.mod   ← pick per stack
├── REPLACE:MIGRATIONS_DIR/
│   └── 001_init.sql                         ← numbered, idempotent
├── src/
│   ├── main.py | index.ts | …
│   ├── REPLACE:PLATFORM_PACKAGE/            ← shared cross-cutting code
│   └── <bounded-context>/                   ← one folder per domain module
│       ├── domain/
│       ├── application/
│       ├── infrastructure/
│       ├── http/                            ← if HTTP-facing
│       └── ports/
└── tests/
    ├── unit/
    ├── integration/
    └── contract/
```

**Dependency rule:** bounded contexts import only `REPLACE:PLATFORM_PACKAGE` and published `ports/` / `events/` from other contexts (see CONVENTIONS).

---

## Documentation map (read order)

| Task | Read first |
|------|------------|
| Any code change | `.cursorrules`, `.work/context/HANDOFF.md` |
| Layout | This file |
| Stack versions | `REPLACE:TECH_STACK_DOC` |
| Feature work | `.work/features/<slug>/*-SPEC.md` |
| API design | `standards/*-api-style-guide.md` (when present) |
| Security | data-classification + threat-model standards (when present) |
| External APIs | `.work/plans/foundation/*-02-*.md`, `docs/integration/MANIFEST.txt` |

---

## Gate

Foundation doc 04 should reference this map. Update it when adding a new top-level directory (ADR per FEATURE_STANDARD §9).

**Code-to-registry parity:** After material app-tree changes or brownfield adoption, run `@plan-verify coverage`. Unmapped routes/pages/controllers → `@plan-repair repair - from coverage` (SPEC **Implementation map**, not parallel `feature.yml` registries).
