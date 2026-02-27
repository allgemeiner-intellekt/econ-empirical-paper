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

# Candidate IVs from harmonized Life History that are childhood-health related and available now.
iv_candidates <- c(
  "miss_school_health",
  "bedbound_health",
  "hospitalized_childhood",
  "hospitalized_3plus",
  "vaccinated_childhood"
)

iv_labels <- c(
  miss_school_health = "ramischlth: r miss school for a month because of a health condition before 15",
  bedbound_health = "rachbedhlth: r confined to bed for a month because of a health condition before 15",
  hospitalized_childhood = "rachhospital: r in hospital for a month because of a health condition before 15",
  hospitalized_3plus = "rachhospital3: r in hospital 3 times because of a health condition before 15",
  vaccinated_childhood = "rachvaccine: r vaccination during childhood"
)

paper_targets <- c(m1 = -0.221, m2 = -0.108, m3 = -0.130, m4 = -0.068)

star_label <- function(p) {
  ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))
}

prepare_data <- function(data, y_var, controls, iv_var) {
  vars <- c(y_var, "childhealth", controls, iv_var)
  data %>%
    select(all_of(vars)) %>%
    mutate(across(everything(), as.numeric)) %>%
    filter(complete.cases(.))
}

run_2sls <- function(data, y_var, controls, iv_var) {
  dat <- prepare_data(data, y_var, controls, iv_var)
  n <- nrow(dat)
  if (n < 100) return(NULL)

  x_formula <- if (length(controls) == 0) {
    "~ childhealth"
  } else {
    paste0("~ childhealth + ", paste(controls, collapse = " + "))
  }

  z_formula <- if (length(controls) == 0) {
    paste0("~ ", iv_var)
  } else {
    paste0("~ ", iv_var, " + ", paste(controls, collapse = " + "))
  }

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

  fs_full <- if (length(controls) == 0) {
    lm(as.formula(paste0("childhealth ~ ", iv_var)), data = dat)
  } else {
    lm(as.formula(paste0("childhealth ~ ", iv_var, " + ", paste(controls, collapse = " + "))), data = dat)
  }

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
    first_stage_coef = coef(fs_full)[iv_var],
    first_stage_f = as.numeric(fs_anova$F[2]),
    first_stage_p = as.numeric(fs_anova$`Pr(>F)`[2])
  )
}

model_specs <- list(
  list(id = "m1", dep = "Risk_Dummy", controls = character(0), controls_label = "No"),
  list(id = "m2", dep = "Risk_Dummy", controls = c("age", "gender", "hukou", "marriage"), controls_label = "Yes"),
  list(id = "m3", dep = "Risk_Ratio", controls = character(0), controls_label = "No"),
  list(id = "m4", dep = "Risk_Ratio", controls = c("age", "gender", "hukou", "marriage"), controls_label = "Yes")
)

