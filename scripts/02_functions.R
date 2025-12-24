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

#' Plot Correlation Matrix (Meteo Only)
plot_correlations <- function(data) {
  
  # 1. Selezioniamo solo le colonne numeriche
  numeric_vars <- data %>% 
    select(where(is.numeric)) %>% 
    # 2. ESCLUSIONI:
    # - Rimuoviamo ID e Coordinate (inutili)
    # - Rimuoviamo 'StringencyIndex' (come richiesto)
    # - Rimuoviamo 'Y' (usiamo solo Log_Y per la correlazione)
    select(-any_of(c("IDStations", "Altitude", "Longitude", "Latitude", 
                     "StringencyIndex", "Y")))
  
  # 3. Calcolo Correlazione
  M <- cor(numeric_vars, use = "complete.obs")
  
  # 4. Plot
  corrplot::corrplot(M, 
                     method = "color", 
                     type = "upper", 
                     order = "hclust", 
                     addCoef.col = "black", # Mostra i numeri
                     tl.col = "black", 
                     tl.srt = 45, 
                     diag = FALSE,
                     number.cex = 0.8 # Grandezza numeri
  )
}

#' Plot Wind Analysis
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

#' Plot PM10 Histograms
plot_pm10_histograms <- function(data) {
  p1 <- ggplot(data, aes(x=Y)) + 
    geom_histogram(fill="lightblue", color="white", bins=40) +
    labs(title="Original PM10", subtitle="Right-skewed", x="PM10 (ug/m3)") + theme_minimal()
  
  p2 <- ggplot(data, aes(x=Log_Y)) + 
    geom_histogram(fill="lightgreen", color="white", bins=40) +
    labs(title="Log-Transformed PM10", subtitle="Approx. Normal", x="Log(PM10)") + theme_minimal()
  
  return(p1 + p2)
}

# ==============================================================================
# 2. MODEL REPORTING FUNCTIONS
# ==============================================================================

#' Create a Ranked and Colored Model Table
#'
#' - Filters out Intercept.
#' - Sorts by Estimate.
#' - COLORS ESTIMATE COLUMN based on Sign:
#'   RED (>0) = Increases Pollution.
#'   GREEN (<0) = Decreases Pollution.
print_model_table <- function(model, caption_text = "Meteorological Model Results") {
  
  # 1. Estrazione dati
  tidy_data <- broom::tidy(model) %>%
    filter(!term %in% c("(Intercept)")) %>%
    arrange(desc(estimate)) # Ordina dal più positivo al più negativo
  
  # 2. Definisci i colori in base al SEGNO dell'Estimate
  # Se > 0 -> Rosso (D9534F), Se < 0 -> Verde (5CB85C)
  est_colors <- ifelse(tidy_data$estimate > 0, "#D9534F", "#5CB85C")
  
  # 3. Creazione Tabella
  tidy_data %>%
    mutate(
      p_label = scales::pvalue(p.value),
      estimate = round(estimate, 4),
      std.error = round(std.error, 4),
      statistic = round(statistic, 2)
    ) %>%
    select(term, estimate, std.error, statistic, p_label) %>%
    kable(
      caption = caption_text, 
      align = "c",
      col.names = c("Variable", "Estimate", "Std. Error", "t-value", "P-Value")
    ) %>%
    kable_styling(bootstrap_options = c("striped", "hover"), full_width = F) %>%
    
    # 4. Applica i colori alla colonna 2 (Estimate)
    column_spec(2, color = "white", bold = TRUE, background = est_colors)
}

#' Compare Multiple Models
compare_models <- function(model_list) {
  comparison <- map_dfr(model_list, function(m) {
    broom::glance(m) %>% select(adj.r.squared, AIC, BIC, sigma)
  }, .id = "Model_Name")
  
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