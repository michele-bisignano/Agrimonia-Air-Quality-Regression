# Analysis of Pollution Drivers in Lombardy

## 👥 Group LUNA
*   [Mattia Franchini](https://github.com/Mattia-Franchini) (1099581)
*   [Fabio Ghislanzoni](https://github.com/FabioGhislanzoni05) (1099423)
*   [Lino Mazzoleni](https://github.com/LinoMazzo) (1098962)
*   [Michele Bisignano](https://github.com/michele-bisignano) (1099385)

---

## 🎓 Academic Context
This analysis was conducted as the final project for the **Statistics** course (9 CFU) within the Bachelor's Degree in Computer Engineering at the **University of Bergamo**.

*   **Course:** Statistica (Statistics)
*   **Professor:** Rodolfo Metulini
*   **Academic Year:** 2025/2026
*   **Date:** January 2026

---

## 📂 Project Resources & Quick Links

Access the full analysis and source code here:

*   📄 **Read the Full Report:** [**GLuna_Report.html**](./report/GLuna_Report.html)  
    *(Click to download or view the rendered HTML analysis)*

*   📂 **Source Code Folder:** [**Go to Scripts**](./scripts)
    *(Contains all R scripts used for data cleaning and modeling)*

*   ⚙️ **Key Scripts:**
    *   [Data Preparation](./scripts/01_data_preparation.R) (Cleaning & Preprocessing)
    *   [Model Analysis](./scripts/03_analysis.R) (Regressions & Visualizations)

---

## 📖 Project Overview
Air pollution in the Lombardy region is a critical environmental issue. This project systematically analyzes the drivers of **PM10** and **NO2** concentrations using the **Agrimonia dataset** (2016-2021).

The study is structured into three main parts:

1.  **Meteorological Drivers:** A robust regression model to quantify how natural factors (wind direction, precipitation, seasonality) influence PM10 accumulation in Saronno.
2.  **The "Covid Effect":** Utilizing the *Oxford Stringency Index* to evaluate whether government lockdown restrictions significantly reduced PM10 levels after filtering out meteorological noise.
3.  **Pollutant Sensitivity:** A comparative study between PM10 (multi-source) and NO2 (traffic-linked) to validate the statistical methodology.

---

## 📚 Data Sources & Citations
The analysis is based on the **Agrimonia** dataset. Per the authors' requirements, we cite the dataset and the related publication as follows:

> Fassò, A., Rodeschini, J., Fusta Moro, A., Shaboviq, Q., Vinciguerra, M., Maranzano, P., Cameletti, M., Finazzi, F., Golini, N., Ignaccolo, R., & Otto, P. (2023). **AgrImOnIA: Open Access dataset correlating livestock and air quality in the Lombardy region, Italy** (3.0.0) [Data set]. Zenodo. https://doi.org/10.5281/zenodo.7956006

> Fassò, A., Rodeschini, J., Fusta Moro, A., Shaboviq, Q., Maranzano, P., Cameletti, M., ... & Otto, P. (2023). **Agrimonia: a dataset on livestock, meteorology and air quality in the Lombardy region, Italy**. *Scientific Data*, 10(1), 143.

**Additional Data:**
*   **Oxford COVID-19 Government Response Tracker (OxCGRT):** Hale, T., et al. (2021). "A global panel database of pandemic policies". *Nature Human Behaviour*. https://doi.org/10.1038/s41562-021-01079-8
