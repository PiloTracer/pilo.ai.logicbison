# Feedback → Security OS (`.ai.soc`)

**From:** pilo-mail cohabitation audit, 2026-10-15
**Audit reference:** `20261015-cohabitation-audit.md` (findings F-12, F-13, F-15)
**Status of this document:** recommendations only — **no framework source was modified**

> **One-line summary:** SOC is the **reference implementation** for thin-client cohabitation — correctly
> marked, pointer-relative, and fully self-verifying. It has one low-severity hygiene item and one
> cross-cutting duplication item. **Nothing here is urgent; the priority is to protect this behaviour and
> use it as the model the other frameworks copy.**

---

## 1. Verification result — clean

```
$ soc-deploy-basic.sh verify .
  OK:   .cursorrules present
  OK:   SOC block present (SOC_DESIGN_OS_BEGIN/END)
  OK:   no stale skill handles (soc-* naming)
  OK:   SOC_SOURCE → /mnt/work/Projects/pilo.ai.soc.logicbison (reachable, skills registry present)
  OK:   .work.soc/ skeleton present (HANDOFF_SOC, NEXT_SOC, UNKNOWNS_SOC)
  OK:   section present: SOC context files
  OK:   section present: SOC placeholders
  OK:   section present: SOC skills
  OK:   section present: Data Loss Prevention
verify: all checks passed
```

`.work.soc/` exists with 8 files. The block occupies `.cursorrules:214-295`, is delimited by
`<!-- SOC_DESIGN_OS_BEGIN -->` / `<!-- SOC_DESIGN_OS_END -->`, and every path resolves through the pointer.

---

## 2. What SOC does right — copy these patterns

These are the specific behaviours the other frameworks should adopt. They are listed so a future refactor
does not "simplify" them away.

| # | Behaviour | Evidence | Why it matters |
|---|-----------|----------|----------------|
| 1 | **Delimited block** | `.cursorrules:214`, `:295` | Enables idempotent update; a re-run cannot duplicate rules. UI has no markers in this repo (audit F-03) |
| 2 | **Pointer-relative script paths** | `:226` `bash $SOC_SOURCE/scripts/soc-deploy-basic.sh verify .`; `:248` `$SOC_SOURCE/scripts/sister-discovery.sh` | Works in thin-client mode, where no local `.ai.soc/` exists. UI hard-codes relative `.ai.ui/scripts/...` (audit F-05) |
| 3 | **Ships its own verify command, documented in the block** | `:226` | The adopter can audit the integration without reading framework source. This is the single most valuable practice here |
| 4 | **Self-describing section set** | `### SOC context files`, `### SOC placeholders`, `### SOC skills`, `### Data Loss Prevention` | The verifier checks for each by name (`soc-deploy-basic.sh verify`), so a partial merge is detectable. UI's verifier accepts a bare string match (audit F-04) |
| 5 | **Explicit DLP invariant** | `:287-293` | Guarantees destructive-operation rules exist even if Agent OS is absent or fat-client |
| 6 | **No stale skill handles** | verify output | The verifier actively looks for drift, not just presence |

**Recommendation:** publish these six as the required cross-framework deployment contract, and have every
framework's verifier assert them. A framework that cannot demonstrate 1–4 is not safely co-installable.

---

## 3. F-13 — INFO — discovery reports on-disk siblings, not wired ones

`sister-discovery.sh:37` fixes `FRAMEWORK_SLOTS="ui biz soc cto flutter mlt"`, and SOC's verify therefore
reports:

```
info: sister framework .ai.ui: installed
info: sister framework .ai.biz: installed
info: sister framework .ai.soc: installed
info: sister framework .ai.cto: installed
info: sister framework .ai.flutter: installed
info: sister framework .ai.mlt: installed
```

Six are on disk; **three** are wired into `.cursorrules`. The output is accurate but reads as if all six
are active.

**Recommended change:** label the distinction explicitly, e.g.
`installed (.ai.cto) — not declared in .cursorrules`. Low severity, but it prevents an operator from
believing unimplemented frameworks are in play.

---

## 4. F-15 — LOW — duplicated governance across blocks, with no precedence rule

SOC's `### Data Loss Prevention (SOC deploy invariant)` (`.cursorrules:287-293`) restates rules that Agent
OS already carries in Core Principle 8 (`.cursorrules:20`) and in `## Change safety (mechanical)`
(`:25-40`): per-message git permission, no file deletion without same-message approval, no database/volume
destruction.

The intent is defensible — SOC wants its invariant present regardless of whether Agent OS was deployed.
The consequences are:

1. the same rule now exists **twice** in a 295-line file that is read at the start of every conversation;
2. the two copies can **drift** (Agent OS could change Principle 8 while SOC's text stays as written);
3. there is **no stated precedence** if they ever conflict.

The same pattern will occur with UI, whose snippet also carries a change-safety table
(`cursorrules.ui.snippet.template:10-17`), a data-loss union (`:19-23`) and a completion gate (`:25-27`).

**Recommended change (pick one):**

- **Preferred:** each framework block carries only its **delta** plus a pointer — e.g. *"DLP rules: see Core
  Principle 8; SOC adds: …"* — so there is one normative copy.
- Or keep full restatements but (a) mark one block as **normative** and the rest as **restatements**, and
  (b) add a coherence check that fails when the copies diverge.

**Acceptance:** a deliberate edit to Agent OS Core Principle 8 is either reflected in the SOC restatement or
raises a verification failure — not silently ignored.

---

## 5. F-08 (framework-wide) — SOC ships no `COHABITATION.md`

`.ai.soc/COHABITATION.md` does not exist (only `.ai.ui` has one). SOC's boundary with Agent OS is implied by
its DLP section and `.work.soc/` scoping but is not stated as a contract.

**Recommended change:** publish `.ai.soc/COHABITATION.md` covering, at minimum: what SOC owns
(`.work.soc/**`, SOC standards/scripts), what it must never write (`.work/plans/NEXT.md`,
`.work/context/HANDOFF.md`, `.work/touch-scope`), the cross-link mechanism, and the precedence rule from §4.

This is shared with the Agent OS feedback (R8 in the audit) — it should be one agreed template, not three
independent documents.

---

## 6. Summary for the SOC maintainer

| Finding | Severity | Action |
|---------|----------|--------|
| F-12 verifier clean, thin-client-correct | — | **Protect**; use as the reference model |
| F-13 discovery reports installed vs declared | INFO | Label the distinction |
| F-15 duplicated DLP governance | LOW | Prefer delta + pointer; or mark normative vs restatement |
| F-08 no `COHABITATION.md` | LOW | Publish one, from a shared template |

**Nothing in this document is a blocker, and nothing requires changing the SOC block in pilo-mail.** The
block is correct as deployed.

---

## Next action

Adopt the shared `COHABITATION.md` template (audit R8) and label installed-vs-declared frameworks in
`sister-discovery.sh` output.
