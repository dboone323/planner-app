#!/usr/bin/env python3
"""Post a deterministic PR review comment with actionable findings.

This script is intended for CI use in GitHub Actions and does not require
external AI APIs. It inspects changed files/patches from the PR and posts
(or updates) a single marker comment on the PR.
"""

from __future__ import annotations

import os
import re
import sys
from dataclasses import dataclass
from typing import Dict, Iterable, List

import requests


@dataclass
class Finding:
    file: str
    level: str
    message: str


def require_env(name: str) -> str:
    value = os.getenv(name)
    if not value:
        raise RuntimeError(f"Missing required environment variable: {name}")
    return value


def github_headers(token: str) -> Dict[str, str]:
    return {
        "Authorization": f"token {token}",
        "Accept": "application/vnd.github+json",
        "User-Agent": "copilot-review-ci/1.0",
    }


def paged_get(
    url: str, headers: Dict[str, str], params: Dict[str, str] | None = None
) -> List[dict]:
    items: List[dict] = []
    page = 1
    while True:
        qp = {"per_page": 100, "page": page}
        if params:
            qp.update(params)
        response = requests.get(url, headers=headers, params=qp, timeout=30)
        response.raise_for_status()
        batch = response.json()
        if not isinstance(batch, list) or not batch:
            break
        items.extend(batch)
        if len(batch) < 100:
            break
        page += 1
    return items


def iter_added_lines(patch: str) -> Iterable[str]:
    for line in patch.splitlines():
        if line.startswith("+++"):
            continue
        if line.startswith("+"):
            yield line[1:]


def analyze_file(file_entry: dict) -> List[Finding]:
    filename = file_entry.get("filename", "")
    patch = file_entry.get("patch") or ""
    findings: List[Finding] = []

    if not patch:
        return findings

    added_lines = list(iter_added_lines(patch))
    lower_name = filename.lower()

    for idx, line in enumerate(added_lines, start=1):
        stripped = line.strip()

        if "todo" in stripped.lower() or "fixme" in stripped.lower():
            findings.append(
                Finding(filename, "info", f"Added unresolved note: `{stripped[:120]}`")
            )

        if re.search(r"\beval\s*\(", stripped) and lower_name.endswith(
            (".py", ".js", ".ts", ".sh", ".bash")
        ):
            findings.append(
                Finding(
                    filename,
                    "high",
                    "Uses `eval(...)`; verify input is trusted to avoid code injection.",
                )
            )

        if "shell=True" in stripped and lower_name.endswith(".py"):
            findings.append(
                Finding(
                    filename,
                    "high",
                    "`subprocess` with `shell=True` detected; prefer argument arrays when possible.",
                )
            )

        if stripped.startswith("uses:") and "@" in stripped:
            # Flag mutable refs like main/master/v* tags.
            if re.search(r"@[A-Za-z][A-Za-z0-9._/-]*$", stripped):
                if any(token in stripped for token in ("@main", "@master", "@v")):
                    findings.append(
                        Finding(
                            filename,
                            "medium",
                            "Action reference appears mutable; pin to a full commit SHA for supply-chain safety.",
                        )
                    )

        if len(stripped) > 180:
            findings.append(
                Finding(
                    filename,
                    "low",
                    f"Long added line ({len(stripped)} chars) may hurt readability.",
                )
            )

        if idx >= 500:
            break

    return findings


def format_comment(
    repo: str, pr_number: str, files: List[dict], findings: List[Finding]
) -> str:
    marker = "<!-- copilot-review-bot -->"
    changed = len(files)
    added = sum(int(f.get("additions", 0)) for f in files)
    deleted = sum(int(f.get("deletions", 0)) for f in files)

    lines = [
        marker,
        "## Copilot Review (Deterministic)",
        "",
        f"Repository: `{repo}`",
        f"PR: `#{pr_number}`",
        f"Files changed: `{changed}` | Added: `{added}` | Removed: `{deleted}`",
        "",
    ]

    if not findings:
        lines.append("No high-confidence issues were detected in the changed hunks.")
        lines.append("")
        lines.append(
            "Checks performed: TODO/FIXME notes, risky eval/shell usage, mutable action refs, very long added lines."
        )
        return "\n".join(lines)

    grouped: Dict[str, List[Finding]] = {
        "high": [],
        "medium": [],
        "low": [],
        "info": [],
    }
    for finding in findings:
        grouped.setdefault(finding.level, []).append(finding)

    lines.append("### Findings")
    for level in ("high", "medium", "low", "info"):
        items = grouped.get(level, [])
        if not items:
            continue
        lines.append(f"- `{level.upper()}`: {len(items)}")

    lines.append("")
    lines.append("### Details")
    for level in ("high", "medium", "low", "info"):
        for finding in grouped.get(level, [])[:20]:
            lines.append(
                f"- `{finding.level.upper()}` `{finding.file}`: {finding.message}"
            )

    if len(findings) > 20:
        lines.append(f"- Additional findings not shown: {len(findings) - 20}")

    return "\n".join(lines)


def upsert_comment(
    owner: str, repo_name: str, pr_number: str, token: str, body: str
) -> None:
    headers = github_headers(token)
    comments_url = (
        f"https://api.github.com/repos/{owner}/{repo_name}/issues/{pr_number}/comments"
    )
    comments = paged_get(comments_url, headers)

    marker = "<!-- copilot-review-bot -->"
    existing_id: int | None = None
    for comment in comments:
        user_login = ((comment.get("user") or {}).get("login") or "").lower()
        comment_body = comment.get("body") or ""
        if marker in comment_body and user_login in {
            "github-actions[bot]",
            "dboone323",
            "codex",
        }:
            existing_id = comment.get("id")
            break

    if existing_id:
        url = f"https://api.github.com/repos/{owner}/{repo_name}/issues/comments/{existing_id}"
        response = requests.patch(url, headers=headers, json={"body": body}, timeout=30)
    else:
        response = requests.post(
            comments_url, headers=headers, json={"body": body}, timeout=30
        )

    response.raise_for_status()


def main() -> int:
    token = require_env("GITHUB_TOKEN")
    owner = require_env("GITHUB_OWNER")
    repo_name = require_env("GITHUB_REPO")
    pr_number = require_env("PR_NUMBER")
    repo = f"{owner}/{repo_name}"

    headers = github_headers(token)
    files_url = (
        f"https://api.github.com/repos/{owner}/{repo_name}/pulls/{pr_number}/files"
    )
    files = paged_get(files_url, headers)

    findings: List[Finding] = []
    for file_entry in files[:200]:
        findings.extend(analyze_file(file_entry))

    # Keep the comment concise and stable between reruns.
    unique = {(f.file, f.level, f.message): f for f in findings}
    deduped = list(unique.values())
    deduped.sort(key=lambda f: (f.level, f.file, f.message))

    body = format_comment(repo=repo, pr_number=pr_number, files=files, findings=deduped)
    upsert_comment(
        owner=owner, repo_name=repo_name, pr_number=pr_number, token=token, body=body
    )
    print(
        f"Posted review comment for {repo} PR #{pr_number} with {len(deduped)} finding(s)."
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:  # noqa: BLE001 - fail loudly in CI logs
        print(f"copilot-review failed: {exc}", file=sys.stderr)
        raise SystemExit(1)
