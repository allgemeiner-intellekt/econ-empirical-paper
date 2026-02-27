#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(dplyr)
})

root_dir <- "repro_charls_childhood_risk_asset"
output_dir <- file.path(root_dir, "output")
tables_dir <- file.path(output_dir, "tables")
logs_dir <- file.path(root_dir, "logs")

dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(logs_dir, recursive = TRUE, showWarnings = FALSE)

analysis_dataset <- readRDS(file.path(output_dir, "analysis_dataset.rds"))

paper_targets <- data.frame(
  model_id = c("(1)", "(2)", "(3)", "(4)"),
  paper_childhealth = c(-0.221, -0.108, -0.130, -0.068),
  stringsAsFactors = FALSE
)

prepare_data <- function(data, y_var, controls, iv_vars) {
  use_vars <- c(y_var, "childhealth", controls, iv_vars)
  data %>%
    select(all_of(use_vars)) %>%
    mutate(across(everything(), as.numeric)) %>%
    filter(complete.cases(.))
}

run_2sls <- function(data, y_var, controls, iv_vars) {
  dat <- prepare_data(data, y_var, controls, iv_vars)
  n <- nrow(dat)
  if (n < 100) return(NULL)

  x_formula <- if (length(controls) == 0) {
    "~ childhealth"
  } else {
    paste0("~ childhealth + ", paste(controls, collapse = " + "))
  }

  z_terms <- if (length(controls) == 0) {
    iv_vars
  } else {
    c(iv_vars, controls)
  }
  z_formula <- paste0("~ ", paste(z_terms, collapse = " + "))

  X <- model.matrix(as.formula(x_formula), data = dat)
  Z <- model.matrix(as.formula(z_formula), data = dat)
  y <- as.matrix(dat[[y_var]])

  ZtZ_inv <- solve(t(Z) %*% Z)
  XPZX <- t(X) %*% Z %*% ZtZ_inv %*% t(Z) %*% X
  beta <- solve(XPZX, t(X) %*% Z %*% ZtZ_inv %*% t(Z) %*% y)

  u <- y - X %*% beta
  k <- ncol(X)

  middle <- t(X) %*% Z %*% ZtZ_inv %*% t(Z) %*% diag(as.numeric(u^2), n, n) %*% Z %*% ZtZ_inv %*% t(Z) %*% X
  vcov_hc1 <- solve(XPZX) %*% middle %*% solve(XPZX) * (n / (n - k))

  coef_names <- colnames(X)
  beta_vec <- as.numeric(beta)
  names(beta_vec) <- coef_names
  se_vec <- sqrt(diag(vcov_hc1))
  names(se_vec) <- coef_names
  stat_vec <- beta_vec / se_vec
  p_vec <- 2 * pnorm(abs(stat_vec), lower.tail = FALSE)

  # First-stage joint F-test for excluded instruments (classic OLS F).
  fs_full <- lm(
    as.formula(paste0("childhealth ~ ", paste(c(iv_vars, controls), collapse = " + "))),
    data = dat
  )
  fs_rest <- if (length(controls) == 0) {
    lm(childhealth ~ 1, data = dat)
  } else {
    lm(as.formula(paste0("childhealth ~ ", paste(controls, collapse = " + "))), data = dat)
  }
  fs_anova <- anova(fs_rest, fs_full)

  list(
    n = n,
    child_beta = beta_vec["childhealth"],
    child_se = se_vec["childhealth"],
    child_p = p_vec["childhealth"],
    first_stage_f = as.numeric(fs_anova$F[2]),
    first_stage_p = as.numeric(fs_anova$`Pr(>F)`[2])
  )
}

model_specs <- list(
  list(model_id = "(1)", dep = "Risk_Dummy", controls = character(0), controls_label = "No"),
  list(model_id = "(2)", dep = "Risk_Dummy", controls = c("age", "gender", "hukou", "marriage"), controls_label = "Yes"),
  list(model_id = "(3)", dep = "Risk_Ratio", controls = character(0), controls_label = "No"),
  list(model_id = "(4)", dep = "Risk_Ratio", controls = c("age", "gender", "hukou", "marriage"), controls_label = "Yes")
)

iv_specs <- list(
  list(iv_spec_id = "hospital_proxy", iv_vars = c("hospital_proxy"), iv_label = "proxy: childhood hospitalization (NOT paper IV)"),
  list(iv_spec_id = "vaccinated_childhood", iv_vars = c("vaccinated_childhood"), iv_label = "proxy: childhood vaccination (closest to access)"),
  list(iv_spec_id = "vaccinated_plus_hosp3", iv_vars = c("vaccinated_childhood", "hospitalized_3plus"), iv_label = "multi-IV: vaccinated + hospitalized_3plus"),
  list(iv_spec_id = "vaccinated_plus_hosp3_plus_bed", iv_vars = c("vaccinated_childhood", "hospitalized_3plus", "bedbound_health"), iv_label = "multi-IV: vaccinated + hospitalized_3plus + bedbound")
)

rows <- list()
for (iv in iv_specs) {
  for (spec in model_specs) {
    fit <- run_2sls(analysis_dataset, spec$dep, spec$controls, iv$iv_vars)
    if (is.null(fit)) next

    rows[[length(rows) + 1]] <- data.frame(
      iv_spec_id = iv$iv_spec_id,
      iv_vars = paste(iv$iv_vars, collapse = "+"),
      iv_label = iv$iv_label,
      model_id = spec$model_id,
      dependent_variable = spec$dep,
      controls = spec$controls_label,
      n = fit$n,
      estimate = fit$child_beta,
      robust_se = fit$child_se,
      p_value = fit$child_p,
      first_stage_f = fit$first_stage_f,
      first_stage_p = fit$first_stage_p,
      stringsAsFactors = FALSE
    )
  }
}

res <- bind_rows(rows) %>%
  left_join(paper_targets, by = "model_id") %>%
  mutate(
    diff_vs_paper = estimate - paper_childhealth,
    abs_diff_vs_paper = abs(diff_vs_paper)
  )

iv_score <- res %>%
  group_by(iv_spec_id, iv_vars, iv_label) %>%
  summarise(
    total_abs_diff_vs_paper = sum(abs_diff_vs_paper),
    min_first_stage_f = min(first_stage_f),
    negative_beta_count = sum(estimate < 0),
    all_four_beta_negative = all(estimate < 0),
    all_four_p_lt_0_1 = all(p_value < 0.1),
    .groups = "drop"
  ) %>%
  arrange(total_abs_diff_vs_paper, desc(min_first_stage_f)) %>%
  mutate(rank_by_total_abs_diff = row_number())

res <- res %>% left_join(iv_score, by = c("iv_spec_id", "iv_vars", "iv_label")) %>%
  arrange(rank_by_total_abs_diff, iv_spec_id, model_id)

write.csv(res, file.path(tables_dir, "table3_iv_sensitivity.csv"), row.names = FALSE)
write.csv(iv_score, file.path(tables_dir, "table3_iv_sensitivity_summary.csv"), row.names = FALSE)

summary_lines <- c(
  sprintf("Generated at: %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  sprintf("IV specs evaluated: %d", nrow(iv_score)),
  "Summary ranking (top 4):",
  paste(capture.output(print(iv_score %>% select(rank_by_total_abs_diff, iv_spec_id, iv_vars, total_abs_diff_vs_paper, min_first_stage_f, all_four_beta_negative, all_four_p_lt_0_1))), collapse = "\n")
)

writeLines(summary_lines, file.path(logs_dir, "iv_sensitivity_alternative_ivs.log"))
cat(paste(summary_lines, collapse = "\n"), "\n")

