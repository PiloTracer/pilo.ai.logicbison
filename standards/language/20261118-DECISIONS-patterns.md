# Pattern decisions

The module that owns the invariant owns the type. Public surface stays small.

**Status:** Binding when the selector loads this card · 2026-11-18
**Needs:** nothing beyond the selector. Consumer CONVENTIONS win. This card does not set folder layout.

- **PAT-0.** No named pattern (Factory, Strategy, Observer, Singleton, Adapter, and the rest) unless this task has two real variants now. Name the pattern and the reason in the task notes. One implementation stays a function or a concrete type.

## Python

- **PAT-PY1.** A function when there is no state to keep. A class when several operations share a resource or mutable state.
- **PAT-PY2.** Type hints on public functions.
- **PAT-PY3.** Callers import the public function of the module that owns the type. They do not reach into a helper the module did not export.

## Go

- **PAT-GO1.** Return a concrete type. Put an interface in the package that uses it, and only once a real caller needs that seam. Do not declare an interface "for mocking" before it is used.
- **PAT-GO2.** The default API is synchronous. The caller adds a goroutine when the caller needs concurrency.
- **PAT-GO3.** The package that owns the invariant owns the type. Do not export fields the caller must keep consistent.

## Rust

- **PAT-RS1.** Fields that carry an invariant stay private to the owning module.
- **PAT-RS2.** The crate root re-exports what callers need. Do not mark every module public.
- **PAT-RS3.** A public signature carries `tokio` types only when the crate's job is async I/O.

## TypeScript

- **PAT-TS1.** Export the types that cross the module boundary. Leave the rest unexported.
- **PAT-TS2.** A function for a transform. A class when the value has a lifecycle: open, use, close.
- **PAT-TS3.** No `any` on an exported type. `unknown` plus a narrow is the escape.

## Example

Go, `PAT-GO1` and `PAT-GO2`. The API returns a concrete type and finishes before it returns. The caller adds a goroutine only when the caller needs one. Other languages follow their own section in this same shape.

```go
func Fetch(ctx context.Context, url string) (Body, error) {
    req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
    if err != nil {
        return Body{}, fmt.Errorf("fetch %s: %w", url, err)
    }
    res, err := http.DefaultClient.Do(req)
    if err != nil {
        return Body{}, fmt.Errorf("fetch %s: %w", url, err)
    }
    defer res.Body.Close()
    b, err := io.ReadAll(res.Body)
    if err != nil {
        return Body{}, fmt.Errorf("fetch %s: %w", url, err)
    }
    return Body{Bytes: b}, nil
}
```

## Verify

The project type checker or compiler on the touched packages. A new exported type has a test through its public function, not through a private field.

## Ledger

`PAT-GO1` matches the Go Code Review Comments on interfaces (`20261118-SOURCES.md`). Paired task: `unmeasured`.
