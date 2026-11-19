# Statement decisions

Straight-line happy path. A language feature is a choice with a reason, not a decoration.

**Status:** Binding when the selector loads this card · 2026-11-18
**Needs:** nothing beyond the selector. Consumer CONVENTIONS win.

## Python

- **STM-PY1.** Return early. Do not nest the happy path under `else`.
- **STM-PY2.** A comprehension builds one collection with a single expression. A `for` loop is for a side effect or more than one statement.
- **STM-PY3.** A decorator wraps a named policy (auth, retry, timing). It does not hide a required argument.
- **STM-PY4.** A closure that must keep this iteration's value binds that value as a default argument. The loop variable is read when the closure runs.

## Go

- **STM-GO1.** Return on the error. The happy path stays at the left edge.
- **STM-GO2.** `defer` the release on the line after a successful acquire.
- **STM-GO3.** No `else` after a return.

## Rust

- **STM-RS1.** `?` on the error path. `match` when variants differ. `if let` for one variant.
- **STM-RS2.** An iterator chain for a pure transform. A `for` loop for a side effect. Do not collect only to loop.
- **STM-RS3.** Do not `clone` inside a match to dodge a borrow. Name the reason for a clone that stays.

## TypeScript

- **STM-TS1.** Return early. `async`/`await` instead of a nested callback for I/O that is already promised.
- **STM-TS2.** `const` by default. `let` when the binding changes. Do not use `var`.
- **STM-TS3.** Optional chaining when absence means skip. An explicit branch when absence is a different outcome.

## Example

Python, `STM-PY1` and `STM-PY4`. The success path returns immediately. The closure keeps the value from that pass. Other languages follow their own section in this same shape.

```python
def label(user: User | None) -> str:
    if user is None:
        return "guest"
    return user.name

handlers = [(lambda i=i: i) for i in range(3)]
```

## Verify

The project linter. A new branch or loop has a test for the early-exit path. A decorator or closure has a test that the captured value is the one the caller asked for.

## Ledger

`STM-PY4` matches the Python FAQ on lambdas in a loop (see `20261118-SOURCES.md`). Other if/then lines are this card. Paired task: `unmeasured`.
