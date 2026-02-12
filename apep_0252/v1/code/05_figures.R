## 05_figures.R — Generate all figures
## APEP-0241: State Prohibition and the German-American Brewing Elite

source("00_packages.R")
if (!requireNamespace("ggrepel", quietly = TRUE)) install.packages("ggrepel", repos = "https://cloud.r-project.org")
library(ggrepel)

data_dir <- file.path("..", "data")
fig_dir <- file.path("..", "figures")
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

panel <- readRDS(file.path(data_dir, "state_panel.rds"))
panel_full <- readRDS(file.path(data_dir, "state_panel_full.rds"))

# ====================================================================
# FIGURE 1: PROHIBITION ADOPTION TIMELINE
# ====================================================================

adoption <- panel[, .(prohibition_year = first(prohibition_year)), by = state_abbr]
adoption <- adoption[prohibition_year < 1920]  # Exclude never-treated

fig1 <- ggplot(adoption, aes(x = prohibition_year)) +
  geom_histogram(binwidth = 2, fill = "#c0392b", alpha = 0.8, color = "white") +
  geom_vline(xintercept = 1917, linetype = "dashed", color = "gray40") +
  annotate("text", x = 1917, y = Inf, label = "US enters WWI",
           hjust = -0.1, vjust = 1.5, size = 3) +
  labs(x = "Year of State Prohibition Adoption",
       y = "Number of States",
       title = "Staggered Adoption of State Prohibition Laws") +
  scale_x_continuous(breaks = seq(1880, 1920, 5)) +
  theme(plot.title = element_text(size = 10))

ggsave(file.path(fig_dir, "fig1_adoption_timeline.pdf"), fig1,
       width = 7, height = 4.5)
cat("Figure 1 saved.\n")

# ====================================================================
# FIGURE 2: GERMAN-BORN POPULATION TRENDS BY TREATMENT STATUS
# ====================================================================

# Classify states by treatment timing
# Early: prohibition before 1910; Late: 1910-1919; Never: 1920
panel[, treat_group := fifelse(prohibition_year < 1910, "Early prohibition (<1910)",
                        fifelse(prohibition_year < 1920, "Late prohibition (1910-19)",
                               "Never dry"))]

trends <- panel[, .(
  mean_german_share = mean(german_share, na.rm = TRUE),
  mean_fb_share = mean(fb_share, na.rm = TRUE),
  n = .N
), by = .(year, treat_group)]

fig2 <- ggplot(trends, aes(x = year, y = mean_german_share * 100,
                            color = treat_group, shape = treat_group)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2.5) +
  labs(x = "Census Year",
       y = "German-Born Share (%)",
       color = NULL, shape = NULL,
       title = "German-Born Population Share by Prohibition Status") +
  scale_x_continuous(breaks = seq(1870, 1920, 10)) +
  scale_color_manual(values = c("Early prohibition (<1910)" = "#c0392b",
                                "Late prohibition (1910-19)" = "#e67e22",
                                "Never dry" = "#2c3e50")) +
  theme(legend.position = "bottom",
        plot.title = element_text(size = 10))

ggsave(file.path(fig_dir, "fig2_german_trends.pdf"), fig2,
       width = 7, height = 5)
cat("Figure 2 saved.\n")

# ====================================================================
# FIGURE 3: FOREIGN-BORN SHARE TRENDS
# ====================================================================

fig3 <- ggplot(trends, aes(x = year, y = mean_fb_share * 100,
                            color = treat_group, shape = treat_group)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2.5) +
  labs(x = "Census Year",
       y = "Foreign-Born Share (%)",
       color = NULL, shape = NULL,
       title = "Foreign-Born Population Share by Prohibition Status") +
  scale_x_continuous(breaks = seq(1870, 1920, 10)) +
  scale_color_manual(values = c("Early prohibition (<1910)" = "#c0392b",
                                "Late prohibition (1910-19)" = "#e67e22",
                                "Never dry" = "#2c3e50")) +
  theme(legend.position = "bottom",
        plot.title = element_text(size = 10))

ggsave(file.path(fig_dir, "fig3_fb_trends.pdf"), fig3,
       width = 7, height = 5)
cat("Figure 3 saved.\n")

# ====================================================================
# FIGURE 4: EVENT STUDY — CS-DiD
# ====================================================================

es_file <- file.path(data_dir, "es_german.rds")
if (file.exists(es_file)) {
  es_german <- readRDS(es_file)

  es_df <- data.frame(
    event_time = es_german$egt,
    att = es_german$att.egt,
    se = es_german$se.egt
  )
  es_df$ci_lo <- es_df$att - 1.96 * es_df$se
  es_df$ci_hi <- es_df$att + 1.96 * es_df$se

  fig4 <- ggplot(es_df, aes(x = event_time, y = att)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    geom_vline(xintercept = -5, linetype = "dotted", color = "gray70") +
    geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.2, fill = "#c0392b") +
    geom_line(color = "#c0392b", linewidth = 0.8) +
    geom_point(color = "#c0392b", size = 2.5) +
    labs(x = "Years Relative to Prohibition Adoption",
         y = "ATT (German-Born Share)",
         title = "Event Study — Callaway & Sant'Anna (2021)") +
    theme(plot.title = element_text(size = 10))

  ggsave(file.path(fig_dir, "fig4_cs_event_study.pdf"), fig4,
         width = 7, height = 5)
  cat("Figure 4 saved.\n")
} else {
  cat("Figure 4 skipped (CS-DiD results not available).\n")
}

