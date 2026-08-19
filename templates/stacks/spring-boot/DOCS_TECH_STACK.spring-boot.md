# Technology stack fragment — Spring Boot

Merge into `DOCS_TECH_STACK.md` (from `templates/DOCS_TECH_STACK.md.template`). Fills §1 table rows and §3 command rows for `p2-backend = java-spring-boot`.

---

## 1. Summary (rows)

| Layer | Choice | Version (pin) | Notes |
|-------|--------|---------------|-------|
| Language (primary) | Java | 21 (LTS) | records, sealed types ok |
| HTTP API | Spring Boot (Spring Web MVC) | 3.x | synchronous MVC; no WebFlux mixing |
| Database | PostgreSQL | 16 | idempotent SQL migrations per `@db-migration` |
| Cache / queue | none yet | - | add via ADR when introduced |
| Frontend | none yet | - | n/a for basic pack |
| Auth | Spring Security | per Boot 3.x | configure in SPEC when needed |
| Hosting | Docker (compose dev) | - | see `Dockerfile.spring-boot` |

Build: **Maven wrapper** (`./mvnw`). Gradle (`./gradlew`) is a noted variant - pick one.

---

## 2. Repository layout (rows)

| Path | Purpose |
|------|---------|
| `backend/` | Application source (`src/main/java/com/<group>/…`) |
| `backend/src/main/resources/db/migration/` | Idempotent SQL migrations |

---

## 3. Local development (rows)

| Item | Value |
|------|-------|
| Dev stack script | `bin/start.sh` |
| Compose file | `docker-compose.yml` |
| Test command | `./mvnw test` |
| Lint | `./mvnw -q spotless:check` |
| Type check | n/a (javac via build) |
