#!/usr/bin/env python3
# Partial Snapshot Overlay
#
# For each project file, walk all exec_command reads in the Codex sessions.
# Build a per-file timeline of "evidence windows":
#     (timestamp, start_line, end_line, content_lines)
# For each line position in the file, the LATEST window covering that line
# wins. Stitch the latest evidence into the file.
#
# Patterns recognized:
#   - sed -n 'N,Mp' path                      (range N..M)
#   - sed -n '1,$p' path                       (full)
#   - cat path, cat -n path                    (full)
#   - nl path, nl -ba path                     (full, with line numbers)
#   - nl -ba path | sed -n 'N,Mp'              (range N..M, line numbers)
#   - head -n N path                           (1..N or shorter if EOF)
#   - cd <dir> && <one of the above>           (cd is dropped)
#
# Strategy is conservative: only overlay lines, never extend the file
# beyond its current length. Latest timestamp per line wins.

import json
import re
from pathlib import Path
from collections import defaultdict

CODEX_SESSIONS = Path.home() / ".codex" / "sessions"
TARGET_CWD = "/Users/timo/ceo_os"
PROJECT_ROOT = Path(TARGET_CWD)


def normalize_path(p):
    if not p:
        return p
    prefix = TARGET_CWD + "/"
    if p.startswith(prefix):
        p = p[len(prefix):]
    return p.lstrip("/")


# Multiple read patterns. Each is matched against a single command segment.
# Returns (path, start_or_None, end_or_None, has_line_numbers).
READ_PATTERNS = [
    # nl -ba path | sed -n 'N,Mp'
    (re.compile(
        r"^\s*nl(?:\s+-\w+)?\s+(\S+)\s*\|\s*sed\s+-n\s+'(\d+)\s*,\s*(\d+)\s*p'\s*$"),
     lambda m: (m.group(1), int(m.group(2)), int(m.group(3)), True)),
    # sed -n 'N,Mp' path
    (re.compile(r"^\s*sed\s+-n\s+'(\d+)\s*,\s*(\d+)\s*p'\s+(\S+)\s*$"),
     lambda m: (m.group(3), int(m.group(1)), int(m.group(2)), False)),
    # sed -n '1,$p' path
    (re.compile(r"^\s*sed\s+-n\s+'1,\$p'\s+(\S+)\s*$"),
     lambda m: (m.group(1), 1, None, False)),
    # head -n N path
    (re.compile(r"^\s*head\s+-n\s+(\d+)\s+(\S+)\s*$"),
     lambda m: (m.group(2), 1, int(m.group(1)), False)),
    # head path
    (re.compile(r"^\s*head\s+(\S+)\s*$"),
     lambda m: (m.group(1), 1, 10, False)),
    # tail -n N path
    (re.compile(r"^\s*tail\s+-n\s+(\d+)\s+(\S+)\s*$"),
     lambda m: (m.group(2), -int(m.group(1)), None, False)),  # -N means last N
    # cat -n path
    (re.compile(r"^\s*cat\s+-n\s+(\S+)\s*$"),
     lambda m: (m.group(1), 1, None, True)),
    # nl path / nl -ba path
    (re.compile(r"^\s*nl(?:\s+-\w+)?\s+(\S+)\s*$"),
     lambda m: (m.group(1), 1, None, True)),
    # cat path
    (re.compile(r"^\s*cat\s+(\S+)\s*$"),
     lambda m: (m.group(1), 1, None, False)),
]


def parse_command_segments(cmd):
    """Yield read segments from a possibly-chained command."""
    # Strip a leading cd
    cmd = re.sub(r"^\s*cd\s+\S+\s*&&\s*", "", cmd.strip())
    # Split on && or ;  (top-level only — naive)
    for seg in re.split(r"\s*(?:&&|;)\s*", cmd):
        seg = seg.strip()
        if not seg:
            continue
        # Strip "| cat" tail (common for paging)
        seg = re.sub(r"\s*\|\s*cat\s*$", "", seg)
        for pat, builder in READ_PATTERNS:
            m = pat.match(seg)
            if m:
                yield builder(m), seg
                break


def strip_line_numbers(text):
    out = []
    for line in text.split("\n"):
        s = re.sub(r"^\s*\d+\t", "", line)
        if s == line:
            s = re.sub(r"^\s*\d+\s{2,}", "", line)
        out.append(s)
    return "\n".join(out)


def extract_body(output_text):
    if not output_text or "Process exited with code 0" not in output_text:
        return None
    ix = output_text.find("\nOutput:")
    if ix == -1:
        return None
    body = output_text[ix + len("\nOutput:"):]
    if body.startswith("\n"):
        body = body[1:]
    if "truncated" in output_text.lower():
        return None
    return body


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


