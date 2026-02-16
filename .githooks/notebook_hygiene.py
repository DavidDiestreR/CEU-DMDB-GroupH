#!/usr/bin/env python3
import argparse
import json
import subprocess
import sys
from pathlib import Path


def run_git(args):
    return subprocess.run(["git", *args], text=True, capture_output=True)


def staged_notebooks():
    proc = run_git(["diff", "--cached", "--name-only", "--diff-filter=ACM"])
    if proc.returncode != 0:
        print("notebook-hygiene: failed to list staged files.", file=sys.stderr)
        if proc.stderr:
            print(proc.stderr.strip(), file=sys.stderr)
        return None
    files = [line.strip() for line in proc.stdout.splitlines() if line.strip()]
    return [f for f in files if f.endswith(".ipynb")]


def tracked_notebooks():
    proc = run_git(["ls-files", "*.ipynb"])
    if proc.returncode != 0:
        print("notebook-hygiene: failed to list tracked notebooks.", file=sys.stderr)
        if proc.stderr:
            print(proc.stderr.strip(), file=sys.stderr)
        return None
    return [line.strip() for line in proc.stdout.splitlines() if line.strip()]


def load_notebook(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f), None
    except Exception as exc:
        return None, str(exc)


def notebook_issues(nb):
    issues = []
    cells = nb.get("cells", [])
    if isinstance(cells, list):
        for idx, cell in enumerate(cells):
            if not isinstance(cell, dict) or cell.get("cell_type") != "code":
                continue
            outputs = cell.get("outputs")
            if isinstance(outputs, list) and len(outputs) > 0:
                issues.append(f"cell {idx}: outputs not empty")
            if cell.get("execution_count") is not None:
                issues.append(f"cell {idx}: execution_count is not null")
    metadata = nb.get("metadata")
    if isinstance(metadata, dict) and "widgets" in metadata:
        issues.append("metadata.widgets present")
    return issues


def strip_notebook(nb):
    changed = False
    for cell in nb.get("cells", []):
        if not isinstance(cell, dict) or cell.get("cell_type") != "code":
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
    return changed


def write_notebook(path, nb):
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        json.dump(nb, f, ensure_ascii=False, indent=1)
        f.write("\n")


def fix_staged():
    notebooks = staged_notebooks()
    if notebooks is None:
        return 1
    if not notebooks:
        return 0

    changed_any = False
    for nb_path in notebooks:
        path = Path(nb_path)
        if not path.exists():
            continue
        nb, err = load_notebook(path)
        if err is not None:
            print(f"pre-commit: failed to parse notebook '{nb_path}': {err}", file=sys.stderr)
            return 1
        changed = strip_notebook(nb)
        if changed:
            write_notebook(path, nb)
            add = run_git(["add", "--", nb_path])
            if add.returncode != 0:
                print(f"pre-commit: failed to re-stage notebook '{nb_path}'.", file=sys.stderr)
                if add.stderr:
                    print(add.stderr.strip(), file=sys.stderr)
                return 1
            print(f"pre-commit: stripped outputs from {nb_path}")
            changed_any = True

    if changed_any:
        print("pre-commit: notebook outputs were removed and re-staged.")
    return 0


def check_all(paths):
    if not paths:
        paths = tracked_notebooks()
        if paths is None:
            return 2

    if not paths:
        print("notebook-hygiene: no notebooks found.")
        return 0

    bad = 0
    for p in paths:
        path = Path(p)
        if not path.exists() or path.suffix != ".ipynb":
            continue
        nb, err = load_notebook(path)
        if err is not None:
            bad += 1
            print(f"FAIL {p}")
            print(f"  - parse error: {err}")
            continue

        issues = notebook_issues(nb)
        if issues:
            bad += 1
            print(f"FAIL {p}")
            for issue in issues:
                print(f"  - {issue}")

    if bad:
        print(
            f"\nnotebook-hygiene: {bad} notebook(s) contain outputs/state.",
            file=sys.stderr,
        )
        return 1

    print("notebook-hygiene: all notebooks are clean.")
    return 0


def parse_args():
    parser = argparse.ArgumentParser(description="Notebook hygiene utilities")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--fix-staged", action="store_true", help="Strip staged notebooks in pre-commit")
    group.add_argument("--check-all", action="store_true", help="Fail if tracked notebooks contain outputs/state")
    parser.add_argument("paths", nargs="*", help="Optional notebook paths for --check-all")
    return parser.parse_args()


def main():
    args = parse_args()
    if args.fix_staged:
        return fix_staged()
    return check_all(args.paths)


if __name__ == "__main__":
    sys.exit(main())
