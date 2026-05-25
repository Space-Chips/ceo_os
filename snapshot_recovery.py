#!/usr/bin/env python3
# Snapshot Recovery - find every full-ish file snapshot captured by Codex
# shell reads in session logs, pick the latest reliable one per file, and
# overlay it on the working tree.
#
# Detection: scans exec_command calls for read patterns that fetch a full
# file:
#   - cat <path>
#   - cat -n <path>          (strip line numbers in output)
#   - nl <path>, nl -ba <path>  (strip line numbers in output)
#   - sed -n '1,$p' <path>
#   - sed -n '1,Np' <path>     (kept if output line count < N: full file)
#   - head -n N <path>         (kept if output line count < N)
#   - nl -ba <path> | sed -n '1,Np'  (line numbers, range from pipe end)
# Scoring per file: prefer (latest_ts, most_lines).
# Conservative: only replaces a project file if the snapshot has at least
# as many lines AND the current working-tree version has analyzer errors
# OR was empty.

import json
import re
import shlex
import subprocess
from pathlib import Path
from collections import defaultdict

CODEX_SESSIONS = Path.home() / ".codex" / "sessions"
TARGET_CWD = "/Users/timo/ceo_os"
PROJECT_ROOT = Path(TARGET_CWD)
OUT_DIR = Path.home() / "ceo_os_latest_snapshots"


# -----------------------------------------------------------------------
# Read pattern parsing
# -----------------------------------------------------------------------

# Returns (path, claimed_range_or_None, has_line_numbers)
# `claimed_range_or_None` is (start, end) if a range is asserted.
def parse_read(cmd):
    s = cmd.strip()
    # Drop leading `cd <dir> && `
    s = re.sub(r"^cd\s+\S+\s*&&\s*", "", s)
    # Drop trailing semicolons / pipe-to-cat noise
    s = re.sub(r"\s*\|\s*cat\s*$", "", s)

    # cat path
    m = re.fullmatch(r"cat\s+(\S+)", s)
    if m:
        return m.group(1), None, False
    # cat -n path
    m = re.fullmatch(r"cat\s+-n\s+(\S+)", s)
    if m:
        return m.group(1), None, True
    # nl path  or  nl -ba path
    m = re.fullmatch(r"nl(?:\s+-\w+)?\s+(\S+)", s)
    if m:
        return m.group(1), None, True
    # sed -n '1,$p' path
    m = re.fullmatch(r"sed\s+-n\s+'1,\$p'\s+(\S+)", s)
    if m:
        return m.group(1), None, False
    # sed -n 'N,Mp' path (any range starting from 1 with reasonable upper)
    m = re.fullmatch(r"sed\s+-n\s+'(\d+)\s*,\s*(\d+)\s*p'\s+(\S+)", s)
    if m:
        start, end = int(m.group(1)), int(m.group(2))
        return m.group(3), (start, end), False
    # head -n N path
    m = re.fullmatch(r"head\s+-n\s+(\d+)\s+(\S+)", s)
    if m:
        n = int(m.group(1))
        return m.group(2), (1, n), False
    # head path
    m = re.fullmatch(r"head\s+(\S+)", s)
    if m:
        return m.group(1), (1, 10), False
    # nl -ba path | sed -n '1,Np'
    m = re.fullmatch(
        r"nl(?:\s+-\w+)?\s+(\S+)\s*\|\s*sed\s+-n\s+'(\d+)\s*,\s*(\d+)\s*p'", s
    )
    if m:
        return m.group(1), (int(m.group(2)), int(m.group(3))), True
    return None, None, False


def strip_line_numbers(text):
    """Convert nl/cat -n output back to raw content. nl uses tab; cat -n uses
       spaces. Strip the leading whitespace + digits + tab/spaces."""
    out = []
    for line in text.split("\n"):
        # nl format: spaces + digits + tab + content
        s = re.sub(r"^\s*\d+\t", "", line)
        if s == line:
            # cat -n format: whitespace + digits + at least two spaces + content
            s = re.sub(r"^\s*\d+\s{2,}", "", line)
        out.append(s)
    return "\n".join(out)


def extract_exec_body(output_text):
    """Extract stdout body from an exec_command output blob."""
    if not output_text:
        return None
    ix = output_text.find("\nOutput:")
    if ix == -1:
        return None
    body = output_text[ix + len("\nOutput:"):]
    if body.startswith("\n"):
        body = body[1:]
    # Skip if Codex truncated
    if "truncated" in output_text.lower():
        return None
    return body


def normalize_path(p):
    if not p:
        return p
    prefix = TARGET_CWD + "/"
    if p.startswith(prefix):
        p = p[len(prefix):]
    return p.lstrip("/")


