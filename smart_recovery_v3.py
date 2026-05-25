#!/usr/bin/env python3
# Smart Recovery v3 - Codex session reconstruction.
#
# Goal: rebuild every file Codex touched at its FINAL post-2-months state,
# without modifying the working tree. Output lands in a separate directory.
#
# Strategy:
#   1. Walk all Codex sessions, keep events whose cwd == project root.
#   2. Pair every apply_patch call with its output. Keep only successes.
#   3. Dedupe by call_id (sessions sometimes overlap or are reloaded).
#   4. Parse each patch into per-file Add/Update/Delete ops with normalized
#      project-relative paths.
#   5. Group ops by file, sort by (timestamp, session_path, event_idx).
#   6. For each file, try MULTIPLE baselines (HEAD~1, HEAD, empty, working
#      tree) and replay all ops on top. Score each candidate. Keep the best.
#   7. Apply hunks with a 6-strategy fuzzy matcher (exact -> rtrim -> stripped
#      with indent preserve -> indent-shifted -> already-applied -> unique
#      anchor).
#   8. Normalize line endings + smart quotes before matching so trivial
#      formatting differences never cause a miss.
#   9. Write output to ~/ceo_os/smart_recovery_v3/ and a detailed report.
#
# Nothing in the project working tree is modified.

import json
import re
import shlex
import subprocess
import sys
from pathlib import Path
from collections import defaultdict

# ---------- Configuration ----------

CODEX_SESSIONS = Path.home() / ".codex" / "sessions"
TARGET_CWD = "/Users/timo/ceo_os"
PROJECT_ROOT = Path(TARGET_CWD)
OUTPUT_DIR = Path.home() / "ceo_os" / "smart_recovery_v3"
REPORT_PATH = Path.home() / "ceo_os" / "smart_recovery_v3_report.txt"
BASELINE_REFS = ["a57ee06", "179e501", "HEAD"]  # dev baseline, pass-1, current

SMART_QUOTES = {
    "‘": "'", "’": "'",
    "“": '"', "”": '"',
}

# Files to skip entirely (binaries, lockfiles, large derived state)
SKIP_SUFFIXES = {".png", ".jpg", ".jpeg", ".gif", ".webp", ".ico",
                 ".pdf", ".zip", ".tar", ".gz", ".jar", ".so", ".dylib"}


# ---------- Normalization ----------

def normalize_path(p):
    if not p:
        return p
    prefix = TARGET_CWD + "/"
    if p.startswith(prefix):
        p = p[len(prefix):]
    return p.lstrip("/")


def normalize_text(text):
    """Stable text shape for matching: LF endings + ASCII quotes."""
    if text is None:
        return None
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    for s, a in SMART_QUOTES.items():
        if s in text:
            text = text.replace(s, a)
    return text


# ---------- Session walking ----------

def iter_session_events():
    """Yield (timestamp, session_path, idx, event) for every event in a
       session whose cwd is the project root."""
    sessions = sorted(CODEX_SESSIONS.rglob("rollout-*.jsonl"))
    print(f"[scan] {len(sessions)} session files")
    for path in sessions:
        cwd = None
        try:
            with open(path, "r", encoding="utf-8", errors="replace") as f:
                for idx, line in enumerate(f):
                    try:
                        e = json.loads(line.strip())
                    except Exception:
                        continue
                    if e.get("type") == "session_meta":
                        cwd = e.get("payload", {}).get("cwd")
                        if cwd != TARGET_CWD:
                            break
                    if cwd == TARGET_CWD:
                        yield e.get("timestamp", ""), str(path), idx, e
        except Exception as exc:
            print(f"[scan] skip {path.name}: {exc}")


# ---------- Patch collection ----------

def is_success_output(text):
    if not text:
        return False
    return ("Success" in text
            or '"exit_code":0' in text
            or '"exit_code": 0' in text
            or "Process exited with code 0" in text
            or "exited with code 0" in text)


