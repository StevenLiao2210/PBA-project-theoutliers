# Run from repository root: Rscript scripts/make_figures.R
# Uses the committed subset, base R only; no models or significance tests.
dir.create("output/figures", recursive = TRUE, showWarnings = FALSE)
dir.create("output/pdf", recursive = TRUE, showWarnings = FALSE)
d <- read.csv("data/processed/listings_subset.csv", colClasses = c(listing_id = "character"),
              na.strings = "", encoding = "UTF-8")
levels_group <- c("1-2 nights", "3-6 nights", "7+ nights")
d$stay_group <- factor(d$stay_group, levels = levels_group)
counts <- table(d$stay_group)
good <- !is.na(d$stay_group) & is.finite(d$quoted_nightly_price_twd) & d$quoted_nightly_price_twd > 0
p <- d[good, ]
prices <- split(p$quoted_nightly_price_twd, p$stay_group)
med <- vapply(prices, median, numeric(1))
ns <- vapply(prices, length, integer(1))
stats <- data.frame(stay_group = levels_group, listings = as.integer(counts),
  share_percent = 100 * as.integer(counts) / sum(counts), valid_price_n = ns,
  median_twd = med, q1_twd = vapply(prices, quantile, numeric(1), probs = .25),
  q3_twd = vapply(prices, quantile, numeric(1), probs = .75), row.names = NULL)
write.csv(stats, "data/processed/figure_summary.csv", row.names = FALSE)
fmt <- function(x) format(round(x), big.mark = ",", trim = TRUE, scientific = FALSE)
colours <- c("#257F8E", "#4979AF", "#C47A35")
setup <- function() par(mar = c(4.8, 6.0, 1, 1), mgp = c(3.7, .8, 0),
                       family = "sans", col.axis = "#364457", col.lab = "#364457", las = 1)
fig1 <- function() {
  setup()
  at <- barplot(counts, col = colours, border = NA, ylim = c(0, max(counts) * 1.22),
          ylab = "Number of listings", xlab = "Listing-level minimum-stay requirement", axes = FALSE)
  axis(2, at = seq(0, 3500, 500), labels = fmt(seq(0, 3500, 500)), tick = FALSE)
  text(at, as.numeric(counts), labels = paste0(fmt(counts), " (", sprintf("%.1f", stats$share_percent), "%)"),
       pos = 3, cex = .95, col = "#203047")
  box(bty = "n")
}
fig2 <- function() {
  setup()
  boxplot(prices, log = "y", col = colours, border = "#3D4855", outline = TRUE,
    pch = 16, cex = .35, ylab = "Quoted nightly price (TWD, log scale)",
    xlab = "Listing-level minimum-stay requirement", yaxt = "n", xaxt = "n")
  axis(1, at = 1:3, labels = paste0(levels_group, "\n", "n = ", fmt(ns)), tick = FALSE)
  ticks <- c(100, 300, 1000, 3000, 10000, 30000, 100000, 300000, 1000000)
  ticks <- ticks[ticks >= min(p$quoted_nightly_price_twd) & ticks <= max(p$quoted_nightly_price_twd)]
  axis(2, at = ticks, labels = fmt(ticks), tick = FALSE, cex.axis = .85)
  box(bty = "l", col = "#CCD3DB")
}
for (i in 1:2) {
  png(sprintf("output/figures/figure_%d.png", i), width = 1800, height = 1050, res = 200)
  if (i == 1) fig1() else fig2()
  dev.off()
}
n <- nrow(d)
text1 <- sprintf(paste0("Of %s Taipei listings with valid minimum-stay rules, %s (%.1f%%) allow stays of 1-2 nights, ",
  "%s (%.1f%%) require 3-6 nights, and %s (%.1f%%) require at least 7 nights. ",
  "Requirements cluster at 1 night (%s listings), 2 nights (%s), and 30 nights (%s). ",
  "There are %s listings requiring at least 28 nights. These counts suggest meaningful variation ",
  "between short-stay and longer-stay offerings, rather than one minimum-stay rule shared by the whole sample."),
  fmt(sum(counts)), fmt(counts[1]), stats$share_percent[1], fmt(counts[2]), stats$share_percent[2],
  fmt(counts[3]), stats$share_percent[3], fmt(sum(d$minimum_nights == 1, na.rm = TRUE)),
  fmt(sum(d$minimum_nights == 2, na.rm = TRUE)), fmt(sum(d$minimum_nights == 30, na.rm = TRUE)),
  fmt(sum(d$minimum_nights >= 28, na.rm = TRUE)))
why1 <- paste("This variation makes our research question worth asking: do listings targeting longer stays also",
  "have more stable seasonal prices? Each proposed group contains over a thousand listings before price filtering.",
  "A future analysis would compare the same listing across periods and relate its percentage price difference",
  "to these groups, accounting for neighbourhood, room type, and guest capacity. The broad 7+ group combines",
  "weekly and monthly policies; we would check whether separating them changes the descriptive pattern.")
