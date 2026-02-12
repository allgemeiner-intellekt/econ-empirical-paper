## 00_packages.R — Load required packages and set global options
## APEP-0241: State Prohibition and the German-American Brewing Elite

# Core data manipulation
library(data.table)
library(tidyverse)

# Econometrics
library(fixest)     # Fast fixed effects
library(did)        # Callaway & Sant'Anna (2021)

# Tables and figures
library(modelsummary)
library(kableExtra)
library(ggplot2)
library(patchwork)
library(scales)

# Set ggplot theme
theme_set(
  theme_minimal(base_size = 11) +
    theme(
      panel.grid.minor = element_blank(),
      plot.title = element_text(face = "bold", size = 12),
      legend.position = "bottom"
    )
)

# Color palette
pal_main <- c("German-born" = "#c0392b", "Other" = "#2c3e50")
pal_treat <- c("Prohibition" = "#e74c3c", "Wet" = "#3498db")

cat("Packages loaded successfully.\n")
