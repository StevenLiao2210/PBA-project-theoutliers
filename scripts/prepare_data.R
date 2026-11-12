# Run from the repository root:
# Rscript scripts/prepare_data.R [directory containing both raw .csv.gz files]
# The QMD remains the single source of the R data-preparation logic.
args <- commandArgs(trailingOnly = TRUE)
params <- list(raw_dir = if (length(args)) args[1] else "data/raw",
               refresh_data = TRUE, download_raw = FALSE)
lines <- readLines("AirBnB_Price_Difference.qmd", encoding = "UTF-8")
for (label in c("setup", "prepare-real-data")) {
  first <- match(paste0("#| label: ", label), lines)
  if (is.na(first)) stop("Missing QMD chunk: ", label)
  end <- which(seq_along(lines) > first & lines == "```")[1]
  if (is.na(end)) stop("Unclosed QMD chunk: ", label)
  code <- lines[seq.int(first + 1L, end - 1L)]
  eval(parse(text = code), envir = .GlobalEnv)
}
print(read.csv("data/processed/audit.csv"), row.names = FALSE)
