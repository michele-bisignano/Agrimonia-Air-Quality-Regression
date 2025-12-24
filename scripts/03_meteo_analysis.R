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
ggsave(here("img", "01_wind_boxplot.png"), plot = p_wind, width = 8, height = 5)

# B. Histograms (Transformation check)
message("Generating Histograms...")
p_hist <- plot_pm10_histograms(df)
ggsave(here("img", "02_histograms.png"), plot = p_hist, width = 10, height = 5)

# C. Seasonality Boxplot
message("Generating Seasonality Plot...")
p_seas <- plot_seasonality(df)
ggsave(here("img", "03_seasonality.png"), plot = p_seas, width = 6, height = 4)

# D. Correlation Plot
# Note: corrplot is tricky to save via ggsave because it's a base plot, not ggplot.
# We use png() device.
message("Generating Correlation Matrix...")
png(filename = here("img", "04_correlogram.png"), width = 800, height = 800, res = 100)
df %>% 
  select(-StringencyIndex) %>% 
  plot_correlations()

dev.off()

# ==============================================================================
# 4. RUN REGRESSION MODEL (Part 1 - Meteo Only)
# ==============================================================================

message("Running Linear Model (Meteo)...")

# Model 1: Log_Y vs Weather + Season (No Covid yet)
model_meteo <- lm(Log_Y ~ Temp + WindSpeed + Precipitation + Humidity + WindDir + Season, data = df)

# Save the model object (so we can load it in Rmd to print tables)
saveRDS(model_meteo, here("output", "models", "m1_meteo.rds"))

message("--- ANALYSIS COMPLETE. OUTPUTS SAVED. ---")
message("Plots saved in: /img/")
message("Model saved in: /output/models/m1_meteo.rds")
