# Run from the repository root. No contributed R packages are required.
# Usage: Rscript scripts/prepare_data.R [directory containing both .csv.gz files]
args <- commandArgs(trailingOnly = TRUE)
raw_dir <- if (length(args)) args[1] else "data/raw"
dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
read_gz <- function(path) {
  # Preserve UTF-8 bytes instead of transcoding through the Windows locale.
  con <- gzfile(path, "rt")
  on.exit(close(con))
  read.csv(con, colClasses = "character", check.names = FALSE,
           na.strings = c("", "NA"), encoding = "UTF-8")
}
listings_path <- file.path(raw_dir, "listings.csv.gz")
calendar_path <- file.path(raw_dir, "calendar.csv.gz")
stopifnot(file.exists(listings_path), file.exists(calendar_path))
l <- read_gz(listings_path)
c <- read_gz(calendar_path)
needed <- c("id", "last_scraped", "minimum_nights", "price", "room_type",
            "neighbourhood_cleansed", "accommodates", "price_quote_raw",
            "price_quote_checkin_date", "price_quote_checkout_date")
stopifnot(all(needed %in% names(l)), all(c("listing_id", "date", "available", "minimum_nights", "maximum_nights") %in% names(c)))
stopifnot(!anyNA(l$id), !anyDuplicated(l$id))
stopifnot(!anyNA(c$listing_id), !anyNA(c$date),
          !anyDuplicated(c[c("listing_id", "date")]), all(c$listing_id %in% l$id),
          all(c$available %in% c("t", "f")))
minimum <- suppressWarnings(as.integer(l$minimum_nights))
valid_minimum <- !is.na(minimum) & minimum >= 1
price <- suppressWarnings(as.numeric(gsub("[$,]", "", l$price)))
currency <- rep(NA_character_, nrow(l))
has_currency <- !is.na(l$price_quote_raw) & grepl('"currency"\\s*:', l$price_quote_raw)
currency[has_currency] <- sub('.*"currency"\\s*:\\s*"([^"]+)".*', '\\1', l$price_quote_raw[has_currency])
valid_price <- is.finite(price) & price > 0 & !is.na(currency) & currency == "TWD"
group <- ifelse(!valid_minimum, NA, ifelse(minimum <= 2, "1-2 nights", ifelse(minimum <= 6, "3-6 nights", "7+ nights")))
d <- data.frame(listing_id = l$id, last_scraped = l$last_scraped,
  minimum_nights = minimum, stay_group = group, room_type = l$room_type,
  neighbourhood_cleansed = l$neighbourhood_cleansed,
  accommodates = suppressWarnings(as.integer(l$accommodates)),
  quoted_nightly_price_twd = ifelse(valid_price, price, NA_real_),
  quote_currency = currency, quote_checkin = l$price_quote_checkin_date,
  quote_checkout = l$price_quote_checkout_date,
  quote_stay_nights = as.integer(as.Date(l$price_quote_checkout_date) - as.Date(l$price_quote_checkin_date)),
  stringsAsFactors = FALSE)
write.csv(d, "data/processed/listings_subset.csv", row.names = FALSE, na = "", fileEncoding = "UTF-8")
month <- substr(c$date, 1, 7)
monthly <- do.call(rbind, lapply(sort(unique(month)), function(m) {
  z <- c[month == m, ]
  data.frame(month = m, calendar_rows = nrow(z), listings = length(unique(z$listing_id)),
    dates = length(unique(z$date)), available_rows = sum(z$available == "t"))
}))
write.csv(monthly, "data/processed/calendar_monthly.csv", row.names = FALSE)
audit <- data.frame(metric = c("listings", "calendar_rows", "calendar_listings", "calendar_start", "calendar_end",
    "duplicate_listing_ids", "duplicate_listing_dates", "invalid_minimum_nights",
    "valid_positive_twd_prices", "missing_or_invalid_or_non_twd_prices", "calendar_has_price",
    "raw_listings_md5", "raw_calendar_md5"),
  value = c(nrow(l), nrow(c), length(unique(c$listing_id)), min(c$date), max(c$date), 0, 0,
    sum(!valid_minimum), sum(valid_price), sum(!valid_price), "price" %in% names(c),
    unname(tools::md5sum(listings_path)), unname(tools::md5sum(calendar_path))))
write.csv(audit, "data/processed/audit.csv", row.names = FALSE)
writeLines(c("Calendar columns:", paste(names(c), collapse = ", "),
             "Calendar contains no date-level prices in this supplied release."), "data/processed/schema_note.txt")
print(audit, row.names = FALSE)
