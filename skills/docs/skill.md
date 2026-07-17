---
name: docs
description: >-
  Create and manage project documentation: guides, tutorials, reference docs,
  and feature documentation. Routes documentation requests to the correct
  template and path under .work/docs/. Use when the user says docs, guide,
  tutorial, write docs, or documentation.
---

# docs

Create and manage human-readable project documentation under `{DOCS_ROOT}` (`.work/docs/`). Does **not** replace `@feature-spec` — formal SPECs live in `.work/features/` per FEATURE_STANDARD. This skill owns prose documentation for human readers.

**Canonical path:** `.ai/skills/docs/skill.md`
**Artifact root:** `.work/docs/`

**Pairs with:** `feature-spec` (feature docs may reference/derive from SPECs), `session-control` (handoff notes may link to docs).

**Hard rules:**
- Never write formal SPECs — route to `@feature-spec`.
- Never edit archived or Approved SPECs — route to `@feature-spec amend`.
- One file per doc; output naming `YYYYMMDD-<slug>.md` (substitute the real kebab-case slug).
- Template files on disk use literal `slug` (never `<>` in repo paths): `YYYYMMDD-slug.md.template`.
- Keep docs git-friendly — one sentence per line when possible.

---

## Parse invocation

| User says | Mode |
|-----------|------|
| `@docs` **create guide** - \<slug\> | Create a how-to guide |
| `@docs` **create tutorial** - \<slug\> | Create a tutorial |
| `@docs` **create reference** - \<slug\> | Create reference docs |
| `@docs` **status** | List all docs with paths |

**Aliases:** `guide` → `create guide`, `tutorial` → `create tutorial`, `reference` → `create reference`.

**Default:** `status` if no verb matches.

---

## Create guide protocol

### G1 - Derive slug

If text after `-` is not a valid kebab-case slug, derive one from the free-text purpose (e.g. "how to deploy the app" → `deploy-app`). State and proceed unless user objects.

### G2 - Brownfield check

If any `.work/docs/guides/YYYYMMDD-<slug>.md` already exists for that slug → **stop** with blocked report:
- **Required:** no dated guide for this slug
- **Detected:** existing file at path
- **Run first:** `@docs create guide - <different-slug>` or delete the existing file if stale

### G3 - Create

1. Read template from `.ai/templates/work/docs/guides/YYYYMMDD-slug.md.template` (self-hosted: `templates/work/docs/guides/YYYYMMDD-slug.md.template`).
2. Write to `.work/docs/guides/YYYYMMDD-<slug>.md` with filled sections (`YYYYMMDD` = today; `<slug>` = kebab-case slug).
3. If user gave a free-text purpose, populate the goal section from it.

### G4 - Report

```markdown
## @docs create guide - <slug>

**Path:** `.work/docs/guides/YYYYMMDD-<slug>.md`
**Template:** `templates/work/docs/guides/YYYYMMDD-slug.md.template`
**Status:** created
```

---

## Create tutorial protocol

Same as guide protocol but:
- **Template:** `.ai/templates/work/docs/tutorials/YYYYMMDD-slug.md.template`
- **Output:** `.work/docs/tutorials/YYYYMMDD-<slug>.md`

---

## Create reference protocol

Same as guide protocol but:
- **Template:** `.ai/templates/work/docs/reference/YYYYMMDD-slug.md.template`
- **Output:** `.work/docs/reference/YYYYMMDD-<slug>.md`

---

## Status protocol

Read-only. List all files under `.work/docs/` grouped by subdirectory. Report counts per type.

---

## Integration

| Skill / doc | When |
|-------------|------|
| `@ai-director` docs bucket | Free-text docs requests route here |
| `@feature-spec document` | Brownfield feature docs (writes to `.work/docs/features/`) |
| `.work/docs/README.md` | Navigation for all docs |

---

## Completion checklist

| # | Check | Result |
|---|-------|--------|
| 1 | Valid slug | pass |
| 2 | No brownfield collision | pass/fail |
| 3 | File created at correct path | pass |
| 4 | Template sections filled | pass |
