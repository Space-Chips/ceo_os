#!/usr/bin/env python3
# Smart Recovery (passe 2)
#
# Strategy: per-file replay with timestamp ordering.
# - Walks all Codex .jsonl sessions
# - Filters by cwd = /Users/timo/ceo_os
# - For each apply_patch call that succeeded, extracts per-file operations
# - Groups operations by file path
# - For each file, replays its operations in strict chronological order,
#   reconstructing the final state independently of other files' history.
# - Uses fuzzy matching when exact hunk context has drifted.
#
# Output goes to a SEPARATE directory (smart_recovery_output/) so nothing
# in the working tree is touched. The user reviews the result, then decides
# whether to copy files into the project.

import json
import os
import re
import subprocess
import sys
from pathlib import Path
from collections import defaultdict

CODEX_SESSIONS = Path.home() / ".codex" / "sessions"
TARGET_CWD = "/Users/timo/ceo_os"
PROJECT_ROOT = Path(TARGET_CWD)
OUTPUT_DIR = Path.home() / "ceo_os" / "smart_recovery_output"
REPORT_PATH = Path.home() / "ceo_os" / "smart_recovery_report.txt"
# Baseline commit: the dev's last commit before the recovery pass 1.
# Files unknown to Codex at session start are seeded from this commit.
BASELINE_REF = "HEAD~1"


def normalize_path(path):
    """Return project-relative path. Strips absolute prefix and leading slashes."""
    if not path:
        return path
    prefix = TARGET_CWD + "/"
    if path.startswith(prefix):
        path = path[len(prefix):]
    elif path == TARGET_CWD:
        return ""
    # Drop any leading slash that survives
    return path.lstrip("/")


def read_disk_state(rel_path):
    """Read the current working-tree content for a path, or None if unreadable."""
    if not rel_path:
        return None
    full = PROJECT_ROOT / rel_path
    try:
        return full.read_text(encoding="utf-8")
    except Exception:
        return None


_baseline_cache = {}


def read_baseline_state(rel_path):
    """Return the file content at BASELINE_REF (dev's pre-recovery commit), or None.

    Cached. Falls back to current working-tree if git lookup fails (e.g., file
    didn't exist at that commit but exists now — rare)."""
    if not rel_path:
        return None
    if rel_path in _baseline_cache:
        return _baseline_cache[rel_path]
    try:
        result = subprocess.run(
            ["git", "-C", str(PROJECT_ROOT), "show", f"{BASELINE_REF}:{rel_path}"],
            capture_output=True,
            timeout=10,
        )
        if result.returncode == 0:
            content = result.stdout.decode("utf-8", errors="replace")
            _baseline_cache[rel_path] = content
            return content
    except Exception:
        pass
    # Fall back to current disk state, then to empty
    disk = read_disk_state(rel_path)
    _baseline_cache[rel_path] = disk
    return disk


def load_relevant_events():
    """Walk every rollout-*.jsonl, keep events from sessions whose cwd == TARGET_CWD."""
    events = []
    sessions = list(CODEX_SESSIONS.rglob("rollout-*.jsonl"))
    print(f"[scan] {len(sessions)} session files found")
    for path in sessions:
        session_cwd = None
        kept_for_this_session = 0
        try:
            with open(path, "r", encoding="utf-8") as f:
                for line in f:
                    try:
                        e = json.loads(line.strip())
                    except Exception:
                        continue
                    if e.get("type") == "session_meta":
                        session_cwd = e.get("payload", {}).get("cwd")
                        if session_cwd != TARGET_CWD:
                            break  # entire session irrelevant
                    if session_cwd == TARGET_CWD:
                        events.append(e)
                        kept_for_this_session += 1
        except Exception as exc:
            print(f"[scan] skip {path}: {exc}")
            continue
    print(f"[scan] {len(events)} events kept for ceo_os")
    return events


def is_success_output(output_text):
    """Heuristic: did the custom_tool_call_output indicate a successful apply_patch?"""
    if not output_text:
        return False
    if "Success" in output_text:
        return True
    if '"exit_code":0' in output_text or '"exit_code": 0' in output_text:
        return True
    return False


def collect_successful_patches(events):
    """Return [(timestamp, patch_input_text)] for every apply_patch call whose output succeeded."""
    pending = {}  # call_id -> (ts, input)
    success_ids = set()
    for e in events:
        if e.get("type") != "response_item":
            continue
        ts = e.get("timestamp", "")
        p = e.get("payload", {})
        ptype = p.get("type", "")
        if ptype == "custom_tool_call" and p.get("name") == "apply_patch":
            call_id = p.get("call_id", "")
            inp = p.get("input", "")
            if call_id and inp:
                pending[call_id] = (ts, inp)
        elif ptype == "custom_tool_call_output":
            call_id = p.get("call_id", "")
            if call_id and is_success_output(p.get("output", "")):
                success_ids.add(call_id)
    result = []
    for call_id, (ts, inp) in pending.items():
        if call_id in success_ids:
            result.append((ts, inp))
    print(f"[patches] {len(result)} successful apply_patch calls")
    return result


