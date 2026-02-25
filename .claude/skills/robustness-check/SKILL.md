---
name: robustness-check
description: >-
  Add robustness tests (placebo, alternative estimator, sample restriction)
  to strengthen an existing analysis.
argument-hint: "<check description>"
disable-model-invocation: true
---

# Robustness Check — Add Additional Robustness Tests

You add robustness checks to an existing analysis, typically in response to referee requests or to strengthen the paper.

## Input

- Existing project directory with completed analysis
- If arguments were provided (`$ARGUMENTS`), use those as the check description. Otherwise, ask the user what check is needed.

## Common Check Types

### 1. Placebo Test
Run the analysis on an unrelated outcome that should NOT be affected by the treatment.
- Generate new event study figure
- If placebo shows "effect" → concern about confounders

### 2. Alternative Estimator
Swap the primary estimator:
- CS-DiD → Sun-Abraham (`fixest::feols()` with `sunab()`)
- CS-DiD → Imputation (`didimputation::did_imputation()`)
- CS-DiD → Borusyak-Jaravel-Spiess
- TWFE → any heterogeneity-robust estimator

### 3. Sample Restriction
- Exclude specific periods (e.g., COVID 2020–2021)
- Exclude specific units (e.g., early adopters, outlier states)
- Restrict to pre-2020 cohorts only
- Restrict to specific subgroups

### 4. Alternative Specification
- Different fixed effects structure (state × quarter FE, region × year FE)
- Different control variables
- Different outcome transformation (levels vs logs, per-capita vs total)
- Different clustering level

### 5. Permutation / Randomization Inference
- Randomly reassign treatment across units
- Run estimation N times (500–1000)
- Compute p-value as share of permuted estimates exceeding actual

### 6. Leave-One-Out
- Drop each treated cohort one at a time
- Drop each state one at a time
- Check if results driven by single unit

### 7. Dose-Response
- If treatment has intensity variation (e.g., years since adoption)
- Run with continuous treatment intensity instead of binary

### 8. Sensitivity Analysis (Oster 2019)
- Compute bounds for omitted variable bias
- Report δ (how much selection on unobservables relative to observables needed to explain away the result)

## Procedure

1. **Identify the check** from user description
2. **Check pre-analysis plan**: Was this check pre-registered?
   - If YES: note compliance
   - If NO: record in `deviations.json` as post-hoc addition with justification
3. **Generate R script**: `code/07_robustness_[name].R`
   - Source `00_packages.R`
   - Load analysis panel
   - Run the check
   - Save results and any new figures/tables
4. **Execute** the script
5. **Report results** to user

## Output

- New R script: `code/07_robustness_[name].R` (or 08, 09 for subsequent checks)
- New figure(s) in `figures/` (if applicable)
- New table(s) in `tables/` (if applicable)
- Updated `deviations.json` (if not pre-registered)

## Deviation Recording

If the check was NOT in the original pre-analysis plan:
```json
{
  "timestamp": "ISO-8601",
  "file": "code/07_robustness_[name].R",
  "description": "Added [check name]",
  "justification": "[Why — e.g., Referee 2 requested, or discovered during analysis]",
  "pre_registered": false
}
```

## After Completion

Report the check result and whether it supports or weakens the main findings. Suggest whether/how to incorporate into the paper.
