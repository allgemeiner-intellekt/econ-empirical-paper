#!/usr/bin/env python3
"""Pre-Execution Dependency Check — PreToolUse on Bash with Rscript/bash."""
import json
import sys
import os
import glob


def main():
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, EOFError):
        return

    tool_name = data.get("tool_name", "")
    tool_input = data.get("tool_input", {})

    if tool_name != "Bash":
        return

    command = tool_input.get("command", "")

    # Only trigger on Rscript or bash run_all commands
    if "Rscript" not in command and "run_all" not in command:
        return

    warnings = []

    # Try to find the project code directory
    # Look for code/ relative to CWD or in the command path
    cwd = os.getcwd()
    code_dir = None
    for candidate in [
        os.path.join(cwd, "code"),
        os.path.join(cwd, "..", "code") if "code" in cwd else None,
        cwd if cwd.endswith("code") else None,
    ]:
        if candidate and os.path.isdir(candidate):
            code_dir = candidate
            break

    if code_dir is None:
        # Can't find code directory — not necessarily an error, skip checks
        return

    project_dir = (
        os.path.dirname(code_dir) if not code_dir.endswith("code") else os.path.dirname(code_dir)
    )

    # Check 1: Expected scripts exist
    expected_scripts = [
        "00_packages.R",
        "01_fetch_data.R",
        "02_clean_data.R",
        "03_main_analysis.R",
        "04_robustness.R",
        "05_figures.R",
        "06_tables.R",
        "run_all.sh",
    ]
    # Also accept 01_load_data.R as alternative to 01_fetch_data.R
    alt_scripts = {"01_fetch_data.R": "01_load_data.R"}

    missing = []
    for script in expected_scripts:
        path = os.path.join(code_dir, script)
        alt = alt_scripts.get(script)
        alt_path = os.path.join(code_dir, alt) if alt else None
        if not os.path.exists(path) and not (alt_path and os.path.exists(alt_path)):
            missing.append(script)

    if missing:
        warnings.append(f"[PRE-EXEC] Missing scripts in code/: {', '.join(missing)}")

    # Check 2: data/ directory
    data_dir = os.path.join(project_dir, "data")
    if not os.path.isdir(data_dir):
        warnings.append(
            "[PRE-EXEC] data/ directory does not exist — will be created by scripts if needed"
        )

    # Check 3: Check if scripts reference API keys that aren't set
    api_keys_to_check = {
        "FRED_API_KEY": "fredr|FRED",
        "CENSUS_API_KEY": "census|acs",
        "BLS_API_KEY": "bls\\.gov",
    }
    for script in glob.glob(os.path.join(code_dir, "*.R")):
        try:
            with open(script) as f:
                content = f.read()
        except IOError:
            continue
        for env_var, pattern in api_keys_to_check.items():
            import re

            if re.search(pattern, content, re.IGNORECASE) and env_var in content:
                if not os.environ.get(env_var):
                    warnings.append(
                        f"[PRE-EXEC] {os.path.basename(script)} references {env_var} but it's not set in environment"
                    )

    if warnings:
        print("\n".join(warnings), file=sys.stderr)


if __name__ == "__main__":
    main()
