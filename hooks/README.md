# Git hooks (Agent OS)

Install into the **application repo root** (where `.git/` lives), not inside `.ai/` only:

```bash
bash .ai/scripts/install-git-hooks.sh          # nested layout
bash scripts/install-git-hooks.sh              # self-hosted Agent OS root
```

Or automatically via `@project-bootstrap init`, `templates/bootstrap.sh`, `@deploy-basic`, and in-place `@deploy-files`.

| Hook | Role |
|------|------|
| `prepare-commit-msg` | Strip `Co-authored-by:` trailers; prepend task ref when known |
| `commit-msg` | Reject commits that still contain `Co-authored-by:`; warn on missing task ref |
| `pre-commit` | Change-safety gate: runs touch-scope-verify --strict + blast-radius-check (warn-only by default, never blocks) |
| `post-commit` | Write `.work/commit-ref-pending/` for tools-project ref linker (optional) |

**Policy:** `Co-authored-by` lines (including IDE/agent attribution such as `Co-authored-by: Cursor <cursoragent@cursor.com>`) are **forbidden** per `.cursorrules` § No Co-authored-by. Agents must not use `git commit --trailer "Co-authored-by:..."`.
