# Code Conventions & Project Standards

## R Pipeline Structure

Every project uses a numbered pipeline of R scripts:

```
code/
├── 00_packages.R        # Package loading + APEP theme
├── 01_fetch_data.R      # API calls (or 01_load_data.R for local data)
├── 02_clean_data.R      # Panel construction, variable creation
├── 03_main_analysis.R   # Core causal inference estimation
├── 04_robustness.R      # Placebo tests, alternative specifications
├── 05_figures.R         # Publication-ready plots
├── 06_tables.R          # LaTeX tables
└── run_all.sh           # One-click execution
```

Each script (01–06) must `source("00_packages.R")` as its first executable line.

---

## Treatment Variable Construction

**Always hardcode treatment assignments in a `tribble()` for auditability.**

```r
treatment <- tribble(
  ~state_fips, ~state_abbr, ~state_name,          ~treat_year,
  "01",        "AL",        "Alabama",             2017,
  "02",        "AK",        "Alaska",              0,     # Never treated
  ...
)
```

Rules:
- `treat_year = 0` for never-treated (NOT `NA`, NOT `Inf`, NOT `9999`) — `did` package requires 0
- Include ALL 50 states + DC even if some are excluded
- Add comments for exclusion reasons (e.g., `# Enacted 2025, too recent`)
- Source treatment dates from official records, not secondary sources

---

## FIPS Codes

**CRITICAL: FIPS codes MUST be character type, never numeric.**

```r
# CORRECT
state_fips = "01"
mutate(fips = sprintf("%02d", as.integer(raw_fips)))

# WRONG — loses leading zeros
state_fips = 1
as.numeric(fips_column)
```

---

## API Call Pattern

Every network call must follow this pattern:

```r
result <- tryCatch({
  resp <- httr::GET(url, httr::timeout(60))
  if (httr::status_code(resp) == 200) {
    # process
  }
}, error = function(e) {
  cat(sprintf("ERROR: %s\n", e$message))
  return(NULL)
})
Sys.sleep(0.5)  # Rate limiting between sequential calls
```

Required elements:
- `httr::timeout(60)` on every call
- `tryCatch()` wrapping every network call
- `Sys.sleep(0.5)` between sequential calls
- Console status output: `cat(sprintf("Fetching %s ... OK (%d rows)\n", label, nrow(df)))`

---

## Log Transformation

**Always `log(x + 1)`, never `log(x)`** to avoid `log(0) = -Inf`.

```r
# CORRECT
mutate(log_outcome = log(outcome + 1))

# WRONG — will produce -Inf for zero values
mutate(log_outcome = log(outcome))
```

---

## Panel Construction

After any merge, always verify row counts:

```r
n_before <- nrow(panel)
panel <- panel %>% left_join(treatment, by = "state_fips")
n_after <- nrow(panel)
cat(sprintf("Merge: %d → %d rows (change: %+d)\n", n_before, n_after, n_after - n_before))
stopifnot(n_after >= n_before * 0.9, n_after <= n_before * 1.1)  # Sanity check
```

---

## Figure Standards

- All figures use `theme_apep()` from `00_packages.R`
- Colorblind-safe palette (Wong 2011): `"#0072B2"`, `"#D55E00"`, `"#009E73"`, `"#CC79A7"`, `"#F0E442"`, `"#56B4E9"`
- Default size: 9 × 6 inches
- Save as PDF: `ggsave("../figures/figN_description.pdf", width = 9, height = 6)`
- Axis labels must be informative (not variable names)
- Include subtitle with method/sample details

---

## Table Standards

- LaTeX tables use `booktabs` + `threeparttable` format
- Include table notes explaining data, methods, significance levels
- Significance stars: `*** p<0.01, ** p<0.05, * p<0.10`
- Standard errors in parentheses below coefficients

---

## File Naming

| Type | Pattern | Example |
|------|---------|---------|
| Figures | `figN_description.pdf` | `fig1_treatment_rollout.pdf` |
| Tables | `tabN_description.tex` | `tab1_summary_stats.tex` |
| Raw data | `raw_*.csv` | `raw_qcew_2014.csv` |
| Processed data | Descriptive name | `analysis_panel.rds` |
| Results | Descriptive name | `main_results.rds` |

---

## Standard Project Directory Layout

```
paper_[topic_slug]/
├── progress.json           ← Stage tracking
├── initialization.md       ← User preferences
├── ideas.md                ← Research ideas
├── ideas_ranked.json       ← Scored rankings
├── ranking.md              ← Ranking rationale
├── initial_plan.md         ← Pre-analysis plan
├── pre_analysis.md         ← SHA-256 lock
├── deviations.json         ← Plan deviations log
├── code/
│   ├── 00_packages.R
│   ├── 01_fetch_data.R (or 01_load_data.R)
│   ├── 02_clean_data.R
│   ├── 03_main_analysis.R
│   ├── 04_robustness.R
│   ├── 05_figures.R
│   ├── 06_tables.R
│   └── run_all.sh
├── data/
│   ├── raw_*.csv
│   ├── analysis_panel.csv
│   ├── analysis_panel.rds
│   ├── main_results.rds
│   └── robust_results.rds
├── figures/                ← PDF figures (8+)
├── tables/                 ← LaTeX table fragments (4+)
├── paper.tex
├── references.bib
├── metadata.json
└── REPLICATION.md
```
