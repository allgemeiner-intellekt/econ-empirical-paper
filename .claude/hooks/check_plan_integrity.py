#!/usr/bin/env python3
"""Pre-Analysis Plan Integrity Hook — PostToolUse on Write/Edit of initial_plan.md."""
import json
import sys
import hashlib
import os
import re
from datetime import datetime, timezone


def compute_sha256(file_path):
    """Compute SHA-256 hash of a file."""
    h = hashlib.sha256()
    with open(file_path, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            h.update(chunk)
    return h.hexdigest()


def main():
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, EOFError):
        return

    tool_input = data.get("tool_input", {})
    file_path = tool_input.get("file_path", "")

    # Only trigger on initial_plan.md
    if not file_path.endswith("initial_plan.md"):
        return

    if not os.path.exists(file_path):
        return

    plan_dir = os.path.dirname(file_path)
    pre_analysis_path = os.path.join(plan_dir, "pre_analysis.md")

    # If pre_analysis.md doesn't exist yet, plan hasn't been locked — nothing to check
    if not os.path.exists(pre_analysis_path):
        return

    # Compute current hash
    current_hash = compute_sha256(file_path)

    # Extract stored hash from pre_analysis.md
    with open(pre_analysis_path, "r") as f:
        content = f.read()

    stored_hash = None
    for line in content.split("\n"):
        match = re.search(r"SHA-256:\s*(?:sha256:)?([a-f0-9]{64})", line, re.IGNORECASE)
        if match:
            stored_hash = match.group(1)
            break

    if stored_hash is None:
        print(
            "[PLAN INTEGRITY] WARNING: pre_analysis.md exists but no SHA-256 hash found",
            file=sys.stderr,
        )
        return

    if current_hash != stored_hash:
        print(
            f"[PLAN INTEGRITY] WARNING: initial_plan.md has been modified after locking!",
            file=sys.stderr,
        )
        print(f"  Stored hash:  {stored_hash}", file=sys.stderr)
        print(f"  Current hash: {current_hash}", file=sys.stderr)
        print(
            "  This deviation must be documented and justified in the paper.",
            file=sys.stderr,
        )

        # Record deviation in deviations.json
        deviations_path = os.path.join(plan_dir, "deviations.json")
        deviations = {"deviations": []}
        if os.path.exists(deviations_path):
            try:
                with open(deviations_path, "r") as f:
                    deviations = json.load(f)
            except (json.JSONDecodeError, IOError):
                pass

        deviations["deviations"].append(
            {
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "file": "initial_plan.md",
                "old_hash": stored_hash,
                "new_hash": current_hash,
                "description": "Plan modified after SHA-256 lock",
                "justification": "NEEDS JUSTIFICATION — update this entry",
            }
        )

        with open(deviations_path, "w") as f:
            json.dump(deviations, f, indent=2)

        print(
            f"  Deviation logged to {deviations_path}",
            file=sys.stderr,
        )


if __name__ == "__main__":
    main()
