
```
Agrimonia-Air-Quality-Regression
├── Agrimonia-Air-Quality-Regression.Rproj     # RStudio Project file (Sets the root directory for relative paths)
├── README.md                   # General documentation, team members, and objective
├── tree_structure.md          # This file: Visual map of the repository structure
├── .gitignore                  # Files to exclude from version control (e.g., local config, large temp files)
│
├── img/ # useful project images (not output)   
│
├── data/                       # Folder containing all datasets
│   ├── raw/                    # Immutable, original source data
│   │   ├── Agrimonia_stations.RData  # The primary dataset provided by the professor
│   │   └── OxCGRT_compact_national_v1.csv # Covid Dataset
│   └── processed/              # Modified/cleaned data for analysis
│       └── final_saronno_pm10.rds    # Data filtered for the specific station, specific params
│
├── scripts/                    # R scripts for modular code (supporting the Rmd)
│   ├── 00_packages.R           # Library installation and loading
│   ├── 01_data_preparation.R   # Code to clean variables and handle missing values
│   ├── 02_functions.R          # Custom functions (e.g., for plotting or diagnostics)
    └── 03_meteo_analysis.R     #
│
├── report/                     # The final deliverables for the exam
│   ├── GLuna_Report.Rmd   # The main R Markdown source code
│   └── GLuna_Report.html  # The compiled HTML report to be submitted via email
│
└── output/                     # Generated artifacts for the presentation
    └── plots/                  # Images exported for presentation
        ├── img00.png
        └── img01.png
```