#!/usr/bin/env python3
# Pass 3 Recovery - symbol-level reconstruction on top of pass-2.
#
# Goal: bring the recovered codebase to compilation-readiness by extracting
# every top-level symbol definition (class, enum, extension, mixin, typedef,
# static field/getter/method) from Codex session history, finding the latest
# version of each, and injecting any missing ones into their host files.
#
# Plus, for files in extra-bad shape, replay against the LATEST patch's
# post-state as an alternative baseline.
#
# Modifies the working tree in place. Writes a detailed report.

import json
import re
import subprocess
import sys
from pathlib import Path
from collections import defaultdict

CODEX_SESSIONS = Path.home() / ".codex" / "sessions"
TARGET_CWD = "/Users/timo/ceo_os"
PROJECT_ROOT = Path(TARGET_CWD)
REPORT_PATH = PROJECT_ROOT / "pass3_report.txt"

SMART_QUOTES = {"‘": "'", "’": "'", "“": '"', "”": '"'}


# ---------- Session loading (mirrors v3) ----------

def iter_session_events():
    for path in sorted(CODEX_SESSIONS.rglob("rollout-*.jsonl")):
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


def is_success_output(text):
    if not text:
        return False
    return ("Success" in text
            or '"exit_code":0' in text or '"exit_code": 0' in text
            or "Process exited with code 0" in text)


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


def collect_patches():
    pending, success = {}, set()
    for ts, sess, idx, e in iter_session_events():
        if e.get("type") != "response_item":
            continue
        p = e.get("payload", {})
        ptype, name = p.get("type", ""), p.get("name", "")
        if ptype == "custom_tool_call" and name == "apply_patch":
            cid = p.get("call_id", "")
            inp = p.get("input", "")
            if cid and inp:
                sk = (ts, sess, idx)
                if cid not in pending or sk < pending[cid][0]:
                    pending[cid] = (sk, inp)
        elif ptype == "custom_tool_call_output":
            cid = p.get("call_id", "")
            if cid and is_success_output(p.get("output", "")):
                success.add(cid)
    out = [(sk, cid, text) for cid, (sk, text) in pending.items() if cid in success]
    out.sort(key=lambda x: x[0])
    return out


# ---------- Patch parsing ----------

def parse_patch(text):
    """Yield ops with normalized paths. Same shape as v3."""
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
            if cur is not None:
                cur["_raw"] = buf
                ops.append(cur)
            cur = {"action": "add", "path": normalize_path(line[14:].strip())}
            buf = []
            continue
        if line.startswith("*** Update File:"):
            if cur is not None:
                cur["_raw"] = buf
                ops.append(cur)
            cur = {"action": "update", "path": normalize_path(line[17:].strip())}
            buf = []
            continue
        if line.startswith("*** Delete File:"):
            if cur is not None:
                cur["_raw"] = buf
                ops.append(cur)
            cur = {"action": "delete", "path": normalize_path(line[17:].strip())}
            buf = []
            continue
        if cur is not None:
            buf.append(line)
    if cur is not None and "_raw" not in cur:
        cur["_raw"] = buf
        ops.append(cur)

    for op in ops:
        raw = op.pop("_raw", [])
        if op["action"] == "add":
            content_lines = [l[1:] if l.startswith("+") else "" for l in raw
                             if l.startswith("+") or l.strip() == ""]
            content = "\n".join(content_lines)
            if content and not content.endswith("\n"):
                content += "\n"
            op["content"] = content
        elif op["action"] == "update":
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


def hunk_post_state(hunk):
    """Return the lines representing the file state AFTER this hunk's changes,
       for the lines covered by the hunk."""
    out = []
    for l in hunk:
        if l.startswith("+"):
            out.append(l[1:])
        elif l.startswith("-"):
            continue
        else:
            out.append(l[1:] if l.startswith(" ") else l)
    return out


# ---------- Symbol detection ----------

# Patterns matched at line start, after optional leading whitespace.
# Class-level statics live at depth 2 (within a class). Top-level at depth 0.
TOP_PATTERNS = [
    ("class",     re.compile(r"^\s*(?:abstract\s+|sealed\s+|final\s+|base\s+|interface\s+)?class\s+(\w+)\b")),
    ("enum",      re.compile(r"^\s*enum\s+(\w+)\b")),
    ("mixin",     re.compile(r"^\s*mixin\s+(\w+)\b")),
    ("extension", re.compile(r"^\s*extension\s+(\w+)\b")),
    ("typedef",   re.compile(r"^\s*typedef\s+(\w+)\b")),
]

