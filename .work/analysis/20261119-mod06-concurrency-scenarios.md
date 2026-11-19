# MOD-06 — concurrency scenario rows (2026-11-19)

## AI change risk summary

- AI-assisted: yes
- Boundaries crossed: 2 — `standards/language`, `skills/code-implementation` (changelog line only outside those trees)
- New cross-boundary deps: none
- Test isolation: weak — this repo has no application runtime. The reversed-rule tests are specified on the cards for the consumer task that loads them. `bash scripts/touch-scope-verify.sh` and `bash scripts/blast-radius-check.sh` cover this diff.
- Human architectural review: optional — policy text. Java library claims cite pages checked HTTP 200 on 2026-11-19.
- Blast radius: an agent on a `.java` file now has a section for collections, errors, statements, patterns, concurrency, and a JDK profiler line for speed. A wrong row biases those choices until the ledger drops it. The database-pool sentence no longer grows with virtual-thread count. The skill forbids using any of these cards to choose Java. Agents that do not load a card are unchanged.

## Recommendation

merge_with_conditions — Java sections and the three situation rows are policy. Paired keep/drop runs did not happen.

## Conditions if merge_with_conditions

- Must add tests: the consumer task that loads a card adds the reversed-rule test that card names. No runtime test belongs in this repo.
- Must split PR: no
- Ledger stays `unmeasured` until a scratch consumer records a with-card and a without-card run.

Evidence: `assumption` on behavior change. `measured` on the HTTP 200 checks in `standards/language/20261118-SOURCES.md`, including the Java pages checked 2026-11-19.
