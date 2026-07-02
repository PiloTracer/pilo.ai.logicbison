#!/usr/bin/env bash
# Install or sync opencode.json from opencode.json.template for the consuming repo.
#
# Modes:
#   (default)       Create opencode.json when missing; skip when present (no-overwrite).
#   --sync-paths    Update framework path fields only (instructions, references, skills.paths).
#                   Preserves custom mcp blocks and operator-added entries. Creates when missing.
#   --force         Full regenerate from template (destructive to customizations).
#
# Usage:
#   REPO_ROOT=/path/to/app AI_SOURCE=/path/.ai bash install-opencode-config.sh
#   OLD_SOURCE=/old/path/.ai ... --sync-paths   # pass prior AGENT_OS_SOURCE when source moved
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORCE=0
SYNC_PATHS=0
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    --sync-paths) SYNC_PATHS=1 ;;
  esac
done

if [[ -n "${REPO_ROOT:-}" ]]; then
  REPO_ROOT="$(cd "$REPO_ROOT" && pwd)"
elif git rev-parse --show-toplevel >/dev/null 2>&1; then
  REPO_ROOT="$(git rev-parse --show-toplevel)"
else
  REPO_ROOT="$(pwd)"
fi

resolve_ai_root() {
  if [[ -n "${AI_SOURCE:-}" ]]; then
    echo "$(cd "$AI_SOURCE" && pwd)"
    return 0
  fi
  if [[ -d "${REPO_ROOT}/.ai/skills" ]]; then
    echo "${REPO_ROOT}/.ai"
    return 0
  fi
  if [[ -f "${REPO_ROOT}/.cursorrules" ]]; then
    local src
    src="$(grep -oE 'AGENT_OS_SOURCE=[^[:space:]]+' "${REPO_ROOT}/.cursorrules" 2>/dev/null | head -1 | cut -d= -f2- || true)"
    if [[ -n "$src" && "$src" != "REPLACE_BASICSOURCE" && -d "${src}/skills" ]]; then
      echo "$src"
      return 0
    fi
  fi
  if [[ -d "${REPO_ROOT}/skills" && -f "${REPO_ROOT}/skills/README.md" ]]; then
    echo "$REPO_ROOT"
    return 0
  fi
  if [[ -d "${SCRIPT_DIR}/../skills" ]]; then
    echo "$(cd "${SCRIPT_DIR}/.." && pwd)"
    return 0
  fi
  return 1
}

compute_os_prefix() {
  local ai_root="$1"
  if [[ -d "${REPO_ROOT}/.ai/skills" ]]; then
    echo ".ai"
    return 0
  elif [[ -f "${REPO_ROOT}/.cursorrules" ]]; then
    local src
    src="$(grep -oE 'AGENT_OS_SOURCE=[^[:space:]]+' "${REPO_ROOT}/.cursorrules" 2>/dev/null | head -1 | cut -d= -f2- || true)"
    if [[ -n "$src" && "$src" != "REPLACE_BASICSOURCE" && -d "${src}/skills" && ! -d "${REPO_ROOT}/.ai/skills" ]]; then
      echo "$src"
      return 0
    fi
  fi
  if [[ -d "${ai_root}/skills" && "$ai_root" == "$REPO_ROOT" ]]; then
    echo "."
    return 0
  fi
  echo "$ai_root"
}

AI_ROOT="$(resolve_ai_root)" || {
  echo "skip: could not resolve Agent OS root (no .ai/skills, AGENT_OS_SOURCE, or self-hosted layout)" >&2
  exit 0
}

TEMPLATE="${AI_ROOT}/opencode.json.template"
DEST="${REPO_ROOT}/opencode.json"
OS_PREFIX="$(compute_os_prefix "$AI_ROOT")"

if [[ ! -f "$TEMPLATE" ]]; then
  echo "skip: no opencode.json.template at ${TEMPLATE}" >&2
  exit 0
fi

if [[ -f "$DEST" && "$FORCE" -eq 0 && "$SYNC_PATHS" -eq 0 ]]; then
  echo "skip (exists): ${DEST}"
  exit 0
fi

export TEMPLATE DEST OS_PREFIX AI_ROOT REPO_ROOT OLD_SOURCE="${OLD_SOURCE:-}"
export INSTALL_OPENCODE_FORCE="$FORCE" INSTALL_OPENCODE_SYNC="$SYNC_PATHS"

python3 << 'PYEOF'
import json, os, pathlib, sys

