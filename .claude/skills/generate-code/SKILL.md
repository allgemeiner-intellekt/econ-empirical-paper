---
name: generate-code
description: >-
  Generate a complete numbered R analysis pipeline (00–06) from a locked
  pre-analysis plan.
disable-model-invocation: true
---

# Generate Code — R Analysis Pipeline Generation

You generate the complete numbered R analysis pipeline from a locked pre-analysis plan.

## Input

- `initial_plan.md` — Locked pre-analysis plan with identification strategy, robustness checks, data sources

## Before Generating

Read these references:
- `.claude/references/code-patterns.md` — R pipeline best practices, API patterns, figure/table templates
- `.claude/references/causal-methods.md` — Method-specific estimator code (DiD, RDD, IV, SCM, DR)
- `.claude/references/data-sources.md` — API endpoints and data fetching patterns
- `.claude/docs/conventions.md` — Coding standards, naming, directory structure
- `.claude/docs/pitfalls.md` — Common bugs to avoid

## Two Data Modes

### API Mode (data fetched from remote APIs)
Generate `01_fetch_data.R`:
- Fetch from BLS QCEW, FRED, Census ACS, etc.
- `tryCatch()` + `httr::timeout(60)` on every call
- `Sys.sleep(0.5)` between calls
- Console status output for every fetch
- Save raw data to `../data/raw_*.csv`

### Local Data Mode (user has local files)
Generate `01_load_data.R`:
- Load from `.csv`, `.dta`, `.sav`, `.xlsx`, `.rds`, `.RData`
- Use `haven::read_dta()`, `readxl::read_xlsx()`, etc.
- Extract and print variable labels
- Handle encoding (UTF-8 default, GBK fallback)
- Save processed data to `../data/`

Detect which mode based on `initial_plan.md` data sources table.

## Scripts to Generate

### `00_packages.R`
Copy from `.claude/skills/econ-paper/assets/packages-template.R`. Add method-specific packages:
- DiD: `did`, `bacondecomp`
- RDD: `rdrobust`, `rddensity`
- IV: `ivreg` (fixest handles IV natively)
- SCM: `Synth`, `gsynth`, `augsynth`
- DR: `DRDID`
- Local data: `haven`, `readxl`

### `01_fetch_data.R` or `01_load_data.R`
- Sources `00_packages.R`
- Creates `../data/` directory
- **Treatment variable in `tribble()`** with ALL units, treatment years, and comments
- Fetches/loads all data sources
- Saves raw data to `../data/`
- Prints summary of loaded data

### `02_clean_data.R`
- Sources `00_packages.R`
- Loads raw data and treatment variable
- Merges with row count verification
- Creates treatment indicators: `treated`, `first_treat` (0 = never-treated), `post`
- Creates log outcomes: `log(x + 1)` (never `log(x)`)
- Creates cohort labels
- Prints summary statistics
- Saves `analysis_panel.csv` and `analysis_panel.rds`

### `03_main_analysis.R`
- Sources `00_packages.R`
- Loads analysis panel
- Runs primary estimator based on chosen method:
  - **DiD**: `did::att_gt()` → `did::aggte()` (overall + event study + cohort)
  - **RDD**: `rdrobust::rdrobust()` + `rddensity::rddensity()`
  - **IV**: `fixest::feols()` with IV syntax
  - **SCM**: `gsynth::gsynth()` or `Synth::synth()`
  - **DR**: `did::att_gt()` with `est_method = "dr"`
- Runs TWFE comparison (if applicable)
- Runs alternative estimator (Sun-Abraham for DiD, etc.)
- Saves `main_results.rds` and `estimates_table.csv`

### `04_robustness.R`
- Sources `00_packages.R`
- Implements ALL robustness checks from `initial_plan.md` (8–10 checks)
- Each check: run estimation, print results, save estimates
- Saves `robust_results.rds` and `robustness_table.csv`

### `05_figures.R`
- Sources `00_packages.R`
- Generates 8–9 publication-ready PDF figures using `theme_apep()`:
  1. Treatment rollout (adoption timeline)
  2. Pre-treatment trends by cohort
  3. Event study — main outcome
  4. Event study — secondary outcome
  5. Event study — mechanism outcome
  6. Placebo event study
  7. Sub-group comparison
  8. Cohort-specific ATTs
  9. Bacon decomposition (if TWFE used)
- All saved to `../figures/` as PDF, 9×6 inches

### `06_tables.R`
- Sources `00_packages.R`
- Generates 4+ LaTeX tables in booktabs + threeparttable format:
  1. Summary statistics with pre-treatment balance
  2. Main results (CS DiD + TWFE panels)
  3. Robustness checks
  4. Event study coefficients
- All saved to `../tables/` as `.tex` files

### `run_all.sh`
```bash
#!/bin/bash
set -euo pipefail
echo "=== Analysis Pipeline ==="
echo "Started: $(date)"
cd "$(dirname "$0")"
# Run all scripts sequentially with progress
for i in 00 01 02 03 04 05 06; do
  script=$(ls ${i}_*.R 2>/dev/null | head -1)
  if [ -n "$script" ]; then
    echo "[${i}] Running $script..."
    Rscript "$script"
  fi
done
echo "=== Pipeline complete ==="
echo "Figures: $(ls ../figures/*.pdf 2>/dev/null | wc -l) PDFs"
echo "Tables: $(ls ../tables/*.tex 2>/dev/null | wc -l) .tex files"
```

## After Generation

Tell the user: "Code generated. Review the scripts in code/. Run `/run-analysis` to execute the pipeline."
