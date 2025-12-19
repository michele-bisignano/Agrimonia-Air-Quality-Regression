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
# 'EM_' variables are removed as they are model-based inventory estimates (often annual) 
# rather than empirical observations. Using theoretical proxies to predict real pollution 
# levels introduces circularity and potential bias.
# The analysis focuses exclusively on the impact of measured meteorological variables 
# on air quality to ensure data integrity.

df_intermediate <- agri_raw %>% 
  # Remove columns starting with "EM_"
  select(-starts_with("EM_"))

message("Step 3 Complete: 'EM_' variables removed.")

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
    slice(3) %>%                      # Selecting the 3rd place because the first 2 were outside Italy
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

# ==============================================================================
# 5. FINAL SELECTION & CLEANING (Based on team decision)
# ==============================================================================

# Choice based on the previous analysis
selected_station   <- "Saronno Via Santuario" 
selected_pollutant <- "AQ_pm10"            

message(paste("Creating final dataset for station:", selected_station))
message(paste("Target Variable (Y):", selected_pollutant))

df_final <- df_intermediate %>% 
  # 1. Filter only for the selected station
  filter(NameStation == selected_station) %>% 
  
  # 2. Select variables
  # Y: The chosen pollutant (PM10)
  # X: Weather variables (Temperature, Wind, Precipitation, Humidity)
  # Note: We remove everything else to keep the dataset lightweight
  select(
    Date = Time,
    Y = all_of(selected_pollutant),  # Rename AQ_pm10 to 'Y'
    
    # Weather Covariates (X)
    Temp = WE_temp_2m,
    WindSpeed = WE_wind_speed_10m_mean,
    Precipitation = WE_tot_precipitation,
    Humidity = WE_rh_mean,
    
    # Wind Direction (Important factor!)
    WindDir = WE_mode_wind_direction_10m
  ) %>% 
  
  # 3. Handle Missing Values
  # We simply remove them. This is the cleanest and most honest approach 
  # given the low percentage of missing data.
  drop_na() %>% 
  
  # 4. Feature Engineering (Model Preparation)
  mutate(
    Date = as.Date(Date),
    
    # Logarithmic Transformation (Crucial for normalizing residuals)
    # We add +1 to avoid log(0) in case there are days with 0 PM10 (rare but possible)
    Log_Y = log(Y + 1), 
    
    # Create Seasonality
    Month = month(Date),
    Season = case_when(
      Month %in% c(12, 1, 2) ~ "Winter",
      Month %in% c(3, 4, 5)  ~ "Spring",
      Month %in% c(6, 7, 8)  ~ "Summer",
      Month %in% c(9, 10, 11) ~ "Autumn"
    ),
    # Set 'Winter' as the baseline (reference) level for contrasts
    Season = factor(Season, levels = c("Winter", "Spring", "Summer", "Autumn")),
    
    # Handle Wind Direction
    # If WindDir has too many rare levels, we might need to group them,
    # but for now, we simply convert it to a factor.
    WindDir = as.factor(WindDir)
  )

# ==============================================================================
# 5.1. COVID-19 DATA INTEGRATION
# ==============================================================================

# Objective: Incorporate the Oxford Covid-19 Government Response Tracker (OxCGRT)
# to account for lockdown effects on air quality using 'StringencyIndex_Average'.

covid_path <- here("data", "raw", "OxCGRT_compact_national_v1.csv")

if(file.exists(covid_path)) {
  
  message("Loading and processing COVID-19 data...")
  
  # 1. Load and Filter for Italy
  # show_col_types = FALSE prevents clutter in the console
  covid_data <- read_csv(covid_path, show_col_types = FALSE) %>%
    filter(CountryName == "Italy") %>% 
    
    # 2. Select only relevant columns
    # We choose StringencyIndex_Average as it represents closure policies
    select(Date, StringencyIndex = StringencyIndex_Average) %>% 
    
    # 3. Fix Date Format
    # The raw CSV has numeric dates (e.g., 20200101). ymd() converts them properly.
    mutate(Date = ymd(Date))
  
  # 4. Join with Main Dataset
  # We use left_join to ensure we keep all Agrimonia rows (2016-2021)
  df_final <- df_final %>% 
    left_join(covid_data, by = "Date") %>% 
    
    # 5. Handle Missing Values (Pre-2020)
    # Before 2020, Covid did not exist, so the Stringency Index is NA.
    # We impute 0 for those dates (meaning: zero restrictions).
    mutate(StringencyIndex = replace_na(StringencyIndex, 0))
  
  message("COVID-19 Stringency Index successfully added.")
  
  # 6. Quick Correlation Check (Optional)
  # Prints the correlation to verify if restrictions negatively affect pollution as expected
  cor_val <- cor(df_final$Log_Y, df_final$StringencyIndex, use="complete.obs")
  message(paste("Correlation between Log(Pollutant) and Stringency Index:", round(cor_val, 3)))
  
} else {
  warning("COVID data file not found in data/raw/. Skipping this step.")
}

# ==============================================================================
# 6. SAVE FINAL DATASET
# ==============================================================================

# Save the cleaned file ready for RMarkdown analysis
output_path <- here("data", "processed", "final_saronno_pm10.rds")
saveRDS(df_final, file = output_path)

message("---------------------------------------------------------")
message(paste("✅ SUCCESS! Final dataset saved to:", output_path))
message(paste("   Station:", selected_station))
message(paste("   Pollutant:", selected_pollutant))
message(paste("   Total Observations:", nrow(df_final)))
message(paste("   Covid Data Integrated:", exists("covid_data")))
message("---------------------------------------------------------")