template_path = os.environ["TEMPLATE"]
dest_path = os.environ["DEST"]
os_prefix = os.environ["OS_PREFIX"]
ai_root = os.path.abspath(os.environ["AI_ROOT"])
repo_root = os.path.abspath(os.environ["REPO_ROOT"])
old_source = os.environ.get("OLD_SOURCE", "").strip()
force = os.environ.get("INSTALL_OPENCODE_FORCE") == "1"
sync_paths = os.environ.get("INSTALL_OPENCODE_SYNC") == "1"


def join(rel):
    if os_prefix == ".":
        return f"./{rel}"
    return f"{os_prefix.rstrip('/')}/{rel}"


def build_config():
    cfg = {}
    if os.path.isfile(template_path):
        with open(template_path) as f:
            cfg = json.load(f)

    cfg["instructions"] = [
        join("START_HERE.md"),
        join("PROCESS_ROUTER.md"),
    ]

    sibling_parent = pathlib.Path(ai_root).parent
    sisters = [
        ("ai-ui", ".ai.ui", "UI Design OS: UI component specs, design tokens, accessibility"),
        ("ai-biz", ".ai.biz", "Business OS: strategy, brand, content, pricing"),
        ("ai-soc", ".ai.soc", "Security OS: autonomous AI security testing, penetration testing, vulnerability assessment"),
    ]
    refs = {
        "ai": {
            "path": os_prefix if os_prefix != "." else ".",
            "description": "Agent OS: skills, standards, concepts, workflow guides",
        }
    }
    for key, dirname, desc in sisters:
        sib = sibling_parent / dirname
        if sib.is_dir() and (sib / "skills" / "README.md").is_file():
            rel = os.path.relpath(sib, repo_root)
            cfg["instructions"].append(f"{rel}/START_HERE.md")
            refs[key] = {"path": rel, "description": desc}

    cfg["references"] = refs
    cfg.setdefault("skills", {})["paths"] = [join("skills")]
    for key, _, _ in sisters:
        if key in refs:
            cfg["skills"]["paths"].append(refs[key]["path"] + "/skills")

    mcp = cfg.get("mcp") or {}
    if "tools-project" not in mcp:
        mcp["tools-project"] = {
            "type": "local",
            "command": ["python3", ".opencode/mcp/project-mcp/mcp_server.py"],
            "enabled": True,
        }
    cfg["mcp"] = mcp
    return cfg


def norm_path(p):
    if not p:
        return ""
    p = p.rstrip("/")
    if p.startswith("./"):
        return p[2:]
    return p


def expected_skills_path():
    return norm_path(join("skills"))


def collect_strings(obj, out):
    if isinstance(obj, str):
        out.append(obj)
    elif isinstance(obj, dict):
        for v in obj.values():
            collect_strings(v, out)
    elif isinstance(obj, list):
        for v in obj:
            collect_strings(v, out)


def replace_prefix_in_tree(obj, old_prefix, new_prefix):
    old_n = norm_path(old_prefix)
    new_n = norm_path(new_prefix)
    if not old_n or old_n == new_n:
        return False
    changed = False

    def repl(val):
        nonlocal changed
        if not isinstance(val, str):
            return val
        updated = val
        for old, new in (
            (old_prefix.rstrip("/"), new_prefix.rstrip("/")),
            (old_n, new_n),
            (old_n + "/", new_n + "/"),
        ):
            if old and old in updated:
                updated = updated.replace(old, new)
        if updated != val:
            changed = True
        return updated

    def walk(node):
        if isinstance(node, dict):
            for k, v in list(node.items()):
                if k == "mcp":
                    continue
                if isinstance(v, (dict, list)):
                    walk(v)
                elif isinstance(v, str):
                    node[k] = repl(v)
        elif isinstance(node, list):
            for i, v in enumerate(node):
                if isinstance(v, (dict, list)):
                    walk(v)
                elif isinstance(v, str):
                    node[i] = repl(v)

    walk(obj)
    return changed


def infer_old_prefix(cfg):
    if old_source:
        return old_source
    paths = (cfg.get("skills") or {}).get("paths") or []
    for p in paths:
        p = norm_path(p)
        if p.endswith("/skills"):
            return p[: -len("/skills")]
        if p.endswith("skills"):
            base = p[: -len("skills")].rstrip("/")
            if base:
                return base
    refs = cfg.get("references") or {}
    ai_ref = refs.get("ai") or {}
    rp = norm_path(ai_ref.get("path", ""))
    if rp and rp not in (".", ""):
        return rp
    return ""


