## 02_clean_data.R — Validate and describe the state-year panel
## APEP-0241: State Prohibition and the German-American Brewing Elite

source("00_packages.R")

data_dir <- file.path("..", "data")
panel <- readRDS(file.path(data_dir, "state_panel.rds"))

# ====================================================================
# 1. VALIDATION
# ====================================================================

cat("=== Data Validation ===\n")

# Check panel balance
tab <- panel[, .N, by = year]
cat("\nObservations per year:\n")
print(tab)

# Verify treatment timing
treat_tab <- panel[, .(
  first_treated = min(year[treated == 1]),
  prohibition_year = first(prohibition_year)
), by = state_abbr]
cat("\nTreatment cohort distribution:\n")
print(table(treat_tab$prohibition_year))

# Check for outliers in German share
cat("\nGerman share distribution (1890):\n")
print(summary(panel[year == 1890, german_share]))

# Brewery intensity distribution
cat("\nBrewery intensity distribution (1870):\n")
print(summary(panel[year == 1870, brew_intensity]))

# ====================================================================
# 2. SUMMARY STATISTICS TABLE
# ====================================================================

# Create summary statistics for Table 1
summ <- panel[year %in% c(1870, 1890, 1910, 1920), .(
  `Total population (000s)` = mean(total_pop / 1000, na.rm = TRUE),
  `Foreign-born share` = mean(fb_share, na.rm = TRUE),
  `German-born share` = mean(german_share, na.rm = TRUE),
  `Brewery intensity (per 100k)` = mean(brew_intensity, na.rm = TRUE),
  `N states` = uniqueN(state_abbr)
), by = .(year, `Prohibition active` = factor(treated, labels = c("No", "Yes")))]

cat("\n=== Summary by Year and Treatment ===\n")
print(summ)

# Pre-treatment balance: compare eventual-treated vs never-treated
# Using 1890 (pre-prohibition for most states)
pre <- panel[year == 1890]
pre[, eventual_treat := as.integer(prohibition_year < 1920)]

cat("\n=== Pre-Treatment Balance (1890) ===\n")
balance_vars <- c("total_pop", "fb_share", "german_share", "brew_intensity")
for (v in balance_vars) {
  t_mean <- pre[eventual_treat == 1, mean(get(v), na.rm = TRUE)]
  c_mean <- pre[eventual_treat == 0, mean(get(v), na.rm = TRUE)]
  cat(sprintf("%-25s  Treated: %10.4f  Control: %10.4f  Diff: %10.4f\n",
              v, t_mean, c_mean, t_mean - c_mean))
}

# Save summary stats for Table 1
saveRDS(summ, file.path(data_dir, "summary_stats.rds"))

cat("\nValidation complete.\n")
