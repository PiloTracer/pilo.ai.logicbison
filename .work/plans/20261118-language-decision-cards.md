# Language decision cards

Prescription from `.work/feedback/improve-language-strategy/general.md`. Phases 0–2 are in the tree. Phase 3's keep/drop procedure is in the selector. The paired runs are `unmeasured`.

**Status:** Approved · 2026-11-18
**Needs:** scratch-consumer paired tasks before any rule is deleted.
**Task ref:** AIOS-1

## Verdict

Use the note. Decision rules, the reason for each rule, anti-patterns, dated facts, and verify commands change what the model picks. Textbook explanations of decorators, generators, closures, or the GIL do not (`.work/feedback/improve-language-strategy/general.md:L19`).

Agent OS already has the half that matters more than a guide: tests, lint, and types on every task (`skills/code-implementation/reference.md:L646`), a five-prompt self-critique (`skills/code-implementation/reference.md:L666`), and an AI-diff review (MOD-06 "AI change risk review" — `concepts/ai-amplification/prompt.md:L19`). It has no language decision card. A search of `concepts/` and `skills/` finds no asyncio, goroutine, GIL, clippy, or tokio rule.

Do not add a skill per language. The v0.7 draft already classifies app-stack guidance as a template pack, not a skill (`.work/plans/20260819-v07-tech-expansion-draft-plan.md:L52`). Today's playbook intake rejected a TypeScript layout and universal named tools (`.work/plans/20261118-coding-playbook-intake.md:L46`). Universal `standards/20260517-CONVENTIONS.md:L12` stays language-agnostic. MOD-09 "release pipeline" is already named (`.work/plans/20260819-v07-tech-expansion-draft-plan.md:L95`) and is not this work.

Consumer project bans (versions, libraries) stay in that repo's `.work/standards/`. A card is the default only while the consumer row is still a `REPLACE:` token. The consumer file wins when they conflict.

## What to adopt

Four phases. Stop after any phase whose paired task does not change the result (`.work/feedback/improve-language-strategy/general.md:L110`).

### Phase 0 — decision before code

Smallest change. Highest chance of a better concurrency choice.

When a task says concurrent, parallel, faster, optimize, scale, or async, `code-implementation` states three lines before the first edit:

1. Workload class: waiting, computing, or unknown.
2. Model chosen, and the reason.
3. What would make that choice wrong.

Unknown workload: ask or measure. Do not pick a model to look modern (`.work/feedback/improve-language-strategy/general.md:L44`).

No new file. One paragraph in `skills/code-implementation/skill.md` per-task loop (`skills/code-implementation/skill.md:L215`).

### Phase 1 — one-page cards

Create these templates. Each card is one page: default, if/then with the reason, anti-patterns, a dated fact, verify commands, one good-output sketch. No concept essays.

| File | Covers |
|------|--------|
| `standards/language/20261118-DECISIONS-python.md` | CPython concurrency and public types |
| `standards/language/20261118-DECISIONS-go.md` | Goroutines, cancellation, errors |
| `standards/language/20261118-DECISIONS-rust.md` | Ownership, errors, async vs threads |
| `standards/language/20261118-DECISIONS-typescript.md` | Node and browser JS runtime, plus TS public types |
| `standards/language/20261118-DECISIONS-optimization.md` | Measurement rule shared by all five |

Superseded 2026-11-18: the four per-language files are gone. The tree holds six topic cards (collections, errors, statements, patterns, concurrency, optimization). Optimization stayed.

JavaScript does not get a second card. Untyped JS uses the TypeScript card's runtime section and records type-check as a documented baseline exception (`standards/20260517-CONVENTIONS.md:L22`).

Ship cards without full stack packs. Go and Rust have no `templates/stacks/` directory today. Only `templates/stacks/spring-boot/` exists. A decision card is not a Dockerfile. Later packs link the card the way Spring Boot merges conventions (`templates/stacks/spring-boot/README.md:L24`).

#### Python rules to put on the card

