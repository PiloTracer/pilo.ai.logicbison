# Plan an Implementation Iteration

## Check readiness

```text
@code-implementation status
```

## Declare scope (required before first write)

```text
# Add a Files column to each task in NEXT.md ## Current iteration
# or create .work/touch-scope JSON:
# {"allowed_paths":["src/module/file.ts"],"allowed_patterns":[]}
```

## Plan the iteration (requires implementation-ready)

```text
@code-implementation plan - M1
@code-implementation plan - add test coverage for AC guardrails (after implementation-ready)
```

## After implementing: verify & complete

```text
@code-verify milestone
@code-implementation complete
```