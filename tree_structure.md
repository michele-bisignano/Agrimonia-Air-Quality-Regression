```
project/                                              # root
│
├── README.md                                         # overview
├── tree_structure.md                                 # repo tree
│
├── report/                                           # reports
│   ├── GLuna_Report.Rmd                              # Rmd (clean)
│   ├── GLuna_Report.html                             # HTML report
│   └── proj_presentation.pptx                        # presentation
│
├── scripts/                                          # scripts
│   ├── 00_packages.R                                 # load packages
│   ├── 01_data_preparation.R                         # data prep
│   ├── 02_functions.R                                # helper funcs
│   └── 03_analysis.R                                 # analysis
│
├── output/                                           # outputs
│   ├── graphs/                                       # figures
│   │   ├── corrplot_meteo.png                        # corrplot
│   │   ├── covid_trend_pm10.png                      # covid vs pm10
│   │   ├── meteo_diagnostics.png                     # meteo diag
│   │   ├── pm10_hist.png                             # pm10 hist
│   │   ├── wind_boxplot.png                          # wind boxplot
│   │   └── seasonality/                              # seasonality figs
│   │
│   ├── models/                                       # models
│   │   └── m1_meteo.rds                              # model m1
│   │
│   ├── tables/                                       # tables
│   │   ├── comparison_ols_gamma_table.rds            # model compare
│   │   ├── model_meteo_table.rds                     # meteo table
│   │   ├── model_no2_table.rds                       # no2 table
│   │   ├── model_pm10_covid_table.rds                # pm10+covid table
│   │   ├── tab_model_meteo.rds                       # meteo tab
│   │   ├── vif_meteo_table.rds                       # vif table
│   │   ├── wind_stats_table.rds                      # wind stats
│   │   └── wind_table.png                            # wind image
│   │
│   └── results/                                      # results
│       ├── r2_pm10.rds                               # r2 pm10
│       ├── r2_no2.rds                                # r2 no2
│       └── r2_pm10_meteo.rds                         # r2 pm10 meteo
│
├── data/                                             # data
│   ├── raw/                                          # raw data
│   │   ├── Agrimonia_stations.RData                  # stations raw
│   │   └── OxCGRT_compact_national_v1.csv            # oxcgrt raw
│   │
│   └── processed/                                    # processed data
│       └── final_saronno_pm10.rds                    # final dataset
│
└── img/                                              # images
    └── Saronno_context.png                           # saronno map

```