def collect_patches():
    """Return [(sort_key, call_id, patch_text)] for every successful apply_patch.
       Deduped by call_id (earliest occurrence wins)."""
    pending = {}        # call_id -> (sort_key, patch_text)
    success_ids = set()
    for ts, sess, idx, e in iter_session_events():
        if e.get("type") != "response_item":
            continue
        p = e.get("payload", {})
        ptype = p.get("type", "")
        if ptype == "custom_tool_call" and p.get("name") == "apply_patch":
            cid = p.get("call_id", "")
            inp = p.get("input", "")
            if cid and inp:
                sk = (ts, sess, idx)
                if cid not in pending or sk < pending[cid][0]:
                    pending[cid] = (sk, inp)
        elif ptype == "custom_tool_call_output":
            cid = p.get("call_id", "")
            if cid and is_success_output(p.get("output", "")):
                success_ids.add(cid)
    out = [(sk, cid, text) for cid, (sk, text) in pending.items()
           if cid in success_ids]
    out.sort(key=lambda x: x[0])
    print(f"[patches] {len(out)} unique successful patches")
    return out


# ---------- Shell-based file writes ----------

# `cat > path <<['"]?TAG['"]?\n ... \nTAG`   (overwrite)
# `cat >> path <<['"]?TAG['"]?\n ... \nTAG`  (append)
# `cat <<['"]?TAG['"]?\n ... \nTAG > path`   (less common, redirect after)
HEREDOC_OUT_FIRST = re.compile(
    r"cat\s*(>>?)\s*(\S+)\s*<<-?\s*['\"]?([A-Za-z_][A-Za-z0-9_]*)['\"]?\s*\n"
    r"(.*?)\n\3\s*(?:\n|$)",
    re.DOTALL,
)
HEREDOC_REDIR_LAST = re.compile(
    r"cat\s*<<-?\s*['\"]?([A-Za-z_][A-Za-z0-9_]*)['\"]?\s*(>>?)\s*(\S+)\s*\n"
    r"(.*?)\n\1\s*(?:\n|$)",
    re.DOTALL,
)


def extract_heredoc_writes(cmd_text):
    """Yield (mode, path, content) tuples. mode is 'overwrite' or 'append'."""
    if not cmd_text or "cat" not in cmd_text or "<<" not in cmd_text:
        return
    for m in HEREDOC_OUT_FIRST.finditer(cmd_text):
        redir, path, _tag, body = m.group(1), m.group(2), m.group(3), m.group(4)
        mode = "append" if redir == ">>" else "overwrite"
        content = body if body.endswith("\n") else body + "\n"
        yield mode, path.strip("\"'"), content
    for m in HEREDOC_REDIR_LAST.finditer(cmd_text):
        _tag, redir, path, body = m.group(1), m.group(2), m.group(3), m.group(4)
        mode = "append" if redir == ">>" else "overwrite"
        content = body if body.endswith("\n") else body + "\n"
        yield mode, path.strip("\"'"), content


def collect_shell_writes():
    """Walk sessions and yield synthetic ops representing file writes done
       through shell tools (cat <<EOF, etc.). Successes only."""
    pending = {}   # call_id -> (sort_key, cmd_text)
    success_ids = set()
    for ts, sess, idx, e in iter_session_events():
        if e.get("type") != "response_item":
            continue
        p = e.get("payload", {})
        ptype = p.get("type", "")
        name = p.get("name", "")
        if (ptype in ("custom_tool_call", "function_call")
                and name in ("shell", "local_shell", "container.exec",
                             "exec_command", "bash")):
            cid = p.get("call_id", "")
            raw = p.get("input", "") or p.get("arguments", "")
            if not (cid and raw):
                continue
            cmd_text = ""
            try:
                obj = json.loads(raw)
                if isinstance(obj, dict):
                    cmd_text = obj.get("cmd", "")
                    if not cmd_text and isinstance(obj.get("command"), list):
                        # ["bash", "-lc", "..."] form
                        cmd_text = " ".join(obj["command"][-1:])
            except Exception:
                cmd_text = raw
            if "cat" in cmd_text and "<<" in cmd_text:
                pending[cid] = ((ts, sess, idx), cmd_text)
        elif ptype in ("custom_tool_call_output", "function_call_output"):
            cid = p.get("call_id", "")
            if cid and is_success_output(p.get("output", "")):
                success_ids.add(cid)

    synth_events = []   # (sort_key, op)
    for cid, (sk, cmd_text) in pending.items():
        if cid not in success_ids:
            continue
        for mode, raw_path, content in extract_heredoc_writes(cmd_text):
            rel = normalize_path(raw_path)
            if not rel:
                continue
            if mode == "overwrite":
                synth_events.append((sk, {
                    "action": "add",
                    "path": rel,
                    "content": content,
                    "_origin": "shell",
                }))
            else:  # append: emit a synthetic update that appends.
                # Encode as an update with no expected (pure addition).
                lines = content.split("\n")
                hunk = [f"+{l}" for l in lines]
                synth_events.append((sk, {
                    "action": "update",
                    "path": rel,
                    "hunks": [hunk],
                    "_origin": "shell-append",
                }))
    print(f"[shell] {len(synth_events)} synthetic file writes from heredocs")
    return synth_events


