## 04_robustness.R — Robustness checks and diagnostics
## APEP-0241: State Prohibition and the German-American Brewing Elite

source("00_packages.R")

data_dir <- file.path("..", "data")
panel <- readRDS(file.path(data_dir, "state_panel.rds"))
models <- readRDS(file.path(data_dir, "models.rds"))

fig_dir <- file.path("..", "figures")
tab_dir <- file.path("..", "tables")

# ====================================================================
# 1. PLACEBO TESTS
# ====================================================================

cat("=== Placebo Tests ===\n")

# Placebo 1: Fake prohibition 20 years early
panel_placebo <- copy(panel)
panel_placebo[, placebo_treated := as.integer(year >= (prohibition_year - 20))]
# Restrict to pre-treatment period only
panel_pre <- panel_placebo[year < prohibition_year]

p1 <- tryCatch(
  feols(german_share ~ placebo_treated | state_id + year,
        data = panel_pre, cluster = ~state_id),
  error = function(e) { cat("Placebo 1 error:", e$message, "\n"); NULL }
)

# Placebo 2: Randomize treatment across states
set.seed(20241)
n_treated <- panel[year == 1900, sum(prohibition_year < 1920)]
all_states <- panel[year == 1900, unique(state_abbr)]

placebo_results <- data.table()
for (i in 1:500) {
  fake_treated <- sample(all_states, n_treated)
  panel[, fake_treat := as.integer(state_abbr %in% fake_treated & year >= 1910)]
  m_fake <- tryCatch(
    feols(german_share ~ fake_treat | state_id + year,
          data = panel, cluster = ~state_id),
    error = function(e) NULL
  )
  if (!is.null(m_fake)) {
    placebo_results <- rbind(placebo_results,
                             data.table(iter = i,
                                        coef = coef(m_fake)["fake_treat"],
                                        se = se(m_fake)["fake_treat"]))
  }
}
panel[, fake_treat := NULL]

# True effect
true_coef <- coef(models$twfe_german_share)["treated"]
ri_pval <- mean(abs(placebo_results$coef) >= abs(true_coef))

cat(sprintf("Randomization inference p-value: %.4f\n", ri_pval))
cat(sprintf("True coefficient: %.6f\n", true_coef))
cat(sprintf("Placebo distribution: mean=%.6f, sd=%.6f\n",
            mean(placebo_results$coef), sd(placebo_results$coef)))

saveRDS(placebo_results, file.path(data_dir, "ri_results.rds"))

# ====================================================================
# 2. ALTERNATIVE CONTROL GROUPS
# ====================================================================

cat("\n=== Alternative Control Groups ===\n")

# (a) Drop border states (states adjacent to prohibition states)
border_states <- c("MO", "NJ", "CT", "MA", "RI", "DE", "MD", "LA", "NY", "PA")
panel_noborder <- panel[!state_abbr %in% border_states]
r1 <- feols(german_share ~ treated | state_id + year,
            data = panel_noborder, cluster = ~state_id)

# (b) Only Southern prohibition states vs Western wet states
south <- c("GA","MS","NC","AL","TN","WV","VA","SC","AR","FL","TX","OK")
west_wet <- c("CA","NV","NJ","CT","NY","PA","RI","MA")
panel_sw <- panel[state_abbr %in% c(south, west_wet)]
r2 <- feols(german_share ~ treated | state_id + year,
            data = panel_sw, cluster = ~state_id)

# (c) Drop DC and territories
r3 <- feols(german_share ~ treated | state_id + year,
            data = panel[state_abbr != "DC"], cluster = ~state_id)

cat("\nAlternative control groups:\n")
etable(models$twfe_german_share, r1, r2, r3,
       headers = c("Baseline", "Drop border", "South vs West", "Drop DC"))

# ====================================================================
# 3. ALTERNATIVE OUTCOMES
# ====================================================================

cat("\n=== Alternative Outcomes ===\n")

# Total population (should be smaller/null — prohibition doesn't depopulate)
r4 <- feols(log_pop ~ treated | state_id + year,
            data = panel, cluster = ~state_id)

# Foreign-born share (broader than just German)
r5 <- feols(fb_share ~ treated | state_id + year,
            data = panel, cluster = ~state_id)

cat("\nAlternative outcomes:\n")
etable(r4, r5,
       headers = c("Log Population", "Foreign-Born Share"))

# ====================================================================
# 4. EVENT STUDY (TWFE)
# ====================================================================

cat("\n=== Event Study ===\n")

# Create event-time dummies (relative to prohibition year)
# Bin at -30 and +10
panel[, event_bin := pmin(pmax(event_time, -30), 10)]

# TWFE event study
es_twfe <- feols(german_share ~ i(event_bin, ref = -10) | state_id + year,
                 data = panel[event_bin >= -30 & event_bin <= 10],
                 cluster = ~state_id)

cat("\nEvent study coefficients:\n")
print(coeftable(es_twfe))

saveRDS(es_twfe, file.path(data_dir, "es_twfe.rds"))

# ====================================================================
# 5. DOSE-RESPONSE: YEARS UNDER PROHIBITION
# ====================================================================

cat("\n=== Dose-Response ===\n")

# Duration of prohibition at time of census
panel[, prohib_duration := pmax(0, year - prohibition_year)]

r6 <- feols(german_share ~ prohib_duration | state_id + year,
            data = panel, cluster = ~state_id)

r7 <- feols(log_german ~ prohib_duration | state_id + year,
            data = panel, cluster = ~state_id)

cat("\nDose-response (years under prohibition):\n")
etable(r6, r7,
       headers = c("German Share", "Log German"))

# ====================================================================
# 6. SAVE ROBUSTNESS RESULTS
# ====================================================================

robust <- list(
  placebo_early = p1,
  ri_pval = ri_pval,
  ri_results = placebo_results,
  drop_border = r1,
  south_west = r2,
  drop_dc = r3,
  log_pop = r4,
  fb_share = r5,
  es_twfe = es_twfe,
  dose_duration = r6,
  dose_log = r7
)

saveRDS(robust, file.path(data_dir, "robustness.rds"))
cat("\nRobustness results saved.\n")
