# ==============================================================================
# FILE: scripts/03_meteo_analysis.R
# DESCRIPTION: Execution script for Part 1 (Meteo Analysis).
# PURPOSE: Generates plots/models and saves them to specific folders.
# ==============================================================================

# 1. Setup
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse, here, patchwork)

# Load Functions
source(here("scripts", "02_functions.R"))

# --- DIRECTORY SETUP (Enforcing the requested structure) ---
dirs <- c(
  here("output"), 
  here("output", "graph"),   # For Plots
  here("output", "tables"),  # For RDS/HTML Tables
  here("output", "models")   # For Model Objects
)

# Create directories if they don't exist
walk(dirs, ~if(!dir.exists(.x)) dir.create(.x))

message("--- STARTING PART 1: METEO ANALYSIS ---")

# 2. Load Data
df <- readRDS(here("data", "processed", "final_saronno_pm10.rds"))

# ==============================================================================
# 3. GENERATE & SAVE PLOTS (Folder: output/graph)
# ==============================================================================

# A. Wind Analysis Boxplot
message("Generating Wind Plot...")
p_wind <- plot_wind_analysis(df)
ggsave(here("output", "graph", "01_wind_boxplot.png"), plot = p_wind, width = 9, height = 6)

# B. Histograms (Transformation check)
message("Generating Histograms...")
p_hist <- plot_pm10_histograms(df)
ggsave(here("output", "graph", "02_histograms.png"), plot = p_hist, width = 10, height = 5)

# C. Seasonality Boxplot
message("Generating Seasonality Plot...")
p_seas <- plot_seasonality(df)
ggsave(here("output", "graph", "03_seasonality.png"), plot = p_seas, width = 7, height = 5)

# D. Correlation Matrix
# Special handling for base R plots
message("Generating Correlogram...")
png(filename = here("output", "graph", "04_correlogram.png"), width = 800, height = 800, res = 100)
# We remove StringencyIndex here to focus only on Meteo
df %>% select(-StringencyIndex) %>% plot_correlations() 
dev.off() 

# ==============================================================================
# 4. TABLES AND STATISTICS (Folder: output/tables)
# ==============================================================================

# E. Generate Wind Summary Table (Dataframe)
message("Generating Wind Statistics Table...")

wind_stats <- df %>%
  group_by(WindDir) %>%
  summarise(
    Days = n(),
    Median_Log = median(Log_Y, na.rm = TRUE),
    Median_PM10 = exp(median(Log_Y, na.rm = TRUE)) - 1
  ) %>%
  arrange(desc(Median_Log))

# Save the table data
saveRDS(wind_stats, here("output", "tables", "wind_stats_table.rds"))

# ==============================================================================
# 5. REGRESSION MODEL (Folder: output/models and output/tables)
# ==============================================================================

message("Fitting Meteorological Linear Model...")

# 1. Model Fitting
# We use: Log_Y ~ Meteo Variables + Wind Direction + Seasonality
# This establishes the "Natural Baseline"
model_meteo <- lm(Log_Y ~ Temp + WindSpeed + Precipitation + Humidity + WindDir + Season, data = df)

# 2. Generate Formatted HTML Table
message("Generating formatted HTML table...")
table_meteo_object <- print_model_table(
  model_meteo, 
  caption_text = "Meteorological Model Results (Quantitative + Factors)"
)

# 3. Save Objects
# Save Model Object (output/models)
saveRDS(model_meteo, here("output", "models", "m1_meteo.rds"))

# Save Formatted Table (output/tables)
saveRDS(table_meteo_object, here("output", "tables", "tab_model_meteo.rds"))

message("--- ANALYSIS COMPLETE ---")
message("Plots saved in: /output/graph/")
message("Tables saved in: /output/tables/")