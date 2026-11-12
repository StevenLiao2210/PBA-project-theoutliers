# Taipei Airbnb milestone data codebook

Source: Inside Airbnb, Taipei, **2026-09-28 release**, downloaded by the team.
Individual listing scrape dates are September 28-29, 2026. Source files are
`listings.csv.gz` and `calendar.csv.gz` from
<https://data.insideairbnb.com/taiwan/northern-taiwan/taipei/2026-09-28/data/>.
License: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
Reference: [Inside Airbnb data dictionary](https://docs.google.com/spreadsheets/d/1iWCNJcSutYqpULSQHlNyGInUvHg2BoUGoNRIGa6Szc4/edit).
Our raw schema includes additional price-quote fields; the supplied files are the
authority for which fields are present.

## listings_subset.csv

Unit: one listing. **6,367 rows**, unique listing IDs. This is a column subset
of all listings, not a random sample. Names, host IDs, URLs, descriptions, photos,
and coordinates are omitted. Empty CSV cells mean missing values.

| Column | Type / units | Definition |
|---|---|---|
| listing_id | Character identifier | Source `id`; read as text to preserve large IDs exactly. |
| last_scraped | YYYY-MM-DD | Individual listing scrape date. |
| minimum_nights | Integer nights | Source listing-level general rule; one missing value. Calendar rules can differ. |
| stay_group | Category | 1-2 nights, 3-6 nights, or 7+ nights. Missing if the minimum is missing or below 1. |
| room_type | Category | Source room type, including entire home/apt, private room, shared room, hotel room. |
| neighbourhood_cleansed | Text | Source geocoded neighbourhood. Retained for planned adjustment; not used in these figures. |
| accommodates | Integer guests | Advertised guest capacity; retained for planned adjustment. |
| quoted_nightly_price_twd | Numeric TWD/night | Source `price`, stripped of dollar signs and commas; kept only if finite, positive, and the currency in `price_quote_raw` is TWD. A quoted per-night amount, not a completed transaction or calendar-date series. |
| quote_currency | Currency code | Extracted from `price_quote_raw` using its currency field; TWD for every nonmissing usable price in this snapshot. |
| quote_checkin | YYYY-MM-DD | Source `price_quote_checkin_date`; differs across listings. |
| quote_checkout | YYYY-MM-DD | Source `price_quote_checkout_date`. |
| quote_stay_nights | Integer nights | Checkout minus check-in. Quotes can cover different stay lengths and incorporate discounts. |

Figure 1 retains **5,868** listings with a positive TWD quote, regardless of whether
the minimum-stay rule is present.
Figure 2 retains **5,867** listings with both a valid rule and a positive TWD price.
There are **499 missing/unusable prices**, plus one additional listing with a
valid price but a missing rule. No eligible positive prices are winsorized,
trimmed, or dropped as outliers. The minimum-stay group counts in the data overview
and summary CSV use 6,366 valid rules as denominator.

## calendar_monthly.csv

Unit: a calendar month, including partial September months at the endpoints.
It summarizes all **2,323,955** original listing-date rows covering
2026-09-28 through 2027-09-28. This is a coverage audit, not an occupancy estimate.

| Column | Definition |
|---|---|
| month | YYYY-MM calendar month. |
| calendar_rows | Number of listing-date rows in the month. |
| listings | Distinct listing IDs represented in the month. |
| dates | Distinct calendar dates represented in the month. |
| available_rows | Rows with source `available == "t"`. Unavailable may mean booked or host-blocked. |

**The raw calendar has no prices.** Its five columns are `listing_id`, `date`,
`available`, `minimum_nights`, and `maximum_nights`. The December 2026 versus
August 2027 price comparison in the proposal cannot be computed from it. No
calendar price, seasonal premium, booked-night count, or occupancy outcome is imputed.

## Other outputs

- `audit.csv`: input row counts, date range, missing-value checks, duplicate counts,
  a calendar-price-presence flag, and input file MD5 fingerprints. Duplicate counts
  are zero after assertions in the preparation script; a duplicate causes failure.
- `schema_note.txt`: records the raw calendar columns and missing price field.
- `figure_summary.csv`: one row per minimum-stay group, with listing count,
  share among valid rules, valid price count, median, and 25th/75th percentiles.
  Summary quantiles use R's default type 7 in original TWD units. Figure 2 uses
  `geom_boxplot()` and `scale_y_log10()`: ggplot2 computes its quartiles and
  1.5-IQR whiskers on log10 prices; dots show observations beyond those whiskers.
- `price_distribution_summary.csv`: one row describing all 5,868 usable quotes:
  count, median, 25th/75th/90th percentiles, maximum (TWD), and the percentage
  above TWD 10,000. Figure 1 uses histogram bins of width 0.1 in log10 TWD units,
  corresponding to adjacent price boundaries about 26% apart. Counts sum to 5,868.

## Reproduction and limits

The `prepare-real-data` R chunk in `AirBnB_Price_Difference.qmd` reads both gzip files, validates IDs and listing-date
uniqueness, checks calendar joins and availability coding, parses prices, and writes
the subsets. It reads UTF-8 text without conversion through the Windows locale.
The remaining R chunks regenerate both figures and the summary CSV, and the
QMD combines these with write-ups containing inline R statistics. All code is
in the QMD. The small `scripts/prepare_data.R` entry point executes the QMD's
first two named chunks so data preparation can also run with Rscript without
duplicating its logic. Default rendering uses the committed subset;
`refresh_data:true` rebuilds it from the gzip files. Cleaning and summaries use
dplyr; figures use ggplot2. Rendering needs Quarto, knitr, rmarkdown, and XeLaTeX.

These are descriptive, cross-sectional visualizations. Advertised quote levels
do not measure seasonal stability, transactions, revenue, or causal effects.
Different check-in dates, stay lengths, discounts, room types, and locations
can explain group differences. A future paired seasonal analysis needs an
actual date-level price source and sufficient matched-listing coverage first.
