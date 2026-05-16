import json
import sys
import os
import re
import shutil
import shlex
import subprocess
from pathlib import Path
from datetime import datetime
from collections import defaultdict

MISSING = object()


class ExtractedPatch:
    """Small in-memory patch record with the Path-like bits the applier needs."""

    def __init__(self, name, text):
        self.name = name
        self._text = text

    def read_text(self, encoding="utf-8"):
        return self._text

# ========================= TERMINAL UI =========================

class C:
    """ANSI color codes for terminal output."""
    RESET  = "\033[0m"
    BOLD   = "\033[1m"
    DIM    = "\033[2m"
    RED    = "\033[91m"
    GREEN  = "\033[92m"
    YELLOW = "\033[93m"
    BLUE   = "\033[94m"
    CYAN   = "\033[96m"
    WHITE  = "\033[97m"
    MAG    = "\033[95m"
    BG     = "\033[48;5;235m"
    ULINE  = "\033[4m"

def _w():
    """Terminal width, clamped."""
    return min(shutil.get_terminal_size((80, 24)).columns, 100)

def banner():
    w = _w()
    line = f"{C.DIM}{'=' * w}{C.RESET}"
    title = "TRUC DE PATCH  RECOVERY 2"
    pad = (w - len(title)) // 2
    print()
    print(line)
    print(f"{C.BOLD}{C.CYAN}{' ' * pad}{title}{C.RESET}")
    print(f"{C.DIM}{' ' * ((w - 42) // 2)}Extract and replay patches from Codex sessions{C.RESET}")
    print(line)

def section(text):
    w = _w()
    print(f"\n{C.BOLD}{C.BLUE}--- {text} {'-' * max(0, w - len(text) - 5)}{C.RESET}")

def ok(msg):
    print(f"  {C.GREEN}[ok]{C.RESET}   {msg}")

def fail(msg):
    print(f"  {C.RED}[fail]{C.RESET} {msg}")

def skip(msg):
    print(f"  {C.YELLOW}[skip]{C.RESET} {msg}")

def skip(msg):
    print(f"  {C.YELLOW}[skip]{C.RESET} {msg}")

def warn(msg):
    print(f"  {C.YELLOW}[warn]{C.RESET} {msg}")

def info(msg):
    print(f"  {C.DIM}[info]{C.RESET} {msg}")

def prompt(label, default=""):
    suffix = f" {C.DIM}[{default}]{C.RESET}" if default else ""
    try:
        val = input(f"\n  {C.CYAN}{C.BOLD}>{C.RESET} {label}{suffix}: ").strip()
    except (EOFError, KeyboardInterrupt):
        print(f"\n{C.DIM}Cancelled.{C.RESET}")
        sys.exit(0)
    return val or default

def confirm(label):
    try:
        val = input(f"\n  {C.YELLOW}{C.BOLD}?{C.RESET} {label} {C.DIM}[y/N]{C.RESET}: ").strip().lower()
    except (EOFError, KeyboardInterrupt):
        print(f"\n{C.DIM}Cancelled.{C.RESET}")
        sys.exit(0)
    return val in ("y", "yes")

def discover_workspaces():
    """Scan Codex sessions and return a list of (cwd, session_count) sorted by count."""
    codex_base = Path.home() / ".codex"
    files = []
    for d in [codex_base / "sessions", codex_base / "archived_sessions"]:
        if d.exists():
            files.extend(d.rglob("rollout-*.jsonl"))

    projects = defaultdict(int)
    for fpath in files:
        try:
            with open(fpath, "r", encoding="utf-8") as f:
                for raw in f:
                    try:
                        d = json.loads(raw.strip())
                    except (json.JSONDecodeError, UnicodeDecodeError):
                        continue
                    if d.get("type") == "session_meta":
                        cwd = d.get("payload", {}).get("cwd", "")
                        if cwd:
                            projects[cwd] += 1
                        break
        except Exception:
            continue
    return sorted(projects.items(), key=lambda x: -x[1])


def run_cmd(cmd, cwd=None, check=True):
    result = subprocess.run(cmd, shell=True, cwd=cwd, capture_output=True, text=True)
    if check and result.returncode != 0:
        print(f"[ERROR] Command failed: {cmd}\n{result.stderr}")
    return result


