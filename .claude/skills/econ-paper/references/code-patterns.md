# Code Patterns — R Analysis Pipeline Best Practices

## Pipeline Structure

Every APEP paper uses a numbered pipeline of R scripts:

```
code/
├── 00_packages.R        # Package loading + APEP theme
├── 01_fetch_data.R      # API calls, data download
├── 02_clean_data.R      # Panel construction, variable creation
├── 03_main_analysis.R   # Core causal inference estimation
├── 04_robustness.R      # Placebo tests, alternative specifications
├── 05_figures.R         # Publication-ready plots
├── 06_tables.R          # LaTeX tables
└── run_all.sh           # One-click execution
```

Each script `source("00_packages.R")` at the top. Data flows through `../data/` directory.

---

## Package Recommendations by Method

### Core (always include)
```r
"tidyverse"     # dplyr, ggplot2, tidyr, readr, purrr, stringr
"fixest"        # High-performance fixed effects
"ggplot2"       # Figures
"httr"          # API calls
"jsonlite"      # JSON parsing
"knitr"         # Tables
"broom"         # Tidy model output
```

### DiD
```r
"did"           # Callaway-Sant'Anna
"bacondecomp"   # Goodman-Bacon decomposition
```

### RDD
```r
"rdrobust"      # Optimal bandwidth, robust inference
"rddensity"     # Manipulation testing
```

### IV
```r
"ivreg"         # Standard 2SLS
# fixest handles IV with fixed effects natively
```

### SCM
```r
"Synth"         # Classic Abadie-Diamond-Hainmueller
"gsynth"        # Generalized SCM (multiple treated)
"augsynth"      # Augmented SCM
```

### DR
```r
"DRDID"         # Doubly robust DiD
```

---

## Treatment Variable Construction

**CRITICAL: Always hardcode treatment assignments in a `tribble()` for auditability.**

```r
treatment <- tribble(
  ~state_fips, ~state_abbr, ~state_name,          ~treat_year,
  "01",        "AL",        "Alabama",             2017,
  "02",        "AK",        "Alaska",              0,     # Never treated
  "04",        "AZ",        "Arizona",             2017,
  # ... all 50 states + DC
)

# Verification output
cat(sprintf("Treatment data: %d jurisdictions\n", nrow(treatment)))
cat(sprintf("  Never treated: %d\n", sum(treatment$treat_year == 0)))
cat(sprintf("  Treated: %d\n", sum(treatment$treat_year > 0)))
```

**Rules:**
- `treat_year = 0` for never-treated (not `NA`)
- Include ALL 50 states + DC even if some are excluded
- Add comments for exclusion reasons (e.g., `# Enacted 2025, too recent`)
- Source treatment dates from official records, not secondary sources

---

## Data Fetching Pattern

```r
fetch_api_data <- function(url, label = "") {
  cat(sprintf("  Fetching %s ... ", label))

  result <- tryCatch({
    resp <- httr::GET(url, httr::timeout(60))
    if (httr::status_code(resp) == 200) {
      txt <- httr::content(resp, as = "text", encoding = "UTF-8")
      df <- read.csv(textConnection(txt), stringsAsFactors = FALSE)
      cat(sprintf("OK (%d rows)\n", nrow(df)))
      return(df)
    } else {
      cat(sprintf("HTTP %d\n", httr::status_code(resp)))
      return(NULL)
    }
  }, error = function(e) {
    cat(sprintf("ERROR: %s\n", e$message))
    return(NULL)
  })

  return(result)
}
```

**Rules:**
- Always set `httr::timeout(60)` on API calls
- Print status to console (HTTP code, row count)
- `tryCatch()` every network call
- `Sys.sleep(0.5)` between sequential API calls (rate limiting)
- Load API keys from environment variables, fall back to `.env` file

---

## Panel Construction Pattern

```r
# Reshape to wide (one row per unit-time)
panel_wide <- raw_data %>%
  pivot_wider(
    id_cols = c(unit_id, year),
    names_from = category,
    values_from = c(outcome1, outcome2)
  )

# Merge treatment
panel <- panel_wide %>%
  left_join(treatment, by = "unit_id") %>%
  filter(!is.na(unit_id))

# Create treatment indicators
panel <- panel %>%
  mutate(
    treated = as.integer(treat_year > 0 & year >= treat_year),
    first_treat = treat_year,  # 0 = never treated (for did package)
    unit_numeric = as.integer(unit_id)
  )

# Log outcomes (add 1 to handle zeros)
panel <- panel %>%
  mutate(
    log_outcome = log(outcome + 1)
  )
```

---

## Figure Style Guide

### APEP Theme
Use `theme_apep()` from `00_packages.R` for all figures. Key properties:
- `theme_minimal` base, 12pt
- No minor gridlines
- Bold axis titles (11pt), grey axis text (10pt)
- Legend at bottom
- Title 13pt bold, left-aligned