# A single, full-file read: `[cd <dir> && ] cat <path>` (no pipes/redirects).
CAT_FULL_RE = re.compile(
    r"^\s*(?:cd\s+\S+\s*&&\s*)?cat\s+([^\s|;><]+)\s*$"
)


def _extract_exec_stdout(output_text):
    """Pull the stdout payload from an exec_command output blob."""
    if not output_text:
        return None
    # Header looks like:
    #   Chunk ID: ...
    #   Wall time: ...
    #   Process exited with code 0
    #   Original token count: ...
    #   Output:
    #   <stdout>
    ix = output_text.find("\nOutput:")
    if ix == -1:
        return None
    body = output_text[ix + len("\nOutput:"):]
    # Drop a single leading newline if present, keep the rest verbatim.
    if body.startswith("\n"):
        body = body[1:]
    # Skip if the output was truncated (Codex marks it).
    low = output_text.lower()
    if "truncated" in low or "[output truncated]" in low:
        return None
    return body


def collect_file_snapshots():
    """Find exec_command calls that read a full file via plain `cat <path>`.
       Return synthetic Add ops at the read's timestamp."""
    pending = {}   # call_id -> (sort_key, cmd_text)
    outputs = {}
    for ts, sess, idx, e in iter_session_events():
        if e.get("type") != "response_item":
            continue
        p = e.get("payload", {})
        ptype = p.get("type", "")
        name = p.get("name", "")
        if ptype == "function_call" and name == "exec_command":
            cid = p.get("call_id", "")
            raw = p.get("input", "") or p.get("arguments", "")
            cmd = ""
            try:
                obj = json.loads(raw)
                if isinstance(obj, dict):
                    cmd = obj.get("cmd", "")
            except Exception:
                cmd = raw
            if cid and cmd:
                pending[cid] = ((ts, sess, idx), cmd)
        elif ptype == "function_call_output":
            cid = p.get("call_id", "")
            if cid:
                outputs[cid] = p.get("output", "")

    snaps = []
    for cid, (sk, cmd) in pending.items():
        m = CAT_FULL_RE.match(cmd.strip())
        if not m:
            continue
        raw_path = m.group(1).strip("'\"")
        rel = normalize_path(raw_path)
        if not rel:
            continue
        out = outputs.get(cid, "")
        if "Process exited with code 0" not in out:
            continue
        body = _extract_exec_stdout(out)
        if body is None:
            continue
        snaps.append((sk, {
            "action": "add",
            "path": rel,
            "content": body if body.endswith("\n") or not body else body + "\n",
            "_origin": "snapshot",
        }))
    print(f"[snapshots] {len(snaps)} full-file read snapshots")
    return snaps


# ---------- Patch parsing ----------

def parse_patch(text):
    """Parse Codex apply_patch text into a list of ops."""
    ops = []
    cur = None
    buf = []
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
            if cur is not None:
                cur["_raw"] = buf
                ops.append(cur)
            cur = {"action": "add",
                   "path": normalize_path(line[len("*** Add File:"):].strip())}
            buf = []
            continue
        if line.startswith("*** Update File:"):
            if cur is not None:
                cur["_raw"] = buf
                ops.append(cur)
            cur = {"action": "update",
                   "path": normalize_path(line[len("*** Update File:"):].strip())}
            buf = []
            continue
        if line.startswith("*** Delete File:"):
            if cur is not None:
                cur["_raw"] = buf
                ops.append(cur)
            cur = {"action": "delete",
                   "path": normalize_path(line[len("*** Delete File:"):].strip())}
            buf = []
            continue
        if line.startswith("*** Move to:"):
            if cur is not None and cur.get("action") == "update":
                cur["move_to"] = normalize_path(
                    line[len("*** Move to:"):].strip())
            continue
        if cur is not None:
            buf.append(line)
    if cur is not None and "_raw" not in cur:
        cur["_raw"] = buf
        ops.append(cur)

    for op in ops:
        raw = op.pop("_raw", [])
        if op["action"] == "add":
            content_lines = []
            for l in raw:
                if l.startswith("+"):
                    content_lines.append(l[1:])
                elif l.strip() == "":
                    content_lines.append("")
            content = "\n".join(content_lines)
            if content and not content.endswith("\n"):
                content += "\n"
            op["content"] = content
        elif op["action"] == "update":
            op["hunks"] = split_hunks(raw)
    return ops


