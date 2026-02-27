#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
})

root_dir <- "repro_charls_childhood_risk_asset"
output_dir <- file.path(root_dir, "output")
logs_dir <- file.path(root_dir, "logs")

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(logs_dir, recursive = TRUE, showWarnings = FALSE)

num_clean <- function(x) {
  x <- as.numeric(x)
  x[x < 0] <- NA_real_
  x
}

# Conditional amount variables in CHARLS: indicator==1 -> valid amount, indicator==2 -> 0, others -> missing.
conditional_amount <- function(indicator, amount) {
  ifelse(indicator == 2, 0,
         ifelse(indicator == 1, amount, NA_real_))
}

sample_infor <- read_dta("data/temp_2018/Sample_Infor.dta") %>%
  transmute(
    ID,
    householdID,
    communityID,
    died = num_clean(died),
    crosssection = num_clean(crosssection),
    iyear = num_clean(iyear),
    imonth = num_clean(imonth)
  )

demo <- read_dta("data/temp_2018/Demographic_Background.dta") %>%
  transmute(
    ID,
    birth_year = num_clean(ba004_w3_1),
    gender_raw = num_clean(ba000_w2_3),
    hukou_raw = num_clean(zbc004),
    marriage_raw = num_clean(be001),
    education_raw = num_clean(bd001_w2_4)
  )

lh <- read_dta("data/H_CHARLS_LH_a.dta") %>%
  transmute(
    ID,
    childhealth_raw = num_clean(rachchlt),
    miss_school_health = num_clean(ramischlth),
    bedbound_health = num_clean(rachbedhlth),
    hospitalized_childhood = num_clean(rachhospital),
    hospitalized_3plus = num_clean(rachhospital3),
    vaccinated_childhood = num_clean(rachvaccine),
    mom_occup_raw = num_clean(ramomoccup_c),
    dad_occup_raw = num_clean(radadoccup_c)
  )

inc_raw <- read_dta("data/temp_2018/Individual_Income.dta") %>%
  transmute(
    ID,
    cash_amt = num_clean(hc001),
    emoney_amt = num_clean(hc003_w4),
    deposit_amt = num_clean(hc005),
    own_bond = num_clean(hc007),
    bond_amt_raw = num_clean(hc008),
    own_stock = num_clean(hc010),
    stock_amt_raw = num_clean(hc013),
    own_fund = num_clean(hc015),
    fund_amt_raw = num_clean(hc018),
    own_other_fin = num_clean(hc016_w4),
    other_fin_amt_raw = num_clean(hc017_w4),
    own_housing_fund = num_clean(hc027),
    housing_fund_amt_raw = num_clean(hc028),
    own_jizikuan = num_clean(hc030),
    jizikuan_amt_raw = num_clean(hc031),
    have_unpaid_salary = num_clean(hc033),
    unpaid_salary_amt_raw = num_clean(hc034),
    lend_money = num_clean(hc039_w3),
    lend_money_amt_raw = num_clean(hc040_w3)
  ) %>%
  mutate(
    bond_amt = conditional_amount(own_bond, bond_amt_raw),
    stock_amt = conditional_amount(own_stock, stock_amt_raw),
    fund_amt = conditional_amount(own_fund, fund_amt_raw),
    other_fin_amt = conditional_amount(own_other_fin, other_fin_amt_raw),
    housing_fund_amt = conditional_amount(own_housing_fund, housing_fund_amt_raw),
    jizikuan_amt = conditional_amount(own_jizikuan, jizikuan_amt_raw),
    unpaid_salary_amt = conditional_amount(have_unpaid_salary, unpaid_salary_amt_raw),
    lend_amt = conditional_amount(lend_money, lend_money_amt_raw)
  )

base_data <- sample_infor %>%
  left_join(demo, by = "ID") %>%
  left_join(lh, by = "ID") %>%
  left_join(inc_raw, by = "ID") %>%
  mutate(
    age = iyear - birth_year
  )

financial_components <- c(
  "cash_amt", "emoney_amt", "deposit_amt", "bond_amt", "stock_amt", "fund_amt",
  "other_fin_amt", "housing_fund_amt", "jizikuan_amt", "unpaid_salary_amt", "lend_amt"
)

risk_components <- c("stock_amt", "fund_amt", "lend_amt")

sample_step1 <- base_data
sample_step2 <- sample_step1 %>% filter(crosssection == 1, died == 0)
sample_step3 <- sample_step2 %>% filter(!is.na(age), age >= 45)
sample_step4 <- sample_step3 %>% filter(!is.na(childhealth_raw), childhealth_raw %in% 1:5)
sample_step5 <- sample_step4 %>%
  filter(
    !is.na(gender_raw),
    !is.na(hukou_raw),
    !is.na(marriage_raw)
  )
sample_step6 <- sample_step5 %>% filter(complete.cases(across(all_of(financial_components))))

analysis_sample <- sample_step6 %>%
  mutate(
    risk_asset_total = rowSums(across(all_of(risk_components))),
    financial_asset_total = rowSums(across(all_of(financial_components))),
    Risk_Dummy = ifelse(risk_asset_total > 0, 1, 0),
    Risk_Ratio = ifelse(financial_asset_total > 0, risk_asset_total / financial_asset_total, 0)
  ) %>%
  filter(!is.na(Risk_Ratio), Risk_Ratio >= 0, Risk_Ratio <= 1)

sample_flow <- data.frame(
  step = c(
    "S0_start_2018_sample_infor",
    "S1_keep_crosssection_1_and_alive",
    "S2_keep_age_ge_45",
    "S3_keep_childhealth_nonmissing_1to5",
    "S4_keep_core_controls_nonmissing",
    "S5_keep_financial_components_observed",
    "S6_drop_abnormal_risk_ratio_outside_0_1"
  ),
  n = c(
    nrow(sample_step1),
    nrow(sample_step2),
    nrow(sample_step3),
    nrow(sample_step4),
    nrow(sample_step5),
    nrow(sample_step6),
    nrow(analysis_sample)
  ),
  stringsAsFactors = FALSE
) %>%
  mutate(
    dropped = dplyr::lag(n) - n,
    dropped = ifelse(is.na(dropped), 0, dropped),
    drop_rate_from_prev_pct = ifelse(
      is.na(dplyr::lag(n)),
      0,
      ifelse(dplyr::lag(n) > 0, round(100 * dropped / dplyr::lag(n), 2), 0)
    ),
    keep_rate_from_start_pct = round(100 * n / first(n), 2)
  )

write.csv(sample_flow, file.path(output_dir, "sample_flow.csv"), row.names = FALSE)
write.csv(analysis_sample, file.path(output_dir, "analysis_sample_stage2.csv"), row.names = FALSE, na = "")
saveRDS(analysis_sample, file.path(output_dir, "analysis_sample_stage2.rds"))

summary_lines <- c(
  sprintf("Generated at: %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  sprintf("Final sample size: %d", nrow(analysis_sample)),
  sprintf("Risk_Dummy mean (share with risk assets): %.4f", mean(analysis_sample$Risk_Dummy, na.rm = TRUE)),
  sprintf("Risk_Ratio mean: %.4f", mean(analysis_sample$Risk_Ratio, na.rm = TRUE)),
  sprintf("Risk_Ratio p99: %.4f", as.numeric(quantile(analysis_sample$Risk_Ratio, probs = 0.99, na.rm = TRUE)))
)

writeLines(summary_lines, con = file.path(logs_dir, "sample_build_summary.log"))
cat(paste(summary_lines, collapse = "\n"), "\n")
