## 03_main_analysis.R — Core DiD analysis
## APEP-0241: State Prohibition and the German-American Brewing Elite

source("00_packages.R")

data_dir <- file.path("..", "data")
panel <- readRDS(file.path(data_dir, "state_panel.rds"))

fig_dir <- file.path("..", "figures")
tab_dir <- file.path("..", "tables")
dir.create(fig_dir, showWarnings = FALSE)
dir.create(tab_dir, showWarnings = FALSE)

# ====================================================================
# 1. TWFE: GERMAN-BORN SHARE
# ====================================================================
# Y = german_share, D = treated, state + year FE

m1 <- feols(german_share ~ treated | state_id + year,
            data = panel, cluster = ~state_id)

m2 <- feols(log_german ~ treated | state_id + year,
            data = panel, cluster = ~state_id)

m3 <- feols(fb_share ~ treated | state_id + year,
            data = panel, cluster = ~state_id)

m4 <- feols(log_fb ~ treated | state_id + year,
            data = panel, cluster = ~state_id)

cat("=== Table 2: TWFE — Population Outcomes ===\n")
etable(m1, m2, m3, m4,
       headers = c("German Share", "Log German", "FB Share", "Log FB"))

# ====================================================================
# 1B. SUN & ABRAHAM (2021) — HETEROGENEITY-ROBUST ESTIMATOR
# ====================================================================
# Map prohibition years to nearest census year for Sun-Abraham cohorts
# Never-treated states use Inf

census_years <- c(1870, 1880, 1890, 1900, 1910, 1920)

panel[, cohort_sa := {
  py <- prohibition_year[1]
  cy <- census_years[census_years >= py]
  if (length(cy) > 0 && py < 1920) min(cy) else 10000
}, by = state_abbr]

cat("\n=== Sun & Abraham (2021) Estimates ===\n")
cat("Cohort distribution:\n")
print(table(panel[year == 1900, cohort_sa]))

m_sa1 <- tryCatch({
  feols(german_share ~ sunab(cohort_sa, year) | state_id + year,
        data = panel, cluster = ~state_id)
}, error = function(e) {
  cat("Sun-Abraham error:", e$message, "\n")
  NULL
})

if (!is.null(m_sa1)) {
  cat("\nSun-Abraham ATT (German share):\n")
  print(summary(m_sa1, agg = "ATT"))
}

m_sa2 <- tryCatch({
  feols(fb_share ~ sunab(cohort_sa, year) | state_id + year,
        data = panel, cluster = ~state_id)
}, error = function(e) {
  cat("Sun-Abraham (FB) error:", e$message, "\n")
  NULL
})

if (!is.null(m_sa2)) {
  cat("\nSun-Abraham ATT (FB share):\n")
  print(summary(m_sa2, agg = "ATT"))
}

# ====================================================================
# 2. HETEROGENEOUS EFFECTS: BREWING INTENSITY
# ====================================================================
# Triple-difference: Prohibition × High-Brewing State

m5 <- feols(german_share ~ treated * high_brewing | state_id + year,
            data = panel, cluster = ~state_id)

m6 <- feols(log_german ~ treated * high_brewing | state_id + year,
            data = panel, cluster = ~state_id)

m7 <- feols(german_share ~ treated * brew_intensity | state_id + year,
            data = panel, cluster = ~state_id)

cat("\n=== Table 3: Heterogeneity by Brewing Intensity ===\n")
etable(m5, m6, m7,
       headers = c("German Share (Disc)", "Log German (Disc)", "German Share (Cont)"))

# ====================================================================
# 3. CALLAWAY & SANT'ANNA (2021)
# ====================================================================
# Map prohibition years to nearest census year for group assignment
# (CS-DiD requires discrete time periods)

# Map prohibition_year to next census year (census_years defined above)
panel[, cohort_census := {
  cy <- census_years[census_years >= prohibition_year]
  if (length(cy) > 0) min(cy) else 0
}, by = state_abbr]

# Never-treated states get cohort_census = 0
panel[prohibition_year == 1920, cohort_census := 0]

