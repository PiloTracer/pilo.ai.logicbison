# Language topic selector

The language is already chosen. A card says how to write that language. It is not a reason to pick one.

**Status:** Binding when a topic signal matches · 2026-11-18
**Needs:** Paired keep/drop runs remain `unmeasured`.

Consumer `.work/standards/*CONVENTIONS*` wins on conflict. A new synchronous network hop still runs MOD-02 (`concepts/network-cost/prompt.md`).

## Language

Read the section for the language already on the task. Take it from the file suffix, or from the recorded stack (`p2-backend` in the stack ADR or `DOCS_TECH_STACK`).

| Suffix | Section |
|--------|---------|
| `.py` | Python |
| `.go` | Go |
| `.rs` | Rust |
| `.ts`, `.tsx`, `.js`, `.mjs`, `.cjs` | TypeScript |

Untyped JavaScript reads the TypeScript section and skips a rule that needs a type checker. Record that skip.

No suffix and no recorded stack: stop. Do not pick a runtime. The next command is `@plan-foundation` at `p2-backend` (`skills/plan-foundation/reference.md`). Parallelism, collections, and speed are not evidence for that grill.

## Topics

Load every card whose decision this task is actually making. There is no cap. A word in the task text is not enough.

For each row, ask: "Is this task choosing that?" Yes loads the card. No leaves it unloaded. A task that chooses three loads all three.

| The task is choosing… | Load | A passing mention does not count |
|-----------------------|------|----------------------------------|
| Which collection to store, copy, or stream | `20261118-DECISIONS-collections.md` | `map` as a verb, a field name, or a roadmap. `list` as a verb. |
| How a failure is reported, caught, wrapped, or ignored | `20261118-DECISIONS-errors.md` | `error` meaning "the bug", "fix the error", or an error-message string. `result` as a variable or a test result. |
| A generator, decorator, closure, comprehension, or the shape of a branch or loop | `20261118-DECISIONS-statements.md` | `loop` as "run the tests again". `branch` as a git branch. |
| The public surface of a module or type, or a named design pattern | `20261118-DECISIONS-patterns.md` | `public` as a word in a sentence. `interface` as a UI screen. `pattern` as a vague request to be clean. |
| How work runs in parallel or async | `20261118-DECISIONS-concurrency.md` | `worker` as a job title. `async` copied from a filename the task is not changing. |
| Whether a change is faster, and how that will be measured | `20261118-DECISIONS-optimization.md` | `scale` as team or company size. `slow` as a complaint with no request to change speed. |

A rename, a comment, or a bugfix that does not make one of those choices loads nothing.

## Before the first edit

Write three lines in the task `Notes`:

1. Language, and whether it came from a suffix or the recorded stack. If neither exists, stop.
2. Every card loaded, and the rule ids to follow. If none, write `no card — this task is not choosing a listed decision`.
3. Default kept, or the deviation and the reason.

When the concurrency card is loaded, also name the workload: `waiting`, `computing`, `mixed`, or `unknown`. `unknown`: ask or measure before writing that code.

Match the Example on each loaded card. Same shape, the language of this task.

## Verify

Run each loaded card's verify command when it is not already `REPLACE:TEST_COMMAND`, `REPLACE:LINT_COMMAND`, or `REPLACE:TYPECHECK_COMMAND`. If the tool is absent, record `skip - tool not in this repo` and the command. A skip is not a pass for a repo that claims that language.

## Keep or drop

Scratch consumer only. One task per topic, twice: card loaded, and card not loaded. Keep a rule only when the with-card run changes the choice or the first-pass verify result. A row marked `unmeasured` stays. This session did not run those pairs.

## Ledger

| Card | Mechanics check | Paired task |
|------|-----------------|-------------|
| Collections | 2026-11-18 | `unmeasured` |
| Errors | 2026-11-18 | `unmeasured` |
| Statements | 2026-11-18 | `unmeasured` |
| Patterns | 2026-11-18 | `unmeasured` |
| Concurrency | 2026-11-18 | `unmeasured` |
| Optimization | 2026-11-18 | `unmeasured` |