text2 <- sprintf(paste0("Among %s listings with a positive, currency-verified TWD price, median quoted nightly prices ",
  "are TWD %s for 1-2-night requirements, TWD %s for 3-6 nights, and TWD %s for 7+ nights. ",
  "The boxes show the middle 50%% of prices; the distributions overlap and include a long upper tail. ",
  "The logarithmic axis keeps unusually expensive listings visible without compressing the main distributions. ",
  "Of the original %s listings, 499 lack a usable price and one further listing lacks a valid minimum-stay rule. ",
  "No otherwise eligible positive TWD prices are trimmed."),
  fmt(nrow(p)), fmt(med[1]), fmt(med[2]), fmt(med[3]), fmt(n))
why2 <- paste("The spread and overlap motivate a paired comparison and attention to skewness, rather than treating",
  "a difference in price levels as evidence of seasonal stability. These are quotes for differing check-in dates",
  "and stay lengths; prices may incorporate long-stay discounts. This cross-sectional figure therefore does",
  "not measure a December-versus-August premium or establish that minimum stays cause price differences.")
limitation <- paste("Feasibility finding: the supplied calendar has 2,323,955 listing-date rows for 6,367 listings,",
  "covering September 28, 2026 to September 28, 2027, but only listing ID, date, availability, and minimum/maximum nights.",
  "It has no price column. Thus the planned December 2026 versus August 2027 comparison cannot be calculated",
  "from these files. We must obtain date-level advertised prices or revise the question before the main analysis.",
  "Availability is not a price or a reliable measure of bookings; unavailable dates can be host-blocked.")
paragraph <- function(txt, y, size = 10.3, width = 96) {
  lines <- strwrap(txt, width = width)
  text(.08, y, paste(lines, collapse = "\n"), adj = c(0, 1), cex = size/12,
       col = "#364457", family = "sans", lheight = 1.25)
  y - length(lines) * .032 - .035
}
heading <- function(txt, y) text(.08, y, txt, adj = c(0, 1), cex = 1.05, font = 2, col = "#203047")
pdf("output/pdf/group4_data_visualization_milestone.pdf", width = 8.27, height = 11.69,
    family = "Helvetica", title = "Group 4 - Taipei Airbnb: First Look at the Data", useDingbats = FALSE)
for (i in 1:2) {
  layout(matrix(1:4, ncol = 1), heights = c(1.6, 4, 5.5, .59))
  par(oma = c(0,0,0,0), mar = rep(0,4), cex = 1)
  plot(NA, type = "n", xlim = c(0,1), ylim = c(0,1), xaxs = "i", yaxs = "i", axes = FALSE, xlab = "", ylab = "")
  text(.08,.88,"GROUP 4  /  DATA VISUALIZATION MILESTONE", adj = c(0,1), cex = .8, col = "#257F8E", font = 2)
  text(.08,.62,if (i == 1) "Minimum stays in Taipei's Airbnb market" else "Quoted prices vary within every stay group",
       adj = c(0,1), cex = 1.38, font = 2, col = "#203047")
  paragraph(if (i == 1) paste("Research question: Do listings with longer minimum-stay requirements exhibit smaller",
    "seasonal differences in advertised nightly prices?") else
    "Figure 2 is a first look at price levels, not a test of seasonal differences.", .30, size = 10)
  if (i == 1) fig1() else fig2()
  par(mar = rep(0,4))
  plot(NA, type = "n", xlim = c(0,1), ylim = c(0,1), xaxs = "i", yaxs = "i", axes = FALSE, xlab = "", ylab = "")
  heading("What stands out", .975)
  y <- paragraph(if (i == 1) text1 else text2, .92)
  heading("Why it matters for the planned analysis", y)
  y <- paragraph(if (i == 1) why1 else why2, y - .055)
  if (i == 1) {
    heading("Data and scope", y)
    paragraph(paste("One observation per listing. Inside Airbnb's Taipei release is dated September 28, 2026;",
      "individual listings were scraped September 28-29. One of 6,367 listings has a missing minimum-night",
      "requirement and is excluded from Figure 1. Percentages use the 6,366 valid listings. These are descriptive figures."), y - .055, size = 9.5)
  } else {
    heading("An important limit on the original plan", y)
    paragraph(limitation, y - .055, size = 9.5)
  }
  par(mar = rep(0,4))
  plot(NA, type = "n", xlim = c(0,1), ylim = c(0,1), xaxs = "i", yaxs = "i", axes = FALSE, xlab = "", ylab = "")
  text(.08,.85,"Source: Inside Airbnb, Taipei, September 28, 2026 release. CC BY 4.0. Team calculations.", adj = c(0,1), cex = .65, col = "#536274")
  text(.08,.59,"https://insideairbnb.com/get-the-data/  |  https://insideairbnb.com/data-assumptions/", adj = c(0,1), cex = .65, col = "#536274")
  text(.92,.36,paste(i,"/ 2"), adj = c(1,0), cex = .7, col = "#536274")
}
dev.off()
writeLines(c("# Figure 1: Minimum-stay requirements", text1, "", why1, "",
  "# Figure 2: Quoted nightly prices", text2, "", why2, "", "# Feasibility limitation", limitation),
  "output/figure_writeups.md")
print(stats, row.names = FALSE)