# Class-level static patterns. These are detected anywhere a `static` line
# appears in the post-state window.
STATIC_GETTER = re.compile(r"^\s*static\s+(?:final\s+|const\s+)?\S[^=;]*?\s+get\s+(\w+)\s*[={]")
STATIC_FIELD = re.compile(
    r"^\s*static\s+(?:final\s+|const\s+|late\s+final\s+|late\s+)?[^=;]+?\s+(\w+)\s*=\s*"
)
STATIC_METHOD = re.compile(
    r"^\s*static\s+(?:Future<[^>]*>\s+|FutureOr<[^>]*>\s+|Stream<[^>]*>\s+|Iterable<[^>]*>\s+|List<[^>]*>\s+|Map<[^,]+,[^>]+>\s+|[A-Za-z_][\w<>?,]*\s+)(\w+)\s*\(.*\)\s*(?:async\s*)?\{"
)
TOP_FUNC = re.compile(
    r"^([A-Z]?\w+(?:<[^>]+>)?(?:\?)?)\s+(\w+)\s*\([^)]*\)\s*(?:async\s*)?[{=]"
)


def find_block_end(lines, start_idx):
    """Given start_idx points at a line containing '{', find the index of the
       matching '}'. Returns the index, or len(lines)-1 if unmatched."""
    depth = 0
    in_string = None  # delim char if inside string
    started = False
    for i in range(start_idx, len(lines)):
        line = lines[i]
        j = 0
        while j < len(line):
            c = line[j]
            if in_string is None:
                # Skip line comments
                if c == "/" and j + 1 < len(line) and line[j + 1] == "/":
                    break
                # Strings
                if c in ("'", '"'):
                    if (j + 2 < len(line)
                            and line[j + 1] == c and line[j + 2] == c):
                        # Triple-quoted: skip until matching triple
                        end = line.find(c * 3, j + 3)
                        if end == -1:
                            # Multi-line triple — find on subsequent lines
                            j = len(line)
                            in_string = c * 3
                            break
                        j = end + 3
                        continue
                    in_string = c
                    j += 1
                    continue
                if c == "{":
                    depth += 1
                    started = True
                elif c == "}":
                    depth -= 1
                    if started and depth == 0:
                        return i
            else:
                # Inside a string
                if in_string in ("'", '"'):
                    if c == "\\" and j + 1 < len(line):
                        j += 2
                        continue
                    if c == in_string:
                        in_string = None
                else:
                    # Triple-quoted multiline
                    if line[j:j + 3] == in_string:
                        j += 3
                        in_string = None
                        continue
            j += 1
        # End of line — if inside non-triple string, the string is broken;
        # treat as ended for robustness.
        if in_string in ("'", '"'):
            in_string = None
    return len(lines) - 1


def find_semicolon_end(lines, start_idx):
    """For single-statement definitions (e.g. `static Color get x => y;`),
       find the line ending with `;`."""
    for i in range(start_idx, min(start_idx + 30, len(lines))):
        if lines[i].rstrip().endswith(";"):
            return i
    return start_idx


def extract_definitions(window, source_file, ts):
    """Yield (kind, name, block_lines, source_file, ts) for every top-level
       or class-static symbol definition we find in this window."""
    n = len(window)
    i = 0
    while i < n:
        line = window[i]

        # Top-level constructs
        matched = False
        for kind, pat in TOP_PATTERNS:
            m = pat.match(line)
            if m and "{" in "".join(window[i:i + 6]):
                # Find the line with `{` (could be `class X\n  extends Y\n{`)
                brace_line = i
                while brace_line < n and "{" not in window[brace_line]:
                    brace_line += 1
                if brace_line >= n:
                    break
                end = find_block_end(window, brace_line)
                block = window[i:end + 1]
                yield kind, m.group(1), block, source_file, ts
                i = end + 1
                matched = True
                break
            if m and ";" in line and "{" not in line:
                # typedef X = ...;
                yield kind, m.group(1), [line], source_file, ts
                i += 1
                matched = True
                break
        if matched:
            continue

        # Class-static getter
        m = STATIC_GETTER.match(line)
        if m:
            if "=>" in line:
                end = find_semicolon_end(window, i)
                yield "static_getter", m.group(1), window[i:end + 1], source_file, ts
                i = end + 1
                continue
            if "{" in line:
                end = find_block_end(window, i)
                yield "static_getter", m.group(1), window[i:end + 1], source_file, ts
                i = end + 1
                continue

        # Class-static method
        m = STATIC_METHOD.match(line)
        if m:
            end = find_block_end(window, i)
            yield "static_method", m.group(1), window[i:end + 1], source_file, ts
            i = end + 1
            continue

        # Class-static field
        m = STATIC_FIELD.match(line)
        if m and "get " not in line[:line.find(m.group(1))]:
            end = find_semicolon_end(window, i)
            yield "static_field", m.group(1), window[i:end + 1], source_file, ts
            i = end + 1
            continue

        i += 1


