---
name: replicate
description: >-
  Reproduce a published paper's results by extracting methodology,
  reconstructing the analysis pipeline, and comparing outputs.
argument-hint: "<PDF path, DOI, or paper details>"
disable-model-invocation: true
---

# Replicate — Reproduce Published Paper Results

You read a published empirical economics paper, extract its methodology, reconstruct the analysis pipeline, execute it, and compare replicated results with the original.

## Before Starting

Read `.claude/docs/replication-guide.md` for the full replication workflow and standards.

## Input

If arguments were provided (`$ARGUMENTS`), use those as the paper source. Otherwise, ask the user for one of:
- PDF file path (use Read tool to view)
- Paper details pasted by user (title, authors, method, key tables)
- DOI or citation for context

## Workflow

### Step 1: Paper Parsing

Extract from the paper:

**Per table/figure:**
- Estimator (OLS, 2SLS, DiD variant, RDD, etc.)
- Dependent variable with transformation
- Treatment variable definition
- Control variables (full list)
- Fixed effects structure
- Standard error clustering
- Sample restrictions

**Overall:**
- Data source(s) with exact names, versions, years
- Unit of observation
- Sample size (N obs, N clusters)
- Key variable definitions

### Step 2: Reproducibility Assessment

Rate each dimension:
| Dimension | Rating |
|-----------|--------|
| Data availability | Public / Downloadable / Restricted / Proprietary |
| Code availability | Open source / Supplementary / Not available |
| Specification clarity | Complete / Partial / Ambiguous |

Identify every gap requiring an assumption. Document each in `assumptions.md`:
```markdown
## Assumption 1: Employment variable definition
- **What's missing**: Paper says "healthcare employment" without specifying NAICS level
- **Our assumption**: NAICS 62 (Health Care and Social Assistance) from QCEW
- **Justification**: Most common definition in health economics literature
- **Impact**: If authors used NAICS 621, our estimates may be attenuated
```

### Step 3: Specification Document

Create `replication_spec.md` with exact specification for each table and figure:
```markdown
## Table 2, Column (1): Baseline DiD
- Estimator: TWFE
- DV: log(employment + 1)
- Treatment: 1[state adopted IMLC by year t]
- Controls: log(pop), unemp_rate, log(gdp_pc)
- FE: State, Year
- Clustering: State
- Sample: 2012–2023, 51 jurisdictions, excl. 2020
- Expected: β = 0.034 (SE = 0.012), N = 12,450
```

### Step 4: Code Generation

Generate R pipeline (reuse patterns from `.claude/references/code-patterns.md`):

```
replicate_[author]_[year]/
├── replication_spec.md
├── assumptions.md
├── code/
│   ├── 00_packages.R
│   ├── 01_fetch_data.R (or 01_load_data.R)
│   ├── 02_clean_data.R
│   ├── 03_replicate_main.R      ← Replicate main tables
│   ├── 04_replicate_robust.R    ← Replicate robustness checks
│   ├── 05_figures.R             ← Replicate key figures
│   ├── 06_comparison.R          ← Generate comparison outputs
│   └── run_all.sh
├── data/
├── figures/
├── tables/
└── comparison/
```

### Step 5: Execution

Run the pipeline via `/run-analysis` patterns. If errors occur, diagnose and fix (max 3 retries per script).

### Step 6: Comparison

Generate `06_comparison.R` that produces:

**Coefficient comparison table** (`comparison/summary_table.tex`):
```
| Metric | Original | Replicated | Δ (%) | Verdict |
|--------|----------|------------|-------|---------|
| ATT (T2 C1) | 0.034** (0.012) | 0.031** (0.013) | -8.8% | ≈ Approx. |
```

**Event study overlay** (`comparison/event_study_overlay.pdf`):
- Original coefficients (from paper's figure, digitized if needed) vs replicated
- Side by side or overlaid

### Step 7: Difference Analysis

For each difference > 5%, investigate and document:
- Likely cause (data vintage, sample construction, package version, variable definition)
- Evidence for the explanation
- Whether the difference affects the paper's conclusions

### Step 8: Replication Report

Generate `replication_report.md`:
```markdown
# Replication Report: [Author] ([Year])

## Paper: "[Title]"
## Journal: [Name]

## Overall Assessment: [Largely Replicated / Partially Replicated / Not Replicated]

## Results Comparison
[Full comparison table]

## Differences and Explanations
[Per-difference analysis]

## Assumptions Made
[Summary of all assumptions with impact assessment]

## Conclusion
[1 paragraph summary of replication findings]
```

## Difference Verdicts

| Δ | Verdict |
|---|---------|
| < 5% | **Replicated** ✓ |
| 5–15% | **Approximately replicated** ≈ (document cause) |
| > 15% | **Not replicated** ✗ (investigate thoroughly) |
| Significance flipped | **Flag** regardless of magnitude |

## After Completion

Report the overall replication verdict and key findings to the user.