def branch_exists(repo_path: Path, branch_name: str) -> bool:
    result = run_cmd(
        f"git rev-parse --verify --quiet {shlex.quote(branch_name)}",
        cwd=repo_path,
        check=False,
    )
    return result.returncode == 0


def unique_branch_name(repo_path: Path, base_name: str) -> str:
    if not branch_exists(repo_path, base_name):
        return base_name

    idx = 2
    while True:
        candidate = f"{base_name}-{idx}"
        if not branch_exists(repo_path, candidate):
            return candidate
        idx += 1


def branch_exists(repo_path: Path, branch_name: str) -> bool:
    result = run_cmd(
        f"git rev-parse --verify --quiet {shlex.quote(branch_name)}",
        cwd=repo_path,
        check=False,
    )
    return result.returncode == 0


def unique_branch_name(repo_path: Path, base_name: str) -> str:
    if not branch_exists(repo_path, base_name):
        return base_name

    idx = 2
    while True:
        candidate = f"{base_name}-{idx}"
        if not branch_exists(repo_path, candidate):
            return candidate
        idx += 1


def find_relevant_rollouts(project_path: Path):
    """Find Codex rollout files that belong to the given project.

    Uses the session_meta cwd field for accurate matching, with fallback
    to scanning line content for the project path or name.
    """
    codex_base = Path.home() / ".codex"
    search_dirs = [codex_base / "sessions", codex_base / "archived_sessions"]
    rollouts = []

    for d in search_dirs:
        if d.exists():
            rollouts.extend(list(d.rglob("rollout-*.jsonl")))

    relevant = []
    project_str = str(project_path.resolve())
    project_name = project_path.name

    print(f"[SCAN] Scanning {len(rollouts)} rollout files for project: {project_name}")

    for r in rollouts:
        try:
            with open(r, "r", encoding="utf-8") as f:
                for _ in range(20):  # session_meta is always in first few lines
                    line = f.readline()
                    if not line:
                        break
                    try:
                        data = json.loads(line.strip())
                    except json.JSONDecodeError:
                        continue

                    # Best match: session_meta contains the cwd
                    if data.get("type") == "session_meta":
                        cwd = data.get("payload", {}).get("cwd", "")
                        if cwd and (
                            cwd == project_str
                            or cwd.startswith(project_str + "/")
                            or project_str.startswith(cwd + "/")
                            or project_name in cwd
                        ):
                            relevant.append(r)
                            break

                    # Fallback: turn_context or other early lines mention the project
                    if data.get("type") == "turn_context":
                        tc_cwd = data.get("payload", {}).get("cwd", "")
                        if tc_cwd and (project_str in tc_cwd or project_name in tc_cwd):
                            relevant.append(r)
                            break
        except Exception:
            continue

    if not relevant:
        print("[WARN] No direct matches found. Using 20 most recent sessions as fallback.")
        relevant = sorted(rollouts, key=lambda p: p.stat().st_mtime, reverse=True)[:20]

    # Sort oldest to newest so patches apply in chronological order
    return sorted(relevant, key=lambda p: p.stat().st_mtime)


