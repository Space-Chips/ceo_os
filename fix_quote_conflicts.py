#!/usr/bin/env python3
# Fix Dart single-line string literals where the ASCII normalization
# collapsed an inner curly apostrophe into a real `'`, prematurely closing
# the string. Example before fix:
#     'Conditions d'utilisation'   <-- broken: 3 single-quotes on the line
# After:
#     "Conditions d'utilisation"
#
# Heuristic: inside a `'...'` literal, if a `'` is immediately followed by
# an alphabetic char or underscore, treat it as an INNER apostrophe and
# continue scanning until we hit a `'` followed by non-identifier char.
# Then, if the resolved string actually contains inner `'`, swap the outer
# delimiter to `"` (or escape inner if `"` is already present).
#
# Idempotent. Skips: comments, triple-quoted strings, already-valid strings.

import re
import sys
from pathlib import Path

EXCLUDED_DIRS = {".git", ".dart_tool", "build", ".pub-cache", "Pods",
                 "codex_recovery", "smart_recovery_output", "smart_recovery_v3"}

IDENT_CHARS = set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_$")


def _scan_string(line, i, delim, is_raw):
    """Find the real closing index of a string starting at `i` (line[i]==delim).
       Returns (close_index, inner_apostrophe_count). close_index is the index
       OF the closing delim, or -1 if not found on this line."""
    n = len(line)
    j = i + 1
    inner_count = 0
    while j < n:
        c = line[j]
        if not is_raw and c == "\\" and j + 1 < n:
            j += 2
            continue
        if c == delim:
            # Look ahead: is next char an identifier char? Then this is an
            # inner apostrophe (only meaningful for single-quote strings,
            # where the conflict is `'` inside `'...'`).
            if delim == "'" and j + 1 < n and line[j + 1] in IDENT_CHARS:
                inner_count += 1
                j += 1
                continue
            return j, inner_count
        if c == "\n":
            return -1, inner_count
        j += 1
    return -1, inner_count


def process(content: str) -> str:
    out = []
    i = 0
    n = len(content)
    while i < n:
        c = content[i]

        # Line comment
        if c == "/" and i + 1 < n and content[i + 1] == "/":
            eol = content.find("\n", i)
            eol = n if eol == -1 else eol
            out.append(content[i:eol])
            i = eol
            continue

        # Block comment
        if c == "/" and i + 1 < n and content[i + 1] == "*":
            end = content.find("*/", i + 2)
            end = n if end == -1 else end + 2
            out.append(content[i:end])
            i = end
            continue

        # Optional raw prefix r before a quote
        is_raw = False
        prefix = ""
        if c == "r" and i + 1 < n and content[i + 1] in ("'", '"'):
            # Confirm `r` is not part of a longer identifier (e.g. `var`).
            prev_char = content[i - 1] if i > 0 else " "
            if prev_char not in IDENT_CHARS:
                is_raw = True
                prefix = "r"
                i += 1
                c = content[i]

        if c in ("'", '"'):
            # Triple-quoted: leave verbatim
            if i + 2 < n and content[i + 1] == c and content[i + 2] == c:
                delim_str = c * 3
                end = content.find(delim_str, i + 3)
                if end == -1:
                    out.append(prefix + content[i:])
                    i = n
                    break
                out.append(prefix + content[i:end + 3])
                i = end + 3
                continue

            delim = c
            close_idx, inner_count = _scan_string(content, i, delim, is_raw)
            if close_idx == -1:
                # Couldn't resolve on this line — leave the rest of the line as-is
                eol = content.find("\n", i)
                eol = n if eol == -1 else eol
                out.append(prefix + content[i:eol])
                i = eol
                continue

            inner = content[i + 1:close_idx]
            if delim == "'" and inner_count > 0:
                # Conflict: inner apostrophes were absorbed.
                if '"' not in inner:
                    out.append(prefix + '"' + inner + '"')
                else:
                    # Both delims present in content — escape the inner '
                    inner2 = re.sub(r"(?<!\\)'", r"\\'", inner)
                    out.append(prefix + "'" + inner2 + "'")
            else:
                out.append(prefix + content[i:close_idx + 1])
            i = close_idx + 1
            continue

        out.append(c)
        i += 1
    return "".join(out)


def main() -> int:
    root = Path.cwd()
    files = []
    for p in root.rglob("*.dart"):
        if any(part in EXCLUDED_DIRS for part in p.parts):
            continue
        files.append(p)

    changed = 0
    for f in files:
        try:
            text = f.read_text(encoding="utf-8")
        except Exception as exc:
            print(f"skip {f}: {exc}", file=sys.stderr)
            continue
        new_text = process(text)
        if new_text != text:
            f.write_text(new_text, encoding="utf-8")
            print(f"fixed {f.relative_to(root)}")
            changed += 1
    print(f"\nDone. {changed} file(s) modified.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
