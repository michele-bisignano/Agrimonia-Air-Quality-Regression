# ==============================================================================
# FILE: scripts/00_packages.R
# DESCRIPTION: Setup file to manage project dependencies.
# PURPOSE: Installs (if missing) and loads all required libraries for the project.
# AUTHORS: Group LUNA
# ==============================================================================

# 1. Install 'pacman' package manager if not already installed
if (!require("pacman")) {
  install.packages("pacman")
}

# 2. Load libraries using pacman::p_load
# This function checks if a package is installed:
# - If NO: it installs it and then loads it.
# - If YES: it just loads it.
pacman::p_load(
  tidyverse,    # Metapackage for data science (dplyr, ggplot2, readr, etc.)
  here,         # For relative file paths (essential for reproducibility)
  lubridate,    # For easy date and time manipulation
  corrplot,     # For visualizing correlation matrices
  knitr,        # For dynamic report generation
  kableExtra,   # For creating complex and beautiful tables
  car,          # For Regression Diagnostics (e.g., VIF)
  lmtest,       # For diagnostic tests (e.g., Breusch-Pagan, Durbin-Watson)
  performance,  # For model performance metrics and comparison
  patchwork     # For combining multiple plots easily
)

# 3. Set Global Options (Optional)
# Prevent scientific notation for readability (e.g., 0.001 instead of 1e-3)
options(scipen = 999)

# 4. Success Message
message("---------------------------------------------------------")
message(" [OK] All required packages have been loaded successfully.")
message("      Project environment is ready.")
message("---------------------------------------------------------")