# ====================================================================
# FIGURE 4B: SUN & ABRAHAM EVENT STUDY
# ====================================================================

# Re-estimate Sun-Abraham model to extract event-time coefficients
panel_sa_fig <- readRDS(file.path(data_dir, "state_panel.rds"))
census_years_fig <- c(1870, 1880, 1890, 1900, 1910, 1920)
panel_sa_fig[, cohort_sa := {
  py <- prohibition_year[1]
  cy <- census_years_fig[census_years_fig >= py]
  if (length(cy) > 0 && py < 1920) min(cy) else 10000
}, by = state_abbr]

sa_es <- tryCatch({
  feols(german_share ~ sunab(cohort_sa, year) | state_id + year,
        data = panel_sa_fig, cluster = ~state_id)
}, error = function(e) {
  cat("Sun-Abraham event study error:", e$message, "\n")
  NULL
})

if (!is.null(sa_es)) {
  ct_sa <- coeftable(sa_es)
  sa_df <- data.frame(
    event_time = as.numeric(gsub("year::", "", rownames(ct_sa))),
    estimate = ct_sa[, "Estimate"],
    se = ct_sa[, "Std. Error"]
  )
  sa_df$ci_lo <- sa_df$estimate - 1.96 * sa_df$se
  sa_df$ci_hi <- sa_df$estimate + 1.96 * sa_df$se

  fig4b <- ggplot(sa_df, aes(x = event_time, y = estimate)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.15, fill = "#c0392b") +
    geom_line(color = "#c0392b", linewidth = 0.8) +
    geom_point(color = "#c0392b", size = 2.5) +
    labs(x = "Census Year",
         y = "Coefficient (German-Born Share)",
         title = "Sun & Abraham (2021) Event Study — German-Born Share") +
    theme_bw(base_size = 11) +
    theme(
      panel.grid.minor = element_blank(),
      plot.title = element_text(face = "bold", size = 12)
    )

  ggsave(file.path(fig_dir, "fig4b_sa_event_study.pdf"), fig4b,
         width = 7, height = 5)
  cat("Figure 4b (Sun-Abraham event study) saved.\n")
}
rm(panel_sa_fig, census_years_fig)

# ====================================================================
# FIGURE 5: BREWING INTENSITY AND GERMAN DECLINE
# ====================================================================

# Cross-section: 1870 brewery intensity vs change in German share 1890-1920
change <- panel[year %in% c(1890, 1920),
                .(german_share = german_share[1],
                  german_share_1920 = german_share[2],
                  brew_intensity = brew_intensity[1],
                  prohibition_year = prohibition_year[1]),
                by = state_abbr]
change <- change[!is.na(german_share) & !is.na(german_share_1920)]
change[, german_change := german_share_1920 - german_share]
change[, early_prohib := prohibition_year < 1910]

fig5 <- ggplot(change, aes(x = brew_intensity, y = german_change * 100)) +
  geom_smooth(aes(color = early_prohib, linetype = early_prohib),
              method = "lm", se = TRUE, linewidth = 0.8, alpha = 0.15) +
  geom_point(aes(color = early_prohib), size = 2.5, alpha = 0.7) +
  ggrepel::geom_text_repel(aes(label = state_abbr), size = 2,
                            max.overlaps = 15, seed = 42) +
  labs(x = "Brewery Intensity (per 100,000 pop., 1870)",
       y = "Change in German-Born Share (pp, 1890-1920)",
       color = "Early prohibition\n(<1910)",
       linetype = "Early prohibition\n(<1910)",
       title = "Brewing Intensity and German Population Decline") +
  scale_color_manual(values = c("TRUE" = "#c0392b", "FALSE" = "#2c3e50")) +
  scale_linetype_manual(values = c("TRUE" = "solid", "FALSE" = "dashed")) +
  theme(plot.title = element_text(size = 10))

ggsave(file.path(fig_dir, "fig5_brew_intensity.pdf"), fig5,
       width = 7, height = 5)
cat("Figure 5 saved.\n")

# ====================================================================
# FIGURE 6: RANDOMIZATION INFERENCE
# ====================================================================