# ---------- Build symbol database ----------

def build_symbol_db():
    print("[1/5] Collecting patches from sessions...")
    patches = collect_patches()
    print(f"      {len(patches)} successful patches")

    print("[2/5] Parsing patches into ops...")
    all_ops = []
    for sk, cid, text in patches:
        try:
            for op in parse_patch(text):
                all_ops.append((sk, op))
        except Exception:
            continue
    print(f"      {len(all_ops)} ops")

    print("[3/5] Extracting symbol definitions from every hunk's post-state...")
    # symbol_name -> list of (ts, kind, source_file, block_lines)
    db = defaultdict(list)
    for sk, op in all_ops:
        ts = sk[0]
        if op["action"] == "add":
            window = (op.get("content") or "").splitlines()
            for kind, name, block, src, t in extract_definitions(window, op["path"], ts):
                db[name].append((t, kind, src, block))
        elif op["action"] == "update":
            for hunk in op.get("hunks", []):
                window = hunk_post_state(hunk)
                for kind, name, block, src, t in extract_definitions(window, op["path"], ts):
                    db[name].append((t, kind, src, block))
    # Sort by timestamp ascending; latest will be last entry
    for k in db:
        db[k].sort(key=lambda r: r[0])
    print(f"      {len(db)} unique symbols indexed "
          f"({sum(len(v) for v in db.values())} definitions total)")
    return db


# ---------- Flutter analyze parsing ----------

ANALYZE_LINE = re.compile(
    r"^\s*error\s+•\s+(.+?)\s+•\s+(.+?):(\d+):(\d+)\s+•\s+(\w+)\s*$"
)


def run_flutter_analyze():
    print("[4/5] Running flutter analyze...")
    r = subprocess.run(
        ["flutter", "analyze"], cwd=PROJECT_ROOT,
        capture_output=True, text=True, timeout=180,
    )
    out = r.stdout + "\n" + r.stderr
    errors = []
    for ln in out.splitlines():
        m = ANALYZE_LINE.match(ln)
        if m:
            msg, fpath, line, col, code = m.groups()
            errors.append({
                "message": msg.strip(),
                "file": fpath.strip(),
                "line": int(line),
                "col": int(col),
                "code": code,
            })
    print(f"      {len(errors)} errors parsed")
    return errors


def extract_undefined_symbol(err):
    """Return the symbol name implicated by an error, or None."""
    msg = err["message"]
    # Common patterns
    patterns = [
        r"Undefined name '(\w+)'",
        r"Undefined class '(\w+)'",
        r"The getter '(\w+)' isn't defined",
        r"The setter '(\w+)' isn't defined",
        r"The method '(\w+)' isn't defined",
        r"The function '(\w+)' isn't defined",
        r"Undefined identifier '(\w+)'",
        r"Couldn't find constructor '(\w+)'",
        r"The name '(\w+)' is being referenced through the prefix",
        r"The named parameter '(\w+)' isn't defined",
    ]
    for p in patterns:
        m = re.search(p, msg)
        if m:
            return m.group(1)
    return None


# ---------- Injection ----------

def already_has_symbol(file_content, kind, name):
    """Heuristic: does the file already define this symbol?"""
    if kind in ("class", "enum", "mixin", "extension", "typedef"):
        return bool(re.search(rf"\b{re.escape(kind)}\s+{re.escape(name)}\b", file_content))
    if kind == "static_getter":
        return bool(re.search(rf"static\s+[^;\n]+\s+get\s+{re.escape(name)}\b", file_content))
    if kind == "static_field":
        return bool(re.search(
            rf"static\s+(?:final\s+|const\s+)?[^=;\n]+\s+{re.escape(name)}\s*=",
            file_content))
    if kind == "static_method":
        return bool(re.search(rf"static\s+[^;\n]+\s+{re.escape(name)}\s*\(",
                              file_content))
    return name in file_content


