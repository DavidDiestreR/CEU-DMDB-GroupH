#!/usr/bin/env python3
import json
import subprocess
import sys
from pathlib import Path


def run_git(args):
    return subprocess.run(["git", *args], text=True, capture_output=True)


def staged_notebooks():
    proc = run_git(["diff", "--cached", "--name-only", "--diff-filter=ACM"])
    if proc.returncode != 0:
        print("pre-commit: failed to list staged files.", file=sys.stderr)
        if proc.stderr:
            print(proc.stderr.strip(), file=sys.stderr)
        return None

    files = [line.strip() for line in proc.stdout.splitlines() if line.strip()]
    return [f for f in files if f.endswith(".ipynb")]


def strip_notebook(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            nb = json.load(f)
    except Exception:
        print(f"pre-commit: failed to parse notebook '{path}'.", file=sys.stderr)
        return False, True

    changed = False

    for cell in nb.get("cells", []):
        if cell.get("cell_type") != "code":
            continue

        outputs = cell.get("outputs")
        if isinstance(outputs, list) and len(outputs) > 0:
            cell["outputs"] = []
            changed = True

        if "execution_count" in cell and cell.get("execution_count") is not None:
            cell["execution_count"] = None
            changed = True

    metadata = nb.get("metadata")
    if isinstance(metadata, dict) and "widgets" in metadata:
        del metadata["widgets"]
        changed = True

    if changed:
        with open(path, "w", encoding="utf-8", newline="\n") as f:
            json.dump(nb, f, ensure_ascii=False, indent=1)
            f.write("\n")

    return changed, False


def main():
    notebooks = staged_notebooks()
    if notebooks is None:
        return 1

    if not notebooks:
        return 0

    changed_any = False

    for nb in notebooks:
        p = Path(nb)
        if not p.exists():
            continue

        changed, had_error = strip_notebook(p)
        if had_error:
            return 1

        if changed:
            add = run_git(["add", "--", nb])
            if add.returncode != 0:
                print(f"pre-commit: failed to re-stage notebook '{nb}'.", file=sys.stderr)
                if add.stderr:
                    print(add.stderr.strip(), file=sys.stderr)
                return 1
            print(f"pre-commit: stripped outputs from {nb}")
            changed_any = True

    if changed_any:
        print("pre-commit: notebook outputs were removed and re-staged.")

    return 0


if __name__ == "__main__":
    sys.exit(main())