# ==============================================================================
# FILE: scripts/02_functions.R
# DESCRIPTION: Custom functions for plotting and model reporting (Part 1).
# PURPOSE: Pure functions only. No execution code here.
# AUTHORS: Group LUNA
# ==============================================================================

if (!require("pacman")) install.packages("pacman")
pacman::p_load(ggplot2, dplyr, kableExtra, broom, car, patchwork)

# --- 1. PLOTTING FUNCTIONS ---

#' Plot Correlation Matrix
plot_correlations <- function(data) {
  numeric_vars <- data %>% 
    select(where(is.numeric)) %>% 
    select(-any_of(c("IDStations", "Altitude", "Longitude", "Latitude")))
  
  M <- cor(numeric_vars, use = "complete.obs")
  
  corrplot::corrplot(M, 
                     method = "color", 
                     type = "upper", 
                     order = "hclust", 
                     addCoef.col = "black", 
                     tl.col = "black", 
                     tl.srt = 45, 
                     diag = FALSE,
                     number.cex = 0.7
  )
}

#' Plot Wind Analysis (Boxplot with Median Line)
#' Visualizes PM10 distribution by Wind Direction
plot_wind_analysis <- function(data) {
  # Order directions logically
  data_ord <- data %>%
    mutate(WindDir = factor(WindDir, levels = c("N", "NE", "E", "SE", "S", "SW", "W", "NW"))) %>% 
    filter(!is.na(WindDir))
  
  ggplot(data_ord, aes(x = WindDir, y = Log_Y, fill = WindDir)) +
    geom_boxplot(alpha = 0.6, outlier.shape = NA) + 
    # Thick Red Dashed Line for Median
    stat_summary(fun = median, geom = "line", aes(group = 1), 
                 color = "firebrick", linewidth = 1.5, linetype = "dashed") +
    scale_fill_viridis_d(option = "D", guide = "none") +
    labs(
      title = "Impact of Wind Direction on PM10 Levels",
      subtitle = "Red Line = Median Trend. High pollution from SE (Milan), low from NW (Alps).",
      y = "Log(PM10)",
      x = "Wind Direction"
    ) +
    theme_minimal()
}

#' Plot Histograms (Original vs Log)
#' Compares skewness of original Y vs Normality of Log_Y
plot_pm10_histograms <- function(data) {
  p1 <- ggplot(data, aes(x=Y)) + 
    geom_histogram(fill="lightblue", color="white", bins=40) +
    labs(title="Original PM10", subtitle="Right-skewed", x="PM10 (ug/m3)") + theme_minimal()
  
  p2 <- ggplot(data, aes(x=Log_Y)) + 
    geom_histogram(fill="lightgreen", color="white", bins=40) +
    labs(title="Log-Transformed PM10", subtitle="Approx. Normal", x="Log(PM10)") + theme_minimal()
  
  # Return combined plot (requires 'patchwork' library)
  return(p1 + p2)
}

#' Plot Seasonal Boxplot
plot_seasonality <- function(data) {
  ggplot(data, aes(x = Season, y = Log_Y, fill = Season)) +
    geom_boxplot(alpha = 0.7) +
    scale_fill_brewer(palette = "Set2") +
    labs(
      title = "Seasonal Distribution of PM10",
      subtitle = "Winter (Reference) shows the highest levels.",
      y = "Log(PM10)",
      x = ""
    ) +
    theme_minimal() +
    theme(legend.position = "none")
}

# --- 2. TABLE FUNCTIONS ---

#' Show Key Data Points
show_key_dates <- function(data) {
  set.seed(123)
  bind_rows(
    head(data, 1),
    data %>% filter(year(Date) == 2020, month(Date) == 3) %>% head(1),
    data %>% filter(year(Date) == 2021) %>% sample_n(1)
  ) %>% 
    kable(caption = "Dataset Preview") %>% 
    kable_styling(bootstrap_options = c("striped", "hover"), full_width = F)
}