## 06_tables.R — Generate all LaTeX tables
## APEP-0241: State Prohibition and the German-American Brewing Elite

source("00_packages.R")

data_dir <- file.path("..", "data")
tab_dir <- file.path("..", "tables")
dir.create(tab_dir, showWarnings = FALSE, recursive = TRUE)

panel <- readRDS(file.path(data_dir, "state_panel.rds"))
models <- readRDS(file.path(data_dir, "models.rds"))

# ====================================================================
# TABLE 1: SUMMARY STATISTICS
# ====================================================================

cat("=== Generating Table 1 ===\n")

# Panel A: Full sample by year
summ_year <- panel[, .(
  N = .N,
  `Mean pop. (000s)` = round(mean(total_pop / 1000)),
  `Foreign-born (\\%)` = sprintf("%.1f", mean(fb_share * 100, na.rm = TRUE)),
  `German-born (\\%)` = sprintf("%.2f", mean(german_share * 100, na.rm = TRUE)),
  `Treated (\\%)` = sprintf("%.0f", mean(treated) * 100)
), by = .(Year = year)]

tab1_tex <- kable(summ_year, format = "latex", booktabs = TRUE,
                  escape = FALSE, align = c("c", rep("r", 5)),
                  caption = "Summary Statistics by Census Year") %>%
  kable_styling(latex_options = "hold_position")

writeLines(tab1_tex, file.path(tab_dir, "tab1_summary.tex"))

# Panel B: Pre-treatment balance
pre <- panel[year == 1890]
pre[, ever_treat := as.integer(prohibition_year < 1920)]

bal <- rbind(
  pre[, .(Group = "Eventual prohibition",
          `Pop. (000s)` = round(mean(total_pop[ever_treat == 1] / 1000)),
          `FB share` = sprintf("%.3f", mean(fb_share[ever_treat == 1])),
          `German share` = sprintf("%.4f", mean(german_share[ever_treat == 1], na.rm = TRUE)),
          `Brew intensity` = sprintf("%.1f", mean(brew_intensity[ever_treat == 1], na.rm = TRUE)),
          N = sum(ever_treat == 1))],
  pre[, .(Group = "Never dry (control)",
          `Pop. (000s)` = round(mean(total_pop[ever_treat == 0] / 1000)),
          `FB share` = sprintf("%.3f", mean(fb_share[ever_treat == 0])),
          `German share` = sprintf("%.4f", mean(german_share[ever_treat == 0], na.rm = TRUE)),
          `Brew intensity` = sprintf("%.1f", mean(brew_intensity[ever_treat == 0], na.rm = TRUE)),
          N = sum(ever_treat == 0))]
)

tab1b_tex <- kable(bal, format = "latex", booktabs = TRUE,
                   caption = "Pre-Treatment Balance (1890)") %>%
  kable_styling(latex_options = "hold_position")

writeLines(tab1b_tex, file.path(tab_dir, "tab1b_balance.tex"))
cat("Table 1 saved.\n")

# ====================================================================
# TABLE 2: MAIN TWFE RESULTS
# ====================================================================

cat("=== Generating Table 2 ===\n")

tab2_tex <- etable(
  models$twfe_german_share,
  models$twfe_log_german,
  models$twfe_fb_share,
  models$twfe_log_fb,
  headers = c("German Share", "Log German", "FB Share", "Log FB"),
  tex = TRUE,
  depvar = FALSE,
  style.tex = style.tex("aer"),
  title = "Effect of State Prohibition on Immigrant Population",
  notes = "State and year fixed effects. Standard errors clustered by state.",
  fitstat = ~ n + r2
)

writeLines(tab2_tex, file.path(tab_dir, "tab2_twfe.tex"))
cat("Table 2 saved.\n")

# ====================================================================
# TABLE 2B: SUN & ABRAHAM (2021) RESULTS
# ====================================================================

cat("=== Generating Table 2b ===\n")

# Sun-Abraham models store sunab formulas that need cohort_sa in scope
# Re-estimate to get aggregated ATT
panel_sa <- readRDS(file.path(data_dir, "state_panel.rds"))
census_years_sa <- c(1870, 1880, 1890, 1900, 1910, 1920)
panel_sa[, cohort_sa := {
  py <- prohibition_year[1]
  cy <- census_years_sa[census_years_sa >= py]
  if (length(cy) > 0 && py < 1920) min(cy) else 10000
}, by = state_abbr]

sa1 <- feols(german_share ~ sunab(cohort_sa, year) | state_id + year,
             data = panel_sa, cluster = ~state_id)