scan_rows <- list()
for (iv in iv_candidates) {
  if (!iv %in% names(analysis_dataset)) next

  iv_nonmissing <- sum(!is.na(analysis_dataset[[iv]]))
  iv_unique <- dplyr::n_distinct(analysis_dataset[[iv]], na.rm = TRUE)

  res_by_model <- list()
  ok <- TRUE
  for (spec in model_specs) {
    fit <- run_2sls(analysis_dataset, spec$dep, spec$controls, iv)
    if (is.null(fit)) {
      ok <- FALSE
      break
    }
    res_by_model[[spec$id]] <- fit
  }
  if (!ok) next

  m1 <- res_by_model$m1
  m2 <- res_by_model$m2
  m3 <- res_by_model$m3
  m4 <- res_by_model$m4

  betas <- c(m1$child_beta, m2$child_beta, m3$child_beta, m4$child_beta)
  fs_vals <- c(m1$first_stage_f, m2$first_stage_f, m3$first_stage_f, m4$first_stage_f)

  scan_rows[[length(scan_rows) + 1]] <- data.frame(
    iv_variable = iv,
    iv_label = iv_labels[[iv]],
    nonmissing_in_analysis = iv_nonmissing,
    unique_n_in_analysis = iv_unique,

    m1_depvar = "Risk_Dummy",
    m1_controls = "No",
    m1_n = m1$n,
    m1_childhealth_beta = m1$child_beta,
    m1_childhealth_se = m1$child_se,
    m1_childhealth_p = m1$child_p,
    m1_first_stage_coef_iv = m1$first_stage_coef,
    m1_first_stage_f = m1$first_stage_f,
    m1_first_stage_p = m1$first_stage_p,

    m2_depvar = "Risk_Dummy",
    m2_controls = "Yes",
    m2_n = m2$n,
    m2_childhealth_beta = m2$child_beta,
    m2_childhealth_se = m2$child_se,
    m2_childhealth_p = m2$child_p,
    m2_first_stage_coef_iv = m2$first_stage_coef,
    m2_first_stage_f = m2$first_stage_f,
    m2_first_stage_p = m2$first_stage_p,

    m3_depvar = "Risk_Ratio",
    m3_controls = "No",
    m3_n = m3$n,
    m3_childhealth_beta = m3$child_beta,
    m3_childhealth_se = m3$child_se,
    m3_childhealth_p = m3$child_p,
    m3_first_stage_coef_iv = m3$first_stage_coef,
    m3_first_stage_f = m3$first_stage_f,
    m3_first_stage_p = m3$first_stage_p,

    m4_depvar = "Risk_Ratio",
    m4_controls = "Yes",
    m4_n = m4$n,
    m4_childhealth_beta = m4$child_beta,
    m4_childhealth_se = m4$child_se,
    m4_childhealth_p = m4$child_p,
    m4_first_stage_coef_iv = m4$first_stage_coef,
    m4_first_stage_f = m4$first_stage_f,
    m4_first_stage_p = m4$first_stage_p,

    first_stage_f_min = min(fs_vals),
    first_stage_f_max = max(fs_vals),
    negative_beta_count = sum(betas < 0),
    all_four_beta_negative = all(betas < 0),
    all_four_first_stage_f_gt10 = all(fs_vals > 10),
    strict_match_paper_direction_and_strong_fs = all(betas < 0) & all(fs_vals > 10),

    diff_vs_paper_m1 = m1$child_beta - paper_targets["m1"],
    diff_vs_paper_m2 = m2$child_beta - paper_targets["m2"],
    diff_vs_paper_m3 = m3$child_beta - paper_targets["m3"],
    diff_vs_paper_m4 = m4$child_beta - paper_targets["m4"],
    total_abs_diff_vs_paper = abs(m1$child_beta - paper_targets["m1"]) +
      abs(m2$child_beta - paper_targets["m2"]) +
      abs(m3$child_beta - paper_targets["m3"]) +
      abs(m4$child_beta - paper_targets["m4"]),

    stringsAsFactors = FALSE
  )
}

scan <- bind_rows(scan_rows) %>%
  arrange(
    desc(strict_match_paper_direction_and_strong_fs),
    total_abs_diff_vs_paper,
    desc(first_stage_f_min)
  ) %>%
  mutate(rank_overall = row_number())

write.csv(scan, file.path(tables_dir, "table3_iv_candidate_scan.csv"), row.names = FALSE)
write.csv(head(scan, 10), file.path(tables_dir, "table3_iv_candidate_top.csv"), row.names = FALSE)

summary_lines <- c(
  sprintf("Generated at: %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  sprintf("Candidate count scanned: %d", nrow(scan)),
  sprintf("Strict direction+F>10 count: %d", sum(scan$strict_match_paper_direction_and_strong_fs)),
  "Top candidates:",
  paste(capture.output(print(head(scan %>% select(iv_variable, rank_overall, first_stage_f_min, negative_beta_count, total_abs_diff_vs_paper), 5))), collapse = "\n")
)

writeLines(summary_lines, file.path(logs_dir, "iv_candidate_scan.log"))
cat(paste(summary_lines, collapse = "\n"), "\n")