- Waiting, small fan-out: `ThreadPoolExecutor`. It works with blocking libraries.
- Waiting, hundreds of connections, async libraries already in the tree: `asyncio`. Never call blocking code inside `async def`; use `asyncio.to_thread`. Reason: a blocking call stalls every other task on the loop.
- Pure-Python CPU: `ProcessPoolExecutor`. Batch work so pickle cost stays smaller than the compute. Reason: threads do not speed up pure Python while the GIL is on.
- NumPy / hashlib-style C work that releases the GIL: threads may be enough. State that assumption in the answer.
- Free-threaded build: only when the project pins the free-threaded binary, dependencies support it, and a runtime check shows the GIL is off. As of the Python 3.15.2 howto, free-threading is a separate build (`--disable-gil`), `sys._is_gil_enabled()` reports the running process, and an incompatible C extension can turn the GIL back on (`https://docs.python.org/3/howto/free-threading-python.html`, checked 2026-11-18). Tag: `measured` for that howto; `unknown` for the next release. Re-read the howto when the card is written. Do not treat "macOS installs free-threading support" as "the default `python` binary has no GIL".
- Shared mutation needs a `Lock` or a `Queue`. The GIL does not make `x += 1` safe.
- One pool for the process, with a timeout and a shutdown. Do not create a pool per call.
- Public functions get type hints. Verify with `ruff`, a type checker, and a pytest that runs N workers. Any "faster" claim needs a before/after number tagged `measured`.

#### Go rules to put on the card

- Every goroutine has a stop path via `context.Context`. Reason: a goroutine with no cancel leaks for the process lifetime.
- Channels move ownership. A mutex guards state. Use the mutex when a channel is more machinery.
- Return `fmt.Errorf("…: %w", err)`. Do not ignore an error.
- Bound fan-out (`errgroup` with a limit, or a fixed worker pool). State the bound.
- Verify: `go vet`, `go test -race ./...`, `golangci-lint run`.

#### Rust rules to put on the card

- Borrow first. Each `clone()` gets a one-line reason. Reason: clone hides an ownership design the next edit will copy.
- Libraries: `Result` and `?`, no `unwrap()` outside tests, `thiserror`. Applications: `anyhow`.
- CPU: threads and channels. Async I/O: `tokio`. Blocking work inside async goes through `spawn_blocking`. Reason: a blocking call stalls the runtime.
- Verify: `cargo clippy -- -D warnings`, `cargo test`, `cargo fmt --check`. A speed claim needs a benchmark command, not an adjective.
- `skills/tauri-development/skill.md:L29` stays an IPC security skill. It is not this card.

#### TypeScript and JavaScript rules to put on the card

