# Technology stack — Agent OS (framework)

**Status:** Active — self-hosted framework repo. Linked from `.cursorrules` as `DOCS_TECH_STACK.md`.

**Updated:** 2026-07-04

---

## 1. Summary

| Layer | Choice | Version (pin) | Notes |
|-------|--------|---------------|-------|
| Language (primary) | Bash, Python 3 | 3.x | Shell verifiers + skill-functional-verify |
| Framework | Agent OS | self-hosted | Skills, standards, scripts at repo root |
| CI | GitHub Actions | ubuntu-latest | `framework-verify.yml` |
| Hosting | Git (clone from origin) | — | out-of-band; no deploy skill (deploy-repo removed 2026-08-14) |

---

## 2. Repository layout

| Path | Purpose |
|------|---------|
| `skills/` | Agent skills (`skill.md` per folder) |
| `standards/` | Framework template standards + `PROTECTED_SURFACES.json` |
| `.work/standards/` | Project binding standards (generated) |
| `.work/docs/integration/` | Vendor integration cache |
| `scripts/` | Deploy, verify, hooks |
| `templates/` | Bootstrap artifacts for consumer repos |
| `concepts/` | MOD-01…MOD-07 architecture prompts |
| `.work/` | Plans, HANDOFF, `touch-scope` |

See `.work/standards/*-DIRECTORY_MAP.md` after customization (framework templates: `standards/20260517-DIRECTORY_MAP.md`).

---

## 3. Local development

| Item | Value |
|------|-------|
| Dev stack script | *(none — host POSIX shell)* |
| Test command | `bash scripts/framework-verify.sh` |
| Lint | `python3 scripts/skill-functional-verify.py` |
| Scope check | `bash scripts/touch-scope-verify.sh` |
| Blast radius | `bash scripts/blast-radius-check.sh` |
| Type check | *(n/a)* |

**Before commit (AI-assisted sessions):** run test + scope + blast-radius on dirty tree; attach MOD-06 output when application/framework code changed.

---

## 4. CI/CD

| Item | Status |
|------|--------|
| Platform | GitHub Actions |
| Workflow | `.github/workflows/framework-verify.yml` |
| Release gate | `bash scripts/release.sh <version>` |

---

## 5. Open decisions (track in `.work/plans/UNKNOWNS.md`)

| ID | Topic | Owner |
|----|-------|-------|
| — | *(none)* | |

---

## 6. ADR cross-reference

Decisions live in `.work/decisions/`. This file holds **pins** only; rationale belongs in ADRs.
