#!/usr/bin/env python3
# Heuristic missing-imports fixer for Dart.
# Scans every .dart file in lib/. For each file, if it USES a top-level
# symbol that's defined elsewhere in the project but NOT imported, adds
# the necessary import line.
#
# Strategy:
#   1. Build a SYMBOL_MAP: for every public top-level symbol defined in
#      any lib/*.dart file, record (symbol_name -> file_path).
#   2. For every file, find symbol references (identifiers that look like
#      class/static usage: capital-letter names, or known util fns).
#   3. Check if each referenced symbol is defined in the same file or
#      already imported. If not, add the import.
#
# Idempotent. Skip files inside excluded dirs.

import re
import sys
from pathlib import Path
from collections import defaultdict

ROOT = Path.cwd()
EXCLUDED = {".git", ".dart_tool", "build", ".pub-cache", "Pods",
            "codex_recovery", "smart_recovery_output", "smart_recovery_v3",
            "ceo_os_latest_snapshots"}

# Patterns for finding TOP-LEVEL symbol definitions in a Dart file.
DEF_PATTERNS = [
    re.compile(r"^\s*(?:abstract\s+|sealed\s+|final\s+|base\s+|interface\s+)?class\s+(\w+)"),
    re.compile(r"^\s*enum\s+(\w+)"),
    re.compile(r"^\s*mixin\s+(\w+)"),
    re.compile(r"^\s*extension\s+(\w+)"),
    re.compile(r"^\s*typedef\s+(\w+)"),
]

# Files we don't import from (entry points, platform-specific stubs).
SKIP_FILES = set()


def build_symbol_map():
    """symbol_name -> (file_path, kind)"""
    smap = {}
    for p in ROOT.rglob("*.dart"):
        if any(part in EXCLUDED for part in p.parts):
            continue
        try:
            text = p.read_text(encoding="utf-8", errors="replace")
        except Exception:
            continue
        for line in text.split("\n"):
            for pat in DEF_PATTERNS:
                m = pat.match(line)
                if m:
                    name = m.group(1)
                    if name.startswith("_"):
                        continue  # private, can't import
                    if name not in smap:
                        smap[name] = p
                    # else: ambiguous — keep first
                    break
    return smap


def extract_imports(text):
    """Return set of import strings (the path inside the quotes)."""
    imports = set()
    for line in text.split("\n"):
        m = re.match(r"^\s*import\s+['\"]([^'\"]+)['\"]", line)
        if m:
            imports.add(m.group(1))
    return imports


def used_symbols(text, smap):
    """Return set of symbol names referenced in non-string, non-comment code."""
    # Remove strings and comments first (rough).
    cleaned = re.sub(r"//.*?$", "", text, flags=re.M)
    cleaned = re.sub(r"/\*.*?\*/", "", cleaned, flags=re.S)
    cleaned = re.sub(r"'''.*?'''", "''", cleaned, flags=re.S)
    cleaned = re.sub(r'""".*?"""', '""', cleaned, flags=re.S)
    cleaned = re.sub(r"'(?:[^'\\\n]|\\.)*'", "''", cleaned)
    cleaned = re.sub(r'"(?:[^"\\\n]|\\.)*"', '""', cleaned)
    # Now match identifiers
    refs = set()
    for m in re.finditer(r"\b([A-Z][A-Za-z0-9_]*)\b", cleaned):
        n = m.group(1)
        if n in smap:
            refs.add(n)
    return refs


def relative_import(from_file, target_file):
    """Compute the import path from one .dart file to another."""
    from_dir = from_file.parent
    rel = target_file.relative_to(ROOT) if target_file.is_absolute() else target_file
    target_abs = ROOT / rel if not target_file.is_absolute() else target_file
    # Compute relative path
    try:
        rp = target_abs.relative_to(from_dir)
        return str(rp)
    except ValueError:
        # Need to go up
        parts_from = from_dir.relative_to(ROOT).parts
        parts_target = target_abs.relative_to(ROOT).parts
        # Find common prefix
        i = 0
        while (i < len(parts_from) and i < len(parts_target)
               and parts_from[i] == parts_target[i]):
            i += 1
        up = ".." * (len(parts_from) - i)
        rest = "/".join(parts_target[i:])
        ups = "/".join([".." ] * (len(parts_from) - i))
        return f"{ups}/{rest}"


def fix_file(file_path: Path, smap):
    try:
        text = file_path.read_text(encoding="utf-8")
    except Exception:
        return None
    if "import" not in text and "class" not in text:
        return None  # not worth processing

    refs = used_symbols(text, smap)
    if not refs:
        return None
    own_path = file_path.resolve()
    existing_imports = extract_imports(text)

    # Symbols defined in this very file
    own_defs = set()
    for line in text.split("\n"):
        for pat in DEF_PATTERNS:
            m = pat.match(line)
            if m:
                own_defs.add(m.group(1))
                break

    missing = []
    for sym in sorted(refs - own_defs):
        target = smap[sym].resolve()
        if target == own_path:
            continue
        # Compute potential import paths (relative and package:)
        rel = relative_import(file_path, target)
        # Does the file already import this?
        already_imported = False
        target_rel_to_root = target.relative_to(ROOT)
        target_basename = target_rel_to_root.parts[-1]
        for imp in existing_imports:
            if imp == rel or imp.endswith("/" + target_basename) or imp == target_basename:
                already_imported = True
                break
        if not already_imported:
            missing.append((sym, rel))

    if not missing:
        return None

    # Add the missing imports right after the last existing import,
    # or at the top of the file.
    lines = text.split("\n")
    # Find the last import line index
    last_import_idx = -1
    for i, line in enumerate(lines):
        if re.match(r"^\s*import\s+", line):
            last_import_idx = i
    insert_pos = last_import_idx + 1 if last_import_idx != -1 else 0
    new_imports = [f"import '{rel}';" for _, rel in missing]
    new_lines = lines[:insert_pos] + new_imports + lines[insert_pos:]
    file_path.write_text("\n".join(new_lines), encoding="utf-8")
    return [sym for sym, _ in missing]


def main():
    print("[1/2] Building symbol map...")
    smap = build_symbol_map()
    print(f"      {len(smap)} public top-level symbols indexed")

    print("[2/2] Scanning files for missing imports...")
    total_fixed = 0
    total_imports_added = 0
    for p in ROOT.rglob("*.dart"):
        if any(part in EXCLUDED for part in p.parts):
            continue
        result = fix_file(p, smap)
        if result:
            total_fixed += 1
            total_imports_added += len(result)
            rel = p.relative_to(ROOT)
            print(f"  + {rel}: added {len(result)} import(s) for {', '.join(result[:5])}{'...' if len(result) > 5 else ''}")
    print(f"\nFixed {total_fixed} files, added {total_imports_added} import statements.")


if __name__ == "__main__":
    main()
