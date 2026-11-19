# Collection decisions

Default to the structure whose operation is the one the caller performs. Read only the section for the language the selector already resolved.

**Status:** Binding when the selector loads this card · 2026-11-18
**Needs:** nothing beyond the selector. Consumer CONVENTIONS win.

## Python

- **COL-PY1.** `list` to grow a sequence, `tuple` for a fixed record, `set` for membership, `dict` for keyed lookup. Reason: a list scan for membership is linear.
- **COL-PY2.** Do not mutate a list while iterating it. Build a new list, or iterate a copy.
- **COL-PY3.** A generator when the caller must not hold the whole sequence. A `list` when the caller needs length, indexing, or a second pass.

## Go

- **COL-GO1.** A slice is a view. `append` may reuse the backing array. Copy when the callee must own the elements.
- **COL-GO2.** Map iteration order is not a contract. Sort the keys when order matters.
- **COL-GO3.** A set is `map[T]struct{}`. A slice scan only when the task says the collection stays tiny.

## Rust

- **COL-RS1.** Borrow `&[T]` or `&str` at a boundary. Take `Vec<T>` or `String` only when the function stores them.
- **COL-RS2.** `Vec` when order matters. `HashSet` or `HashMap` for membership or key lookup. Do not clone a `Vec` to iterate it.
- **COL-RS3.** Collect an iterator when a collection is the result. Leave it lazy when the caller streams.

## TypeScript

- **COL-TS1.** A readonly array at a public boundary. Copy before mutating an array you received.
- **COL-TS2.** A typed object for a fixed key set. `Map` for dynamic keys. `Set` for membership.
- **COL-TS3.** Do not use an array as a set.

## Example

Python, `COL-PY1`. Membership uses a set. The caller that needs a second pass materializes a list. Other languages follow their own section in this same shape.

```python
def known_ids(rows: list[Row]) -> set[str]:
    return {row.id for row in rows}

def load_all(rows: list[Row]) -> list[Row]:
    return list(rows)
```

## Verify

The project lint and tests. A test that asserts membership or order uses the structure named above, not a linear scan that happens to pass on three items.

## Ledger

Mechanics checked 2026-11-18 against `20261118-SOURCES.md`. The if/then is this card. Paired task: `unmeasured`.
