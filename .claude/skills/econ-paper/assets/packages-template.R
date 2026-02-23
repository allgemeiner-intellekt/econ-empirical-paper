## =============================================================================
## 00_packages.R — Load required packages and set APEP theme
## =============================================================================

cat("Loading packages...\n")

packages <- c(
  # Core data manipulation
  "tidyverse",      # dplyr, ggplot2, tidyr, readr, purrr, stringr
  "data.table",     # Fast data operations for large datasets

  # Causal inference
  "did",            # Callaway-Sant'Anna DiD
  "fixest",         # High-performance fixed effects (TWFE, Sun-Abraham)
  "bacondecomp",    # Goodman-Bacon decomposition

  # Visualization
  "ggplot2",        # Grammar of graphics
  "latex2exp",      # LaTeX expressions in plots
  "scales",         # Scale functions for ggplot2

  # Data access
  "httr",           # HTTP requests for APIs
  "jsonlite",       # JSON parsing

  # Tables and reporting
  "knitr",          # Table formatting
  "kableExtra",     # Extended table formatting
  "broom"           # Tidy model outputs
)

for (pkg in packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
    library(pkg, character.only = TRUE)
  }
}

# =============================================================================
# APEP Standard Theme — Publication-ready figures
# =============================================================================

theme_apep <- function() {
  theme_minimal(base_size = 12) +
    theme(
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color = "grey90", linewidth = 0.3),
      axis.line = element_line(color = "grey30", linewidth = 0.4),
      axis.ticks = element_line(color = "grey30", linewidth = 0.3),
      axis.title = element_text(size = 11, face = "bold"),
      axis.text = element_text(size = 10, color = "grey30"),
      legend.position = "bottom",
      legend.title = element_text(size = 10, face = "bold"),
      legend.text = element_text(size = 9),
      plot.title = element_text(size = 13, face = "bold", hjust = 0),
      plot.subtitle = element_text(size = 10, color = "grey40", hjust = 0),
      plot.caption = element_text(size = 8, color = "grey50", hjust = 1),
      plot.margin = margin(10, 15, 10, 10)
    )
}

# Colorblind-safe palette (Wong 2011)
apep_colors <- c(
  "#0072B2",  # Blue
  "#D55E00",  # Vermillion
  "#009E73",  # Bluish green
  "#CC79A7",  # Reddish purple
  "#F0E442",  # Yellow
  "#56B4E9"   # Sky blue
)

cat("Packages loaded successfully.\n")
