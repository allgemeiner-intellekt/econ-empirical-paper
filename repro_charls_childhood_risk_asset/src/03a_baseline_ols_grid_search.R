#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
  library(lmtest)
  library(sandwich)
})

root_dir <- "repro_charls_childhood_risk_asset"
output_dir <- file.path(root_dir, "output")
tables_dir <- file.path(output_dir, "tables")
logs_dir <- file.path(root_dir, "logs")

dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(logs_dir, recursive = TRUE, showWarnings = FALSE)

data <- readRDS(file.path(output_dir, "analysis_dataset.rds"))

base_denom <- c("cash_amt", "deposit_amt", "bond_amt", "stock_amt", "fund_amt", "lend_amt")
optional_denom <- c("emoney_amt", "other_fin_amt", "housing_fund_amt", "jizikuan_amt", "unpaid_salary_amt")

risk_specs <- list(
  stock_fund = c("stock_amt", "fund_amt"),
  stock_fund_lend = c("stock_amt", "fund_amt", "lend_amt")
)

sample_variants <- c(
  "all",
  "financial_asset_total_gt0",
  "risk_ratio_gt0",
  "winsor_top1",
  "winsor_top2",
  "trim_totalasset_p1_99",
  "trim_totalasset_p2_98"
)

star_label <- function(p) {
  ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
}

run_ols <- function(df, y, controls) {
  formula_text <- if (length(controls) == 0) {
    paste0(y, " ~ childhealth")
  } else {
    paste0(y, " ~ childhealth + ", paste(controls, collapse = " + "))
  }
  fit <- lm(as.formula(formula_text), data = df)
  ct <- coeftest(fit, vcov. = vcovHC(fit, type = "HC1"))
  c(
    beta = ct["childhealth", 1],
    se = ct["childhealth", 2],
    p = ct["childhealth", 4],
    n = nobs(fit)
  )
}

variant_apply <- function(df, ratio_var, variant) {
  out <- df
  if (variant == "financial_asset_total_gt0") {
    out <- out %>% filter(denominator > 0)
  } else if (variant == "risk_ratio_gt0") {
    out <- out %>% filter(.data[[ratio_var]] > 0)
  } else if (variant == "winsor_top1") {
    q <- as.numeric(quantile(out[[ratio_var]], 0.99, na.rm = TRUE))
    out[[ratio_var]] <- pmin(out[[ratio_var]], q)
  } else if (variant == "winsor_top2") {
    q <- as.numeric(quantile(out[[ratio_var]], 0.98, na.rm = TRUE))
    out[[ratio_var]] <- pmin(out[[ratio_var]], q)
  } else if (variant == "trim_totalasset_p1_99") {
    q <- as.numeric(quantile(out$financial_asset_total, 0.99, na.rm = TRUE))
    out <- out %>% filter(financial_asset_total <= q)
  } else if (variant == "trim_totalasset_p2_98") {
    q <- as.numeric(quantile(out$financial_asset_total, 0.98, na.rm = TRUE))
    out <- out %>% filter(financial_asset_total <= q)
  }
  out
}

comb_grid <- expand.grid(
  include_emoney = c(0, 1),
  include_other_fin = c(0, 1),
  include_housing_fund = c(0, 1),
  include_jizikuan = c(0, 1),
  include_unpaid_salary = c(0, 1),
  stringsAsFactors = FALSE
) %>%
  mutate(denom_spec_id = paste0("denom_", row_number()))

rows <- list()

