# `.cursorrules` values — Spring Boot

Fill the stack-relevant `REPLACE:` tokens (see `.cursorrules` § Placeholder map) with these values when `p2-backend = java-spring-boot`.

| Token | Value |
|-------|-------|
| `REPLACE:APP_ROOT` | `backend/` |
| `REPLACE:APP_WORKDIR` | `/app` |
| `REPLACE:APP_ENTRYPOINT` | `backend/src/main/java/<group>/<App>Application.java` |
| `REPLACE:PLATFORM_PACKAGE` | `com.<group>.platform` |
| `REPLACE:MIGRATIONS_DIR` | `backend/src/main/resources/db/migration/` |
| `REPLACE:MIGRATION_RUNNER_PATH` | `backend/src/main/java/com/<group>/platform/migration/MigrationRunner.java` |
| `REPLACE:MIGRATION_RUN_CMD` | `./mvnw spring-boot:run` (migrations run at app start, before the web server accepts traffic) |
| `REPLACE:TEST_COMMAND` | `./mvnw test` |
| `REPLACE:LINT_COMMAND` | `./mvnw -q spotless:check` |
| `REPLACE:TYPECHECK_COMMAND` | n/a (javac via build) |
| `REPLACE:DEV_STACK_SCRIPT` | `bin/start.sh` (per `@dev-stack`) |
| `REPLACE:SCRIPTS_DIR` | `scripts/` |
| `REPLACE:SERVICE_API` | `api` |
| `REPLACE:SERVICE_DB` | `db` |
| `REPLACE:SERVICE_FRONTEND` | n/a (no frontend in the basic pack) |
| `REPLACE:FRONTEND_ROOT` | n/a |
| `REPLACE:FRONTEND_WORKDIR` | n/a |
| `REPLACE:FRONTEND_CONFIG_PATHS` | n/a |
| `REPLACE:STACK_SUFFIX_VAR` | `STACK_SUFFIX` |

Notes:

- **Migrations:** plain idempotent numbered SQL under `REPLACE:MIGRATIONS_DIR` per `@db-migration`. **Flyway is out of scope** for this basic pack; adopting Flyway (or Liquibase) later is a documented variant - record it in an ADR and update `MIGRATION_RUNNER_PATH` / `MIGRATION_RUN_CMD` then.
- **Runner:** the pack ships no runner code. Implement `MigrationRunner` as a Spring `ApplicationRunner` (or `@PostConstruct` in a config bean) that executes the numbered `.sql` scripts alphanumerically at startup; `MIGRATION_RUN_CMD` is whatever starts the app (locally `./mvnw spring-boot:run`, in compose the `api` service start).
- **Lint alternative:** Checkstyle (`./mvnw -q checkstyle:check`) is acceptable instead of Spotless - configure one, not both.
- **FRONTEND_*:** leave as `n/a` unless a frontend is added; fill per the frontend stack pack when one exists.