sa2 <- feols(fb_share ~ sunab(cohort_sa, year) | state_id + year,
             data = panel_sa, cluster = ~state_id)

tab2b_tex <- etable(sa1, sa2,
  headers = c("German Share", "FB Share"),
  tex = TRUE,
  depvar = FALSE,
  style.tex = style.tex("aer"),
  title = "Sun \\& Abraham (2021) Heterogeneity-Robust Estimates",
  notes = "Interaction-weighted estimator following Sun and Abraham (2021). State and year FE. Clustered SE.",
  fitstat = ~ n + r2,
  agg = "ATT"
)
writeLines(tab2b_tex, file.path(tab_dir, "tab2b_sunab.tex"))
cat("Table 2b saved.\n")
rm(panel_sa, census_years_sa, sa1, sa2)

# ====================================================================
# TABLE 3: HETEROGENEITY BY BREWING INTENSITY
# ====================================================================

cat("=== Generating Table 3 ===\n")

tab3_tex <- etable(
  models$het_brew_disc,
  models$het_brew_log,
  models$het_brew_cont,
  headers = c("German Share", "Log German", "German Share"),
  tex = TRUE,
  depvar = FALSE,
  style.tex = style.tex("aer"),
  title = "Heterogeneity by Pre-Prohibition Brewing Intensity",
  notes = "Brewing intensity measured as breweries per 100,000 population in 1870 Census of Manufactures. State and year FE. Clustered SE.",
  fitstat = ~ n + r2
)

writeLines(tab3_tex, file.path(tab_dir, "tab3_heterogeneity.tex"))
cat("Table 3 saved.\n")

# ====================================================================
# TABLE 4: POPULATION GROWTH
# ====================================================================

cat("=== Generating Table 4 ===\n")

tab4_tex <- etable(
  models$growth_pop,
  models$growth_german,
  models$growth_fb,
  headers = c("Pop. Growth", "German Growth", "FB Growth"),
  tex = TRUE,
  depvar = FALSE,
  style.tex = style.tex("aer"),
  title = "Effect of Prohibition on Decade-over-Decade Population Growth",
  notes = "Growth rates computed as decade-over-decade percentage change. State and year FE. Clustered SE.",
  fitstat = ~ n + r2
)

writeLines(tab4_tex, file.path(tab_dir, "tab4_growth.tex"))
cat("Table 4 saved.\n")

# ====================================================================
# TABLE 5: GERMAN ENCLAVE INTERACTION
# ====================================================================

cat("=== Generating Table 5 ===\n")

tab5_tex <- etable(
  models$enclave_german,
  models$enclave_fb,
  headers = c("German Share", "FB Share"),
  tex = TRUE,
  depvar = FALSE,
  style.tex = style.tex("aer"),
  title = "German Enclave Heterogeneity",
  notes = "German enclave = above-median German-born share in 1890. State and year FE. Clustered SE.",
  fitstat = ~ n + r2
)

writeLines(tab5_tex, file.path(tab_dir, "tab5_enclave.tex"))
cat("Table 5 saved.\n")

# ====================================================================
# TABLE 6: ROBUSTNESS — ALTERNATIVE SAMPLES
# ====================================================================

cat("=== Generating Table 6 ===\n")

robust_file <- file.path(data_dir, "robustness.rds")
if (file.exists(robust_file)) {
  robust <- readRDS(robust_file)

  tab6_tex <- etable(
    models$twfe_german_share,
    robust$drop_border,
    robust$south_west,
    robust$drop_dc,
    headers = c("Baseline", "Drop Border", "South vs West", "Drop DC"),
    tex = TRUE,
    depvar = FALSE,
    style.tex = style.tex("aer"),
    title = "Robustness: Alternative Control Groups",
    notes = "All specifications include state and year FE with clustered SE.",
    fitstat = ~ n + r2
  )

  writeLines(tab6_tex, file.path(tab_dir, "tab6_robustness.tex"))
  cat("Table 6 saved.\n")
} else {
  cat("Table 6 skipped (robustness results not available).\n")
}

# ====================================================================
# TABLE 7: DOSE-RESPONSE
# ====================================================================

cat("=== Generating Table 7 ===\n")

if (file.exists(robust_file)) {
  robust <- readRDS(robust_file)

  tab7_tex <- etable(
    robust$dose_duration,
    robust$dose_log,
    headers = c("German Share", "Log German"),
    tex = TRUE,
    depvar = FALSE,
    style.tex = style.tex("aer"),
    title = "Dose-Response: Years Under Prohibition",
    notes = "Duration = max(0, census year - prohibition adoption year). State and year FE. Clustered SE.",
    fitstat = ~ n + r2
  )

  writeLines(tab7_tex, file.path(tab_dir, "tab7_dose.tex"))
  cat("Table 7 saved.\n")
} else {
  cat("Table 7 skipped.\n")
}

