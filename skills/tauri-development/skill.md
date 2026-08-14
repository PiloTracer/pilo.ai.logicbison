---
name: tauri-development
description: >-
  Domain guidance for building tiny, fast, and secure desktop applications with
  the Tauri framework (v1 / v2). Covers Rust backend patterns, IPC security,
  webview shell strategy, state management, event handling, and project-specific
  patterns like Docker-backed webview redirection and API bridge servers.
  Pairs with dev-stack when the Tauri app manages a Docker Compose dev stack.
  Use when the task involves Tauri APIs, Rust commands, webview configuration,
  IPC commands, or Tauri project structure.
---

# tauri-development

Domain guidance for Tauri desktop development. This skill is **read-only reference** — it does not execute file mutations. It provides architectural principles, security patterns, and project conventions for AI agents working with Tauri projects.

**Tool-agnostic** (Cursor, Claude Code, opencode, Codex). **Requires:** a Tauri project with `src-tauri/` directory.

**Pairs with:** `dev-stack` (Docker Compose orchestration when Tauri wraps a containerized backend), `code-implementation` (execution), `code-verify` (verification).

**Registry:** [`.ai/skills/SKILL_DEPENDENCIES.md`](../SKILL_DEPENDENCIES.md).

**Canonical path:** `.ai/skills/tauri-development/skill.md` · **Invocation examples:** `reference.md`

---

## Hard rules

- **Security first.** Only enable specific Tauri APIs required for the task in `tauri.conf.json` / capabilities. Validate all IPC payloads in Rust — never trust the frontend.
- **Heavy lifting in Rust.** Move ALL file system access, system integration, and performance-critical computation to the `src-tauri` layer.
- **Type safety across the bridge.** Provide corresponding TypeScript interfaces for all Rust structs used in `#[tauri::command]` functions.
- **No secrets in Rust commands or webview.** Use environment variables or OS-level secure storage (e.g., `keyring`). Never log or expose tokens via IPC events.
- **Shell strategy preferred.** When the Tauri app wraps a Docker/local web service, prefer webview redirection over iframe embedding. Use iframes only when strict DOM isolation is required.
- **Full-duplex events for async state.** Use `emit` and `listen` for asynchronous updates (e.g., Docker container status, long-running task progress). Do not poll.
- **Binary size discipline.** Strip debug symbols in release builds. Leverage the system webview (WebKit/WebView2) instead of bundling Chromium.
- **Operator handoff:** every response that ends a turn follows the [Operator handoff contract](../SKILL_DEPENDENCIES.md#operator-handoff-contract) — terse output; approvals under `**Needs your approval:**` citing `path:L<n>`; questions numbered under `**Needs your answer:**`; exactly one `**Next step:**` command; one line when nothing is needed (Form A). Decisions and questions never mixed; empty sections omitted.

---

## Guidance areas

### 1. IPC & commands

- Use strongly typed `#[tauri::command]` with `serde::Serialize`/`Deserialize` for all arguments and return types.
- Return `Result<T, E>` where `E: impl Into<InvokeError>` for error propagation to the frontend.
- Use Tauri's `AppHandle` / `State` for shared managed state — never raw statics or `unsafe`.
- For Tauri v2: use `tauri::Emitter` trait for emitting events, `tauri::Listener` / `tauri::listen` for receiving.

### 2. Security capabilities (Tauri v2)

- Declare capabilities in `src-tauri/capabilities/`. Enable only the minimum required permissions.
- Use `tauri::scope` for filesystem and shell access restrictions.
- Disable unused Tauri APIs. Every enabled API is an attack surface vector.
- For dialog/file-system APIs: open native dialogs from Rust commands, not from frontend JS.

### 3. State management & lifecycle

- Use `app.manage(MyState { ... })` to inject shared state (DB connections, config, HTTP clients) during setup.
- Use `setup` hook for async initialization (e.g., start an embedded HTTP server, verify Docker stack).
- Access managed state in commands via `State<'_, MyState>` parameter.
- Use `Arc`/`Mutex` or `RwLock` for mutable shared state; prefer `tokio::sync` types in async contexts.

### 4. HTTP server in Tauri (bridge pattern)

When a Tauri app needs to serve files or APIs to co-located Docker containers:
- Embed a lightweight HTTP server (Axum 0.7 / Actix) spawned during `setup` on a dedicated port.
- Bind to `127.0.0.1` — never `0.0.0.0` — to prevent LAN exposure.
- Use UUID-based path authorization: folder grant → UUID → container requests by UUID, never absolute host paths.
- Enforce path traversal protection: `canonicalize(full_path).starts_with(base_path)` on every request.
- Docker containers reach the host via `host.docker.internal:<port>`.

### 5. Frontend integration

- Use `@tauri-apps/api` (v1) or `@tauri-apps/api` v2 packages for IPC calls from frontend.
- For Tauri v2: use `import { invoke } from '@tauri-apps/api/core'`.
- Listen to events with `import { listen } from '@tauri-apps/api/event'` (v2).
- Prefer webview redirection to a local web service over embedding `<iframe>` when the Tauri app acts as a shell.

---

## Parse invocation

| User says | Verb | Action |
|-----------|------|--------|
| `@tauri-development` | help | Display guidance overview and link to reference.md |
| `@tauri-development status` | status | Read-only: check Tauri project structure, config, and capabilities |
| `@tauri-development help` | help | Point to purpose and reference |

Non-mutating — no `init/create/start/continue/complete` modes.

---

## Self-verify note

This is a read-only reference skill. It does not produce artifacts that need verification. When an agent applies Tauri guidance during `code-implementation`, the standard code gates (tests/lint/type-check) apply per that skill.