# CS-DiD requires numeric ID
panel[, state_num := as.integer(factor(state_abbr))]

cat("\n=== Callaway & Sant'Anna DiD ===\n")
cat("Cohort distribution:\n")
print(table(panel[year == 1900, cohort_census]))

# Run CS-DiD for German share
cs_german <- tryCatch({
  att_gt(
    yname = "german_share",
    tname = "year",
    idname = "state_num",
    gname = "cohort_census",
    data = as.data.frame(panel[!is.na(german_share)]),
    control_group = "nevertreated",
    base_period = "universal"
  )
}, error = function(e) {
  cat("CS-DiD error:", e$message, "\n")
  NULL
})

if (!is.null(cs_german)) {
  cat("\nGroup-time ATTs:\n")
  summary(cs_german)

  es_german <- aggte(cs_german, type = "dynamic")
  cat("\nEvent-study estimates:\n")
  summary(es_german)

  agg_german <- aggte(cs_german, type = "simple")
  cat("\nOverall ATT:\n")
  summary(agg_german)

  saveRDS(cs_german, file.path(data_dir, "cs_german.rds"))
  saveRDS(es_german, file.path(data_dir, "es_german.rds"))
}

# CS-DiD for foreign-born share
cs_fb <- tryCatch({
  att_gt(
    yname = "fb_share",
    tname = "year",
    idname = "state_num",
    gname = "cohort_census",
    data = as.data.frame(panel),
    control_group = "nevertreated",
    base_period = "universal"
  )
}, error = function(e) {
  cat("CS-DiD (FB) error:", e$message, "\n")
  NULL
})

if (!is.null(cs_fb)) {
  es_fb <- aggte(cs_fb, type = "dynamic")
  saveRDS(es_fb, file.path(data_dir, "es_fb.rds"))
}

# ====================================================================
# 3B. GOODMAN-BACON DECOMPOSITION
# ====================================================================
library(bacondecomp)

# Need balanced panel with binary treatment for bacon()
# Create balanced subsample (states present in all 6 years)
panel_bal <- panel[, if(.N == 6) .SD, by = state_abbr]
panel_bal[, treat_binary := as.integer(treated)]

cat("\n=== Goodman-Bacon Decomposition ===\n")
bacon_out <- tryCatch({
  bacon(german_share ~ treat_binary,
        data = as.data.frame(panel_bal),
        id_var = "state_abbr",
        time_var = "year")
}, error = function(e) {
  cat("Bacon decomposition error:", e$message, "\n")
  NULL
})

if (!is.null(bacon_out)) {
  cat("\nDecomposition results:\n")
  print(bacon_out)
  cat("\nWeighted average:", sum(bacon_out$estimate * bacon_out$weight), "\n")
  saveRDS(bacon_out, file.path(data_dir, "bacon_decomp.rds"))
}

# ====================================================================
# 3C. PRE/POST 1890-1920 (OBSERVED YEARS ONLY — NO IMPUTATION)
# ====================================================================
# Use only the two directly observed German-born data points (1890, 1920)
# This addresses imputation concerns raised by all reviewers

panel_prepost <- panel[year %in% c(1890, 1920)]
panel_prepost[, post := as.integer(year == 1920)]

# All states treated in 1920, so use "ever treated before 1920"
panel_prepost[, ever_treated := as.integer(prohibition_year < 1920)]

cat("\n=== Pre/Post 1890-1920 (Observed Years Only) ===\n")

# Simple DiD: German share
m_pp1 <- feols(german_share ~ ever_treated:post | state_id + year,
               data = panel_prepost, cluster = ~state_id)

# Heterogeneity: brewing intensity interaction
m_pp2 <- feols(german_share ~ ever_treated:post + ever_treated:post:high_brewing | state_id + year,
               data = panel_prepost, cluster = ~state_id)

# Heterogeneity: German enclave interaction
m_pp3 <- feols(german_share ~ ever_treated:post + ever_treated:post:german_enclave | state_id + year,
               data = panel_prepost, cluster = ~state_id)

