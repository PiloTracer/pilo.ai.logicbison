# Code conventions — Spring Boot (fragment)

Merge into `.work/standards/YYYYMMDD-CONVENTIONS.md`. Applies when `p2-backend = java-spring-boot`.

---

## Language and framework

- **Java 21 (LTS)**. Use records for immutable carriers, sealed types where they model a closed domain, `var` sparingly (never when it hides a type at an API boundary).
- **Spring Boot 3.x**, Spring Web MVC (synchronous). Do not mix WebFlux into the same service.
- Build with the **Maven wrapper** (`./mvnw`); Gradle is an acceptable variant - pick one, do not mix.

## Modularity (package-by-feature)

- Organize by **bounded context / feature**, not by technical layer at the top level: `com.<group>.<feature>.{api,application,domain,persistence}`.
- **Layered inside each context:** `api` (controllers, DTOs) → `application` (use cases, orchestration) → `domain` (entities, rules, pure) → `persistence` (repositories, JPA). Dependencies point inward; `domain` never imports Spring Web or JPA annotations.
- **No global grab-bag.** Shared code must earn a place in an explicitly named shared kernel package; a `util/` or `common/` dump is a defect (same spirit as `.cursorrules` § Database & Schema Rules: register tables in the bounded context's persistence module).
- **Enforce boundaries mechanically:** ArchUnit tests (package rules) or Spring Modulith (module verification at runtime) - consistent with concepts MOD-01 (coupling-audit) and MOD-05 (modularity-vs-distribution).

## Dependency injection

- **Constructor injection only.** Never `@Autowired` on fields, never field injection of any kind. `final` fields, one constructor (Lombok `@RequiredArgsConstructor` acceptable).

## API boundary

- **DTOs at the boundary.** Controllers accept and return request/response DTOs, never JPA entities. Map explicitly (MapStruct or hand-written mappers).
- Bean Validation (`@Valid` + constraints) on request DTOs; errors mapped via `@RestControllerAdvice` to the project's error shape.

## Persistence

- PostgreSQL via Spring Data JPA (or jOOQ if the project prefers SQL-first - one choice per repo).
- Schema changes are **idempotent numbered SQL scripts** under `REPLACE:MIGRATIONS_DIR` per `@db-migration`; the basic pack does not use Flyway.

## Tests

- **JUnit 5** everywhere. Unit tests for `domain`/`application` without Spring context.
- **Testcontainers** (PostgreSQL) for persistence and controller integration tests - never an in-memory stand-in for schema-sensitive behavior.
- Naming: `<Class>Test` (unit), `<Class>IT` (Testcontainers integration).

## Formatting / lint

- `./mvnw -q spotless:check` (google-java-format) is the default gate; Checkstyle is an acceptable alternative - configure one, wire it into `REPLACE:LINT_COMMAND`.
