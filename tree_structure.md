
```
project/
│
├── report/
│   └── main_report.Rmd        # SOLO testo + include di immagini/tabelle
│
├── scripts/
│   ├── 01_data_preparation.R  # pulizia dati
│   ├── 02_functions.R         # funzioni custom
│   └── 03_analysis.R          # tutti i modelli, grafici, tabelle, numeri
│
├── output/
│   ├── graphs/
│   │   ├── pm10_hist.png
│   │   ├── wind_boxplot.png
│   │   ├── corrplot.png
│   │   └── covid_trend.png
│   │
│   ├── tables/
│   │   ├── wind_stats_table.rds
│   │   ├── model_meteo_table.rds
│   │   ├── model_covid_table.rds
│   │   └── model_no2_table.rds
│   │
│   └── results/
│       ├── r2_pm10.rds
│       ├── r2_no2.rds
│       └── coefficients_comparison.rds
│
├── data/
│   └── processed/
│       └── final_saronno_pm10.rds

```