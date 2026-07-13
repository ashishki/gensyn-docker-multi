#!/usr/bin/env python3
"""Fail when an active workflow weakens the repository's CI trust boundary."""

from __future__ import annotations

import re
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
WORKFLOW_DIR = REPO_ROOT / ".github" / "workflows"
PINNED_OFFICIAL_ACTIONS = {
    "actions/checkout": "9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0",
    "actions/setup-python": "ece7cb06caefa5fff74198d8649806c4678c61a1",
    "actions/setup-node": "a0853c24544627f65ddf259abe73b1d18a591444",
}
USES_PATTERN = re.compile(
    r"^[ \t]*(?:-[ \t]*)?uses:[ \t]+([^\s#]+)",
    re.MULTILINE,
)


def verify_workflow(path: Path) -> int:
    text = path.read_text(encoding="utf-8")
    permission_blocks = re.findall(r"(?m)^([ \t]*)permissions:[ \t]*$", text)
    if permission_blocks != [""]:
        raise ValueError(f"{path}: require exactly one top-level permissions block")

    permissions = re.search(
        r"(?m)^permissions:\s*\n(?P<body>(?:^[ \t]+[^\n]*\n?)*)", text
    )
    if permissions is None:
        raise ValueError(f"{path}: missing permissions block")
    permission_lines = [
        line.strip() for line in permissions.group("body").splitlines() if line.strip()
    ]
    if permission_lines != ["contents: read"]:
        raise ValueError(f"{path}: permissions must be exactly contents: read")

    action_references = USES_PATTERN.findall(text)
    if not action_references:
        raise ValueError(f"{path}: expected at least one approved action")
    for reference in action_references:
        action, separator, revision = reference.partition("@")
        expected = PINNED_OFFICIAL_ACTIONS.get(action)
        if separator != "@" or expected is None or revision != expected:
            raise ValueError(f"{path}: {reference} is not an approved pin")

    lines = text.splitlines()
    checkout_steps = 0
    for index, line in enumerate(lines):
        match = re.match(r"^([ \t]*)-[ \t]+uses:[ \t]+actions/checkout@", line)
        if match is None:
            continue
        checkout_steps += 1
        indent = len(match.group(1))
        end = len(lines)
        for candidate_index in range(index + 1, len(lines)):
            if re.match(rf"^[ \t]{{{indent}}}-[ \t]+", lines[candidate_index]):
                end = candidate_index
                break
        block = lines[index:end]
        if not any(item.strip() == "persist-credentials: false" for item in block):
            raise ValueError(f"{path}: checkout must disable credential persistence")
    if checkout_steps == 0:
        raise ValueError(f"{path}: expected at least one checkout step")
    return len(action_references)


def main() -> None:
    workflows = sorted((*WORKFLOW_DIR.glob("*.yml"), *WORKFLOW_DIR.glob("*.yaml")))
    if not workflows:
        raise ValueError("no active GitHub Actions workflows found")
    action_count = sum(verify_workflow(path) for path in workflows)
    print(
        f"verified {len(workflows)} workflow(s), {action_count} approved action pin(s)"
    )


if __name__ == "__main__":
    main()
