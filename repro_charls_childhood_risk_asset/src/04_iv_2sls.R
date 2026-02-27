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

star_label <- function(p) {
  ifelse(
    p < 0.01,
    "***",
    ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", ""))
  )
}

prepare_data <- function(data, y_var, control_vars, iv_var) {
  use_vars <- c(y_var, "childhealth", control_vars, iv_var)
  data %>%
    select(all_of(use_vars)) %>%
    mutate(across(everything(), as.numeric)) %>%
    filter(complete.cases(.))
}

run_2sls <- function(data, y_var, control_vars, iv_var) {
  dat <- prepare_data(data, y_var, control_vars, iv_var)
  n <- nrow(dat)

  if (n == 0) {
    return(list(status = "unavailable", n = 0))
  }

  x_formula <- if (length(control_vars) == 0) {
    "~ childhealth"
  } else {
    paste0("~ childhealth + ", paste(control_vars, collapse = " + "))
  }

  z_formula <- if (length(control_vars) == 0) {
    paste0("~ ", iv_var)
  } else {
    paste0("~ ", iv_var, " + ", paste(control_vars, collapse = " + "))
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

  # First-stage test for excluded instrument
  full_formula <- if (length(control_vars) == 0) {
    as.formula(paste0("childhealth ~ ", iv_var))
  } else {
    as.formula(paste0("childhealth ~ ", iv_var, " + ", paste(control_vars, collapse = " + ")))
  }

  rest_formula <- if (length(control_vars) == 0) {
    as.formula("childhealth ~ 1")
  } else {
    as.formula(paste0("childhealth ~ ", paste(control_vars, collapse = " + ")))
  }

  fs_full <- lm(full_formula, data = dat)
  fs_rest <- lm(rest_formula, data = dat)
  fs_anova <- anova(fs_rest, fs_full)

  fs_f <- as.numeric(fs_anova$F[2])
  fs_p <- as.numeric(fs_anova$`Pr(>F)`[2])
  fs_coef <- coef(fs_full)[iv_var]

  list(
    status = "ok",
    n = n,
    beta = beta_vec,
    se = se_vec,
    stat = stat_vec,
    p = p_vec,
    first_stage_f = fs_f,
    first_stage_p = fs_p,
    first_stage_coef = fs_coef,
    first_stage_n = nobs(fs_full)
  )
}

analysis_dataset <- readRDS(file.path(output_dir, "analysis_dataset.rds"))

model_specs <- list(
  list(model_id = "(1)", y = "Risk_Dummy", controls = character(0), dv = "Risk_Dummy", model_type = "2SLS"),
  list(model_id = "(2)", y = "Risk_Dummy", controls = c("age", "gender", "hukou", "marriage"), dv = "Risk_Dummy", model_type = "2SLS"),
  list(model_id = "(3)", y = "Risk_Ratio", controls = character(0), dv = "Risk_Ratio", model_type = "2SLS"),
  list(model_id = "(4)", y = "Risk_Ratio", controls = c("age", "gender", "hukou", "marriage"), dv = "Risk_Ratio", model_type = "2SLS")
)

run_set <- function(iv_var, iv_label) {
  rows <- list()
  fs_rows <- list()
  status_rows <- list()

  for (i in seq_along(model_specs)) {
    spec <- model_specs[[i]]
    fit <- run_2sls(analysis_dataset, spec$y, spec$controls, iv_var)

    if (fit$status != "ok") {
      status_rows[[length(status_rows) + 1]] <- data.frame(
        model_id = spec$model_id,
        dependent_variable = spec$dv,
        iv_variable = iv_var,
        iv_label = iv_label,
        status = "unavailable",
        n = fit$n,
        reason = "No complete cases for official IV",
        stringsAsFactors = FALSE
      )
      next
    }

    child_beta <- fit$beta["childhealth"]
    child_se <- fit$se["childhealth"]
    child_stat <- fit$stat["childhealth"]
    child_p <- fit$p["childhealth"]

    rows[[length(rows) + 1]] <- data.frame(
      model_id = spec$model_id,
      dependent_variable = spec$dv,
      model_type = spec$model_type,
      controls = ifelse(length(spec$controls) == 0, "No", "Yes"),
      iv_variable = iv_var,
      iv_label = iv_label,
      n = fit$n,
      estimate = child_beta,
      robust_se = child_se,
      statistic = child_stat,
      p_value = child_p,
      stars = star_label(child_p),
      first_stage_f = fit$first_stage_f,
      first_stage_p = fit$first_stage_p,
      first_stage_coef_iv = fit$first_stage_coef,
      stringsAsFactors = FALSE
    )

    fs_rows[[length(fs_rows) + 1]] <- data.frame(
      model_id = spec$model_id,
      dependent_variable = spec$dv,
      iv_variable = iv_var,
      iv_label = iv_label,
      first_stage_n = fit$first_stage_n,
      first_stage_coef_iv = fit$first_stage_coef,
      first_stage_f = fit$first_stage_f,
      first_stage_p = fit$first_stage_p,
      stringsAsFactors = FALSE
    )

    status_rows[[length(status_rows) + 1]] <- data.frame(
      model_id = spec$model_id,
      dependent_variable = spec$dv,
      iv_variable = iv_var,
      iv_label = iv_label,
      status = "ok",
      n = fit$n,
      reason = "",
      stringsAsFactors = FALSE
    )
  }

  list(
    results = if (length(rows) > 0) bind_rows(rows) else data.frame(),
    first_stage = if (length(fs_rows) > 0) bind_rows(fs_rows) else data.frame(),
    status = bind_rows(status_rows)
  )
}

official <- run_set("hospital", "paper_official_iv")
proxy <- run_set("hospital_proxy", "proxy_iv_childhood_hospitalization")

results_all <- bind_rows(official$results, proxy$results)
first_stage_all <- bind_rows(official$first_stage, proxy$first_stage)
status_all <- bind_rows(official$status, proxy$status)

if (nrow(proxy$results) > 0) {
  proxy_out <- proxy$results %>%
    mutate(
      estimate_fmt = sprintf("%.4f%s", estimate, stars),
      robust_se_fmt = sprintf("(%.4f)", robust_se),
      stat_fmt = sprintf("%.3f", statistic),
      p_fmt = sprintf("%.4f", p_value),
      first_stage_f_fmt = sprintf("%.2f", first_stage_f),
      first_stage_p_fmt = sprintf("%.4f", first_stage_p)
    )

  write.csv(proxy_out, file.path(tables_dir, "table3_reproduced.csv"), row.names = FALSE)
}

write.csv(results_all, file.path(tables_dir, "table3_reproduced_all.csv"), row.names = FALSE)
write.csv(first_stage_all, file.path(tables_dir, "table3_first_stage.csv"), row.names = FALSE)
write.csv(status_all, file.path(tables_dir, "table3_iv_availability.csv"), row.names = FALSE)

# Compare stage 4 baseline vs stage 5 (proxy IV)
if (file.exists(file.path(tables_dir, "table2_reproduced.csv")) && nrow(proxy$results) > 0) {
  table2 <- read.csv(file.path(tables_dir, "table2_reproduced.csv"), stringsAsFactors = FALSE) %>%
    select(model_id, dependent_variable, baseline_estimate = estimate, baseline_p = p_value)

  compare_24_35 <- table2 %>%
    inner_join(proxy$results %>% select(model_id, dependent_variable, iv_estimate = estimate, iv_p = p_value),
               by = c("model_id", "dependent_variable")) %>%
    mutate(
      delta_iv_minus_baseline = iv_estimate - baseline_estimate
    )

  write.csv(compare_24_35, file.path(tables_dir, "table2_table3_compare.csv"), row.names = FALSE)
}

summary_lines <- c(
  sprintf("Generated at: %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  sprintf("Official IV available models: %d/%d", sum(status_all$iv_variable == "hospital" & status_all$status == "ok"), sum(status_all$iv_variable == "hospital")),
  sprintf("Proxy IV available models: %d/%d", sum(status_all$iv_variable == "hospital_proxy" & status_all$status == "ok"), sum(status_all$iv_variable == "hospital_proxy"))
)

if (nrow(proxy$results) > 0) {
  proxy_lines <- apply(proxy$results, 1, function(x) {
    sprintf(
      "%s %s: beta=%.4f%s, se=%.4f, stat=%.3f, p=%.4f, first_stage_F=%.2f",
      x[["model_id"]], x[["dependent_variable"]],
      as.numeric(x[["estimate"]]), star_label(as.numeric(x[["p_value"]])),
      as.numeric(x[["robust_se"]]), as.numeric(x[["statistic"]]), as.numeric(x[["p_value"]]),
      as.numeric(x[["first_stage_f"]])
    )
  })
  summary_lines <- c(summary_lines, "Proxy IV model summary:", proxy_lines)
}

writeLines(summary_lines, file.path(logs_dir, "iv_2sls_summary.log"))
cat(paste(summary_lines, collapse = "\n"), "\n")
