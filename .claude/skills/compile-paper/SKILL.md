---
name: compile-paper
description: >-
  Compile LaTeX manuscript to PDF, verify quality, and generate project
  metadata.
disable-model-invocation: true
---

# Compile Paper — LaTeX to PDF Compilation and Packaging

You compile the LaTeX manuscript into PDF and generate final project metadata.

## Prerequisites

- `paper.tex` — LaTeX manuscript
- `references.bib` — Bibliography file (non-empty)
- `figures/` — PDF figures referenced by paper.tex
- `tables/` — .tex table fragments referenced by paper.tex

## Compilation Sequence

```bash
cd [project_dir]
pdflatex paper.tex
bibtex paper
pdflatex paper.tex
pdflatex paper.tex
```

Three passes of pdflatex are required: first for structure, bibtex for references, second for cross-references, third for final page numbers.

## Error Handling

If compilation fails:

### Common LaTeX Errors
| Error | Cause | Fix |
|-------|-------|-----|
| `File not found` | Missing \input{} or \includegraphics{} target | Check file paths, verify files exist |
| `Undefined control sequence` | Missing package or typo | Add `\usepackage{}` or fix command name |
| `Missing $ inserted` | Math mode issue | Wrap in `$...$` or `\(...\)` |
| `Too many unprocessed floats` | Too many figures/tables | Add `\clearpage` or use `[H]` placement |
| `Citation undefined` | bibtex not run or .bib error | Re-run bibtex, check .bib syntax |

### Diagnosis Process
1. Read the `.log` file for detailed error messages
2. Identify the line number and file
3. Fix the issue in `paper.tex` or referenced files
4. Re-compile

## Post-Compilation Checks

After successful compilation:
1. **Page count**: Read from PDF or log. Must be ≥ 25 pages.
2. **Figures included**: Verify all `\includegraphics` resolved (no missing figure placeholders)
3. **Tables included**: Verify all `\input{tables/...}` resolved
4. **References**: Check for "??" in the PDF (unresolved references)
5. **Bibliography**: Verify references section is non-empty

## Metadata Generation

Create `metadata.json`:
```json
{
  "title": "Paper title",
  "method": "DiD|RDD|IV|SCM|DR",
  "domain": "Policy domain",
  "created_at": "ISO-8601",
  "version": 1,
  "stages_completed": [1, 2, 3, 4, 5, 6, 7, 8],
  "figures_count": 9,
  "tables_count": 4,
  "pages": null
}
```

## Replication Guide

Create `REPLICATION.md`:
```markdown
# Replication Guide

## Requirements
- R 4.x with packages listed in `code/00_packages.R`
- API keys: [list required keys, if any]
- LaTeX distribution (TeX Live or MiKTeX)

## Steps
1. Set API keys as environment variables (if applicable)
2. `cd code && bash run_all.sh`
3. `cd .. && pdflatex paper.tex && bibtex paper && pdflatex paper.tex && pdflatex paper.tex`

## Data Sources
[List all data sources with access information]

## Expected Output
- [N] figures in `figures/`
- [N] tables in `tables/`
- `paper.pdf` (~[N] pages)
```

## Completeness Report

Report to the user:
```markdown
## Compilation Summary

- **PDF**: paper.pdf ([N] pages)
- **Figures**: [N] included
- **Tables**: [N] included
- **References**: [N] cited
- **Pre-analysis plan compliance**: [all checks reported? Y/N]
- **Compilation warnings**: [any LaTeX warnings]
```

## After Compilation

Tell the user: "Paper complete! Output in `[project_dir]/`. Review `paper.pdf`."