### Color Palette (colorblind-safe)
```r
apep_colors <- c(
  "#0072B2",  # Blue (primary)
  "#D55E00",  # Vermillion (secondary)
  "#009E73",  # Bluish green
  "#CC79A7",  # Reddish purple
  "#F0E442",  # Yellow
  "#56B4E9"   # Sky blue
)
```

### Event Study Plot Pattern
```r
es_df <- data.frame(
  time = es_result$egt,
  att = es_result$att.egt,
  se = es_result$se.egt
) %>%
  filter(time >= -5, time <= 6)

ggplot(es_df, aes(x = time, y = att)) +
  geom_ribbon(aes(ymin = att - 1.96 * se, ymax = att + 1.96 * se),
              alpha = 0.2, fill = apep_colors[1]) +
  geom_point(color = apep_colors[1], size = 2.5) +
  geom_line(color = apep_colors[1], linewidth = 0.7) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey40") +
  geom_vline(xintercept = -0.5, linetype = "dotted", color = "grey60") +
  labs(
    title = "Event Study: [Policy] and [Outcome]",
    subtitle = "Callaway-Sant'Anna ATT estimates; 95% CI; never-treated control",
    x = "Years Since [Treatment]",
    y = "ATT (Log [Outcome])"
  ) +
  scale_x_continuous(breaks = seq(-5, 6, 1)) +
  theme_apep()

ggsave("../figures/figN_event_study.pdf", width = 9, height = 6)
```

### Standard Figure Set (8-9 figures)
1. Treatment rollout (adoption timeline bar chart)
2. Pre-treatment trends by cohort
3. Event study — main outcome
4. Event study — secondary outcome
5. Event study — mechanism outcome
6. Placebo event study
7. Sub-group comparison
8. Cohort-specific ATTs
9. Bacon decomposition (if TWFE used)

---

## Table Formatting

### LaTeX Table Pattern (booktabs + threeparttable)
```r
sink(file.path(tab_dir, "tabN_description.tex"))
cat("\\begin{table}[H]\n")
cat("\\centering\n")
cat("\\caption{Table Title}\n")
cat("\\label{tab:label}\n")
cat("\\begin{threeparttable}\n")
cat("\\begin{tabular}{lccc}\n")
cat("\\toprule\n")
cat("Variable & (1) & (2) & (3) \\\\\n")
cat("\\midrule\n")
# ... data rows with sprintf for alignment ...
cat("\\bottomrule\n")
cat("\\end{tabular}\n")
cat("\\begin{tablenotes}[flushleft]\n")
cat("\\small\n")
cat("\\item \\textit{Notes:} Description of data, methods, significance levels.\n")
cat("\\end{tablenotes}\n")
cat("\\end{threeparttable}\n")
cat("\\end{table}\n")
sink()
```

### Standard Table Set (4 tables)
1. Summary statistics (with pre-treatment balance)
2. Main results (CS DiD + TWFE comparison)
3. Robustness checks
4. Event study coefficients

### Significance Stars
```r
stars <- case_when(
  pval < 0.01 ~ "***",
  pval < 0.05 ~ "**",
  pval < 0.10 ~ "*",
  TRUE ~ ""
)
```

---

## run_all.sh Template

```bash
#!/bin/bash
set -euo pipefail

echo "=== APEP Analysis Pipeline ==="
echo "Started: $(date)"

cd "$(dirname "$0")"

echo "[1/7] Loading packages..."
Rscript 00_packages.R

echo "[2/7] Fetching data..."
Rscript 01_fetch_data.R

echo "[3/7] Cleaning data..."
Rscript 02_clean_data.R

echo "[4/7] Main analysis..."
Rscript 03_main_analysis.R

echo "[5/7] Robustness checks..."
Rscript 04_robustness.R

echo "[6/7] Generating figures..."
Rscript 05_figures.R

echo "[7/7] Generating tables..."
Rscript 06_tables.R

echo ""
echo "=== Pipeline complete ==="
echo "Finished: $(date)"
echo "Figures: $(ls ../figures/*.pdf 2>/dev/null | wc -l) PDFs"
echo "Tables: $(ls ../tables/*.tex 2>/dev/null | wc -l) .tex files"
```

---

## Data Directory Structure

```
project/
├── code/           # R scripts
├── data/           # Intermediate data (CSV, RDS)
│   ├── raw_*.csv
│   ├── analysis_panel.csv
│   ├── analysis_panel.rds
│   ├── main_results.rds
│   ├── robust_results.rds
│   └── estimates_table.csv
├── figures/        # PDF figures
├── tables/         # LaTeX table fragments
├── paper.tex
├── references.bib
└── metadata.json
```
