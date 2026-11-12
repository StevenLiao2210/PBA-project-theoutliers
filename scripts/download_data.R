# Optional: download the exact public snapshot; large source files stay ignored.
dir.create("data/raw", recursive = TRUE, showWarnings = FALSE)
base <- "https://data.insideairbnb.com/taiwan/northern-taiwan/taipei/2026-09-28/data/"
for (name in c("listings.csv.gz", "calendar.csv.gz")) {
  target <- file.path("data/raw", name)
  if (!file.exists(target)) download.file(paste0(base, name), target, mode = "wb")
}