def parse_apply_patch(patch_text):
    """Parse Codex apply_patch text into a list of operations:
       [{action: 'add'|'update'|'delete', path: str, content?: str, hunks?: [...], move_to?: str}]
    """
    ops = []
    current = None
    current_lines = []
    for line in patch_text.split("\n"):
        if line.startswith("*** Begin Patch"):
            continue
        if line.startswith("*** End Patch"):
            if current is not None:
                current["_raw"] = current_lines
                ops.append(current)
                current = None
            break
        if line.startswith("*** Add File:"):
            if current is not None:
                current["_raw"] = current_lines
                ops.append(current)
            current = {"action": "add", "path": normalize_path(line[len("*** Add File:"):].strip())}
            current_lines = []
            continue
        if line.startswith("*** Update File:"):
            if current is not None:
                current["_raw"] = current_lines
                ops.append(current)
            current = {"action": "update", "path": normalize_path(line[len("*** Update File:"):].strip())}
            current_lines = []
            continue
        if line.startswith("*** Delete File:"):
            if current is not None:
                current["_raw"] = current_lines
                ops.append(current)
            current = {"action": "delete", "path": normalize_path(line[len("*** Delete File:"):].strip())}
            current_lines = []
            continue
        if line.startswith("*** Move to:"):
            if current is not None and current["action"] == "update":
                current["move_to"] = normalize_path(line[len("*** Move to:"):].strip())
            continue
        if current is not None:
            current_lines.append(line)

    if current is not None and "_raw" not in current:
        current["_raw"] = current_lines
        ops.append(current)

    # Build content for adds, hunks for updates
    for op in ops:
        raw = op.pop("_raw", [])
        if op["action"] == "add":
            content_lines = []
            for l in raw:
                if l.startswith("+"):
                    content_lines.append(l[1:])
                elif l.strip() == "":
                    content_lines.append("")
            op["content"] = "\n".join(content_lines)
            if content_lines and not op["content"].endswith("\n"):
                op["content"] += "\n"
        elif op["action"] == "update":
            op["hunks"] = split_hunks(raw)
    return ops


def split_hunks(raw_lines):
    """Split the body of an Update File into hunks separated by @@ markers."""
    hunks = []
    current = []
    for l in raw_lines:
        if l.startswith("@@"):
            if current:
                hunks.append(current)
            current = []
        else:
            current.append(l)
    if current:
        hunks.append(current)
    return hunks


def find_exact(lines, expected):
    n = len(expected)
    if n == 0 or n > len(lines):
        return None
    for i in range(len(lines) - n + 1):
        if lines[i:i+n] == expected:
            return i
    return None


def find_stripped(lines, expected):
    """Whitespace-insensitive match."""
    n = len(expected)
    if n == 0 or n > len(lines):
        return None
    exp_strip = [l.strip() for l in expected]
    for i in range(len(lines) - n + 1):
        if [l.strip() for l in lines[i:i+n]] == exp_strip:
            return i
    return None


def apply_hunks(content, hunks):
    """Apply hunks with fuzzy matching. Returns (new_content, applied_count, skipped_count)."""
    if content is None:
        content = ""
    lines = content.split("\n")
    applied = 0
    skipped = 0
    for hunk in hunks:
        expected = []   # context + removals
        replacement = []  # context + additions
        for l in hunk:
            if l.startswith("+"):
                replacement.append(l[1:])
            elif l.startswith("-"):
                expected.append(l[1:])
            else:
                text = l[1:] if l.startswith(" ") else l
                expected.append(text)
                replacement.append(text)
        if not expected:
            # Pure addition with no anchor — append to end
            lines.extend(replacement)
            applied += 1
            continue
        idx = find_exact(lines, expected)
        if idx is None:
            idx = find_stripped(lines, expected)
        if idx is None:
            # Check if already applied
            if find_exact(lines, replacement) is not None or find_stripped(lines, replacement) is not None:
                applied += 1  # treat as no-op success
                continue
            skipped += 1
            continue
        lines[idx:idx+len(expected)] = replacement
        applied += 1
    return "\n".join(lines), applied, skipped


