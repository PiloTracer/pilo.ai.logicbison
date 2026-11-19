# Concurrency decisions

Use this card only when the selector's concurrency signal matches. The language is already chosen. Spawn only after the patterns card's synchronous default was considered (`PAT-GO2` for Go; the same idea in the other sections).

**Status:** Binding when the selector loads this card · 2026-11-18; scenarios and Java 2026-11-19
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

## Java

- **CON-JV1.** Waiting work on platform threads uses the server's worker pool, or one `ExecutorService` for the process. Do not create an executor per request. State the bound.
- **CON-JV2.** Java 21 or newer, when the project already runs that JDK: one virtual thread per task. Do not pool virtual threads. Limit a scarce resource with the database pool or a `Semaphore`. Checked 2026-11-19.
- **CON-JV3.** Pure CPU work uses a bounded platform-thread pool. State the bound. Virtual threads do not speed that work.
- **CON-JV4.** One `DataSource` for the process. State its size from what the database can serve. The virtual-thread count does not raise that size. Do not share one `Connection` across threads.
- **CON-JV5.** Stop a slow query with the driver's query timeout or cancel. Do not use `Thread.interrupt` on a thread that is inside Oracle JDBC.

## Scenarios

All three are `waiting`. State the number. One pool for the process (`CON-PY7`, `CON-JV1`). A language with no section on this card still follows these rows and records the runtime.

- **SCN-IN.** Inbound HTTP. Bound the server workers. Java 21+ virtual threads are one per task; the bound is the scarce resource (`CON-JV2`). Cancel the handler when the client disconnects (`CON-GO2`, `CON-TS1`). Java stops a database call with `CON-JV5`. A blocking database or filesystem call on an async handler uses `asyncio.to_thread` or `spawn_blocking` (`CON-PY2`, `CON-RS1`).
- **SCN-OUT.** Outbound HTTP. One client for the process. State max in-flight and a timeout. Pass the request cancel token into the call (`CON-GO2`, `CON-TS1`). Fan-out stays inside that bound (`CON-GO4`, `CON-TS2`).
- **SCN-DB.** Database. One connection pool for the process. State its size from what the database can serve. A larger worker count, including virtual threads, does not raise that size (`CON-JV4`). One transaction per request, or per an explicit unit of work. Abort the query when the request cancel fires. Java uses `CON-JV5`.

## Example

Python, `CON-PY1` and `CON-PY7`. Waiting work uses one pool for the process, with a shutdown. Inbound HTTP, outbound HTTP, and database access use this same shape: the pool exists before the call. Other languages follow their own section in this same shape: a bound, and a way to stop.

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

Python: a test with N workers on the shared-state path. Go: `go test -race` on the touched packages. Rust: the project's test command. TypeScript: a test for the fan-out bound. Java: a test fails when an executor or `DataSource` is constructed per request, and fails when virtual threads are pooled. For `SCN-IN`, `SCN-OUT`, or `SCN-DB`: a test fails when a pool, engine, or client is constructed per request or per call, and passes when that object is created once for the process. A speed claim belongs to the optimization card and needs a `measured` before/after.

## Ledger

Mechanics checked 2026-11-18 against `20261118-SOURCES.md`. Java `CON-JV2` and `CON-JV4`–`CON-JV5` checked 2026-11-19 (HTTP 200). The same day, `SCN-DB` stopped sizing the pool from the worker count, so a virtual-thread count cannot inflate it. Paired task: `unmeasured`.