def split_hunks(raw):
    hunks = []
    cur = []
    for l in raw:
        if l.startswith("@@"):
            if cur:
                hunks.append(cur)
            cur = []
        else:
            cur.append(l)
    if cur:
        hunks.append(cur)
    return hunks


def parse_hunk(hunk_lines):
    """Return (expected_lines, replacement_lines)."""
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


# ---------- Fuzzy matching ----------

def _find(lines, expected, transform):
    """Generic finder using a per-line transform (None for identity).
       Returns ALL matching indices."""
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
    """Return the unique index where expected matches, or None."""
    hits = _find(lines, expected, transform)
    return hits[0] if len(hits) == 1 else None


def find_first(lines, expected, transform=None):
    hits = _find(lines, expected, transform)
    return hits[0] if hits else None


def detect_indent_offset(file_lines, expected):
    """If expected matches file_lines whitespace-insensitively, return the
       common indent offset (file_indent - expected_indent). Else None."""
    offsets = []
    for f, e in zip(file_lines, expected):
        if not e.strip() and not f.strip():
            continue
        if e.strip() != f.strip():
            return None
        fi = len(f) - len(f.lstrip())
        ei = len(e) - len(e.lstrip())
        offsets.append(fi - ei)
    if not offsets:
        return 0
    if all(o == offsets[0] for o in offsets):
        return offsets[0]
    return None


def shift_indent(line, offset):
    if not line.strip() or offset == 0:
        return line
    if offset > 0:
        return " " * offset + line
    cur = len(line) - len(line.lstrip())
    drop = min(-offset, cur)
    return line[drop:]


def apply_hunk(lines, hunk):
    """Apply ONE hunk to `lines` using progressive fuzzy strategies.
       Returns (new_lines, applied: bool, strategy: str)."""
    expected, replacement = parse_hunk(hunk)

    # Pure additions: append to end.
    if not expected:
        return lines + replacement, True, "append"

    # Strategy 1: exact match.
    idx = find_unique(lines, expected) if False else find_first(lines, expected)
    if idx is not None:
        return lines[:idx] + replacement + lines[idx+len(expected):], True, "exact"

    # Strategy 2: rtrim (trailing whitespace).
    idx = find_first(lines, expected, transform=lambda l: l.rstrip())
    if idx is not None:
        return lines[:idx] + replacement + lines[idx+len(expected):], True, "rtrim"

    # Strategy 3: whitespace-insensitive with indent preservation.
    idx = find_first(lines, expected, transform=lambda l: l.strip())
    if idx is not None:
        n = len(expected)
        off = detect_indent_offset(lines[idx:idx+n], expected)
        if off is None:
            off = 0
        new_rep = [shift_indent(r, off) for r in replacement]
        return lines[:idx] + new_rep + lines[idx+n:], True, "strip+indent"

    # Strategy 4: already-applied (replacement already at expected location).
    if (find_first(lines, replacement) is not None
            or find_first(lines, replacement, transform=lambda l: l.strip()) is not None):
        return lines, True, "already"

    # Strategy 5: largest unique substring of expected as anchor.
    n = len(expected)
    for sublen in range(min(n, 8), 1, -1):  # cap search at sublen=8 for speed
        for start in range(n - sublen + 1):
            anchor = expected[start:start+sublen]
            # Prefer rtrim-matching for the anchor.
            hits = _find(lines, anchor, transform=lambda l: l.rstrip())
            if len(hits) == 1:
                anchor_idx = hits[0]
                exp_start = anchor_idx - start
                # Validate full expected fits and matches rtrim
                if 0 <= exp_start and exp_start + n <= len(lines):
                    cand = lines[exp_start:exp_start+n]
                    if [l.rstrip() for l in cand] == [e.rstrip() for e in expected]:
                        return (lines[:exp_start] + replacement + lines[exp_start+n:],
                                True, f"anchor{sublen}")
                # Partial anchor only — would risk inserting garbage. Skip.
    return lines, False, "skip"


