---
name: write-paper
description: >-
  Generate a complete LaTeX manuscript meeting AER/QJE publication standards
  (25+ pages).
disable-model-invocation: true
---

# Write Paper — Generate Publication-Quality LaTeX Manuscript

You generate a complete LaTeX manuscript from analysis outputs, meeting AER/QJE publication standards.

## Prerequisites

Verify these exist before starting:
- `initial_plan.md` — Pre-analysis plan
- `code/03_main_analysis.R` — To extract estimation details
- `data/main_results.rds` or `data/estimates_table.csv` — Point estimates, SEs, p-values
- `figures/` — At least 8 PDF figures
- `tables/` — At least 4 .tex table fragments

## Before Writing

Read these references:
- `.claude/docs/writing-standards.md` — AER/QJE style standards
- `.claude/skills/econ-paper/assets/paper-template.tex` — LaTeX preamble and structure
- `initial_plan.md` — Research question, identification strategy, robustness plan

## Section Requirements

### Abstract (~250 words)
- Method: "Using a staggered difference-in-differences design with the Callaway-Sant'Anna (2021) estimator..."
- Main finding: EXACT point estimate with confidence interval
- Sample: N observations, time period, geographic scope
- Policy implication: One specific sentence

### Introduction (3–4 pages)
1. **Opening hook**: Policy-relevant fact or statistic
2. **The problem**: Why it matters
3. **Literature gap**: 3–5 citations, explicitly state what's missing
4. **Contribution**: Numbered list (3 points)
5. **Preview**: Main result with exact numbers
6. **Roadmap**: "The remainder proceeds as follows..."

### Institutional Background (2–3 pages)
- Full policy description with specific dates and jurisdiction counts
- Mechanism of action
- Reference Figure 1 (treatment rollout)
- Why this creates useful variation

### Data (2–3 pages)
- Source descriptions with API/access details
- Sample construction: universe → restrictions
- Reference Table 1 (summary statistics)
- Data limitations

### Empirical Strategy (3–4 pages)
- Identification assumption in words
- Estimating equation in LaTeX with ALL variable definitions
- Threats to validity (discuss each, explain mitigation)
- Power assessment

### Results (4–5 pages)
- Main results: reference Table 2, point estimate, SE, significance
- Event study: reference Figures 3–5, discuss pre-treatment coefficients explicitly
- Heterogeneity analysis
- Report null results honestly

### Robustness (2–3 pages)
- Reference each check from `initial_plan.md`
- For each: method, finding, verdict (robust/sensitive)
- Reference Table 3 and placebo figures

### Discussion (2–3 pages)
- Interpretation for theory
- Comparison with literature
- **Specific, honest limitations** (not vague disclaimers)

### Conclusion (1–2 pages)
- Summary (1 paragraph)
- Policy implications (specific)
- Future research (2–3 directions)

## Writing Rules

1. **Quantitative specificity**: NEVER "many states" → ALWAYS "42 states across 8 cohorts"
2. **No vague language**: NEVER "may suggest" → ALWAYS "The point estimate of 0.034 indicates"
3. **Acronym rule**: Define on first use
4. **Active references**: "Table 1 reports..." not "the following table"
5. **Citation style**: natbib, `\citet{}` for text, `\citep{}` for parenthetical
6. **Significance**: Stars + exact SE in parentheses
7. **Clustering**: Always state the level

## Output

- `paper.tex` — Complete manuscript using template preamble
- `references.bib` — BibTeX bibliography with DOI where available

**Minimum 25 pages** (including references, excluding appendix).

## After Output

Tell the user: "Paper draft complete. Run `/compile-paper` to compile the PDF."