def find_class_close_position(content):
    """Return the index of the last `}` of the outermost class-like block,
       or len(content) if no class found."""
    # Find the last line that's `}` at column 0 — that's typically the close
    # of the outermost class.
    lines = content.split("\n")
    for i in range(len(lines) - 1, -1, -1):
        s = lines[i].rstrip()
        if s == "}":
            return i
    return len(lines)


def inject_into_class(file_path: Path, block_lines, comment_header="Recovered"):
    """Insert block_lines just before the closing `}` of the outermost class.
       Lines whose original indent is 0 get a 2-space prefix; otherwise kept."""
    content = file_path.read_text(encoding="utf-8")
    lines = content.split("\n")
    close = find_class_close_position(content)
    indented = []
    for l in block_lines:
        if not l:
            indented.append(l)
        elif l.startswith(" "):
            indented.append(l)
        else:
            indented.append("  " + l)
    if close >= len(lines):
        new_lines = lines + [""] + [f"// {comment_header}"] + indented
    else:
        new_lines = (lines[:close]
                     + ["", f"  // {comment_header}"]
                     + indented
                     + lines[close:])
    file_path.write_text("\n".join(new_lines), encoding="utf-8")


def inject_at_eof(file_path: Path, block_lines, comment_header="Recovered"):
    """Append block_lines at end of file. Block keeps its original indent
       (top-level constructs)."""
    content = file_path.read_text(encoding="utf-8")
    if not content.endswith("\n"):
        content += "\n"
    content += "\n" + f"// {comment_header}\n" + "\n".join(block_lines) + "\n"
    file_path.write_text(content, encoding="utf-8")


# ---------- Main pipeline ----------

def main():
    db = build_symbol_db()
    errors = run_flutter_analyze()

    # Collect unique missing symbols
    undefined = defaultdict(list)  # symbol -> list of error dicts
    for err in errors:
        name = extract_undefined_symbol(err)
        if name and name in db:
            undefined[name].append(err)

    print(f"[5/5] {len(undefined)} undefined symbols have candidates in DB")

    log_lines = ["Pass 3 Recovery Report", ""]
    injected = 0
    skipped_existing = 0
    skipped_no_target = 0
    rejected_extension_mismatch = 0

    for name in sorted(undefined.keys()):
        candidates = db[name]
        ts, kind, src_file, block = candidates[-1]  # latest

        src_path = PROJECT_ROOT / src_file
        if not src_path.exists():
            # Source file no longer exists — try ensuring extension matches
            if not src_file.endswith((".dart", ".kt", ".swift", ".java")):
                rejected_extension_mismatch += 1
                continue
            src_path.parent.mkdir(parents=True, exist_ok=True)
            src_path.write_text("", encoding="utf-8")

        cur = src_path.read_text(encoding="utf-8", errors="replace")
        if already_has_symbol(cur, kind, name):
            skipped_existing += 1
            continue

        # Inject. Strategy depends on kind.
        try:
            if kind in ("class", "enum", "mixin", "extension", "typedef"):
                inject_at_eof(src_path, block,
                              comment_header=f"Recovered {kind} {name} @ {ts}")
            elif kind in ("static_getter", "static_field", "static_method"):
                inject_into_class(src_path, block,
                                  comment_header=f"Recovered {kind} {name} @ {ts}")
            else:
                inject_at_eof(src_path, block,
                              comment_header=f"Recovered {kind} {name} @ {ts}")
            injected += 1
            log_lines.append(f"  + {kind:14s} {name:35s} -> {src_file}  ({ts})")
        except Exception as exc:
            log_lines.append(f"  ! {kind:14s} {name:35s} -> ERROR {exc}")

    log_lines.append("")
    log_lines.append(f"Injected: {injected}")
    log_lines.append(f"Skipped (already present): {skipped_existing}")
    log_lines.append(f"Skipped (no target file): {skipped_no_target}")
    log_lines.append(f"Skipped (non-source ext):  {rejected_extension_mismatch}")
    log_lines.append("")
    log_lines.append(f"Errors before: {len(errors)}")
    REPORT_PATH.write_text("\n".join(log_lines), encoding="utf-8")
    print(f"Injected {injected} symbols. Report: {REPORT_PATH}")


if __name__ == "__main__":
    main()
