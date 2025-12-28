# ==============================================================================
# FILE: scripts/02_functions.R
# DESCRIPTION: Custom functions for plotting and model reporting.
# PURPOSE: Keep the RMarkdown file clean by abstracting complex code.
# AUTHORS: Group LUNA
# ==============================================================================

# Ensure required libraries are loaded
if (!require("pacman")) install.packages("pacman")
pacman::p_load(ggplot2, dplyr, kableExtra, broom, car, corrplot, patchwork)

# ==============================================================================
# 1. VISUALIZATION FUNCTIONS
# ==============================================================================

#' Plot Time Series: Pollution vs Covid Restrictions
plot_covid_trend <- function(data, title_text = "Pollution vs Covid-19 Restrictions") {
  scale_factor <- 20 
  ggplot(data, aes(x = Date)) +
    geom_line(aes(y = Log_Y, color = "Log(Pollution)"), alpha = 0.6, linewidth = 0.8) +
    geom_line(aes(y = StringencyIndex / scale_factor, color = "Lockdown Index"), linewidth = 1) +
    scale_y_continuous(
      name = "Log Pollution Concentration",
      sec.axis = sec_axis(~ . * scale_factor, name = "Stringency Index (0-100)")
    ) +
    scale_color_manual(values = c("Log(Pollution)" = "steelblue", "Lockdown Index" = "firebrick")) +
    labs(title = title_text, x = "Date", color = "Variable") +
    theme_minimal() +
    theme(legend.position = "bottom")
}

#' Plot Correlation Matrix
#' Excludes non-numeric and specific variables not needed for the plot
plot_correlations <- function(data) {
  
  # Select numeric vars and remove specific columns
  numeric_vars <- data %>% 
    select(where(is.numeric)) %>% 
    select(-any_of(c("IDStations", "Altitude", "Longitude", "Latitude", "Y")))
  
  # Calculate Correlation
  M <- cor(numeric_vars, use = "complete.obs")
  
  # Plot
  corrplot::corrplot(M, 
                     method = "color", 
                     type = "upper", 
                     order = "hclust", 
                     addCoef.col = "black", # Show numbers
                     tl.col = "black", 
                     tl.srt = 45, 
                     diag = FALSE,
                     number.cex = 0.8 
  )
}

#' Plot Wind Analysis (Boxplot with Median Line)
plot_wind_analysis <- function(data) {
  data_ord <- data %>%
    mutate(WindDir = factor(WindDir, levels = c("N", "NE", "E", "SE", "S", "SW", "W", "NW"))) %>% 
    filter(!is.na(WindDir))
  
  ggplot(data_ord, aes(x = WindDir, y = Log_Y, fill = WindDir)) +
    geom_boxplot(alpha = 0.6, outlier.shape = NA) + 
    stat_summary(fun = median, geom = "line", aes(group = 1), 
                 color = "firebrick", linewidth = 1.5, linetype = "dashed") +
    scale_fill_viridis_d(option = "D", guide = "none") +
    labs(
      title = "Impact of Wind Direction on PM10 Levels",
      y = "Log(PM10)",
      x = "Wind Direction"
    ) +
    theme_minimal()
}

#' Plot PM10 Histograms (Original vs Log)
plot_pm10_histograms <- function(data) {
  p1 <- ggplot(data, aes(x=Y)) + 
    geom_histogram(fill="lightblue", color="white", bins=40) +
    labs(title="Original PM10", subtitle="Right-skewed", x="PM10 (ug/m3)") + theme_minimal()
  
  p2 <- ggplot(data, aes(x=Log_Y)) + 
    geom_histogram(fill="lightgreen", color="white", bins=40) +
    labs(title="Log-Transformed PM10", subtitle="Approx. Normal", x="Log(PM10)") + theme_minimal()
  
  return(p1 + p2)
}

#' Plot Seasonality Boxplot
plot_seasonality <- function(data) {
  ggplot(data, aes(x = Season, y = Log_Y, fill = Season)) +
    geom_boxplot(alpha = 0.7) +
    scale_fill_brewer(palette = "Set2") +
    labs(
      title = "Seasonal Distribution of PM10",
      y = "Log(PM10)",
      x = ""
    ) +
    theme_minimal() +
    theme(legend.position = "none")
}

# ==============================================================================
# 2. MODEL REPORTING FUNCTIONS
# ==============================================================================

#' Create a Ranked and Colored Model Summary Table
#' Sorts by statistical strength (t-value) and colors by estimate sign.
print_model_table <- function(model, caption_text = "Regression Results") {
  
  # 1. Extract coefficients and calculate the percentage effect
  tidy_data <- broom::tidy(model) %>%
    filter(!term %in% c("(Intercept)")) %>%
    mutate(
      pct_effect = (exp(estimate) - 1) * 100,
      pct_label = sprintf("%+.1f%%", pct_effect)
    ) %>%
    # 2. Sort from Highest Effect (most polluting) to Lowest Effect (most cleaning)
    arrange(desc(pct_effect))
  
  # 3. Create a color gradient for the percentage column
  # We use a Red -> White -> Green palette (Red = Positive/Bad, Green = Negative/Good)
  # "RdYlGn" is a standard palette, we reverse it so High=Red, Low=Green
  col_palette <- colorRampPalette(c("#5CB85C", "#F0F0F0", "#D9534F"))(nrow(tidy_data))
  # We map the colors to the sorted values
  val_colors <- rev(col_palette) 
  
  # 4. Generate the table
  tidy_data %>%
    mutate(
      p_label = scales::pvalue(p.value),
      estimate = round(estimate, 4),
      std.error = round(std.error, 4),
      statistic = round(statistic, 2)
    ) %>%
    select(term, estimate, pct_label, std.error, statistic, p_label) %>%
    kable(
      caption = caption_text, 
      align = "c",
      col.names = c("Variable", "Estimate", "Effect (%)", "Std. Error", "t-value", "P-Value")
    ) %>%
    kable_styling(bootstrap_options = c("striped", "hover"), full_width = F) %>%
    # Apply the gradient ONLY to the 3rd column (Effect %)
    column_spec(3, color = "white", bold = TRUE, background = val_colors)
}

# ==============================================================================
# 3. UTILITY FUNCTIONS
# ==============================================================================

#' Show Key Data Points
show_key_dates <- function(data) {
  set.seed(123)
  bind_rows(
    head(data, 1),
    data %>% filter(year(Date) == 2020, month(Date) == 3) %>% head(1),
    data %>% filter(year(Date) == 2021) %>% sample_n(1)
  ) %>% 
    kable(caption = "Dataset Preview: Selected Time Points") %>% 
    kable_styling(bootstrap_options = c("striped", "hover"), full_width = F)
}