def reconstruct_files(all_ops):
    """all_ops is a list of (timestamp, op_dict). Group by path and replay chronologically.
       Returns dict path -> {state, stats}."""
    # Group by path
    by_path = defaultdict(list)
    for ts, op in all_ops:
        by_path[op["path"]].append((ts, op))

    # Stable sort by timestamp inside each path
    for path in by_path:
        by_path[path].sort(key=lambda x: x[0])

    results = {}
    total_files = len(by_path)
    for i, (path, ops) in enumerate(by_path.items(), 1):
        if i % 100 == 0:
            print(f"[replay] {i}/{total_files} files")
        state = None
        deleted = False
        moves = []
        total_applied = 0
        total_skipped = 0
        adds = 0
        updates = 0
        seeded_from_disk = False
        for ts, op in ops:
            action = op["action"]
            if action == "add":
                state = op.get("content", "")
                deleted = False
                adds += 1
            elif action == "update":
                if state is None and not deleted:
                    # Update without prior add — seed from the git baseline
                    # (dev's last commit before recovery), which is the true
                    # pre-Codex state of the file. Fall back to empty.
                    base_state = read_baseline_state(path)
                    if base_state is not None:
                        state = base_state
                        seeded_from_disk = True
                    else:
                        state = ""
                if state is None:
                    # File was deleted, can't update — skip
                    continue
                new_state, applied, skipped = apply_hunks(state, op.get("hunks", []))
                state = new_state
                total_applied += applied
                total_skipped += skipped
                updates += 1
                if op.get("move_to"):
                    moves.append(op["move_to"])
            elif action == "delete":
                state = None
                deleted = True
        results[path] = {
            "state": state,
            "deleted": deleted,
            "adds": adds,
            "updates": updates,
            "applied": total_applied,
            "skipped": total_skipped,
            "moves": moves,
            "op_count": len(ops),
            "seeded_from_disk": seeded_from_disk,
        }
    return results


def write_output(results):
    """Write reconstructed files to OUTPUT_DIR. Skip deleted files."""
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    written = 0
    deleted = 0
    empty = 0
    for path, info in results.items():
        if info["deleted"] or info["state"] is None:
            deleted += 1
            continue
        if not info["state"].strip():
            empty += 1
            # still write — may legitimately be empty
        out = OUTPUT_DIR / path
        out.parent.mkdir(parents=True, exist_ok=True)
        try:
            out.write_text(info["state"], encoding="utf-8")
            written += 1
        except Exception as exc:
            print(f"[write] fail {path}: {exc}")
    return written, deleted, empty


def write_report(results, written, deleted, empty):
    """Write a per-file summary so the user can quickly spot files where many hunks were skipped."""
    lines = []
    lines.append(f"Smart recovery report")
    lines.append(f"Output directory: {OUTPUT_DIR}")
    lines.append(f"Files written: {written}")
    lines.append(f"Files deleted (skipped): {deleted}")
    lines.append(f"Files written empty: {empty}")
    lines.append("")
    lines.append("Top 50 files by skipped hunks (= context drift, may need manual review):")
    sorted_files = sorted(
        results.items(),
        key=lambda kv: kv[1]["skipped"],
        reverse=True,
    )
    for path, info in sorted_files[:50]:
        if info["skipped"] == 0:
            break
        seed = "disk" if info.get("seeded_from_disk") else "new "
        lines.append(
            f"  skipped={info['skipped']:4d}  applied={info['applied']:4d}  "
            f"adds={info['adds']} updates={info['updates']}  seed={seed}  {path}"
        )
    lines.append("")
    lines.append("Top 20 files by total operations (highest churn):")
    sorted_by_ops = sorted(results.items(), key=lambda kv: kv[1]["op_count"], reverse=True)
    for path, info in sorted_by_ops[:20]:
        lines.append(f"  ops={info['op_count']:4d}  {path}")
    REPORT_PATH.write_text("\n".join(lines), encoding="utf-8")


def main():
    events = load_relevant_events()
    patches = collect_successful_patches(events)

    # Flatten: every patch may contain multiple file operations
    all_ops = []
    for ts, patch_text in patches:
        try:
            for op in parse_apply_patch(patch_text):
                all_ops.append((ts, op))
        except Exception as exc:
            print(f"[parse] skip patch at {ts}: {exc}")
            continue
    print(f"[parse] {len(all_ops)} per-file operations extracted")

    results = reconstruct_files(all_ops)
    print(f"[replay] {len(results)} unique files reconstructed")

    written, deleted, empty = write_output(results)
    print(f"[write] {written} files written, {deleted} skipped (deleted), {empty} empty")

    write_report(results, written, deleted, empty)
    print(f"[report] written to {REPORT_PATH}")
    print("")
    print("Next step: review the report, compare smart_recovery_output/ with current project,")
    print("then copy approved files into place. NO files in your project have been modified.")


if __name__ == "__main__":
    main()
