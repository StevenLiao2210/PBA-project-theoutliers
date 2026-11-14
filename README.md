# PBA-Final-Repo
PBA-Final-Repo
Milestone 1 task:
Jeffrey Mark Ivanson 112006232
Steven Ernest Muliawan 112006224
Julianna Villa Real 111006214
Samuel Bradley Winata 112006225

## Milestone 3: Exploratory Data Visualization

Research question: **Do Taipei Airbnb listings with longer minimum-stay
requirements exhibit smaller seasonal differences in advertised nightly prices?**

All R code and write-ups are in the existing
[AirBnB_Price_Difference.qmd](AirBnB_Price_Difference.qmd).
The submission is [the rendered PDF](AirBnB_Price_Difference.pdf).
It includes two figures built from the real September 28, 2026 Taipei release:

1. Histogram of quoted nightly prices (5,868 listings).
2. Boxplots of quoted prices by minimum-stay group (5,867 listings).

Figure 2 separates minimum-stay requirements into 1-2, 3-6, 7-29,
and 30+ nights. The accompanying
`data/processed/stay_group_quality.csv` reports group sizes, usable
prices, missing-price percentages, and median quoted prices.
The report discusses the unequal price coverage across groups.

Both use straightforward `ggplot2` styling, logarithmic price axes, and all eligible
positive-price observations. The QMD uses `dplyr` pipelines for cleaning, filtering,
grouping, and summaries.

Each figure has a short interpretation and an explanation of its relevance to the
planned analysis. There are no fitted models or hypothesis tests.

**Important feasibility finding:** the supplied `calendar.csv.gz` contains
availability and minimum/maximum-night rules, but **no price column**. The
December 2026 versus August 2027 price comparison cannot be computed from these
files. The PDF explicitly reports this limitation. Its price figure uses listing
quotes with differing dates and stay lengths, and does not claim seasonal effects.

### Reproduce the submission from the committed subset

Open the QMD in RStudio and click **Render**, or run the following from the repo
root. You need R, the R packages `knitr`, `rmarkdown`, `dplyr`, and `ggplot2`,
Quarto, and XeLaTeX (for example, a TinyTeX installation).

Install missing R packages once with:

```r
install.packages(c("knitr", "rmarkdown", "dplyr", "ggplot2"))
```

```sh
quarto render AirBnB_Price_Difference.qmd
```

This executes the R chunks in the QMD, embeds both figures, evaluates the inline R
statistics in the write-ups, and produces `AirBnB_Price_Difference.pdf` beside it.
It also exports PNGs under `output/figures/` and descriptive statistics under
`data/processed/figure_summary.csv`. By default it uses the committed small subset
and does not need the large raw downloads. The PDF hides code for readability;
all code remains visible and editable inside the QMD.

`data/processed/price_distribution_summary.csv` contains the overall price
distribution statistics used in the Figure 1 interpretation. Inline R keeps the
reported counts, medians, and percentages tied to the data.

### Rebuild the smaller files from the original downloads

Keep both original `.csv.gz` files together in `data/raw/` (ignored by Git), or
pass the directory where they are saved:

```sh
quarto render AirBnB_Price_Difference.qmd -P refresh_data:true
```

Example using downloads outside the repo:

```powershell
quarto render AirBnB_Price_Difference.qmd -P refresh_data:true -P raw_dir:"C:/Users/ivans/Downloads/Compressed"
```

Alternatively, download the exact public snapshot and rebuild entirely within the QMD:

```sh
quarto render AirBnB_Price_Difference.qmd -P download_raw:true -P refresh_data:true
```

This requires internet access and stores the raw files in ignored `data/raw/`. The preparation
step audits 6,367 listings and 2,323,955 calendar rows and writes a small listing
column subset plus monthly calendar coverage; it does not copy the raw files into Git.

See [the codebook next to the processed data](data/processed/CODEBOOK.md) for field
definitions, units, exclusions, file fingerprints, and limitations. The committed
subsets and all figure outputs can be regenerated from the QMD. Its YAML parameters
control whether it rebuilds the subset or uses the committed version.

For the handoff's standalone R data-preparation entry point:

```sh
Rscript scripts/prepare_data.R data/raw
```

This small entry point executes the `setup` and `prepare-real-data` chunks from
the QMD. The preparation logic remains in the QMD, rather than in a second copy
that could drift. It writes the compact data and audits without rendering the PDF.

### Source and attribution

Inside Airbnb. (2026). *Taipei: detailed listings and calendar data, September 28,
2026 release*. [Download page](https://insideairbnb.com/get-the-data/).
[Source file directory](https://data.insideairbnb.com/taiwan/northern-taiwan/taipei/2026-09-28/data/).
Licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
See also [data assumptions](https://insideairbnb.com/data-assumptions/).
The subset, groupings, plots, and write-ups are team transformations of these files.