def extract_patches(rollout_path: Path, output_dir: Path = None):
    """Extract successful apply_patch calls from a Codex rollout file.

    Codex stores patches as custom_tool_call entries with name 'apply_patch'.
    The patch content is in payload.input using the format:
        *** Begin Patch
        *** Update File: <path>  (or *** Add File: / *** Delete File:)
        @@ context lines and +/- diff lines
        *** End Patch

    Only patches whose corresponding custom_tool_call_output indicates success
    are extracted. Failed patches are skipped since Codex retries them.
    """
    if output_dir:
        output_dir.mkdir(parents=True, exist_ok=True)
    patches = []

    # First pass: collect all apply_patch calls and their outcomes
    patch_calls = {}  # call_id -> patch input text
    successful_ids = set()

    with open(rollout_path, "r", encoding="utf-8") as f:
        for line in f:
            try:
                data = json.loads(line.strip())
            except (json.JSONDecodeError, UnicodeDecodeError):
                continue

            if data.get("type") != "response_item":
                continue

            payload = data.get("payload", {})
            ptype = payload.get("type", "")

            if ptype == "custom_tool_call" and payload.get("name") == "apply_patch":
                call_id = payload.get("call_id", "")
                patch_input = payload.get("input", "")
                if call_id and patch_input:
                    patch_calls[call_id] = {
                        "input": patch_input,
                        "timestamp": data.get("timestamp", ""),
                    }

            elif ptype == "custom_tool_call_output":
                call_id = payload.get("call_id", "")
                output = payload.get("output", "")
                # Check if the patch was applied successfully
                if call_id and ("Success" in output or '"exit_code":0' in output or '"exit_code": 0' in output):
                    successful_ids.add(call_id)

    # Second pass: save only successful patches in order
    count = 0
    for call_id, info in sorted(patch_calls.items(), key=lambda x: x[1]["timestamp"]):
        if call_id not in successful_ids:
            continue

        patch_text = info["input"]
        if "*** Begin Patch" not in patch_text:
            continue

        patch_name = f"patch_{count:04d}_{call_id[-8:]}.patch"
        if output_dir:
            patch_file = output_dir / patch_name
            patch_file.write_text(patch_text, encoding="utf-8")
            patches.append(patch_file)
        else:
            patches.append(ExtractedPatch(patch_name, patch_text))
        count += 1

    return patches, count


def parse_codex_patch(patch_text):
    """Parse a Codex-format patch into a list of file operations.

    Returns a list of dicts:
        {"action": "add"|"update"|"delete", "path": str, "content": str, "hunks": [...]}

    For 'add' files, 'content' contains the full file content (lines starting with +).
    For 'update' files, 'hunks' contains a list of (context_before, removals, additions, context_after).
    For 'delete' files, the file should be removed.
    """
    operations = []
    current_op = None
    current_lines = []

    for line in patch_text.split("\n"):
        if line.startswith("*** Begin Patch"):
            continue
        elif line.startswith("*** End Patch"):
            if current_op:
                current_op["raw_lines"] = current_lines
                operations.append(current_op)
            break
        elif line.startswith("*** Add File:"):
            if current_op:
                current_op["raw_lines"] = current_lines
                operations.append(current_op)
            filepath = line[len("*** Add File:"):].strip()
            current_op = {"action": "add", "path": filepath}
            current_lines = []
        elif line.startswith("*** Update File:"):
            if current_op:
                current_op["raw_lines"] = current_lines
                operations.append(current_op)
            filepath = line[len("*** Update File:"):].strip()
            current_op = {"action": "update", "path": filepath}
            current_lines = []
        elif line.startswith("*** Delete File:"):
            if current_op:
                current_op["raw_lines"] = current_lines
                operations.append(current_op)
            filepath = line[len("*** Delete File:"):].strip()
            current_op = {"action": "delete", "path": filepath}
            current_lines = []
        elif line.startswith("*** Move to:"):
            if current_op and current_op["action"] == "update":
                current_op["move_to"] = line[len("*** Move to:"):].strip()
        else:
            current_lines.append(line)

    # Handle case where *** End Patch wasn't found
    if current_op and "raw_lines" not in current_op:
        current_op["raw_lines"] = current_lines
        operations.append(current_op)

    # Post-process: build content for add files, hunks for update files
    for op in operations:
        raw = op.pop("raw_lines", [])
        if op["action"] == "add":
            # Lines should start with +, strip the leading +
            content_lines = []
            for l in raw:
                if l.startswith("+"):
                    content_lines.append(l[1:])
                elif l.strip():  # non-empty, non-+ line (shouldn't happen but be safe)
                    content_lines.append(l)
            op["content"] = "\n".join(content_lines)
            if content_lines and not op["content"].endswith("\n"):
                op["content"] += "\n"
        elif op["action"] == "update":
            op["hunks"] = _parse_update_hunks(raw)
        # 'delete' doesn't need additional processing

    return operations


