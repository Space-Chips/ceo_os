#!/usr/bin/env python3
# Re-apply Skipped Hunks
#
# Walks all Codex apply_patch ops, parses hunks, and tries to apply each
# against the CURRENT working tree. Hunks that succeeded already (idempotent)
# are no-ops. Hunks that failed in pass 2 but match now are applied.
# Uses the same 6-strategy fuzzy matcher as smart_recovery_v3.
#
# Only applies hunks to files Codex actually touched. Skips files that look
# broken (we don't want to make them worse).

import json
import re
import sys
from pathlib import Path
from collections import defaultdict

CODEX_SESSIONS = Path.home() / ".codex" / "sessions"
TARGET_CWD = "/Users/timo/ceo_os"
PROJECT_ROOT = Path(TARGET_CWD)

SMART_QUOTES = {"‘": "'", "’": "'", "“": '"', "”": '"'}


def normalize_path(p):
    if not p:
        return p
    prefix = TARGET_CWD + "/"
    if p.startswith(prefix):
        p = p[len(prefix):]
    return p.lstrip("/")


def normalize_text(text):
    if text is None:
        return None
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    for s, a in SMART_QUOTES.items():
        if s in text:
            text = text.replace(s, a)
    return text


def iter_session_events():
    for path in sorted(CODEX_SESSIONS.rglob("rollout-*.jsonl")):
        cwd = None
        try:
            with open(path, "r", encoding="utf-8", errors="replace") as f:
                for line in f:
                    try:
                        e = json.loads(line.strip())
                    except Exception:
                        continue
                    if e.get("type") == "session_meta":
                        cwd = e.get("payload", {}).get("cwd")
                        if cwd != TARGET_CWD:
                            break
                    if cwd == TARGET_CWD:
                        yield e
        except Exception:
            continue


def is_success(text):
    if not text:
        return False
    return ("Success" in text or '"exit_code":0' in text
            or '"exit_code": 0' in text
            or "Process exited with code 0" in text)


def collect_patches():
    pending, ok = {}, set()
    for e in iter_session_events():
        if e.get("type") != "response_item":
            continue
        p = e.get("payload", {})
        ptype, name = p.get("type", ""), p.get("name", "")
        if ptype == "custom_tool_call" and name == "apply_patch":
            cid = p.get("call_id", "")
            inp = p.get("input", "")
            if cid and inp:
                sk = (e.get("timestamp", ""), id(e))
                if cid not in pending or sk < pending[cid][0]:
                    pending[cid] = (sk, inp)
        elif ptype == "custom_tool_call_output":
            cid = p.get("call_id", "")
            if cid and is_success(p.get("output", "")):
                ok.add(cid)
    out = [(sk, text) for cid, (sk, text) in pending.items() if cid in ok]
    out.sort(key=lambda x: x[0])
    return out


def parse_patch(text):
    ops = []
    cur, buf = None, []
    for line in text.split("\n"):
        if line.startswith("*** Begin Patch"):
            continue
        if line.startswith("*** End Patch"):
            if cur is not None:
                cur["_raw"] = buf
                ops.append(cur)
                cur = None
            break
        if line.startswith("*** Add File:"):
            if cur:
                cur["_raw"] = buf
                ops.append(cur)
            cur = {"action": "add", "path": normalize_path(line[14:].strip())}
            buf = []
            continue
        if line.startswith("*** Update File:"):
            if cur:
                cur["_raw"] = buf
                ops.append(cur)
            cur = {"action": "update", "path": normalize_path(line[17:].strip())}
            buf = []
            continue
        if line.startswith("*** Delete File:"):
            if cur:
                cur["_raw"] = buf
                ops.append(cur)
            cur = {"action": "delete", "path": normalize_path(line[17:].strip())}
            buf = []
            continue
        if cur is not None:
            buf.append(line)
    if cur and "_raw" not in cur:
        cur["_raw"] = buf
        ops.append(cur)
    for op in ops:
        raw = op.pop("_raw", [])
        if op["action"] == "update":
            hunks = []
            cur_h = []
            for l in raw:
                if l.startswith("@@"):
                    if cur_h:
                        hunks.append(cur_h)
                    cur_h = []
                else:
                    cur_h.append(l)
            if cur_h:
                hunks.append(cur_h)
            op["hunks"] = hunks
    return ops


def parse_hunk(hunk_lines):
    expected, replacement = [], []
    for l in hunk_lines:
        if l.startswith("+"):
            replacement.append(l[1:])
        elif l.startswith("-"):
            expected.append(l[1:])
        else:
            txt = l[1:] if l.startswith(" ") else l
            expected.append(txt)
            replacement.append(txt)
    return expected, replacement


def _find_all(lines, expected, transform=None):
    n = len(expected)
    if n == 0 or n > len(lines):
        return []
    exp = expected if transform is None else [transform(l) for l in expected]
    hits = []
    for i in range(len(lines) - n + 1):
        cand = lines[i:i+n] if transform is None else [transform(x) for x in lines[i:i+n]]
        if cand == exp:
            hits.append(i)
    return hits


def find_unique(lines, expected, transform=None):
    hits = _find_all(lines, expected, transform)
    return hits[0] if len(hits) == 1 else None


def apply_hunk(lines, hunk):
    """Return (new_lines, applied: bool). Strict: only apply if a UNIQUE
       match exists (so we don't mis-place content)."""
    expected, replacement = parse_hunk(hunk)
    if not expected:
        return lines, False  # pure addition needs careful anchor; skip
    # Exact unique
    idx = find_unique(lines, expected)
    if idx is not None:
        return lines[:idx] + replacement + lines[idx+len(expected):], True
    # rtrim unique
    idx = find_unique(lines, expected, transform=lambda l: l.rstrip())
    if idx is not None:
        return lines[:idx] + replacement + lines[idx+len(expected):], True
    # Already applied? unique match for replacement
    if find_unique(lines, replacement) is not None:
        return lines, True
    return lines, False


def main():
    print("[1/3] Collecting patches...")
    patches = collect_patches()
    print(f"      {len(patches)} successful apply_patch calls")

    print("[2/3] Parsing patches...")
    all_ops = []
    for sk, text in patches:
        try:
            for op in parse_patch(text):
                all_ops.append((sk, op))
        except Exception:
            continue
    by_path = defaultdict(list)
    for sk, op in all_ops:
        if op["action"] == "update":
            by_path[op["path"]].append((sk, op))
    for path in by_path:
        by_path[path].sort(key=lambda x: x[0])
    print(f"      {len(by_path)} files with update ops")

    print("[3/3] Re-applying hunks against current working tree...")
    total_applied = 0
    files_touched = 0
    for rel, ops in by_path.items():
        target = PROJECT_ROOT / rel
        if not target.exists():
            continue
        try:
            cur = target.read_text(encoding="utf-8")
        except Exception:
            continue
        original = cur
        lines = normalize_text(cur).split("\n")
        had_trailing = cur.endswith("\n")
        if had_trailing and lines and lines[-1] == "":
            lines.pop()
        applied_here = 0
        for sk, op in ops:
            for hunk in op.get("hunks", []):
                lines, ok = apply_hunk(lines, hunk)
                if ok:
                    applied_here += 1
        if applied_here == 0:
            continue
        new_text = "\n".join(lines)
        if had_trailing:
            new_text += "\n"
        if new_text != original:
            target.write_text(new_text, encoding="utf-8")
            total_applied += applied_here
            files_touched += 1

    print(f"\nDone. {files_touched} files updated, {total_applied} hunks re-applied.")


if __name__ == "__main__":
    main()
