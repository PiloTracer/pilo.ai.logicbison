# Concurrency decisions

Use this card only when the selector's concurrency signal matches. The language is already chosen. Spawn only after the patterns card's synchronous default was considered (`PAT-GO2` for Go; the same idea in the other sections).

**Status:** Binding when the selector loads this card · 2026-11-18
**Needs:** Re-read the free-threading howto before `CON-PY5`. Consumer CONVENTIONS win.

## Python

- **CON-PY1.** Waiting, small fan-out → one `ThreadPoolExecutor` for the process. Reason: blocking libraries keep working.
- **CON-PY2.** Waiting, hundreds of connections, and the tree already uses asyncio → `asyncio`. No blocking call inside `async def`; use `asyncio.to_thread`.
- **CON-PY3.** Pure-Python CPU → `ProcessPoolExecutor`, work batched. Threads do not speed that work while the GIL is held.
- **CON-PY4.** C code that releases the GIL may use threads. State that assumption.
- **CON-PY5.** A free-threaded build only when the project pins that binary, dependencies support it, and `sys._is_gil_enabled()` is false. A C extension can turn the GIL back on. Checked 2026-11-18. `unknown` for the next release.
- **CON-PY6.** Shared mutation uses a `Lock` or a `Queue`. The GIL does not make `x += 1` safe.
- **CON-PY7.** One pool, with a timeout and a shutdown. No pool per call.

## Go

- **CON-GO1.** A goroutine has an obvious exit. The garbage collector does not stop one blocked on a channel.
- **CON-GO2.** Pass `context.Context` as the first parameter of a request-scoped function. Do not store it on a struct.
- **CON-GO3.** A channel hands off ownership. A `sync.Mutex` guards a field. Do not copy a mutex.
- **CON-GO4.** Bound the fan-out and state the bound.

## Rust

- **CON-RS1.** CPU work uses threads and channels. Async I/O uses the runtime already in the tree. Blocking work on that runtime uses `spawn_blocking`.
- **CON-RS2.** Do not add `tokio` to a synchronous crate unless this task is async I/O and the three selector lines say so.

## TypeScript

- **CON-TS1.** I/O stays on `async`/`await`. Cancel with `AbortSignal`.
- **CON-TS2.** Do not block the event loop: no synchronous filesystem call on a request path, no large CPU loop, no unbounded `Promise.all`.
- **CON-TS3.** CPU work uses a bounded pool. Node: `worker_threads`. Browser: Web Workers. Name which runtime.

## Example

Python, `CON-PY1` and `CON-PY7`. Waiting work uses one pool for the process, with a shutdown. Other languages follow their own section in this same shape: a bound, and a way to stop.

```python
from concurrent.futures import ThreadPoolExecutor, wait

pool = ThreadPoolExecutor(max_workers=8)

def run(urls: list[str]) -> None:
    futures = [pool.submit(fetch, url) for url in urls]
    wait(futures, timeout=30)

def close() -> None:
    pool.shutdown(wait=True)
```

## Verify

Python: a test with N workers on the shared-state path. Go: `go test -race` on the touched packages. Rust: the project's test command. TypeScript: a test for the fan-out bound. A speed claim belongs to the optimization card and needs a `measured` before/after.

## Ledger

Mechanics checked 2026-11-18 against `20261118-SOURCES.md`. Paired task: `unmeasured`.