ri_file <- file.path(data_dir, "ri_results.rds")
if (file.exists(ri_file)) {
  ri <- readRDS(ri_file)
  true_coef <- coef(readRDS(file.path(data_dir, "models.rds"))$twfe_german_share)["treated"]

  fig6 <- ggplot(ri, aes(x = coef)) +
    geom_histogram(bins = 40, fill = "gray70", color = "white") +
    geom_vline(xintercept = true_coef, color = "#c0392b", linewidth = 1.2) +
    annotate("text", x = true_coef, y = Inf,
             label = paste0("True estimate\n(p = ",
                            round(mean(abs(ri$coef) >= abs(true_coef)), 3), ")"),
             hjust = -0.1, vjust = 1.5, size = 3, color = "#c0392b") +
    labs(x = "Placebo Coefficient",
         y = "Frequency",
         title = "Randomization Inference (500 Permutations)") +
    theme(plot.title = element_text(size = 10))

  ggsave(file.path(fig_dir, "fig6_ri_distribution.pdf"), fig6,
         width = 7, height = 4.5)
  cat("Figure 6 saved.\n")
} else {
  cat("Figure 6 skipped (RI results not available).\n")
}

# ====================================================================
# FIGURE 7: GOODMAN-BACON DECOMPOSITION
# ====================================================================

bacon_file <- file.path(data_dir, "bacon_decomp.rds")
if (file.exists(bacon_file)) {
  bacon_out <- readRDS(bacon_file)

  fig7_bacon <- ggplot(bacon_out, aes(x = weight, y = estimate,
                                       color = type, shape = type)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    geom_point(size = 3, alpha = 0.8) +
    labs(x = "Weight",
         y = "2×2 DD Estimate",
         color = "Comparison Type", shape = "Comparison Type",
         title = "Goodman-Bacon Decomposition of TWFE Estimate") +
    scale_color_brewer(palette = "Set1") +
    theme(plot.title = element_text(size = 10),
          legend.position = "bottom") +
    guides(color = guide_legend(nrow = 2))

  ggsave(file.path(fig_dir, "fig7_bacon_decomp.pdf"), fig7_bacon,
         width = 7, height = 5)
  cat("Figure 7 (Bacon decomposition) saved.\n")
} else {
  cat("Figure 7 skipped (Bacon decomposition not available).\n")
}

# ====================================================================
# FIGURE 8: MAP OF BREWING INTENSITY
# ====================================================================

if (requireNamespace("usmap", quietly = TRUE)) {
  library(usmap)

  map_data <- panel[year == 1890, .(state_abbr, german_share, brew_intensity,
                                     prohibition_year)]
  map_data[, fips := fips(state_abbr)]

  fig8_map <- plot_usmap(data = map_data, values = "brew_intensity",
                     regions = "states") +
    scale_fill_gradient(low = "white", high = "#c0392b",
                        name = "Breweries per\n100k pop. (1870)",
                        na.value = "gray90") +
    labs(title = "Brewing Intensity by State, 1870") +
    theme(plot.title = element_text(size = 10))

  ggsave(file.path(fig_dir, "fig8_map_brewing.pdf"), fig8_map,
         width = 8, height = 5)
  cat("Figure 8 (map) saved.\n")
} else {
  cat("Figure 8 skipped (usmap package not installed).\n")
}

# ====================================================================
# FIGURE 9: TWFE EVENT STUDY
# ====================================================================

es_twfe_file <- file.path(data_dir, "es_twfe.rds")
if (file.exists(es_twfe_file)) {
  es_twfe <- readRDS(es_twfe_file)

  # Extract coefficients manually for professional ggplot2 rendering
  ct <- coeftable(es_twfe)
  es_twfe_df <- data.frame(
    event_time = as.numeric(gsub("event_bin::", "", rownames(ct))),
    estimate = ct[, "Estimate"],
    se = ct[, "Std. Error"]
  )
  es_twfe_df$ci_lo <- es_twfe_df$estimate - 1.96 * es_twfe_df$se
  es_twfe_df$ci_hi <- es_twfe_df$estimate + 1.96 * es_twfe_df$se
  # Add the omitted reference period (event_time = -1) at zero
  ref_row <- data.frame(event_time = -1, estimate = 0, se = 0, ci_lo = 0, ci_hi = 0)
  es_twfe_df <- rbind(es_twfe_df, ref_row)
  es_twfe_df <- es_twfe_df[order(es_twfe_df$event_time), ]

  fig9_twfe_event_study <- ggplot(es_twfe_df, aes(x = event_time, y = estimate)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray50", linewidth = 0.6) +
    geom_vline(xintercept = -0.5, linetype = "dotted", color = "gray70") +
    geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.15, fill = "#2c3e50") +
    geom_line(color = "#2c3e50", linewidth = 0.9) +
    geom_point(color = "#2c3e50", size = 2.5) +
    labs(x = "Years Relative to Prohibition",
         y = "Coefficient (German-Born Share)",
         title = "TWFE Event Study — German-Born Share") +
    theme_bw(base_size = 11) +
    theme(
      panel.grid.minor = element_blank(),
      plot.title = element_text(face = "bold", size = 12)
    )

  ggsave(file.path(fig_dir, "fig9_twfe_event_study.pdf"), fig9_twfe_event_study,
         width = 7, height = 5)
  cat("Figure 9 saved.\n")
} else {
  cat("Figure 9 skipped (TWFE event study not available).\n")
}

cat("\nAll figures complete.\n")
