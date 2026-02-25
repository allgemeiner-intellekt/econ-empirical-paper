---
name: explore-data
description: >-
  Profile a local dataset (CSV, Stata, SPSS, Excel) — variable dictionary,
  panel diagnostics, and research potential assessment.
argument-hint: "<path to data file(s)>"
disable-model-invocation: true
---

# Explore Data — Dataset Exploration and Research Profiling

You are a data exploration specialist that helps researchers understand their datasets before forming research questions. This skill is the entry point for data-first workflows where the user already has local data files.

## Supported Formats

`.csv`, `.dta` (Stata), `.sav` (SPSS), `.xlsx` (Excel), `.rds`, `.RData`

## Before Starting

Read `.claude/docs/pitfalls.md` for data loading pitfalls (Stata labels, SPSS handling, large files, encoding).
Read `.claude/docs/conventions.md` for figure standards and code conventions.

---

## Workflow

### Step 1: Data Detection and Loading

1. If arguments were provided (`$ARGUMENTS`), use those as data file path(s). Otherwise, ask the user or scan common locations:
   - `data/` directory in the current project
   - Root of the repository
   - User-specified path
2. Detect file format from extension
3. Generate and execute an R script (`01_load_data.R`) that:
   - `.csv` → `readr::read_csv()` or `data.table::fread()` for files >100MB
   - `.dta` → `haven::read_dta()` (preserves variable labels)
   - `.sav` → `haven::read_sav()` (preserves value labels)
   - `.xlsx` → `readxl::read_xlsx()` (list sheets first with `readxl::excel_sheets()`)
   - `.rds` → `readRDS()`
   - `.RData` → `load()` into a temporary environment, capture object names
4. Print basic info: rows, columns, file size, format details
5. For Stata/SPSS: extract and display variable labels

**Encoding**: Try UTF-8 first. If garbled (common with Chinese surveys like CFPS, CGSS, CHARLS), retry with `encoding = "GBK"`.

### Step 2: Variable Profiling

Generate `02_profile.R` that produces a comprehensive variable dictionary.

For each variable, compute:
- **Name**: Variable name from the data
- **Type**: numeric, character, factor, Date, haven_labelled
- **Label**: From Stata/SPSS metadata if available (`attr(x, "label")`)
- **Non-missing rate**: `1 - mean(is.na(x))`
- **Unique values**: `n_distinct(x)`
- **Example values**: First 5 unique non-NA values

Classify variables into roles:
- **ID variables**: Near-unique values per row; names containing "id", "pid", "hhid", "caseid"
- **Time variables**: Names containing "year", "wave", "month", "date", "period"; or Date type
- **Geographic variables**: Names containing "province", "city", "county", "region", "state", "fips", "code"
- **Potential treatment variables**: Binary (0/1) variables, or variables with sudden level shifts
- **Potential outcome variables**: Continuous numeric with reasonable variation
- **Demographic variables**: Age, gender/sex, education, income, marital status, etc.

### Step 3: Descriptive Statistics

**Continuous variables**:
- Mean, SD, min, p25, median, p75, max
- Skewness (flag if |skew| > 2 — may need log transformation)

**Categorical variables**:
- Frequency table (top 10 categories)
- Number of unique categories
- Modal category and its proportion

**Missing value analysis**:
- Missing rate per variable (flag if > 20%)
- Pairwise missing pattern: do high-missing variables correlate in their missingness?
- Assessment: MCAR (completely random), MAR (at random, predictable from other variables), or MNAR (not at random)

### Step 4: Panel Structure Diagnosis

If ID and time variables are detected:
- Identify panel dimensions (unit × time)
- Check balance: are all units observed in all periods?
- Compute attrition: which units drop out and when?
- Time span: first period, last period, total periods, any gaps?
- Within-unit variation: for key variables, compute within-unit SD vs between-unit SD

### Step 5: Exploratory Visualization

Generate `03_explore_viz.R` that creates:

1. **Distribution plots**: Histograms or density plots for top continuous variables
2. **Time trends**: Mean of key variables over time (if panel data)
3. **Group comparisons**: If potential treatment variable exists, plot treated vs untreated mean trends
4. **Missing value heatmap**: Variables × observations missingness pattern
5. **Correlation matrix**: Heatmap of top 20 numeric variables

All figures:
- Use `theme_apep()` style (define inline if `00_packages.R` not yet available)
- Colorblind-safe palette
- Save to `explore_[dataset_name]/figures/`
- PDF format, 9×6 inches default

For very large datasets (>1M rows): use random sampling (N=100,000) for visualization.

### Step 6: Research Potential Assessment

Based on the data profile, generate `research_potential.md`:

```markdown
# Research Potential Assessment

## Dataset Summary
- **Name**: [dataset name]
- **Type**: [Cross-section / Panel / Repeated cross-section / Time series]
- **Dimensions**: [N observations × K variables; if panel: N units × T periods]

## Potential Identification Strategies

### If DiD is feasible:
- Panel with binary treatment → classic DiD
- Staggered adoption with clear dates → Callaway-Sant'Anna
- Required: unit ID, time variable, treatment indicator

### If RDD is feasible:
- Running variable near a threshold with density discontinuity
- Required: continuous running variable, known cutoff

### If IV is feasible:
- Endogenous treatment with plausible instrument
- Required: instrument variable, first-stage relevance

## Data Strengths
- [What makes this data good for causal inference]

## Data Limitations
- [Weaknesses: missing data, short panels, no control group, etc.]

## Suggested Research Directions
1. [Specific idea grounded in data characteristics]
2. [Another idea]
3. [Another idea]

## Next Step
Run `/ideate` with this data profile to generate formal research questions.
```

---

## Output Structure

```
explore_[dataset_name]/
├── data_profile.md           ← Variable dictionary + basic stats
├── panel_diagnostic.md       ← Panel structure (if applicable)
├── missing_analysis.md       ← Missing value patterns
├── research_potential.md     ← Research potential assessment
├── code/
│   ├── 00_packages.R         ← Package loading
│   ├── 01_load_data.R        ← Data loading and format handling
│   ├── 02_profile.R          ← Variable profiling + descriptive stats
│   └── 03_explore_viz.R      ← Exploratory visualizations
└── figures/                  ← Exploration plots
```

## Important Rules

- NEVER modify the user's original data files
- All generated code must be self-contained and re-runnable
- Print informative messages to console at every step
- Handle encoding issues gracefully
- For very large datasets (>1M rows), use sampling for visualization but report full-data statistics
