"""Local helpers for Plan-only verification (Python standard library).

Copied from terraform-solution-generator at devloper-tool-skills commit 016cec1.
No cloud lifecycle mutation commands are implemented here.
"""
import json
import os
from pathlib import Path
import re
import subprocess
import time

SECRET = re.compile(r"(?:^|_)(?:password|passwd|secret|secret_key|access_key|access_key_id|api_key|token|session_token|private_key|client_secret)(?:$|_)", re.I)


class Rejected(Exception):
    pass


def write_json(path, value):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(path.name + ".tmp")
    tmp.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n")
    os.chmod(tmp, 0o600)
    tmp.replace(path)


def redact(text):
    text = str(text)
    for key, value in os.environ.items():
        if SECRET.search(key) and len(value) >= 6:
            text = text.replace(value, "[REDACTED]")
    text = re.sub(r"-----BEGIN [^-]*PRIVATE KEY-----[\s\S]*?-----END [^-]*PRIVATE KEY-----", "[REDACTED PRIVATE KEY]", text)
    text = re.sub(r"\b(?:AKLT|AKIA|ASIA)[A-Za-z0-9]{12,}\b", "[REDACTED ACCESS KEY]", text)
    text = re.sub(r"(?i)(Bearer\s+)\S+", r"\1[REDACTED]", text)
    text = re.sub(r'(?im)((?:[\w-]*(?:password|secret|token|api_key|access_key|private_key)[\w-]*)["\s]*[:=]\s*)["\']?[^\s,"\'}]+', r'\1[REDACTED]', text)
    return text


def run_tf(root, args, timeout=180):
    """Explicit argv; ignore shell aliases, injected TF_CLI_ARGS and provider overrides."""
    root = Path(root).resolve()
    state = root / ".aiac"
    state.mkdir(exist_ok=True)
    config = state / "terraform.rc"
    config.write_text("disable_checkpoint = true\n")
    env = {k: v for k, v in os.environ.items() if not k.startswith("TF_CLI_ARGS") and k not in {"TF_DATA_DIR", "TF_PLUGIN_CACHE_DIR", "TF_LOG", "TF_LOG_PATH"}}
    env.update(TF_IN_AUTOMATION="1", TF_INPUT="0", CHECKPOINT_DISABLE="1", TF_CLI_CONFIG_FILE=str(config))
    started = time.monotonic()
    try:
        p = subprocess.run(["terraform", *args], cwd=root, env=env, capture_output=True, text=True, timeout=timeout)
        return {"command": ["terraform", *args], "exit_code": p.returncode, "duration_seconds": round(time.monotonic()-started, 3), "stdout": p.stdout, "stderr": p.stderr}
    except FileNotFoundError as exc:
        raise Rejected("缺少 Terraform CLI，请安装后重试") from exc
    except subprocess.TimeoutExpired as exc:
        def decode(s):
            return s.decode(errors="replace") if isinstance(s, bytes) else (s or "")
        return {"command": ["terraform", *args], "exit_code": 124, "duration_seconds": round(time.monotonic()-started, 3), "stdout": decode(exc.stdout), "stderr": decode(exc.stderr) + "\n执行超时，未标记通过。"}


def plan_summary(plan):
    changes = []
    totals = {"create": 0, "update": 0, "delete": 0, "replace": 0, "read": 0, "no-op": 0}
    for resource in plan.get("resource_changes", []):
        actions = resource.get("change", {}).get("actions", [])
        if not actions or not set(actions) <= set(totals):
            raise Rejected(f"未支持的 Plan 动作：{actions}；需人工核对后完善摘要逻辑，不推断为通过")
        action = "replace" if "delete" in actions and "create" in actions else next((a for a in actions if a in totals), "unknown")
        totals[action] = totals.get(action, 0) + 1
        changes.append({"address": resource["address"], "type": resource["type"], "mode": resource.get("mode", "managed"), "actions": actions, "summary": action})
    return {"totals": totals, "changes": changes, "requires_confirmation": any(x["summary"] in {"replace", "delete"} for x in changes)}
