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

analysis_sample <- readRDS(file.path(output_dir, "analysis_sample_stage2.rds"))

health <- read_dta("data/temp_2018/Health_Status_and_Functioning.dta") %>%
  transmute(
    ID,
    health_raw = num_clean(da002)
  ) %>%
  mutate(
    health = ifelse(health_raw %in% 1:5, health_raw, NA_real_)
  )

cognition <- read_dta("data/temp_2018/Cognition.dta") %>%
  transmute(
    ID,
    depressed_raw = num_clean(dc011),
    hopeful_raw = num_clean(dc013),
    fear_raw = num_clean(dc014)
  ) %>%
  mutate(
    depressed = ifelse(depressed_raw %in% 1:4, depressed_raw, NA_real_),
    hopeful = ifelse(hopeful_raw %in% 1:4, hopeful_raw, NA_real_),
    fear = ifelse(fear_raw %in% 1:4, fear_raw, NA_real_)
  )

work <- read_dta("data/temp_2018/Work_Retirement.dta") %>%
  transmute(
    ID,
    work_nonfarm_raw = num_clean(fa002_w4),
    work_agri_raw = num_clean(fa006_w3_1)
  ) %>%
  mutate(
    work_nonfarm = ifelse(work_nonfarm_raw %in% c(1, 2), ifelse(work_nonfarm_raw == 1, 1, 0), NA_real_),
    work_agri = ifelse(work_agri_raw %in% c(1, 2), ifelse(work_agri_raw == 1, 1, 0), NA_real_),
    work = work_nonfarm,
    work_any = ifelse(
      work_nonfarm == 1 | work_agri == 1,
      1,
      ifelse(
        work_nonfarm == 0 & (is.na(work_agri) | work_agri == 0),
        0,
        ifelse(is.na(work_nonfarm) & work_agri == 0, 0, NA_real_)
      )
    )
  )

analysis_dataset <- analysis_sample %>%
  left_join(health, by = "ID") %>%
  left_join(cognition, by = "ID") %>%
  left_join(work, by = "ID") %>%
  mutate(
    childhealth = ifelse(childhealth_raw %in% 1:5, childhealth_raw, NA_real_),
    gender = ifelse(gender_raw == 1, 1, ifelse(gender_raw == 2, 0, NA_real_)),
    hukou = ifelse(hukou_raw %in% c(2, 3), 1, ifelse(hukou_raw == 1, 0, NA_real_)),
    marriage = ifelse(marriage_raw %in% c(1, 2), 1, ifelse(marriage_raw %in% c(3, 4, 5, 6), 0, NA_real_)),
    education = ifelse(education_raw %in% 1:11, pmin(education_raw, 10), NA_real_),
    edu = ifelse(education_raw %in% 6:11, 1, ifelse(education_raw %in% 1:5, 0, NA_real_)),
    under60 = ifelse(age <= 60, 1, ifelse(age > 60, 0, NA_real_)),
    lntotalasset = log1p(financial_asset_total),
    Risk_Dummy = ifelse(Risk_Dummy > 0, 1, 0),
    Risk_Ratio = ifelse(Risk_Ratio >= 0 & Risk_Ratio <= 1, Risk_Ratio, NA_real_),
    hospital = NA_real_,
    hospital_proxy = ifelse(hospitalized_childhood %in% c(0, 1), hospitalized_childhood, NA_real_),
    iv_hospital_available = 0
  )

key_vars <- c(
  "Risk_Dummy", "Risk_Ratio", "childhealth", "age", "gender", "hukou", "marriage",
  "work", "education", "health", "lntotalasset", "depressed", "hopeful", "fear",
  "under60", "edu", "hospital", "hospital_proxy"
)

missingness <- data.frame(
  variable = key_vars,
  missing_n = sapply(analysis_dataset[key_vars], function(x) sum(is.na(x))),
  nonmissing_n = sapply(analysis_dataset[key_vars], function(x) sum(!is.na(x))),
  stringsAsFactors = FALSE
)

final_cols <- c(
  "ID", "householdID", "communityID",
  "Risk_Dummy", "Risk_Ratio", "risk_asset_total", "financial_asset_total",
  "childhealth", "hospital", "hospital_proxy", "iv_hospital_available",
  "age", "gender", "hukou", "marriage", "work", "work_any",
  "education", "health", "lntotalasset", "depressed", "hopeful", "fear",
  "under60", "edu",
  "miss_school_health", "bedbound_health", "hospitalized_childhood", "hospitalized_3plus",
  "vaccinated_childhood", "mom_occup_raw", "dad_occup_raw",
  "gender_raw", "hukou_raw", "marriage_raw", "education_raw",
  "health_raw", "depressed_raw", "hopeful_raw", "fear_raw",
  "work_nonfarm_raw", "work_agri_raw",
  "cash_amt", "emoney_amt", "deposit_amt", "bond_amt", "stock_amt", "fund_amt",
  "other_fin_amt", "housing_fund_amt", "jizikuan_amt", "unpaid_salary_amt", "lend_amt"
)

analysis_dataset <- analysis_dataset %>% select(all_of(final_cols))

write.csv(analysis_dataset, file.path(output_dir, "analysis_dataset.csv"), row.names = FALSE, na = "")
saveRDS(analysis_dataset, file.path(output_dir, "analysis_dataset.rds"))
write.csv(missingness, file.path(output_dir, "analysis_dataset_missingness.csv"), row.names = FALSE)

summary_lines <- c(
  sprintf("Generated at: %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  sprintf("Rows: %d", nrow(analysis_dataset)),
  sprintf("Columns: %d", ncol(analysis_dataset)),
  sprintf("Risk_Dummy mean: %.4f", mean(analysis_dataset$Risk_Dummy, na.rm = TRUE)),
  sprintf("Risk_Ratio mean: %.4f", mean(analysis_dataset$Risk_Ratio, na.rm = TRUE)),
  sprintf("Childhealth mean: %.4f", mean(analysis_dataset$childhealth, na.rm = TRUE)),
  sprintf("Hospital available count: %d", sum(!is.na(analysis_dataset$hospital))),
  sprintf("Hospital proxy available count: %d", sum(!is.na(analysis_dataset$hospital_proxy)))
)

writeLines(summary_lines, con = file.path(logs_dir, "variable_construction_summary.log"))
cat(paste(summary_lines, collapse = "\n"), "\n")