def _parse_update_hunks(lines):
    """Parse the hunk lines of an update patch.

    Codex update format uses @@ as hunk separators. Between @@ markers:
    - Lines starting with ' ' (space) are context
    - Lines starting with '+' are additions
    - Lines starting with '-' are removals
    - Plain lines (no prefix) are context
    """
    hunks = []
    current_hunk = []

    for line in lines:
        if line.startswith("@@"):
            if current_hunk:
                hunks.append(current_hunk)
            current_hunk = []
        else:
            current_hunk.append(line)

    if current_hunk:
        hunks.append(current_hunk)

    return hunks


def apply_codex_patch_to_file(op, repo_path: Path):
    """Apply a single Codex file operation to the repository.

    Returns (success: bool, message: str).
    """
    filepath = resolve_patch_path(repo_path, op["path"])

    if op["action"] == "delete":
        if filepath.exists():
            filepath.unlink()
            return True, f"Deleted {display_patch_path(repo_path, filepath)}"
        return True, f"Already absent: {display_patch_path(repo_path, filepath)}"

    if op["action"] == "add":
        if filepath.exists() and filepath.read_text(encoding="utf-8") == op["content"]:
            return True, f"Already exists: {display_patch_path(repo_path, filepath)}"
        if filepath.exists():
            return False, f"Add target already exists with different content: {display_patch_path(repo_path, filepath)}"
        filepath.parent.mkdir(parents=True, exist_ok=True)
        filepath.write_text(op["content"], encoding="utf-8")
        return True, f"Created {display_patch_path(repo_path, filepath)}"

    if op["action"] == "update":
        move_to = op.get("move_to")
        destination = resolve_patch_path(repo_path, move_to) if move_to else None

        # If a previous recovery already moved the file, continue from the
        # destination rather than failing on the old source path.
        if not filepath.exists() and destination and destination.exists():
            filepath = destination

        if not filepath.exists():
            return False, f"File not found for update: {op['path']}"

        try:
            content = filepath.read_text(encoding="utf-8")
        except Exception as e:
            return False, f"Cannot read {op['path']}: {e}"

        file_lines = content.split("\n")

        for hunk in op.get("hunks", []):
            # Separate the hunk into context, additions, and removals
            context_lines = []
            add_lines = []
            remove_lines = []
            hunk_parts = []  # ordered list of (type, text) for reconstruction

            for line in hunk:
                if line.startswith("+"):
                    hunk_parts.append(("add", line[1:]))
                    add_lines.append(line[1:])
                elif line.startswith("-"):
                    hunk_parts.append(("remove", line[1:]))
                    remove_lines.append(line[1:])
                else:
                    # Context line (may have leading space or not)
                    text = line[1:] if line.startswith(" ") else line
                    hunk_parts.append(("context", text))
                    context_lines.append(text)

            # Find the location in the file by matching context + removal lines
            # Build the sequence of lines we expect to find (context and removals)
            expected_sequence = []
            for ptype, ptext in hunk_parts:
                if ptype in ("context", "remove"):
                    expected_sequence.append(ptext)

            if not expected_sequence:
                # Pure addition with no context - append to end
                file_lines.extend(add_lines)
                continue

            # Search for the expected sequence in the file
            match_start = _find_sequence(file_lines, expected_sequence)
            if match_start is None:
                # Try fuzzy match (strip whitespace)
                match_start = _find_sequence_fuzzy(file_lines, expected_sequence)

            # Build replacement lines
            replacement = []
            for ptype, ptext in hunk_parts:
                if ptype == "context":
                    replacement.append(ptext)
                elif ptype == "add":
                    replacement.append(ptext)
                # 'remove' lines are omitted

            if match_start is None:
                if replacement:
                    already_applied_at = _find_sequence(file_lines, replacement)
                    if already_applied_at is None:
                        already_applied_at = _find_sequence_fuzzy(file_lines, replacement)
                    if already_applied_at is not None:
                        continue
                return False, f"Cannot locate hunk context in {display_patch_path(repo_path, filepath)}"

            # Apply the replacement
            match_end = match_start + len(expected_sequence)
            file_lines[match_start:match_end] = replacement

        # Write back
        new_content = "\n".join(file_lines)
        filepath.write_text(new_content, encoding="utf-8")

        if destination and filepath != destination:
            destination.parent.mkdir(parents=True, exist_ok=True)
            if destination.exists():
                return False, f"Move destination already exists: {display_patch_path(repo_path, destination)}"
            filepath.replace(destination)
            return True, f"Updated and moved {display_patch_path(repo_path, filepath)} -> {display_patch_path(repo_path, destination)}"

        return True, f"Updated {display_patch_path(repo_path, filepath)}"

    return False, f"Unknown action: {op['action']}"