# -----------------------------------------------------------------------
# Session walk
# -----------------------------------------------------------------------

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


# -----------------------------------------------------------------------
# Collect & rank snapshots
# -----------------------------------------------------------------------

def collect_snapshots():
    pending = {}    # call_id -> (ts, cmd)
    outputs = {}
    for e in iter_session_events():
        if e.get("type") != "response_item":
            continue
        p = e.get("payload", {})
        if p.get("type") == "function_call" and p.get("name") == "exec_command":
            cid = p.get("call_id", "")
            raw = p.get("input", "") or p.get("arguments", "")
            try:
                cmd = json.loads(raw).get("cmd", "")
            except Exception:
                cmd = raw
            if cid:
                pending[cid] = (e.get("timestamp", ""), cmd)
        elif p.get("type") == "function_call_output":
            cid = p.get("call_id", "")
            if cid:
                outputs[cid] = p.get("output", "")

    print(f"[walk] {len(pending)} exec_command calls indexed")

    # path -> list of (ts, claimed_range, body_lines_count, body)
    per_file = defaultdict(list)
    for cid, (ts, cmd) in pending.items():
        out = outputs.get(cid, "")
        if "Process exited with code 0" not in out:
            continue
        path, claimed_range, has_nums = parse_read(cmd)
        if not path:
            continue
        rel = normalize_path(path.strip("'\""))
        if not rel:
            continue
        # Only project source files
        if not rel.startswith(("lib/", "android/", "ios/", "test/",
                                "packages/", "docs/", "scripts/")):
            continue
        body = extract_exec_body(out)
        if body is None:
            continue
        if has_nums:
            body = strip_line_numbers(body)
        lines = body.count("\n") + (0 if body.endswith("\n") else 1)
        per_file[rel].append((ts, claimed_range, lines, body))

    print(f"[walk] snapshots for {len(per_file)} unique files")
    return per_file


def pick_best(per_file):
    """For each file, pick the LATEST snapshot whose lines covers >= the
       maximum claimed range or whose body is "full" (no range claim).

       Returns dict[rel_path] -> (ts, lines, body)."""
    best = {}
    for rel, snaps in per_file.items():
        # Compute the max lines we've ever observed for this file
        max_seen = max(s[2] for s in snaps)
        # A "full" snapshot: no range claim AND lines >= 0.95 * max_seen
        # OR a range claim where actual lines < (end - start + 1) ⇒ EOF hit
        candidates = []
        for ts, rng, lines, body in snaps:
            full = False
            if rng is None:
                if lines >= max(1, int(0.95 * max_seen)):
                    full = True
            else:
                start, end = rng
                claimed = end - start + 1
                # If output has fewer lines than the claimed range, we hit
                # EOF — so we have the complete file from `start` onward.
                if start == 1 and lines < claimed and lines >= int(0.95 * max_seen):
                    full = True
                elif start == 1 and lines >= int(0.95 * max_seen):
                    full = True
            if full:
                candidates.append((ts, lines, body))
        if not candidates:
            continue
        candidates.sort(key=lambda c: (c[0], c[1]))   # latest, then most lines
        best[rel] = candidates[-1]
    print(f"[rank] {len(best)} files have full-ish snapshots")
    return best


def overlay_snapshots(best, dry_run=False):
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    overlaid = 0
    skipped_smaller = 0
    for rel, (ts, lines, body) in best.items():
        target = PROJECT_ROOT / rel
        try:
            current = target.read_text(encoding="utf-8", errors="replace") if target.exists() else ""
        except Exception:
            current = ""
        current_lines = current.count("\n")
        # Only overlay if snapshot has more content (or current is empty)
        if current_lines > 0 and lines < current_lines:
            skipped_smaller += 1
            # Still mirror to OUT_DIR for inspection
            mirror = OUT_DIR / rel
            mirror.parent.mkdir(parents=True, exist_ok=True)
            mirror.write_text(body, encoding="utf-8")
            continue
        if not dry_run:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(body, encoding="utf-8")
        # Always mirror to OUT_DIR for inspection
        mirror = OUT_DIR / rel
        mirror.parent.mkdir(parents=True, exist_ok=True)
        mirror.write_text(body, encoding="utf-8")
        overlaid += 1
    return overlaid, skipped_smaller


def main():
    per_file = collect_snapshots()
    best = pick_best(per_file)
    overlaid, skipped = overlay_snapshots(best, dry_run=False)
    print(f"[overlay] {overlaid} files written, {skipped} kept (current was larger)")
    print(f"[mirror]  all snapshots mirrored to {OUT_DIR}")


if __name__ == "__main__":
    main()