def apply_hunks(state, hunks):
    """Apply all hunks of an update op to the given state. Returns
       (new_state, applied_count, skipped_count)."""
    if state is None:
        state = ""
    lines = state.split("\n")
    applied = 0
    skipped = 0
    for h in hunks:
        lines, ok, _strategy = apply_hunk(lines, h)
        if ok:
            applied += 1
        else:
            skipped += 1
    return "\n".join(lines), applied, skipped


# ---------- Baseline loaders ----------

def make_git_loader(ref):
    cache = {}
    def load(rel):
        if rel in cache:
            return cache[rel]
        try:
            r = subprocess.run(
                ["git", "-C", str(PROJECT_ROOT), "show", f"{ref}:{rel}"],
                capture_output=True, timeout=15,
            )
            if r.returncode == 0:
                cache[rel] = r.stdout.decode("utf-8", errors="replace")
                return cache[rel]
        except Exception:
            pass
        cache[rel] = None
        return None
    return load


def disk_loader(rel):
    full = PROJECT_ROOT / rel
    try:
        return full.read_text(encoding="utf-8", errors="replace")
    except Exception:
        return None


# ---------- Replay ----------

def replay(path, ops, baseline_provider):
    """Run all ops in order. baseline_provider is either a callable
       (path -> content_or_None) or the string "empty" or None for ops
       whose first action is 'add'."""
    state = None
    deleted = False
    seeded = False
    adds = updates = applied = skipped = 0
    moves = []
    for sort_key, op in ops:
        action = op["action"]
        if action == "add":
            state = normalize_text(op.get("content", ""))
            deleted = False
            adds += 1
        elif action == "update":
            if state is None and not deleted:
                base = None
                if baseline_provider == "empty":
                    base = ""
                elif callable(baseline_provider):
                    base = baseline_provider(path)
                state = normalize_text(base) if base is not None else ""
                seeded = base is not None
            if state is None:
                continue
            new_state, a, s = apply_hunks(state, op.get("hunks", []))
            state = new_state
            applied += a
            skipped += s
            updates += 1
            if op.get("move_to"):
                moves.append(op["move_to"])
        elif action == "delete":
            state = None
            deleted = True
    return state, {
        "deleted": deleted,
        "seeded": seeded,
        "adds": adds,
        "updates": updates,
        "applied": applied,
        "skipped": skipped,
        "moves": moves,
    }


def score_candidate(stats, state):
    """Higher is better. Maximize applied, minimize skipped, then content length."""
    return (
        stats["applied"],
        -stats["skipped"],
        len(state) if state else 0,
    )


def reconstruct_files(all_ops):
    by_path = defaultdict(list)
    for sk, op in all_ops:
        by_path[op["path"]].append((sk, op))
    for p in by_path:
        by_path[p].sort(key=lambda x: x[0])

    print(f"[group] {len(by_path)} unique paths")

    loaders = [(ref, make_git_loader(ref)) for ref in BASELINE_REFS]
    results = {}
    total = len(by_path)
    for i, (path, ops) in enumerate(by_path.items(), 1):
        if i % 50 == 0:
            print(f"[replay] {i}/{total}")

        # Skip binaries.
        if any(path.endswith(suf) for suf in SKIP_SUFFIXES):
            continue

        first_action = ops[0][1]["action"]
        candidates = []
        if first_action == "add":
            state, stats = replay(path, ops, None)
            candidates.append(("(none)", state, stats))
        else:
            for ref, loader in loaders:
                state, stats = replay(path, ops, loader)
                candidates.append((ref, state, stats))
            # Also try working-tree disk + empty
            state, stats = replay(path, ops, disk_loader)
            candidates.append(("disk", state, stats))
            state, stats = replay(path, ops, "empty")
            candidates.append(("empty", state, stats))

        best = max(candidates, key=lambda c: score_candidate(c[2], c[1]))
        ref, state, stats = best
        stats["baseline"] = ref
        stats["op_count"] = len(ops)
        # Also keep per-baseline summary for the report
        stats["candidates"] = {c[0]: (c[2]["applied"], c[2]["skipped"])
                               for c in candidates}
        results[path] = {"state": state, **stats}
    return results