def resolve_patch_path(repo_path: Path, patch_path: str) -> Path:
    """Resolve a Codex patch path while keeping operations inside repo_path."""
    raw = Path(patch_path).expanduser()
    resolved = raw.resolve() if raw.is_absolute() else (repo_path / raw).resolve()
    repo_resolved = repo_path.resolve()
    try:
        resolved.relative_to(repo_resolved)
    except ValueError as exc:
        raise ValueError(f"Patch path escapes target repository: {patch_path}") from exc
    return resolved


def display_patch_path(repo_path: Path, filepath: Path) -> str:
    try:
        return str(filepath.resolve().relative_to(repo_path.resolve()))
    except ValueError:
        return str(filepath)


def touched_files_for_operation(op, repo_path: Path):
    paths = [resolve_patch_path(repo_path, op["path"])]
    if op.get("move_to"):
        paths.append(resolve_patch_path(repo_path, op["move_to"]))
    return paths


def snapshot_files(paths):
    snapshot = {}
    for path in paths:
        if path in snapshot:
            continue
        if path.exists():
            snapshot[path] = path.read_text(encoding="utf-8")
        else:
            snapshot[path] = MISSING
    return snapshot


def restore_snapshot(snapshot):
    for path, content in snapshot.items():
        if content is MISSING:
            if path.exists():
                path.unlink()
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content, encoding="utf-8")


def is_obsolete_patch_reason(reason: str) -> bool:
    obsolete_markers = (
        "Cannot locate hunk context",
        "File not found for update",
        "Move destination already exists",
        "Add target already exists with different content",
    )
    return any(marker in reason for marker in obsolete_markers)


def primary_reason(reason: str) -> str:
    if "Cannot locate hunk context" in reason:
        return "context changed"
    if "File not found for update" in reason:
        return "file missing"
    if "Move destination already exists" in reason:
        return "already moved"
    if "Add target already exists with different content" in reason:
        return "file already exists differently"
    if "Patch path escapes target repository" in reason:
        return "unsafe path"
    return "apply failed"


def is_obsolete_patch_reason(reason: str) -> bool:
    obsolete_markers = (
        "Cannot locate hunk context",
        "File not found for update",
        "Move destination already exists",
        "Add target already exists with different content",
    )
    return any(marker in reason for marker in obsolete_markers)


def primary_reason(reason: str) -> str:
    if "Cannot locate hunk context" in reason:
        return "context changed"
    if "File not found for update" in reason:
        return "file missing"
    if "Move destination already exists" in reason:
        return "already moved"
    if "Add target already exists with different content" in reason:
        return "file already exists differently"
    if "Patch path escapes target repository" in reason:
        return "unsafe path"
    return "apply failed"


def _find_sequence(file_lines, expected):
    """Find the starting index of an exact sequence match in file_lines."""
    seq_len = len(expected)
    for i in range(len(file_lines) - seq_len + 1):
        if file_lines[i : i + seq_len] == expected:
            return i
    return None


def _find_sequence_fuzzy(file_lines, expected):
    """Find the starting index with whitespace-stripped comparison."""
    stripped_expected = [l.strip() for l in expected]
    seq_len = len(stripped_expected)
    for i in range(len(file_lines) - seq_len + 1):
        stripped_file = [l.strip() for l in file_lines[i : i + seq_len]]
        if stripped_file == stripped_expected:
            return i
    return None


