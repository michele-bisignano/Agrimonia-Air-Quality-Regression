# ==============================================================================
# FILE: scripts/02_run_part1_analysis.R
# DESCRIPTION: Execution script for Part 1 (Meteo Analysis).
# PURPOSE: Generates plots/models and saves them to 'img/' and 'output/'.
# ==============================================================================

# 1. Setup
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse, here, patchwork)

# Load Functions
source(here("scripts", "02_functions.R"))

# Create Output Directories if they don't exist
if(!dir.exists(here("img"))) dir.create(here("img"))
if(!dir.exists(here("output"))) dir.create(here("output"))
if(!dir.exists(here("output", "models"))) dir.create(here("output", "models"))

message("--- STARTING PART 1 ANALYSIS ---")

# 2. Load Data
df <- readRDS(here("data", "processed", "final_saronno_pm10.rds"))

# ==============================================================================
# 3. GENERATE & SAVE PLOTS
# ==============================================================================

# A. Wind Analysis Boxplot
message("Generating Wind Plot...")
p_wind <- plot_wind_analysis(df)
ggsave(here("output", "01_wind_boxplot.png"), plot = p_wind, width = 8, height = 5)

# B. Histograms (Transformation check)
message("Generating Histograms...")
p_hist <- plot_pm10_histograms(df)
p_hist <- plot_pm10_histograms(df)
ggsave(here("output", "02_histograms.png"), plot = p_hist, width = 10, height = 5)

# C. Seasonality Boxplot
message("Generating Seasonality Plot...")
p_seas <- plot_seasonality(df)
ggsave(here("output", "03_seasonality.png"), plot = p_seas, width = 6, height = 4)