# ---------- Output ----------

def write_output(results):
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    written = deleted = empty = 0
    for path, info in results.items():
        if info["deleted"] or info["state"] is None:
            deleted += 1
            continue
        if not info["state"].strip():
            empty += 1
        out = OUTPUT_DIR / path
        out.parent.mkdir(parents=True, exist_ok=True)
        try:
            out.write_text(info["state"], encoding="utf-8")
            written += 1
        except Exception as exc:
            print(f"[write] fail {path}: {exc}")
    return written, deleted, empty


def write_report(results, written, deleted, empty):
    L = []
    L.append("Smart Recovery v3 Report")
    L.append(f"Output:  {OUTPUT_DIR}")
    L.append(f"Files written:  {written}")
    L.append(f"Files deleted:  {deleted}")
    L.append(f"Files empty:    {empty}")
    L.append("")

    total_a = sum(r["applied"] for r in results.values())
    total_s = sum(r["skipped"] for r in results.values())
    rate = total_a / (total_a + total_s) * 100 if (total_a + total_s) else 0
    L.append(f"Total hunks applied:  {total_a}")
    L.append(f"Total hunks skipped:  {total_s}")
    L.append(f"Overall apply rate:   {rate:.1f}%")
    L.append("")

    bl_counts = defaultdict(int)
    for r in results.values():
        bl_counts[r["baseline"]] += 1
    L.append("Files per chosen baseline:")
    for b, n in sorted(bl_counts.items()):
        L.append(f"  {b:8s}: {n}")
    L.append("")

    L.append("Files with skipped > 0, sorted by skipped desc (top 80):")
    s_files = sorted(results.items(),
                     key=lambda kv: kv[1]["skipped"], reverse=True)
    L.append(f"{'skip':>5} {'appl':>5} {'upd':>4} {'adds':>4}  base     candidates                  path")
    for path, info in s_files[:80]:
        if info["skipped"] == 0:
            break
        cands = info.get("candidates", {})
        cstr = " ".join(f"{k}:{v[0]}/{v[1]}" for k, v in cands.items())
        L.append(f"{info['skipped']:5d} {info['applied']:5d} "
                 f"{info['updates']:4d} {info['adds']:4d}  "
                 f"{info['baseline']:8s} {cstr:30s} {path}")
    L.append("")

    L.append("Files with 100% apply (sample, first 30):")
    clean = [p for p, r in results.items()
             if r["skipped"] == 0 and not r["deleted"]
             and r["state"] and r["state"].strip()]
    for p in sorted(clean)[:30]:
        L.append(f"  {p}")
    L.append(f"  (total clean files: {len(clean)})")

    REPORT_PATH.write_text("\n".join(L), encoding="utf-8")


# ---------- Main ----------

def main():
    patches = collect_patches()
    all_ops = []
    for sk, cid, text in patches:
        try:
            for op in parse_patch(text):
                all_ops.append((sk, op))
        except Exception as exc:
            print(f"[parse] skip {cid}: {exc}")
    print(f"[parse] {len(all_ops)} per-file operations from apply_patch")

    # Merge synthetic ops from shell heredoc writes (e.g., `cat > file <<EOF`).
    shell_ops = collect_shell_writes()
    all_ops.extend(shell_ops)
    # Merge synthetic Add ops from full-file `cat <path>` reads in sessions.
    snap_ops = collect_file_snapshots()
    all_ops.extend(snap_ops)
    all_ops.sort(key=lambda x: x[0])
    print(f"[parse] {len(all_ops)} total ops after merging shell writes + snapshots")

    results = reconstruct_files(all_ops)
    print(f"[replay] {len(results)} unique files reconstructed")

    written, deleted, empty = write_output(results)
    print(f"[write] {written} files, {deleted} deleted, {empty} empty")

    write_report(results, written, deleted, empty)
    print(f"[report] {REPORT_PATH}")
    print()
    print("Output directory:", OUTPUT_DIR)
    print("No file in the working tree was modified.")


if __name__ == "__main__":
    main()
