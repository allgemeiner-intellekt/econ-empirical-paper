#!/usr/bin/env python3
"""LaTeX Pre-Compile Validation — PreToolUse on Bash with pdflatex."""
import json
import sys
import os
import re


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

    if "pdflatex" not in command:
        return

    # Extract .tex file from command
    tex_match = re.search(r"pdflatex\s+(\S+\.tex)", command)
    if not tex_match:
        return

    tex_file = tex_match.group(1)
    cwd = os.getcwd()

    # Resolve tex file path
    if not os.path.isabs(tex_file):
        tex_file = os.path.join(cwd, tex_file)

    if not os.path.exists(tex_file):
        print(f"[PRE-COMPILE] WARNING: {tex_file} not found", file=sys.stderr)
        return

    tex_dir = os.path.dirname(tex_file)
    warnings = []

    with open(tex_file, "r") as f:
        content = f.read()

    # Check 1: \input{} references
    input_refs = re.findall(r"\\input\{([^}]+)\}", content)
    for ref in input_refs:
        ref_path = os.path.join(tex_dir, ref)
        # Add .tex extension if missing
        if not os.path.exists(ref_path) and not ref.endswith(".tex"):
            ref_path = ref_path + ".tex"
        if not os.path.exists(ref_path):
            warnings.append(f"[PRE-COMPILE] Missing \\input file: {ref}")

    # Check 2: \includegraphics{} references
    graphics_refs = re.findall(r"\\includegraphics(?:\[[^\]]*\])?\{([^}]+)\}", content)
    for ref in graphics_refs:
        ref_path = os.path.join(tex_dir, ref)
        if not os.path.exists(ref_path):
            # Try with common extensions
            found = False
            for ext in [".pdf", ".png", ".jpg", ".eps"]:
                if os.path.exists(ref_path + ext):
                    found = True
                    break
            if not found:
                warnings.append(f"[PRE-COMPILE] Missing figure: {ref}")

    # Check 3: references.bib
    if "\\bibliography{" in content:
        bib_match = re.search(r"\\bibliography\{([^}]+)\}", content)
        if bib_match:
            bib_name = bib_match.group(1)
            bib_path = os.path.join(tex_dir, bib_name)
            if not bib_path.endswith(".bib"):
                bib_path += ".bib"
            if not os.path.exists(bib_path):
                warnings.append(f"[PRE-COMPILE] Missing bibliography file: {bib_name}.bib")
            elif os.path.getsize(bib_path) == 0:
                warnings.append(f"[PRE-COMPILE] {bib_name}.bib is empty")

    if warnings:
        print("\n".join(warnings), file=sys.stderr)
    else:
        print("[PRE-COMPILE] ✓ All referenced files found", file=sys.stderr)


if __name__ == "__main__":
    main()