- I/O uses `async`/`await`. Cancellation uses `AbortSignal` (same job as Go's `context.Context`).
- Do not block the event loop: no sync filesystem calls on a request path, no large CPU loop, no unbounded `Promise.all`.
- CPU work uses a bounded pool: `worker_threads` on Node, Web Workers in the browser. Name which runtime.
- Shared memory across workers needs an explicit reason.
- TypeScript public boundaries: `strict`, no `any`, a discriminated union for errors.
- Verify: `tsc --noEmit` when the project is TypeScript, the project's linter, and tests. A speed claim needs a before/after timing tagged `measured`.
- Module shape stays in the consumer conventions. Do not add `src/features/*/index.ts` here (rejected in `.work/plans/20261118-coding-playbook-intake.md:L46`).

#### Optimization card (all five languages)

Read this card only when the task asks for speed or scale.

- State the workload class before code.
- "Optimized" requires a before/after number tagged `measured`. Otherwise write `assumption`.
- Change the algorithm or the I/O pattern before micro-optimizing.
- Parallelism is a choice with a bound and a shutdown, not a default.
- Cache and pool lifetimes are explicit.

Maintainability stays where it already lives: small tasks, blast radius, MOD-01 "coupling audit" (`concepts/coupling-audit/prompt.md`), MOD-06. Cards add local idioms only. They do not replace module boundaries.

### Phase 2 — load the card, then check it

Wire only after Phase 1 exists.

1. Load a language card only when Phase 0's trigger fired and the files under edit are in that language. Do not inject all five cards into `.cursorrules`. That fights the token budget (`.cursorrules` Core Principle 9; `.work/plans/20261118-coding-playbook-intake.md:L54`).
2. Add one self-critique row, asked only when a card was loaded: which shared mutable state, blocking call inside async, or unbounded fan-out did this diff add? (`skills/code-implementation/reference.md:L670`).
3. If the card's verify command is not already `REPLACE:TEST_COMMAND` / `REPLACE:LINT_COMMAND` / `REPLACE:TYPECHECK_COMMAND`, run it as an extra task-gate check for that language. Paste the output. A gate that did not run is not a pass.

### Phase 3 — keep or delete each rule

In a scratch consumer, not this repo, run two tasks per language (one waiting workload, one computing workload), with the card and without it. Keep a rule only if the with-card run picks the right model or passes the race/lint/type gate on the first try. Delete the rest. Record the pair result in the card's changelog. `assumption`: this has not been run.

## Reject

| Proposal | Why |
|----------|-----|
| Essays on decorators, generators, closures, the GIL | The model already knows them (`.work/feedback/improve-language-strategy/general.md:L19`) |
| A skill per language | Anti-bloat (`.work/plans/20260819-v07-tech-expansion-draft-plan.md:L52`) |
| An always-on language playbook in `.cursorrules` | Token budget; duplicates the task gate |
| Language rules inside universal `CONVENTIONS` | That file is a placeholder table (`standards/20260517-CONVENTIONS.md:L12`) |
| Project library bans inside the framework | Consumer `.work/standards/` owns them |
| Reusing MOD-09 for this | MOD-09 is the release-pipeline concept |
| Full Go/Rust/Node Docker packs in the same change | Out of scope for a one-page decision card |
| Editing the framework in the session that wrote this file | Operator asked for a prescription only |

## Files when a later message says yes

Phase 0 modifies `skills/code-implementation/skill.md` only.

Phase 1 creates the five files in the table above. No skill, no `.cursorrules` edit.

Phase 2 modifies `skills/code-implementation/skill.md` and `skills/code-implementation/reference.md`. Protected `.cursorrules` stays untouched unless the load trigger cannot live in the skill. That edit needs its own same-message yes (`.cursorrules` Core Principle 8).

## Risks

- A dated fact (free-threaded Python) will go stale. The card header carries the date and tells the agent to re-read the official howto before relying on it.
- A card can contradict a consumer convention. The consumer `.work/standards/` file wins.
- Loading cards on every task spends the token budget for no gain. Phase 2's trigger is the guard.
- `assumption`: Phase 0 alone may capture most of the gain. If the paired task shows that, skip Phase 1.

## Rollback

Revert the doc commit that adds the cards and the skill paragraph. No runtime behavior exists until a consumer loads a card.

## Source list

Canonical copy, with the HTTP check and the rule each page supports: `standards/language/20261118-SOURCES.md`. Checked 2026-11-18. Full page copies stay in a consumer `.work/docs/integration/` manifest when a task must quote the page.

- https://docs.python.org/3/howto/free-threading-python.html
- https://docs.python.org/3/library/asyncio-task.html
- https://docs.python.org/3/library/concurrent.futures.html
- https://docs.python.org/3/library/profile.html
- https://go.dev/wiki/CodeReviewComments#goroutine-lifetimes
- https://go.dev/wiki/CodeReviewComments#synchronous-functions
- https://go.dev/wiki/CodeReviewComments#contexts
- https://pkg.go.dev/fmt#Errorf
- https://go.dev/doc/articles/race_detector
- https://go.dev/blog/pprof
- https://rust-lang.github.io/api-guidelines/documentation.html#c-question-mark
- https://rust-lang.github.io/api-guidelines/checklist.html
- https://docs.rs/tokio/latest/tokio/task/fn.spawn_blocking.html
- https://doc.rust-lang.org/clippy/
- https://nodejs.org/learn/asynchronous-work/dont-block-the-event-loop
- https://nodejs.org/api/worker_threads.html
- https://nodejs.org/api/globals.html#class-abortsignal
- https://www.typescriptlang.org/tsconfig/strict.html
- https://nodejs.org/learn/getting-started/profiling

## Implementation

| Phase | Where | State |
|-------|--------|--------|
| 0 | `skills/code-implementation/skill.md` topic selector | in tree |
| 1 | Six topic cards under `standards/language/20261118-DECISIONS-*.md` | in tree |
| 2 | `skills/code-implementation/reference.md` task-gate row and SC1 row 6 | in tree |
| 3 | Keep/drop steps in `standards/language/README.md` | procedure in tree; paired runs `unmeasured` |

Revised 2026-11-18 after the operator said the first cut was only parallelism. The selector no longer asks for a runtime. No recorded language stops the task and returns to `p2-backend`. `skills/plan-foundation/reference.md` states the cards are not evidence for that grill. Per-language concurrency files were replaced by the six topic cards. Go's synchronous default is `PAT-GO2`. Rust `ERR-RS2` cites C-QUESTION-MARK for examples, not a ban on every library `unwrap`.

## Decisions needed

none — approved in the same message as the edit, 2026-11-18.

## Open questions

none

## Next action

Next action: none — do not commit unless the operator asks in that message. Delete a rule only after a scratch-consumer pair changes the result.