def collect_windows():
    """Return path -> list of (ts, start, end, lines)."""
    pending = {}
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

    print(f"[walk] {len(pending)} exec_command calls")
    windows = defaultdict(list)
    for cid, (ts, cmd) in pending.items():
        out = outputs.get(cid, "")
        body = extract_body(out)
        if body is None:
            continue
        # When a command has multiple read segments, the stdout is
        # concatenated. We can't reliably split. So:
        #  - if there's only ONE read segment, attribute the full body.
        #  - if there are MULTIPLE, skip — too ambiguous.
        segs = list(parse_command_segments(cmd))
        if len(segs) != 1:
            continue
        (path, start, end, has_nums), _seg = segs[0]
        rel = normalize_path(path.strip("'\""))
        if not rel:
            continue
        # Restrict to project source files
        if not rel.startswith(("lib/", "android/", "ios/", "test/",
                                "packages/", "docs/", "scripts/")):
            continue
        if has_nums:
            body = strip_line_numbers(body)
        body = body.rstrip("\n")
        line_list = body.split("\n") if body else []
        # If `start` is negative, it's a tail — we don't know the absolute
        # start without knowing file size. Skip these.
        if start is None or start < 0:
            continue
        # If end is None or beyond the actual line count, the read reached
        # EOF, so end = start + len - 1.
        actual_end = start + len(line_list) - 1
        windows[rel].append((ts, start, actual_end, line_list))
    print(f"[walk] {len(windows)} files have read windows")
    return windows


def stitch(rel_path: str, windows: list):
    """Find the LATEST full-file snapshot (EOF hit, range or no-range
       cmd) and return (content, line_count_replaced). Skip partial reads
       because line numbers drift across time.

       A snapshot is "full" if:
         - no range was claimed (cat/nl/sed -n '1,$p') AND it has content,
         - OR a range '1,Np' was claimed but fewer than N lines came back
           (EOF reached).

       Conservative: only return if the snapshot has >= 90% of the current
       file's line count (otherwise it represents an early/regressed state
       we shouldn't restore)."""
    target = PROJECT_ROOT / rel_path
    if not target.exists():
        return None, 0
    cur = target.read_text(encoding="utf-8", errors="replace")
    cur_n = cur.count("\n")

    # Score snapshots, latest first
    full_candidates = []
    for ts, start, end, lines in windows:
        n_lines = len(lines)
        # was the read range claim? we encoded it in (start, end, lines):
        # if start==1 and the original cmd said 1,Np with N specified, we
        # encoded end = start + len - 1 = n_lines. So we can't tell from
        # (start, end) alone whether end was claimed N or computed.
        # As a proxy: a snapshot is "likely full" if the body ends with a
        # line that looks like a top-level close: `}` at column 0, or empty.
        last = lines[-1].rstrip() if lines else ""
        likely_full = (start == 1 and (last == "}" or last == ""
                                       or last.startswith("//")))
        # Reject snapshots much smaller than current file
        if n_lines < int(0.9 * max(1, cur_n)):
            continue
        if not likely_full:
            continue
        full_candidates.append((ts, n_lines, lines))

    if not full_candidates:
        return None, 0

    full_candidates.sort()
    ts, n_lines, lines = full_candidates[-1]
    new_text = "\n".join(lines)
    if not new_text.endswith("\n"):
        new_text += "\n"
    if new_text == cur:
        return None, 0
    return new_text, n_lines


def get_files_with_errors():
    """Run flutter analyze and return set of files (rel paths) with >= 1 error."""
    import subprocess
    r = subprocess.run(["flutter", "analyze"], cwd=PROJECT_ROOT,
                       capture_output=True, text=True, timeout=180)
    out = r.stdout + "\n" + r.stderr
    files = set()
    for line in out.splitlines():
        m = re.match(r"\s*error\s+•\s+.+\s+•\s+(\S+):\d+:\d+\s+•", line)
        if m:
            files.add(m.group(1).strip())
    return files


def main():
    print("Step 1: identify files that currently have analyzer errors...")
    broken = get_files_with_errors()
    print(f"  {len(broken)} files have errors")
    print("Step 2: collect snapshot windows from sessions...")
    windows = collect_windows()
    overlaid = 0
    total_lines = 0
    print("Step 3: overlay full-file snapshots ONLY for files that are broken now...")
    for rel, ws in windows.items():
        if rel not in broken:
            continue
        result, n = stitch(rel, ws)
        if result is not None and n > 0:
            (PROJECT_ROOT / rel).write_text(result, encoding="utf-8")
            print(f"  + {rel}: {n} lines refreshed from snapshots")
            overlaid += 1
            total_lines += n
    print(f"\nDone. {overlaid} broken files updated, {total_lines} lines refreshed.")


if __name__ == "__main__":
    main()
