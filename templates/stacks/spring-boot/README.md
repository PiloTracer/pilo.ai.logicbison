# Spring Boot stack pack

**Status:** Basic support. Java 21 + Spring Boot 3.x + PostgreSQL, Maven wrapper build.

Stack **fragments** for consumer repos whose backend is Spring Boot. This is not a generator and ships no runnable application code - it supplies filled-in conventions, tech-stack rows, a Dockerfile, a compose fragment, and the `.cursorrules` placeholder values so `@project-bootstrap` output can be completed by copy-paste instead of invention.

## When to use it

- After `@project-bootstrap init` (or `@deploy-basic`) has scaffolded `.cursorrules` + `DOCS_TECH_STACK.md`, and
- `@plan-foundation` answered `p2-backend = java-spring-boot` (see `skills/plan-foundation/reference.md` § INTERACTION: p2-backend).

## How to apply

1. Copy the fragments you need into the consumer repo (never wholesale-replace existing files):
   - `CONVENTIONS.spring-boot.md` → merge into the project's `.work/standards/YYYYMMDD-CONVENTIONS.md`.
   - `DOCS_TECH_STACK.spring-boot.md` → merge into `DOCS_TECH_STACK.md` §1 and §3 rows.
   - `Dockerfile.spring-boot` → `Dockerfile` (or `backend/Dockerfile`) at the app root.
   - `docker-compose.spring-boot.yml` → merge into the project's `docker-compose.yml`.
2. Fill the stack-relevant `REPLACE:` tokens in `.cursorrules` from [`CURSORRULES_VALUES.md`](CURSORRULES_VALUES.md).
3. Run `@db-migration init` against `backend/src/main/resources/db/migration/` (Flyway is out of scope for this basic pack - see CURSORRULES_VALUES.md).
4. Generate the dev-stack script with `@dev-stack init`.

## Files

| File | Merges into |
|------|-------------|
| `CONVENTIONS.spring-boot.md` | `.work/standards/*-CONVENTIONS.md` |
| `DOCS_TECH_STACK.spring-boot.md` | `DOCS_TECH_STACK.md` |
| `Dockerfile.spring-boot` | `Dockerfile` |
| `docker-compose.spring-boot.yml` | `docker-compose.yml` |
| `CURSORRULES_VALUES.md` | `.cursorrules` `REPLACE:` tokens |

## Next action

`@project-bootstrap init` (if not already run), then apply this pack per the steps above.
