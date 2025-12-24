# ==============================================================================
# FILE: scripts/02_functions.R
# DESCRIPTION: Custom functions for plotting and model reporting.
# PURPOSE: Keep the RMarkdown file clean by abstracting complex code.
# AUTHORS: Group LUNA
# ==============================================================================

# Ensure required libraries are loaded
if (!require("pacman")) install.packages("pacman")
pacman::p_load(ggplot2, dplyr, kableExtra, broom, car)

#' Plot Correlation Matrix
#' 
#' Creates a readable correlation plot for numeric variables.
#' @param data The full dataframe
#' @return A corrplot
plot_correlations <- function(data) {
  # Select only numeric columns relevant for the model
  # We exclude date and ID columns automatically
  numeric_vars <- data %>% 
    select(where(is.numeric)) %>% 
    select(-any_of(c("IDStations", "Altitude", "Longitude", "Latitude")))
  
  M <- cor(numeric_vars, use = "complete.obs")
  
  corrplot::corrplot(M, 
                     method = "color", 
                     type = "upper", 
                     order = "hclust", 
                     addCoef.col = "black", # Add coefficient of correlation
                     tl.col = "black", 
                     tl.srt = 45, # Text label rotation
                     diag = FALSE,
                     number.cex = 0.7 # Font size
  )
}

#' Show Key Data Points
#'
#' Creates a summary table showing the start of the series, 
#' the critical Covid period (March 2020), and a recent sample (2021).
#'
#' @param data The clean dataframe
#' @return A styled kable object
show_key_dates <- function(data) {
  
  # Set seed for reproducibility of the random sample
  set.seed(123)
  
  # 1. Start of the series (First 2 rows)
  start_rows <- head(data, 2)
  
  # 2. Lockdown Peak (March 2020) - Taking the first entry found
  covid_row <- data %>% 
    filter(year(Date) == 2020, month(Date) == 3) %>% 
    head(1)
  
  # 3. Post-Covid sample (2021) - Random entry
  recent_row <- data %>% 
    filter(year(Date) == 2021) %>% 
    sample_n(1)
  
  # Combine and print
  bind_rows(start_rows, covid_row, recent_row) %>% 
    kable(caption = "Dataset Preview: Pre-Covid, Lockdown (March 2020), and Post-Covid") %>% 
    kable_styling(bootstrap_options = c("striped", "hover"), full_width = F)
}