def apply_patches_safely(patch_files, repo_path: Path):
    """Apply extracted Codex patches to the repository.

    Creates a backup branch first, then applies each patch file by
    parsing the Codex format and performing the file operations directly.
    """
    repo_path = repo_path.resolve()
    timestamp = datetime.now().strftime("%Y%m%d_%H%M")
    backup_branch = f"codex-recovery-{timestamp}"

    # Check if this is a git repo
    is_git = (repo_path / ".git").exists()
    repo_dirty_at_start = False
    if is_git:
        status = run_cmd("git status --porcelain", cwd=repo_path, check=False)
        repo_dirty_at_start = bool(status.stdout.strip())
        if repo_dirty_at_start:
            warn("Git repo has existing changes; recovery will not auto-commit.")
        backup_branch = unique_branch_name(repo_path, backup_branch)
        print(f"\n[BACKUP] Creating safety backup branch: {backup_branch}")
        branch_result = run_cmd(f"git checkout -b {shlex.quote(backup_branch)}", cwd=repo_path, check=False)
        if branch_result.returncode != 0:
            return [], [], [(ExtractedPatch("git-backup", ""), branch_result.stderr.strip())], backup_branch

    applied = []
    failed = []
    skipped = []
    applied_paths = set()
    skip_reasons = defaultdict(int)

    for patch_file in patch_files:
        patch_text = patch_file.read_text(encoding="utf-8")
        operations = parse_codex_patch(patch_text)

        if not operations:
            failed.append((patch_file, "No operations found in patch"))
            continue

        patch_ok = True
        patch_messages = []
        touched_paths = []

        try:
            for op in operations:
                touched_paths.extend(touched_files_for_operation(op, repo_path))
            before_patch = snapshot_files(touched_paths)
        except Exception as e:
            failed.append((patch_file, str(e)))
            print(f"   [FAIL] {e}")
            continue

        for op in operations:
            try:
                success, msg = apply_codex_patch_to_file(op, repo_path)
            except Exception as e:
                success, msg = False, str(e)
            patch_messages.append(msg)
            if not success:
                patch_ok = False
                break

        if patch_ok:
            applied.append(patch_file)
            applied_paths.update(touched_paths)
            for msg in patch_messages:
                print(f"   [OK] {msg}")
        else:
            restore_snapshot(before_patch)
            reason = "; ".join(patch_messages)
            if is_obsolete_patch_reason(reason):
                skipped.append((patch_file, reason))
                skip_reasons[primary_reason(reason)] += 1
            else:
                failed.append((patch_file, reason))
                for msg in patch_messages:
                    print(f"   [FAIL] {msg}")
                print("   [ROLLBACK] Reverted changes from failed patch")

    if is_git and applied and not repo_dirty_at_start:
        rel_paths = sorted(display_patch_path(repo_path, path) for path in applied_paths)
        quoted_paths = " ".join(shlex.quote(path) for path in rel_paths)
        run_cmd(f"git add -- {quoted_paths}", cwd=repo_path)
        run_cmd(
            f'git commit -m "Recovery: applied {len(applied)} patches from Codex sessions"',
            cwd=repo_path,
        )
    elif is_git and applied:
        warn("Skipped auto-commit because the repository was dirty before recovery.")

    if skipped:
        skip(
            f"{len(skipped)} obsolete/already-integrated patch"
            f"{'es' if len(skipped) != 1 else ''} skipped"
        )
        for reason, count in sorted(skip_reasons.items(), key=lambda x: (-x[1], x[0])):
            info(f"{reason}: {count}")

    return applied, skipped, failed, backup_branch if is_git else "(no git repo)"