# ====================================================================
# TABLE 8: CALLAWAY & SANT'ANNA RESULTS
# ====================================================================

cat("=== Generating Table 8 (CS-DiD) ===\n")

cs_german_file <- file.path(data_dir, "cs_german.rds")
cs_fb_file <- file.path(data_dir, "es_fb.rds")

if (file.exists(cs_german_file)) {
  cs_german <- readRDS(cs_german_file)
  agg_german <- aggte(cs_german, type = "simple")

  # Try to get FB results too
  fb_att <- fb_se <- NA
  panel_cs <- readRDS(file.path(data_dir, "state_panel.rds"))
  census_years_cs <- c(1870, 1880, 1890, 1900, 1910, 1920)
  panel_cs[, cohort_census := {
    cy <- census_years_cs[census_years_cs >= prohibition_year]
    if (length(cy) > 0) min(cy) else 0
  }, by = state_abbr]
  panel_cs[prohibition_year == 1920, cohort_census := 0]
  panel_cs[, state_num := as.integer(factor(state_abbr))]

  cs_fb <- tryCatch({
    att_gt(yname = "fb_share", tname = "year", idname = "state_num",
           gname = "cohort_census", data = as.data.frame(panel_cs),
           control_group = "nevertreated", base_period = "universal")
  }, error = function(e) NULL)

  if (!is.null(cs_fb)) {
    agg_fb <- aggte(cs_fb, type = "simple")
    fb_att <- agg_fb$overall.att
    fb_se <- agg_fb$overall.se
  }

  stars_fn <- function(p) {
    if (p < 0.01) "***" else if (p < 0.05) "**" else if (p < 0.1) "*" else ""
  }

  p_german <- 2 * pnorm(-abs(agg_german$overall.att / agg_german$overall.se))
  p_fb <- if (!is.na(fb_att)) 2 * pnorm(-abs(fb_att / fb_se)) else NA

  cs_tab <- sprintf("\\begin{tabular}{lcc}
\\toprule
 & German Share & FB Share \\\\
\\midrule
Overall ATT & %.4f%s & %s%s \\\\
 & (%.4f) & (%s) \\\\
\\midrule
Estimator & \\multicolumn{2}{c}{Callaway \\& Sant'Anna (2021)} \\\\
Control group & \\multicolumn{2}{c}{Never-treated} \\\\
Base period & \\multicolumn{2}{c}{Universal} \\\\
\\bottomrule
\\multicolumn{3}{l}{\\footnotesize *** p$<$0.01, ** p$<$0.05, * p$<$0.1} \\\\
\\end{tabular}",
    agg_german$overall.att, stars_fn(p_german),
    ifelse(!is.na(fb_att), sprintf("%.4f", fb_att), "---"),
    ifelse(!is.na(fb_att), stars_fn(p_fb), ""),
    agg_german$overall.se,
    ifelse(!is.na(fb_se), sprintf("%.4f", fb_se), "---")
  )

  writeLines(cs_tab, file.path(tab_dir, "tab8_csdid.tex"))
  cat("Table 8 saved.\n")
  rm(panel_cs, census_years_cs)
} else {
  cat("Table 8 skipped (CS-DiD results not available).\n")
}

# ====================================================================
# TABLE 9: PRE/POST 1890-1920 (OBSERVED YEARS ONLY)
# ====================================================================

cat("=== Generating Table 9 (Pre/Post) ===\n")

pp_file <- file.path(data_dir, "prepost_models.rds")
if (file.exists(pp_file)) {
  pp <- readRDS(pp_file)

  tab9_tex <- etable(
    pp$pp_base,
    pp$pp_brew,
    pp$pp_enclave,
    pp$pp_fb,
    headers = c("German Share", "× Brewing", "× Enclave", "FB × Enclave"),
    tex = TRUE,
    depvar = FALSE,
    style.tex = style.tex("aer"),
    title = "Pre/Post 1890--1920 Using Only Observed German-Born Data",
    notes = "Uses only 1890 and 1920 census years, for which state-level German-born data are directly observed (no imputation). State FE included. Clustered SE.",
    fitstat = ~ n + r2
  )

  writeLines(tab9_tex, file.path(tab_dir, "tab9_prepost.tex"))
  cat("Table 9 saved.\n")
} else {
  cat("Table 9 skipped (pre/post models not available).\n")
}

cat("\nAll tables complete.\n")
