#!/usr/bin/env bash
# Write .work/reports/last-gate.json after a verification run (audit trail for sessions/CI).
#
# Usage:
#   bash scripts/last-gate-record.sh --verifier NAME --verdict pass|fail|pass_with_conditions \
#     [--command "cmd" --exit 0]...
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/portability.sh
source "${SCRIPT_DIR}/lib/portability.sh"
PY="$(portable_require_python)"

if [[ -n "${LAST_GATE_ROOT:-}" ]]; then
  ROOT="${LAST_GATE_ROOT}"
else
  ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi
OUT="${ROOT}/.work/reports/last-gate.json"
VERIFIER=""
VERDICT=""
CMDS=()
EXITS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --verifier) VERIFIER="${2:-}"; shift 2 ;;
    --verdict) VERDICT="${2:-}"; shift 2 ;;
    --command) CMDS+=("${2:-}"); shift 2 ;;
    --exit) EXITS+=("${2:-}"); shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

[[ -n "${VERIFIER}" && -n "${VERDICT}" ]] || {
  echo "Usage: last-gate-record.sh --verifier NAME --verdict pass|fail|pass_with_conditions [--command CMD --exit N]..." >&2
  exit 2
}

mkdir -p "$(dirname "${OUT}")"

# Empty arrays under `set -u` are unsafe on bash 3.2; skip the expansion.
if [[ ${#CMDS[@]} -eq 0 ]]; then
  CMDS_JSON='[]'
else
  CMDS_JSON="$(printf '%s\0' "${CMDS[@]}" | "$PY" -c 'import json,sys; print(json.dumps([s.decode() for s in sys.stdin.buffer.read().split(b"\0") if s]))')"
fi
if [[ ${#EXITS[@]} -eq 0 ]]; then
  EXITS_JSON='[]'
else
  EXITS_JSON="$(printf '%s\n' "${EXITS[@]}" | "$PY" -c 'import json,sys; print(json.dumps([int(x) if x.strip().lstrip("-").isdigit() else x for x in sys.stdin.read().splitlines() if x.strip()]))')"
fi

export ROOT OUT VERIFIER VERDICT CMDS_JSON EXITS_JSON
"$PY" - <<'PY'
import json, os, subprocess
from datetime import datetime, timezone

root = os.environ["ROOT"]
out = os.environ["OUT"]
verifier = os.environ["VERIFIER"]
verdict = os.environ["VERDICT"]
cmds = json.loads(os.environ["CMDS_JSON"])
exits = json.loads(os.environ["EXITS_JSON"])
while len(exits) < len(cmds):
    exits.append(None)
commands = [{"command": c, "exit_code": e} for c, e in zip(cmds, exits)]

def git_field(*args):
    try:
        return subprocess.check_output(
            ["git", "-C", root] + list(args), text=True, stderr=subprocess.DEVNULL
        ).strip()
    except Exception:
        return "unknown"

doc = {
    "version": 1,
    "recorded_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "branch": git_field("rev-parse", "--abbrev-ref", "HEAD"),
    "commit": git_field("rev-parse", "HEAD"),
    "verifier": verifier,
    "verdict": verdict,
    "commands": commands,
}
os.makedirs(os.path.dirname(out), exist_ok=True)
with open(out, "w", encoding="utf-8") as f:
    json.dump(doc, f, indent=2)
    f.write("\n")
print(f"last-gate-record: wrote {out} ({verifier} {verdict})")
PY