# ========================= MAIN =========================
if __name__ == "__main__":
    banner()

    # ---- Step 1: Discover workspaces ----
    section("Step 1 / 3  -  Select workspace")
    info("Scanning Codex sessions...")
    workspaces = discover_workspaces()

    if not workspaces:
        fail("No Codex sessions found in ~/.codex")
        sys.exit(1)

    home = str(Path.home())
    print()
    for i, (cwd, cnt) in enumerate(workspaces, 1):
        short = cwd.replace(home, "~")
        name = Path(cwd).name
        bar = f"{C.DIM}{'|' * min(cnt, 20)}{C.RESET}"
        print(f"  {C.BOLD}{C.CYAN}{i:3d}{C.RESET}  {name:<35s} {C.DIM}{short}{C.RESET}")
        print(f"       {bar}  {cnt} session{'s' if cnt != 1 else ''}")

    choice = prompt("Enter workspace number")
    try:
        idx = int(choice) - 1
        if not 0 <= idx < len(workspaces):
            raise ValueError
    except ValueError:
        fail("Invalid selection.")
        sys.exit(1)

    workspace_path = Path(workspaces[idx][0]).resolve()
    ok(f"Workspace: {C.BOLD}{workspace_path}{C.RESET}")

    # ---- Step 2: Target repository ----
    section("Step 2 / 3  -  Target repository")
    info("Where should the recovered patches be applied?")
    info(f"This can be the same as the workspace, or a different clone.")

    default_repo = str(workspace_path)
    repo_input = prompt("Path to local repository", default=default_repo)
    repo_path = Path(repo_input).expanduser().resolve()

    if not repo_path.exists():
        fail(f"Path does not exist: {repo_path}")
        sys.exit(1)
    if not repo_path.is_dir():
        fail(f"Not a directory: {repo_path}")
        sys.exit(1)

    is_git = (repo_path / ".git").exists()
    if is_git:
        ok(f"Git repo detected at {C.BOLD}{repo_path}{C.RESET}")
    else:
        warn(f"Not a git repo (no backup branch will be created)")

    # ---- Step 3: Confirm ----
    section("Step 3 / 3  -  Confirm")
    w = _w()
    print()
    print(f"  {C.BOLD}Workspace :{C.RESET}  {workspace_path}")
    print(f"  {C.BOLD}Target    :{C.RESET}  {repo_path}")
    print(f"  {C.BOLD}Git repo  :{C.RESET}  {'Yes' if is_git else 'No'}")

    if not confirm("Proceed with recovery?"):
        print(f"\n{C.DIM}Aborted.{C.RESET}")
        sys.exit(0)

    # ---- Run recovery ----
    section("Scanning sessions")
    rollouts = find_relevant_rollouts(workspace_path)
    info(f"Found {C.BOLD}{len(rollouts)}{C.RESET} matching session(s)")

    all_patches = []
    for i, rollout in enumerate(rollouts, 1):
        short_name = rollout.stem[:50]
        print(f"\n  {C.DIM}[{i}/{len(rollouts)}]{C.RESET} {short_name}")
        patches, count = extract_patches(rollout)
        all_patches.extend(patches)
        if count:
            ok(f"{count} patch{'es' if count != 1 else ''} extracted in memory")
        else:
            info("No successful patches in this session")

    section("Extraction complete")
    info(f"Total patches to apply: {C.BOLD}{len(all_patches)}{C.RESET}")

    if not all_patches:
        warn("Nothing to apply. Check if the correct workspace was selected.")
        sys.exit(0)

    section("Applying patches")
    applied, skipped, failed, backup_branch = apply_patches_safely(all_patches, repo_path)

    # ---- Summary ----
    section("Recovery complete")
    w = _w()
    print()
    if is_git:
        print(f"  {C.BOLD}Backup branch :{C.RESET}  {backup_branch}")
    print(f"  {C.GREEN}{C.BOLD}Applied       :{C.RESET}  {len(applied)}")
    print(f"  {C.YELLOW}{C.BOLD}Skipped       :{C.RESET}  {len(skipped)}")
    if failed:
        print(f"  {C.RED}{C.BOLD}Failed        :{C.RESET}  {len(failed)}")
        print()
        for pf, reason in failed:
            fail(f"{pf.name}: {reason}")
    print(f"  {C.DIM}Patch storage :{C.RESET}  in memory (no codex_recovery files written)")

    if is_git and applied:
        print(f"\n  {C.DIM}Review the recovery branch before merging:{C.RESET}")
        print(f"    git status")
        print(f"    git diff --stat")
        print(f"    git diff")
        if failed:
            print(f"  {C.DIM}Resolve the failed patches before merging this branch.{C.RESET}")
        else:
            print(f"  {C.DIM}When it looks good:{C.RESET}")
            print(f"    git checkout main")
            print(f"    git merge {backup_branch}")

    print(f"\n{C.DIM}{'=' * w}{C.RESET}\n")
