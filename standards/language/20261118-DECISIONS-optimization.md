# Optimization decisions

Read this card only when the selector's speed signal matches. Parallelism is a choice with a bound and a shutdown.

**Status:** Binding when the selector loads this card · 2026-11-18
**Needs:** A number tagged `measured` before anyone calls the change faster. Consumer CONVENTIONS win.

## Decide

- **O1.** State the workload (`waiting`, `computing`, `mixed`, `unknown`) before editing. `unknown`: measure or ask. The language is already chosen.
- **O2.** "Faster" requires a before and after number tagged `measured`. Otherwise write `assumption`.
- **O3.** Change the algorithm or the I/O pattern before micro-optimizing. Reason: a tighter inner loop does not fix an unbounded fan-out.
- **O4.** A pool, a cache, and a worker set have a bound and a shutdown path.
- **O5.** Profile with the tool the language already ships. Python: `cProfile`. Go: `go tool pprof`. Rust: the project's bench or `cargo bench`. Node: `node --prof`. Do not add a profiler dependency in the same change.

The concurrency card decides threads, processes, or async. This card decides whether a speed change is allowed to land. It does not choose the language.

## Avoid

A claim with no baseline. Parallelism as the default. A cache with no bound. A new dependency whose only job is to make a benchmark look real.

## Verify

The profile or benchmark command from O5, pasted into the task notes with the two numbers and the tag `measured`. The language card's tests still run.

## Example

`O2` and `O3`. The notes record the measurement. The code removes the repeated query. No worker pool.

```text
measured: GET /search p99 800 ms -> 90 ms after one query for the page.
```

```python
def search(db: Db, term: str) -> list[Row]:
    return db.query("select * from items where name like ?", f"%{term}%")
```

## Ledger

| Rules | Source | Paired task |
|-------|--------|-------------|
| O1–O4 | this card's if/then | `unmeasured` |
| O5 | `source-checked` for `cProfile`, `go tool pprof`, and `node --prof` in `20261118-SOURCES.md`. No Rust profiler page is indexed. | `unmeasured` |