def paths_stale(cfg):
    expected = expected_skills_path()
    paths = (cfg.get("skills") or {}).get("paths") or []
    if not paths:
        return True, expected, None
    first = norm_path(paths[0])
    exp = norm_path(expected)
    if first == exp:
        return False, expected, first
    if os.path.isabs(exp) and os.path.isabs(first):
        return first != exp, expected, first
    return first != exp, expected, first


def write_cfg(cfg, label):
    with open(dest_path, "w") as f:
        json.dump(cfg, f, indent=2)
        f.write("\n")
    json.load(open(dest_path))
    print(label)


def sanitize_corrupted_strings(cfg):
    """Drop framework path strings corrupted by prior prefix-replace (embedded newlines)."""
    changed = False

    def clean_str(s):
        if isinstance(s, str) and "\n" in s:
            return None
        return s

    inst = cfg.get("instructions") or []
    new_inst = [x for x in inst if clean_str(x) is not None]
    if new_inst != inst:
        cfg["instructions"] = new_inst
        changed = True

    refs = cfg.get("references") or {}
    for k, v in list(refs.items()):
        if isinstance(v, dict) and isinstance(v.get("path"), str) and "\n" in v["path"]:
            del refs[k]
            changed = True
    cfg["references"] = refs

    paths = (cfg.get("skills") or {}).get("paths") or []
    new_paths = [p for p in paths if not (isinstance(p, str) and "\n" in p)]
    if new_paths != paths:
        cfg.setdefault("skills", {})["paths"] = new_paths
        changed = True
    return changed


def sync_framework_sections(cfg):
    """Update framework-owned opencode sections from build_config(); preserve mcp + operator extras."""
    fresh = build_config()
    changed = False

    fw_names = ("START_HERE.md", "PROCESS_ROUTER.md", "COHABITATION.md")
    kept_inst = [
        x for x in cfg.get("instructions", [])
        if not any(str(x).endswith(n) for n in fw_names)
        and x not in fresh["instructions"]
    ]
    new_inst = fresh["instructions"] + kept_inst
    if cfg.get("instructions") != new_inst:
        cfg["instructions"] = new_inst
        changed = True

    refs = dict(cfg.get("references") or {})
    for k, v in fresh.get("references", {}).items():
        prev = refs.get(k, {})
        merged = {**prev, **v}
        if refs.get(k) != merged:
            refs[k] = merged
            changed = True
    cfg["references"] = refs

    fresh_paths = fresh["skills"]["paths"]
    old_paths = (cfg.get("skills") or {}).get("paths", [])
    sister_markers = (".ui/skills", ".biz/skills", ".soc/skills")
    kept_paths = [
        p for p in old_paths
        if p not in fresh_paths and not any(m in str(p) for m in sister_markers)
    ]
    new_paths = fresh_paths + [p for p in kept_paths if p not in fresh_paths]
    if old_paths != new_paths:
        cfg.setdefault("skills", {})["paths"] = new_paths
        changed = True
    return changed


def is_fat_client_prefix():
    return os_prefix == ".ai" or (not os.path.isabs(os_prefix) and os_prefix not in (".", ai_root))


if force or (not os.path.isfile(dest_path) and not sync_paths):
    cfg = build_config()
    write_cfg(cfg, f"created: {dest_path} (Agent OS prefix: {os_prefix})")
    sys.exit(0)

if sync_paths:
    if not os.path.isfile(dest_path):
        cfg = build_config()
        write_cfg(cfg, f"created: {dest_path} (Agent OS prefix: {os_prefix})")
        sys.exit(0)

    with open(dest_path) as f:
        cfg = json.load(f)

    changed = sanitize_corrupted_strings(cfg)
    if is_fat_client_prefix():
        changed = sync_framework_sections(cfg) or changed
    else:
        old_p = old_source or infer_old_prefix(cfg)
        new_p = os_prefix if os_prefix != "." else ai_root
        if old_p and norm_path(old_p) != norm_path(new_p):
            changed = replace_prefix_in_tree(cfg, old_p, new_p) or changed
        stale, expected, actual = paths_stale(cfg)
        if stale:
            changed = sync_framework_sections(cfg) or changed

    if changed:
        write_cfg(cfg, f"synced: {dest_path} (Agent OS prefix: {os_prefix})")
    else:
        stale, expected, actual = paths_stale(cfg)
        if stale:
            print(f"stale: {dest_path} skills.paths[0]={actual!r} expected {expected!r} — manual merge or --force")
            sys.exit(2)
        print(f"sync: {dest_path} (paths already current)")
    sys.exit(0)

# unreachable
sys.exit(0)
PYEOF