for (i in seq_len(nrow(comb_grid))) {
  g <- comb_grid[i, ]
  denom_components <- base_denom
  if (g$include_emoney == 1) denom_components <- c(denom_components, "emoney_amt")
  if (g$include_other_fin == 1) denom_components <- c(denom_components, "other_fin_amt")
  if (g$include_housing_fund == 1) denom_components <- c(denom_components, "housing_fund_amt")
  if (g$include_jizikuan == 1) denom_components <- c(denom_components, "jizikuan_amt")
  if (g$include_unpaid_salary == 1) denom_components <- c(denom_components, "unpaid_salary_amt")

  d0 <- data %>%
    mutate(
      denominator = rowSums(across(all_of(denom_components)))
    )

  for (risk_name in names(risk_specs)) {
    risk_components <- risk_specs[[risk_name]]
    d1 <- d0 %>%
      mutate(
        risk_numerator = rowSums(across(all_of(risk_components))),
        risk_ratio_variant = ifelse(denominator > 0, risk_numerator / denominator, 0)
      ) %>%
      filter(!is.na(risk_ratio_variant), risk_ratio_variant >= 0, risk_ratio_variant <= 1)

    for (sv in sample_variants) {
      d2 <- variant_apply(d1, "risk_ratio_variant", sv)

      d3 <- d2 %>%
        select(risk_ratio_variant, childhealth, age, gender, hukou, marriage) %>%
        filter(complete.cases(.))

      if (nrow(d3) < 30) next

      m3 <- run_ols(d3, "risk_ratio_variant", character(0))
      m4 <- run_ols(d3, "risk_ratio_variant", c("age", "gender", "hukou", "marriage"))

      scenario_id <- paste(g$denom_spec_id, risk_name, sv, "unweighted", sep = "__")

      rows[[length(rows) + 1]] <- data.frame(
        scenario_id = scenario_id,
        denom_spec_id = g$denom_spec_id,
        risk_spec = risk_name,
        sample_variant = sv,
        weighting = "unweighted",
        model_id = "(3)",
        controls = "No",
        target_beta = -0.003,
        childhealth_beta = unname(m3["beta"]),
        robust_se = unname(m3["se"]),
        p_value = unname(m3["p"]),
        n = as.integer(m3["n"]),
        abs_error_to_target = abs(unname(m3["beta"]) + 0.003),
        denom_components = paste(denom_components, collapse = "+"),
        risk_components = paste(risk_components, collapse = "+"),
        include_emoney = g$include_emoney,
        include_other_fin = g$include_other_fin,
        include_housing_fund = g$include_housing_fund,
        include_jizikuan = g$include_jizikuan,
        include_unpaid_salary = g$include_unpaid_salary,
        stringsAsFactors = FALSE
      )

      rows[[length(rows) + 1]] <- data.frame(
        scenario_id = scenario_id,
        denom_spec_id = g$denom_spec_id,
        risk_spec = risk_name,
        sample_variant = sv,
        weighting = "unweighted",
        model_id = "(4)",
        controls = "Yes",
        target_beta = -0.002,
        childhealth_beta = unname(m4["beta"]),
        robust_se = unname(m4["se"]),
        p_value = unname(m4["p"]),
        n = as.integer(m4["n"]),
        abs_error_to_target = abs(unname(m4["beta"]) + 0.002),
        denom_components = paste(denom_components, collapse = "+"),
        risk_components = paste(risk_components, collapse = "+"),
        include_emoney = g$include_emoney,
        include_other_fin = g$include_other_fin,
        include_housing_fund = g$include_housing_fund,
        include_jizikuan = g$include_jizikuan,
        include_unpaid_salary = g$include_unpaid_salary,
        stringsAsFactors = FALSE
      )
    }
  }
}

res <- bind_rows(rows)

scenario_score <- res %>%
  group_by(scenario_id) %>%
  summarise(
    total_abs_error_to_targets = sum(abs_error_to_target),
    max_abs_error_to_target = max(abs_error_to_target),
    min_n_across_models = min(n),
    .groups = "drop"
  ) %>%
  arrange(total_abs_error_to_targets, max_abs_error_to_target, desc(min_n_across_models)) %>%
  mutate(rank_by_target_error = row_number())

res <- res %>%
  left_join(scenario_score, by = "scenario_id") %>%
  arrange(rank_by_target_error, model_id)

write.csv(res, file.path(tables_dir, "table2_ols_grid_search.csv"), row.names = FALSE)

best10 <- res %>%
  filter(rank_by_target_error <= 10) %>%
  mutate(
    coef_fmt = sprintf("%.4f%s", childhealth_beta, star_label(p_value)),
    se_fmt = sprintf("(%.4f)", robust_se),
    p_fmt = sprintf("%.4f", p_value)
  ) %>%
  select(
    rank_by_target_error,
    scenario_id,
    sample_variant,
    risk_spec,
    model_id,
    coef_fmt,
    se_fmt,
    p_fmt,
    n,
    total_abs_error_to_targets
  )

write.csv(best10, file.path(tables_dir, "table2_ols_grid_top10.csv"), row.names = FALSE)

summary_lines <- c(
  sprintf("Generated at: %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  sprintf("Rows in grid output: %d", nrow(res)),
  sprintf("Unique scenarios: %d", dplyr::n_distinct(res$scenario_id)),
  "Top 5 scenarios:",
  paste(capture.output(print(best10 %>% filter(rank_by_target_error <= 5))), collapse = "\n")
)

writeLines(summary_lines, file.path(logs_dir, "baseline_ols_grid_search.log"))
cat(paste(summary_lines, collapse = "\n"), "\n")
