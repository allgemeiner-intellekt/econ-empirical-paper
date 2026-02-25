#!/usr/bin/env python3
"""Post-Execution Output Verification — PostToolUse on Bash with Rscript/bash."""
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
    cwd = os.getcwd()

    # Try to find project directory
    project_dir = None
    for candidate in [
        cwd,
        os.path.dirname(cwd) if os.path.basename(cwd) == "code" else None,
    ]:
        if candidate and (
            os.path.isdir(os.path.join(candidate, "figures"))
            or os.path.isdir(os.path.join(candidate, "tables"))
            or os.path.isdir(os.path.join(candidate, "data"))
        ):
            project_dir = candidate
            break

    if project_dir is None:
        return

    # Check 1: Figure count
    figures_dir = os.path.join(project_dir, "figures")
    if os.path.isdir(figures_dir):
        pdfs = glob.glob(os.path.join(figures_dir, "*.pdf"))
        if len(pdfs) < 8:
            warnings.append(
                f"[POST-EXEC] Only {len(pdfs)} PDF figures found in figures/ (expected ≥ 8)"
            )
        else:
            print(
                f"[POST-EXEC] ✓ {len(pdfs)} PDF figures in figures/",
                file=sys.stderr,
            )
    else:
        warnings.append("[POST-EXEC] figures/ directory not found")

    # Check 2: Table count
    tables_dir = os.path.join(project_dir, "tables")
    if os.path.isdir(tables_dir):
        tex_files = glob.glob(os.path.join(tables_dir, "*.tex"))
        if len(tex_files) < 4:
            warnings.append(
                f"[POST-EXEC] Only {len(tex_files)} .tex tables found in tables/ (expected ≥ 4)"
            )
        else:
            print(
                f"[POST-EXEC] ✓ {len(tex_files)} .tex tables in tables/",
                file=sys.stderr,
            )
    else:
        warnings.append("[POST-EXEC] tables/ directory not found")

    # Check 3: analysis_panel.rds
    panel_path = os.path.join(project_dir, "data", "analysis_panel.rds")
    if os.path.exists(panel_path):
        size = os.path.getsize(panel_path)
        if size < 1024:
            warnings.append(
                f"[POST-EXEC] analysis_panel.rds is only {size} bytes (expected > 1KB)"
            )
        else:
            size_kb = size / 1024
            print(
                f"[POST-EXEC] ✓ analysis_panel.rds ({size_kb:.1f} KB)",
                file=sys.stderr,
            )
    else:
        warnings.append("[POST-EXEC] data/analysis_panel.rds not found")

    # Check 4: main_results.rds
    results_path = os.path.join(project_dir, "data", "main_results.rds")
    if os.path.exists(results_path):
        print("[POST-EXEC] ✓ main_results.rds exists", file=sys.stderr)
    else:
        warnings.append("[POST-EXEC] data/main_results.rds not found")

    if warnings:
        print("\n".join(warnings), file=sys.stderr)


if __name__ == "__main__":
    main()
