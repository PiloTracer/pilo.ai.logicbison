# Error decisions

An expected miss is a value. A broken operation is an error. A broken invariant is the only panic.

**Status:** Binding when the selector loads this card · 2026-11-18; Java 2026-11-19
**Needs:** nothing beyond the selector. Consumer CONVENTIONS win.

## Python

- **ERR-PY1.** Catch a specific exception. No bare `except`.
- **ERR-PY2.** Expected absence is a return value. An exception means the operation failed.
- **ERR-PY3.** A resource acquired here is released with `with`.

## Go

- **ERR-GO1.** Check every error. Wrap with `fmt.Errorf("…: %w", err)`. Lowercase text, no trailing punctuation.
- **ERR-GO2.** `panic` is a broken invariant, not a failed request.
- **ERR-GO3.** Do not drop an error with `_` unless the task notes name why that call cannot fail.

## Rust

- **ERR-RS1.** A fallible function returns `Result` and uses `?`.
- **ERR-RS2.** `unwrap` outside tests needs a comment that names the invariant. Examples use `?`, not `unwrap` (C-QUESTION-MARK).
- **ERR-RS3.** Libraries use `thiserror`. Application binaries may use `anyhow`.

## TypeScript

- **ERR-TS1.** Expected failure on a public function is a discriminated union. `throw` is a broken invariant.
- **ERR-TS2.** `catch` binds `unknown`. Narrow it before reading a property.
- **ERR-TS3.** `strict` stays on. `any` is not how an error is silenced.

## Java

- **ERR-JV1.** Catch the exception type that failed. A `catch (Exception)` or `catch (Throwable)` only at a process boundary, and the task notes say why.
- **ERR-JV2.** Expected absence on a return is an empty `Optional` or an empty collection. An exception means the operation failed. `Optional` is a return type, never a field, and never null itself.
- **ERR-JV3.** A resource acquired here is released with try-with-resources. A `finally` close is only when the type is not `AutoCloseable`.

## Example

Go, `ERR-GO1`. The failure is checked and wrapped. A request does not panic. Other languages follow their own section in this same shape.

```go
func Read(path string) ([]byte, error) {
    b, err := os.ReadFile(path)
    if err != nil {
        return nil, fmt.Errorf("read %s: %w", path, err)
    }
    return b, nil
}
```

## Verify

The project type checker and tests. Add one test for the failure path this task introduced. A swallowed error fails the task.

## Ledger

Mechanics checked 2026-11-18 against `20261118-SOURCES.md`. Java `ERR-JV1`–`ERR-JV3` checked 2026-11-19 (HTTP 200). Paired task: `unmeasured`.
