#!/usr/bin/env python3
"""check_architecture.py

Lightweight checker that enforces a subset of `Tools/ARCHITECTURE.md` rules.
This script emits warnings and exit 0 for warn-only mode, or non-zero for strict mode.
"""
import argparse
import os
import sys

def check_project(path, warn_only=True):
    issues = []
    # Quick helpers
    def is_yaml_multi_doc(fp):
        try:
            with open(fp, 'r', encoding='utf-8') as fh:
                return '\n---' in fh.read()
        except Exception:
            return False
    # Rule: No Swift files under SharedTypes should import SwiftUI
    for root, _dirs, files in os.walk(path):
        for f in files:
            if f.endswith('.swift'):
                fp = os.path.join(root, f)
                try:
                    with open(fp, 'r', encoding='utf-8') as fh:
                        txt = fh.read()
                        if 'SharedTypes' in root and 'import SwiftUI' in txt:
                            issues.append(f"{fp}: SharedTypes must not import SwiftUI")
                except Exception:
                    pass

    # Example rule: Avoid TODO/FIXME in code (stricter)
    todo_count = 0
    for root, _dirs, files in os.walk(path):
        for f in files:
            if f.endswith(('.swift', '.py', '.sh', '.m', '.mm', '.kt', '.java')):
                fp = os.path.join(root, f)
                try:
                    with open(fp, 'r', encoding='utf-8') as fh:
                        for line in fh:
                            if 'TODO' in line or 'FIXME' in line:
                                todo_count += 1
                except Exception:
                    pass
    if todo_count > 10:
        issues.append(f"Project has {todo_count} TODO/FIXME markers; consider cleaning up (threshold=10)")

    # Rule: Detect GitHub Actions workflow multi-document YAMLs (not allowed by policy)
    workflows_dir = os.path.join(path, '.github', 'workflows')
    if os.path.isdir(workflows_dir):
        for wf in os.listdir(workflows_dir):
            if wf.endswith(('.yml', '.yaml')):
                fp = os.path.join(workflows_dir, wf)
                if is_yaml_multi_doc(fp):
                    issues.append(f"Workflow {fp} contains multiple YAML documents (---). Split into single-document files.")
                # Rule: detect deprecated/pinned actions usage heuristics
                try:
                    with open(fp, 'r', encoding='utf-8') as fh:
                        txt = fh.read()
                        # simple heuristic: actions/checkout@v1 or actions/setup-python@v1
                        if '@v1' in txt or "@v2" in txt and 'actions/checkout' in txt and 'actions/setup-python' in txt:
                            issues.append(f"Workflow {fp} may reference deprecated action major versions (check version pins)")
                except Exception:
                    pass
    else:
        issues.append(f"Missing workflows directory: {workflows_dir}")

    # Rule: Check Dockerfiles that use 'latest' tag
    for root, _dirs, files in os.walk(path):
        for f in files:
            if f == 'Dockerfile':
                fp = os.path.join(root, f)
                try:
                    with open(fp, 'r', encoding='utf-8') as fh:
                        for line in fh:
                            if 'FROM' in line and ':latest' in line:
                                issues.append(f"Dockerfile {fp} pins image with :latest; use an explicit tag or digest")
                except Exception:
                    pass

    # Rule: If project contains an Xcode project, ensure there's at least one macOS/iOS workflow
    has_xcode = any(f.endswith('.xcodeproj') for _, _dirs, files in os.walk(path) for f in files)
    if has_xcode:
        found_ci = False
        if os.path.isdir(workflows_dir):
            for wf in os.listdir(workflows_dir):
                if wf.endswith(('.yml', '.yaml')):
                    fp = os.path.join(workflows_dir, wf)
                    try:
                        with open(fp, 'r', encoding='utf-8') as fh:
                            txt = fh.read()
                            if 'macos' in txt or 'macOS' in txt or 'xcodebuild' in txt:
                                found_ci = True
                    except Exception:
                        pass
        if not found_ci:
            issues.append('Xcode project detected but no macOS/iOS CI workflow found in .github/workflows')

    return issues

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--project', required=True)
    parser.add_argument('--warn-only', action='store_true', default=False)
    args = parser.parse_args()

    path = args.project
    if not os.path.isdir(path):
        print(f"Project path not found: {path}")
        sys.exit(2)

    issues = check_project(path, warn_only=args.warn_only)
    if issues:
        print("Architecture issues detected:")
        for it in issues:
            print(f" - {it}")
        if args.warn_only:
            print("Warn-only mode: continuing with warnings")
            sys.exit(0)
        else:
            print("Strict mode: failing")
            sys.exit(1)
    else:
        print("No architecture issues detected")
        sys.exit(0)

if __name__ == '__main__':
    main()
