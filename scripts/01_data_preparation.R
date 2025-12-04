# ==============================================================================
# FILE: scripts/01_data_preparation.R
# DESCRIPTION: Initial data cleaning and missing value analysis.
# OBJECTIVE: Remove forbidden variables (EM_) and assess data quality per station.
# AUTHORS: Group LUNA
# ==============================================================================

# 1. Setup & Library Loading
source(here::here("scripts", "00_packages.R"))

# 2. Load Raw Data
# We use a relative path to ensure reproducibility
raw_data_path <- here("data", "raw", "Agrimonia_stations.RData")

if(file.exists(raw_data_path)) {
  message("Loading raw data...")
  load(raw_data_path)
  
  # Rename the loaded object 'a' to 'agri_raw' for clarity if necessary
  if(exists("a")) {
    agri_raw <- a
    rm(a) # remove the obscure 'a' object to keep environment clean
  }
} else {
  stop("CRITICAL ERROR: Data file not found in 'data/raw/'. Please check the file name.")
}

# ==============================================================================
# 3. Variable Selection (Removing EM_)
# ==============================================================================

# METHODOLOGICAL NOTE:
#'EM_' variables are removed as they are model-based inventory estimates (often annual) rather than empirical observations.
# Using theoretical proxies to predict real pollution levels introduces circularity and potential bias.
# The analysis focuses exclusively on the impact of measured meteorological variables on air quality to ensure data integrity.
df_intermediate <- agri_raw %>% 
  # Remove columns starting with "EM_"
  select(-starts_with("EM_"))

message("Step 3 Complete: 'EM_' variables removed.")

# ... (Previous steps: Load libraries, load data, remove EM_) ...

# ==============================================================================
# 4. INTELLIGENT RANKING SYSTEM (Best Station per Pollutant)
# ==============================================================================

# Calculate missing percentages for each station and pollutant
station_stats <- df_intermediate %>%
  group_by(NameStation) %>%
  summarise(
    PM10_Miss = sum(is.na(AQ_pm10)) / n() * 100,
    PM25_Miss = sum(is.na(AQ_pm25)) / n() * 100,
    NO2_Miss  = sum(is.na(AQ_no2))  / n() * 100,
    CO_Miss   = sum(is.na(AQ_co))   / n() * 100,
    SO2_Miss  = sum(is.na(AQ_so2))  / n() * 100,
    .groups = "drop"
  )

# Function to find the winner for a specific pollutant
find_winner <- function(data, pollutant_col, pollutant_name) {
  winner <- data %>%
    arrange(!!sym(pollutant_col)) %>% # Sort by lowest missing %
    slice(1) %>%                      # Take the top 1
    select(NameStation, Score = !!sym(pollutant_col))
  
  paste0("🏆 Best Station for ", pollutant_name, ": ", 
         winner$NameStation, " (Missing: ", round(winner$Score, 2), "%)")
}

# --- GENERATE THE LEADERBOARD ---
message("\n=======================================================")
message("   🥇 BEST STATION LEADERBOARD (Data Completeness)   ")
message("=======================================================")

print(find_winner(station_stats, "PM10_Miss", "PM10"))
print(find_winner(station_stats, "PM25_Miss", "PM2.5"))
print(find_winner(station_stats, "NO2_Miss",  "NO2 (Traffic)"))
print(find_winner(station_stats, "CO_Miss",   "CO"))
print(find_winner(station_stats, "SO2_Miss",  "SO2"))

message("=======================================================\n")

# --- DETAILED TOP 5 VIEW (Optional, for manual check) ---
# If you want to see the runners-up for PM2.5 specifically:
# print(station_stats %>% select(NameStation, PM25_Miss) %>% arrange(PM25_Miss) %>% head(5))
# ==============================================================================
# 5. Save Intermediate Data
# ==============================================================================

# We save this intermediate file. In the next steps (Rmd), we can decide 
# if we want to filter for one specific station or keep them all.

output_file <- here("data", "processed", "agrimonia_no_EM.rds")
saveRDS(df_intermediate, file = output_file)

message(paste("Intermediate cleaned dataset saved to:", output_file))

