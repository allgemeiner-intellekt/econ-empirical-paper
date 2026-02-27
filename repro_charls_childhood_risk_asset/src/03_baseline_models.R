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

analysis_dataset <- readRDS(file.path(output_dir, "analysis_dataset.rds"))

star_label <- function(p) {
  ifelse(
    p < 0.01,
    "***",
    ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", ""))
  )
}

extract_robust <- function(model, model_id, dv, model_type, controls) {
  ct <- coeftest(model, vcov. = vcovHC(model, type = "HC1"))
  out <- data.frame(
    model_id = model_id,
    dependent_variable = dv,
    model_type = model_type,
    controls = controls,
    term = rownames(ct),
    estimate = ct[, 1],
    robust_se = ct[, 2],
    statistic = ct[, 3],
    p_value = ct[, 4],
    n = nobs(model),
    stringsAsFactors = FALSE
  )
  out$stars <- star_label(out$p_value)
  out
}

m1 <- glm(
  Risk_Dummy ~ childhealth,
  data = analysis_dataset,
  family = binomial()
)

m2 <- glm(
  Risk_Dummy ~ childhealth + age + gender + hukou + marriage,
  data = analysis_dataset,
  family = binomial()
)

m3 <- lm(
  Risk_Ratio ~ childhealth,
  data = analysis_dataset
)

m4 <- lm(
  Risk_Ratio ~ childhealth + age + gender + hukou + marriage,
  data = analysis_dataset
)

res1 <- extract_robust(m1, "(1)", "Risk_Dummy", "Logit", "No")
res2 <- extract_robust(m2, "(2)", "Risk_Dummy", "Logit", "Yes")
res3 <- extract_robust(m3, "(3)", "Risk_Ratio", "OLS", "No")
res4 <- extract_robust(m4, "(4)", "Risk_Ratio", "OLS", "Yes")

full_table <- bind_rows(res1, res2, res3, res4)

childhealth_table <- full_table %>%
  filter(term == "childhealth") %>%
  mutate(
    estimate_fmt = sprintf("%.4f%s", estimate, stars),
    robust_se_fmt = sprintf("(%.4f)", robust_se),
    stat_fmt = sprintf("%.3f", statistic),
    p_fmt = sprintf("%.4f", p_value)
  ) %>%
  select(
    model_id,
    dependent_variable,
    model_type,
    controls,
    n,
    estimate,
    robust_se,
    statistic,
    p_value,
    estimate_fmt,
    robust_se_fmt,
    stat_fmt,
    p_fmt
  )

paper_compare <- data.frame(
  model_id = c("(1)", "(2)", "(3)", "(4)"),
  paper_childhealth = c(-0.045, -0.032, -0.003, -0.002),
  stringsAsFactors = FALSE
) %>%
  left_join(childhealth_table %>% select(model_id, estimate), by = "model_id") %>%
  mutate(diff_reproduced_minus_paper = estimate - paper_childhealth)

# Diagnostics
null_m1 <- glm(Risk_Dummy ~ 1, data = model.frame(m1), family = binomial())
null_m2 <- glm(Risk_Dummy ~ 1, data = model.frame(m2), family = binomial())

diagnostics <- data.frame(
  model_id = c("(1)", "(2)", "(3)", "(4)"),
  dependent_variable = c("Risk_Dummy", "Risk_Dummy", "Risk_Ratio", "Risk_Ratio"),
  model_type = c("Logit", "Logit", "OLS", "OLS"),
  n = c(nobs(m1), nobs(m2), nobs(m3), nobs(m4)),
  fit_stat = c(
    1 - as.numeric(logLik(m1) / logLik(null_m1)),
    1 - as.numeric(logLik(m2) / logLik(null_m2)),
    summary(m3)$r.squared,
    summary(m4)$r.squared
  ),
  fit_stat_name = c("McFadden_R2", "McFadden_R2", "R2", "R2"),
  stringsAsFactors = FALSE
)

write.csv(full_table, file.path(tables_dir, "table2_reproduced_full.csv"), row.names = FALSE)
write.csv(childhealth_table, file.path(tables_dir, "table2_reproduced.csv"), row.names = FALSE)
write.csv(diagnostics, file.path(tables_dir, "table2_model_diagnostics.csv"), row.names = FALSE)
write.csv(paper_compare, file.path(tables_dir, "table2_paper_compare.csv"), row.names = FALSE)

summary_lines <- c(
  sprintf("Generated at: %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "Model summary for childhealth:",
  paste(
    apply(childhealth_table, 1, function(x) {
      sprintf(
        "%s %s %s: beta=%s, se=%s, stat=%s, p=%s, n=%s",
        x[["model_id"]], x[["dependent_variable"]], x[["model_type"]],
        x[["estimate_fmt"]], x[["robust_se_fmt"]], x[["stat_fmt"]], x[["p_fmt"]], x[["n"]]
      )
    }),
    collapse = "\n"
  )
)

writeLines(summary_lines, con = file.path(logs_dir, "baseline_models_summary.log"))
cat(paste(summary_lines, collapse = "\n"), "\n")