# FB share
m_pp4 <- feols(fb_share ~ ever_treated:post + ever_treated:post:german_enclave | state_id + year,
               data = panel_prepost, cluster = ~state_id)

cat("Pre/post results:\n")
etable(m_pp1, m_pp2, m_pp3, m_pp4,
       headers = c("German Share", "× Brewing", "× Enclave", "FB × Enclave"))

saveRDS(list(pp_base = m_pp1, pp_brew = m_pp2, pp_enclave = m_pp3, pp_fb = m_pp4),
        file.path(data_dir, "prepost_models.rds"))

# ====================================================================
# 4. POPULATION GROWTH ANALYSIS
# ====================================================================

m8 <- feols(pop_growth ~ treated | state_id + year,
            data = panel[!is.na(pop_growth)], cluster = ~state_id)

m9 <- feols(german_growth ~ treated | state_id + year,
            data = panel[!is.na(german_growth)], cluster = ~state_id)

m10 <- feols(fb_growth ~ treated | state_id + year,
             data = panel[!is.na(fb_growth)], cluster = ~state_id)

cat("\n=== Table 4: Population Growth ===\n")
etable(m8, m9, m10,
       headers = c("Pop Growth", "German Growth", "FB Growth"))

# ====================================================================
# 5. GERMAN ENCLAVE INTERACTION
# ====================================================================

m11 <- feols(german_share ~ treated * german_enclave | state_id + year,
             data = panel, cluster = ~state_id)

m12 <- feols(fb_share ~ treated * german_enclave | state_id + year,
             data = panel, cluster = ~state_id)

cat("\n=== Table 5: German Enclave Heterogeneity ===\n")
etable(m11, m12,
       headers = c("German Share", "FB Share"))

# ====================================================================
# 5B. WILD CLUSTER BOOTSTRAP
# ====================================================================
library(fwildclusterboot)

cat("\n=== Wild Cluster Bootstrap ===\n")

boot_twfe <- tryCatch({
  boottest(m1, param = "treated",
           B = 999, clustid = "state_id", type = "rademacher")
}, error = function(e) {
  cat("Bootstrap TWFE error:", e$message, "\n")
  NULL
})
if (!is.null(boot_twfe)) {
  cat("TWFE treated: bootstrap p-value =", boot_twfe$p_val, "\n")
}

boot_brew <- tryCatch({
  boottest(m5, param = "treated:high_brewing",
           B = 999, clustid = "state_id", type = "rademacher")
}, error = function(e) {
  cat("Bootstrap brewing error:", e$message, "\n")
  NULL
})
if (!is.null(boot_brew)) {
  cat("Brewing interaction: bootstrap p-value =", boot_brew$p_val, "\n")
}

boot_enclave <- tryCatch({
  boottest(m11, param = "treated:german_enclave",
           B = 999, clustid = "state_id", type = "rademacher")
}, error = function(e) {
  cat("Bootstrap enclave error:", e$message, "\n")
  NULL
})
if (!is.null(boot_enclave)) {
  cat("Enclave interaction: bootstrap p-value =", boot_enclave$p_val, "\n")
}

boot_results <- list(twfe = boot_twfe, brew = boot_brew, enclave = boot_enclave)
saveRDS(boot_results, file.path(data_dir, "bootstrap_results.rds"))

# ====================================================================
# 6. SAVE ALL MODELS
# ====================================================================

models <- list(
  twfe_german_share = m1,
  twfe_log_german = m2,
  twfe_fb_share = m3,
  twfe_log_fb = m4,
  sa_german_share = m_sa1,
  sa_fb_share = m_sa2,
  het_brew_disc = m5,
  het_brew_log = m6,
  het_brew_cont = m7,
  growth_pop = m8,
  growth_german = m9,
  growth_fb = m10,
  enclave_german = m11,
  enclave_fb = m12,
  pp_base = m_pp1,
  pp_brew = m_pp2,
  pp_enclave = m_pp3,
  pp_fb = m_pp4
)

saveRDS(models, file.path(data_dir, "models.rds"))
cat("\nAll models saved.\n")
