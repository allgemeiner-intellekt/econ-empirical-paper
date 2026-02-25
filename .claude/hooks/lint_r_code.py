#!/usr/bin/env python3
"""R Code Lint Hook — PostToolUse on Write/Edit of *.R files."""
import json
import sys
import re
import os


def main():
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, EOFError):
        return

    tool_name = data.get("tool_name", "")
    tool_input = data.get("tool_input", {})

    file_path = tool_input.get("file_path", "")
    if not file_path.endswith(".R"):
        return

    # Get content to lint
    if tool_name == "Write":
        content = tool_input.get("content", "")
    elif tool_name == "Edit":
        if os.path.exists(file_path):
            with open(file_path) as f:
                content = f.read()
        else:
            return
    else:
        return

    basename = os.path.basename(file_path)
    warnings = []
    lines = content.split("\n")

    # Check 1: source("00_packages.R") should be first executable line
    if basename != "00_packages.R":
        found_source = False
        for line in lines:
            stripped = line.strip()
            if not stripped or stripped.startswith("#"):
                continue
            if 'source("00_packages.R")' in stripped or "source('00_packages.R')" in stripped:
                found_source = True
            break
        if not found_source:
            warnings.append(
                f'[LINT] {basename}: First executable line should be source("00_packages.R")'
            )

    # Check 2: log(x) without + 1
    for i, line in enumerate(lines, 1):
        stripped = line.strip()
        if stripped.startswith("#"):
            continue
        if re.search(r"\blog\([^)]+\)", stripped):
            if (
                not re.search(r"\blog\([^)]*\+\s*1[^)]*\)", stripped)
                and "log1p" not in stripped
            ):
                warnings.append(
                    f"[LINT] {basename}:{i}: Possible log(0) risk — consider log(x + 1)"
                )

    # Check 3: Bare API calls without tryCatch
    in_trycatch = False
    trycatch_depth = 0
    for i, line in enumerate(lines, 1):
        stripped = line.strip()
        if stripped.startswith("#"):
            continue
        if "tryCatch" in stripped:
            in_trycatch = True
            trycatch_depth += stripped.count("{") - stripped.count("}")
        elif in_trycatch:
            trycatch_depth += stripped.count("{") - stripped.count("}")
            if trycatch_depth <= 0:
                in_trycatch = False
                trycatch_depth = 0

        if re.search(r"httr::(GET|POST|PUT|DELETE)\(", stripped):
            if not in_trycatch:
                warnings.append(
                    f"[LINT] {basename}:{i}: API call without tryCatch() wrapper"
                )
            # Check for timeout
            context_start = max(0, i - 4)
            context_end = min(len(lines), i + 3)
            context = "\n".join(lines[context_start:context_end])
            if "timeout" not in context:
                warnings.append(
                    f"[LINT] {basename}:{i}: API call may be missing httr::timeout()"
                )

    # Check 4: FIPS as numeric
    for i, line in enumerate(lines, 1):
        stripped = line.strip()
        if stripped.startswith("#"):
            continue
        if re.search(r"as\.(numeric|integer)\(.*fips", stripped, re.IGNORECASE):
            warnings.append(
                f"[LINT] {basename}:{i}: Converting FIPS to numeric — will lose leading zeros"
            )

    # Print warnings to stderr
    if warnings:
        print("\n".join(warnings), file=sys.stderr)


if __name__ == "__main__":
    main()
