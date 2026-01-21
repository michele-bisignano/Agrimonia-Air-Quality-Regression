# ==============================================================================
# 03_analysis.R
# Script centrale: genera TUTTI i risultati dell’analisi
# Output:
#   - Grafici  -> output/graphs/*.png
#   - Tabelle  -> output/tables/*.rds
#   - Risultati numerici (R² ecc.) -> output/results/*.rds
# ==============================================================================

rm(list = ls())

# ------------------------------------------------------------------------------
# LIBRERIE
# ------------------------------------------------------------------------------
if (!require("pacman")) install.packages("pacman")
pacman::p_load(
  tidyverse, here, broom, car, corrplot, lmtest, patchwork, ggplot2
)

# ------------------------------------------------------------------------------å©
# CARTELLE OUTPUT
# ------------------------------------------------------------------------------
dir.create(here("output","graphs"), recursive = TRUE, showWarnings = FALSE)
dir.create(here("output","tables"), recursive = TRUE, showWarnings = FALSE)
dir.create(here("output","results"), recursive = TRUE, showWarnings = FALSE)

# ------------------------------------------------------------------------------
# FUNZIONI CUSTOM
# ------------------------------------------------------------------------------
source(here("scripts","02_functions.R"))

# ------------------------------------------------------------------------------
# CARICAMENTO DATI
# ------------------------------------------------------------------------------
df <- readRDS(here("data","processed","final_saronno_pm10.rds"))

# Target
df$Log_Y <- log(df$Y + 1)

# ------------------------------------------------------------------------------
# 1) ISTOGRAMMI PM10
# ------------------------------------------------------------------------------
p_hist <- plot_pm10_histograms(df)

ggsave(
  here("output","graphs","pm10_hist.png"),
  plot = p_hist,
  width = 10, height = 6, dpi = 300
)

# ------------------------------------------------------------------------------
# 2) WIND BOXPLOT (già prodotto dal tuo script, ma lo rigeneriamo in modo pulito)
# ------------------------------------------------------------------------------
p_wind <- ggplot(df, aes(x = WindDir, y = Log_Y)) +
  geom_boxplot(fill = "lightblue") +
  labs(
    title = "PM10 by Wind Direction (log scale)",
    x = "Wind Direction",
    y = "log(PM10 + 1)"
  ) +
  theme_minimal()

ggsave(
  here("output","graphs","wind_boxplot.png"),
  plot = p_wind,
  width = 10, height = 6, dpi = 300
)

# ------------------------------------------------------------------------------
# 3) TABELLA STATISTICHE VENTO
# ------------------------------------------------------------------------------
wind_tab <- df %>%
  group_by(WindDir) %>%
  summarise(
    Days = n(),
    Median_Log = median(Log_Y, na.rm = TRUE),
    Median_PM10 = exp(Median_Log) - 1,
    .groups = "drop"
  ) %>%
  arrange(desc(Median_PM10))

saveRDS(wind_tab, here("output","tables","wind_stats_table.rds"))

# ------------------------------------------------------------------------------
# 4) MODELLO METEO BASE
# ------------------------------------------------------------------------------
model_meteo <- lm(Log_Y ~ Temp + WindSpeed + Precipitation + Humidity, data = df)

# Salvo R²
saveRDS(summary(model_meteo)$r.squared,
        here("output","results","r2_pm10_meteo.rds"))

# Salvo tabella coefficienti
tab_meteo <- tidy(model_meteo)
saveRDS(tab_meteo,
        here("output","tables","model_meteo_table.rds"))

# ------------------------------------------------------------------------------
# 4.1) DIAGNOSTICA MODELLO METEO
# ------------------------------------------------------------------------------
# Apriamo un file png per salvare i 4 grafici di diagnostica insieme
png(here("output","graphs","meteo_diagnostics.png"), width = 1000, height = 800)

# Impostiamo il layout 2x2 per vedere i 4 grafici classici di lm
par(mfrow = c(2, 2))
plot(model_meteo)
par(mfrow = c(1, 1)) # Reset del layout

dev.off()

# ------------------------------------------------------------------------------
# 5) VIF MODELLO METEO
# ------------------------------------------------------------------------------
vif_meteo <- data.frame(
  Variable = names(car::vif(model_meteo)),
  VIF = as.numeric(car::vif(model_meteo))
)

saveRDS(vif_meteo,
        here("output","tables","vif_meteo_table.rds"))

# ------------------------------------------------------------------------------
# 6) CORR PLOT MODELLO METEO
# ------------------------------------------------------------------------------
df_corr <- df %>%
  select(Log_Y, Temp, WindSpeed, Precipitation, Humidity)

M <- cor(df_corr, use = "complete.obs")

png(here("output","graphs","corrplot_meteo.png"), width = 900, height = 700)
corrplot(
  M,
  method = "color",
  type = "upper",
  addCoef.col = "black",
  tl.col = "black",
  diag = FALSE,
  title = "Cleaned Correlation Matrix",
  mar = c(0,0,2,0)
)
dev.off()

# ------------------------------------------------------------------------------
# 7) MODELLO METEO + COVID + STAGIONI (PM10)
# ------------------------------------------------------------------------------
model_covid <- lm(
  Log_Y ~ Temp + WindSpeed + Precipitation + Humidity +
    StringencyIndex + Season,
  data = df
)

# R²
saveRDS(summary(model_covid)$r.squared,
        here("output","results","r2_pm10_covid.rds"))

# Tabella coefficienti
tab_covid <- tidy(model_covid)
saveRDS(tab_covid,
        here("output","tables","model_pm10_covid_table.rds"))

# ------------------------------------------------------------------------------
# 8) TREND COVID
# ------------------------------------------------------------------------------
p_covid <- plot_covid_trend(df,
                            title_text = "PM10 vs Italy Stringency Index")

ggsave(
  here("output","graphs","covid_trend_pm10.png"),
  plot = p_covid,
  width = 12, height = 6, dpi = 300
)

# ------------------------------------------------------------------------------
# 9) MODELLO NO2
# ------------------------------------------------------------------------------
model_no2 <- lm(
  log(AQ_no2 + 1) ~ Temp + WindSpeed + Precipitation + Humidity +
    StringencyIndex + Season,
  data = df
)

# R² NO2
saveRDS(summary(model_no2)$r.squared,
        here("output","results","r2_no2.rds"))

# Tabella coefficienti NO2
tab_no2 <- tidy(model_no2)
saveRDS(tab_no2,
        here("output","tables","model_no2_table.rds"))

# ------------------------------------------------------------------------------
# 10) CONFRONTO COEFFICIENTI OLS vs GAMMA
# ------------------------------------------------------------------------------
model_gamma <- glm(
  (Y + 0.001) ~ Temp + WindSpeed + Precipitation + Humidity,
  data = df,
  family = Gamma(link = "log")
)

comparison_tab <- data.frame(
  Variable = names(coef(model_meteo))[-1],
  OLS_LogY = coef(model_meteo)[-1],
  GLM_Gamma = coef(model_gamma)[-1]
)

saveRDS(comparison_tab,
        here("output","tables","comparison_ols_gamma_table.rds"))

# ------------------------------------------------------------------------------
# FINE
# ------------------------------------------------------------------------------
cat("\n03_analysis.R completato correttamente.\n")
cat("Tutti gli output sono stati salvati in /output.\n")
