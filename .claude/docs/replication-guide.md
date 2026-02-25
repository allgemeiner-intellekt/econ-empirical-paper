# Replication Workflow Guide

## Overview

This guide details the process for replicating a published empirical economics paper: extracting its methodology, reconstructing the analysis pipeline, executing it, and comparing results.

---

## Step 1: Paper Parsing

Extract from the paper (read PDF or user-provided text):

### Estimation Details (per table/figure)
- **Estimator**: OLS, 2SLS, DiD (which variant), RDD, etc.
- **Dependent variable**: Name, transformation (log, level, rate)
- **Treatment variable**: Binary indicator, intensity measure, instrument
- **Control variables**: Full list with transformations
- **Fixed effects**: Unit FE, time FE, unit-time trends, etc.
- **Standard errors**: Clustered (at what level), robust, bootstrapped
- **Sample restrictions**: Time period, geographic scope, subpopulations

### Data Details
- **Source(s)**: Exact dataset name, version, years
- **Unit of observation**: Individual, firm, county-year, state-quarter
- **Sample size**: N observations, N clusters
- **Key variable definitions**: How treatment is coded, outcome measured

### Robustness Checks
- List all checks reported in the paper
- Note which tables/figures correspond to each

---

## Step 2: Reproducibility Assessment

Rate each dimension:

| Dimension | Rating | Criteria |
|-----------|--------|----------|
| **Data availability** | Public / Downloadable / Restricted / Proprietary | Can we access the same data? |
| **Code availability** | Open source / Supplementary / Not available | Did authors publish replication code? |
| **Specification clarity** | Complete / Partial / Ambiguous | Are all details documented? |

### Identify Gaps
For each gap, document:
- What information is missing
- What assumption we will make
- Justification for the assumption
- Expected impact on replication fidelity

---

## Step 3: Specification Document

Create `replication_spec.md` with exact specifications:

```markdown
## Table 2, Column (1): Baseline DiD

- **Estimator**: TWFE with state and year FE
- **Dependent variable**: log(employment + 1)
- **Treatment**: binary indicator (1 if state adopted IMLC by year t)
- **Controls**: log(population), unemployment rate, log(GDP per capita)
- **Fixed effects**: State, Year
- **Clustering**: State level
- **Sample**: 2012–2023, 50 states + DC, excluding 2020
- **Expected coefficient**: 0.034 (SE = 0.012)
- **Expected N**: 12,450

### Assumptions Required
1. Employment variable: paper says "annual average employment" — assuming QCEW annual_avg_emplvl
2. GDP per capita: paper doesn't specify source — assuming BEA state GDP / Census population
```

---

## Step 4: Code Generation

Generate R pipeline following standard code patterns (see `.claude/references/code-patterns.md`):

```
replicate_[author]_[year]/
├── replication_spec.md
├── code/
│   ├── 00_packages.R
│   ├── 01_fetch_data.R        # Get same data sources
│   ├── 02_clean_data.R        # Replicate sample construction
│   ├── 03_replicate_main.R    # Replicate main tables
│   ├── 04_replicate_robust.R  # Replicate robustness checks
│   ├── 05_figures.R           # Replicate figures
│   ├── 06_comparison.R        # Compare original vs replicated
│   └── run_all.sh
├── data/
├── figures/
├── tables/
├── comparison/
├── assumptions.md
└── replication_report.md
```

Key difference from original research: code targets **matching published results**, not discovering new findings.

---

## Step 5: Execution and Comparison

After running the pipeline, generate `replication_report.md`:

```markdown
# Replication Report: [Author] ([Year])

## Paper: "[Title]"
## Journal: [Journal Name]
## Original DOI: [DOI]

## Summary

| Metric | Original | Replicated | Δ (%) | Verdict |
|--------|----------|------------|-------|---------|
| ATT (Table 2, Col 1) | 0.034** (0.012) | 0.031** (0.013) | -8.8% | ✓ Approx. |
| ATT (Table 2, Col 2) | 0.041*** (0.011) | 0.039*** (0.012) | -4.9% | ✓ Replicated |
| N (Table 2) | 12,450 | 12,380 | -0.6% | ✓ Replicated |
| Pre-trend F-stat | 0.82 | 0.91 | +11.0% | ✓ Approx. |

## Overall Assessment: [Largely Replicated / Partially Replicated / Not Replicated]
```

---

## Difference Thresholds

| Difference | Verdict | Action |
|-----------|---------|--------|
| < 5% | **Replicated** ✓ | No further investigation needed |
| 5–15% | **Approximately replicated** ≈ | Document likely cause |
| > 15% | **Not replicated** ✗ | Investigate thoroughly |

For significance changes (significant → not significant or vice versa): always flag regardless of coefficient magnitude.

---

## Step 6: Difference Analysis

For each notable difference, investigate:

### Common Causes
1. **Data vintage**: BLS/Census revise historical data. Check if authors used preliminary vs revised
2. **Package version**: Different versions of `did`, `rdrobust` etc. may produce different results
3. **Sample construction**: Undocumented sample restrictions (e.g., authors dropped outliers)
4. **Standard error computation**: Small-sample corrections, degrees-of-freedom adjustments
5. **Rounding in published tables**: Authors may round differently
6. **Missing data handling**: Listwise deletion vs imputation vs carry-forward
7. **Variable definition**: Subtle differences in how variables are constructed from raw data

### Investigation Template
```markdown
### Difference: Table 2, Column (3) — ATT

- **Original**: 0.052*** (0.015)
- **Replicated**: 0.039** (0.018)
- **Δ**: -25.0%
- **Significance change**: No (both significant at 5%)

**Likely cause**: Authors appear to use NAICS 6211 (Offices of physicians) while we used NAICS 621 (Ambulatory health care). The narrower industry code produces a larger point estimate, likely because the treatment effect is concentrated in physician practices.

**Evidence**: Replicating with NAICS 6211 yields 0.049*** (0.016), within 5.8% of the original.
```

---

## Output Structure

```
replicate_[author]_[year]/
├── replication_spec.md      ← Extracted specifications
├── replication_report.md    ← Results comparison
├── assumptions.md           ← All assumptions with justifications
├── code/                    ← R pipeline
├── data/                    ← Downloaded/processed data
├── figures/                 ← Replicated figures
├── tables/                  ← Replicated tables
└── comparison/              ← Side-by-side comparisons
    ├── coefficient_comparison.pdf
    ├── event_study_overlay.pdf
    └── summary_table.tex
```
