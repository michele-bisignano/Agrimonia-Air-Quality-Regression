# ==============================================================================
# FILE: scripts/02_functions.R
# DESCRIPTION: Custom functions for plotting and model reporting.
# PURPOSE: Keep the RMarkdown file clean by abstracting complex code.
# AUTHORS: Group LUNA
# ==============================================================================

# Ensure required libraries are loaded
if (!require("pacman")) install.packages("pacman")
pacman::p_load(ggplot2, dplyr, kableExtra, broom, car)

# ==============================================================================
# 1. VISUALIZATION FUNCTIONS
# ==============================================================================

#' Plot Time Series: Pollution vs Covid Restrictions
#'
#' This function creates a dual-axis plot to compare the log-transformed
#' pollutant levels with the Covid-19 Stringency Index.
#'
#' @param data The dataframe containing 'Date', 'Log_Y', and 'StringencyIndex'
#' @param title_text Custom title for the plot
#' @return A ggplot object
plot_covid_trend <- function(data, title_text = "Pollution vs Covid-19 Restrictions") {
  
  # Scaling factor for the secondary axis (to make Stringency visible)
  # Stringency goes 0-100, Log_Y usually 0-5. Factor ~20 works well.
  scale_factor <- 20 
  
  ggplot(data, aes(x = Date)) +
    # Pollution Line
    geom_line(aes(y = Log_Y, color = "Log(Pollution)"), alpha = 0.6, linewidth = 0.8) +
    # Covid Restriction Line (Scaled down)
    geom_line(aes(y = StringencyIndex / scale_factor, color = "Lockdown Index"), linewidth = 1) +
    
    # Dual Y-Axis definition
    scale_y_continuous(
      name = "Log Pollution Concentration",
      sec.axis = sec_axis(~ . * scale_factor, name = "Stringency Index (0-100)")
    ) +
    
    # Aesthetics
    scale_color_manual(values = c("Log(Pollution)" = "steelblue", "Lockdown Index" = "firebrick")) +
    labs(title = title_text, x = "Date", color = "Variable") +
    theme_minimal() +
    theme(legend.position = "bottom")
}


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

# ==============================================================================
# 2. MODEL REPORTING FUNCTIONS
# ==============================================================================

#' Create a Professional Model Summary Table
#'
#' Converts the raw summary() of a linear model into a nice HTML table.
#' Useful to save space in the report.
#'
#' @param model A linear model object (lm)
#' @param caption_text Title of the table
#' @return A kable object (HTML table)
print_model_table <- function(model, caption_text = "Regression Results") {
  
  # Extract coefficients, p-values, etc.
  broom::tidy(model) %>%
    mutate(
      # Format p-values to look nice (e.g., <0.001)
      p.value = scales::pvalue(p.value),
      estimate = round(estimate, 4),
      std.error = round(std.error, 4),
      statistic = round(statistic, 2)
    ) %>%
    kable(caption = caption_text, align = "c") %>%
    kable_styling(bootstrap_options = c("striped", "hover", "condensed"), full_width = F)
}


#' Compare Multiple Models (Fit Statistics)
#'
#' Creates a table comparing R-squared, AIC, and BIC for a list of models.
#'
#' @param model_list A named list of lm objects. e.g. list("Base"=m1, "Full"=m2)
#' @return A kable object
compare_models <- function(model_list) {
  
  # Calculate metrics for each model
  comparison <- map_dfr(model_list, function(m) {
    glance(m) %>% select(adj.r.squared, AIC, BIC, sigma)
  }, .id = "Model_Name")
  
  # Formatting
  comparison %>%
    mutate(
      adj.r.squared = round(adj.r.squared, 3),
      AIC = round(AIC, 1),
      BIC = round(BIC, 1),
      sigma = round(sigma, 3)
    ) %>%
    rename("Adj R2" = adj.r.squared, "Resid. Std. Error" = sigma) %>%
    kable(caption = "Model Comparison: Fit Metrics") %>%
    kable_styling(bootstrap_options = c("striped", "hover"), full_width = F)
}

# ==============================================================================
# 3. DIAGNOSTIC FUNCTIONS
# ==============================================================================

#' Check Variance Inflation Factor (VIF)
#' 
#' Checks for multicollinearity. VIF > 5 or 10 indicates a problem.
#' @param model A linear model object
print_vif <- function(model) {
  vif_vals <- car::vif(model)
  
  # Handle cases where VIF returns a matrix (if factors are involved with Generalized VIF)
  if(is.matrix(vif_vals)) {
    # If GVIF, we usually look at GVIF^(1/(2*Df)) squared, but let's keep it simple for printing
    print(vif_vals)
    message("Note: Generalized VIF used due to categorical variables.")
  } else {
    # If standard VIF vector
    vif_df <- data.frame(Variable = names(vif_vals), VIF = vif_vals)
    
    vif_df %>%
      arrange(desc(VIF)) %>%
      kable(caption = "Multicollinearity Check (VIF)") %>%
      kable_styling(full_width = F)
  }
}