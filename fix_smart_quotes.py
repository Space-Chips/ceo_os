#!/usr/bin/env python3
# Replace typographic (smart) quotes in Dart files with ASCII equivalents.
#
# Walks each .dart file as a simple tokenizer that understands:
#   - line comments and block comments
#   - single-line single-quoted and double-quoted strings
#   - triple-quoted strings (single or double)
#   - raw strings (r-prefixed)
#
# In string literals, smart quotes are replaced with straight ASCII quotes.
# If the replacement would conflict with the outer delimiter, the script
# swaps the delimiter or escapes the conflict. In comments, smart quotes
# are replaced unconditionally.
#
# Run from the project root. Prints each modified file and a summary.
import re
import sys
from pathlib import Path

SMART = {
    "‘": "'",  # LEFT SINGLE QUOTATION MARK
    "’": "'",  # RIGHT SINGLE QUOTATION MARK / apostrophe
    "“": '"',  # LEFT DOUBLE QUOTATION MARK
    "”": '"',  # RIGHT DOUBLE QUOTATION MARK
}
SMART_CHARS = set(SMART.keys())
EXCLUDED_DIRS = {".git", ".dart_tool", "build", ".pub-cache", "Pods", "codex_recovery"}


def replace_smart(text: str) -> str:
    for s, straight in SMART.items():
        text = text.replace(s, straight)
    return text


def fix_string_inner(inner: str, delim: str):
    """Return (new_inner, new_delim) after smart-quote replacement.

    Picks a valid outer delimiter:
      - if the resulting content has an unescaped ', wrap in "..."
      - if it has an unescaped ", wrap in '...'
      - if both, keep the original delimiter and escape conflicts
    """
    new_inner = replace_smart(inner)
    if delim == "'":
        unescaped_single = re.search(r"(?<!\\)'", new_inner) is not None
        has_double = '"' in new_inner
        if unescaped_single and not has_double:
            return new_inner, '"'
        if unescaped_single:
            new_inner = re.sub(r"(?<!\\)'", r"\\'", new_inner)
        return new_inner, "'"
    else:
        unescaped_double = re.search(r'(?<!\\)"', new_inner) is not None
        has_single = "'" in new_inner
        if unescaped_double and not has_single:
            return new_inner, "'"
        if unescaped_double:
            new_inner = re.sub(r'(?<!\\)"', r'\\"', new_inner)
        return new_inner, '"'


def process(content: str) -> str:
    out = []
    i = 0
    n = len(content)
    while i < n:
        c = content[i]

        # Line comment
        if c == "/" and i + 1 < n and content[i + 1] == "/":
            eol = content.find("\n", i)
            if eol == -1:
                eol = n
            out.append(replace_smart(content[i:eol]))
            i = eol
            continue

        # Block comment
        if c == "/" and i + 1 < n and content[i + 1] == "*":
            end = content.find("*/", i + 2)
            end = n if end == -1 else end + 2
            out.append(replace_smart(content[i:end]))
            i = end
            continue

        # Raw string prefix r before quote
        is_raw = False
        prefix = ""
        if c == "r" and i + 1 < n and content[i + 1] in ("'", '"'):
            is_raw = True
            prefix = "r"
            i += 1
            c = content[i]

        # String literals
        if c in ("'", '"'):
            # Triple-quoted
            if i + 2 < n and content[i + 1] == c and content[i + 2] == c:
                delim_str = c * 3
                end = content.find(delim_str, i + 3)
                if end == -1:
                    out.append(prefix + content[i:])
                    i = n
                    break
                inner = content[i + 3 : end]
                inner = replace_smart(inner)
                out.append(prefix + delim_str + inner + delim_str)
                i = end + 3
                continue

            # Single-line quoted string
            delim = c
            j = i + 1
            while j < n and content[j] != delim:
                if not is_raw and content[j] == "\\" and j + 1 < n:
                    j += 2
                    continue
                if content[j] == "\n":
                    break
                j += 1
            if j >= n or content[j] != delim:
                # Unterminated — copy as-is and continue past where we got
                out.append(prefix + content[i:j])
                i = j
                continue

            inner = content[i + 1 : j]
            if any(sc in inner for sc in SMART_CHARS):
                if is_raw:
                    # Raw strings cannot escape; just swap delimiter if needed
                    new_inner = replace_smart(inner)
                    if delim == "'" and "'" in new_inner and '"' not in new_inner:
                        out.append(prefix + '"' + new_inner + '"')
                    elif delim == '"' and '"' in new_inner and "'" not in new_inner:
                        out.append(prefix + "'" + new_inner + "'")
                    else:
                        # Last resort: keep delimiter, drop raw-ness (rare)
                        out.append(delim + new_inner + delim)
                else:
                    new_inner, new_delim = fix_string_inner(inner, delim)
                    out.append(prefix + new_delim + new_inner + new_delim)
            else:
                out.append(prefix + content[i : j + 1])
            i = j + 1
            continue

        # Anything else
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
        except Exception as e:
            print(f"skip {f}: {e}", file=sys.stderr)
            continue
        if not any(sc in text for sc in SMART_CHARS):
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
