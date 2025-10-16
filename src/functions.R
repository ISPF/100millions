library(data.table)
library(dplyr)
library(arrow)
set.seed(42)  # reproductibilité
log_file <- "generation_population.log"

format_number <- function(x) {
  if (x >= 1e9) {
    paste0(round(x / 1e9, 1), "B")
  } else if (x >= 1e6) {
    paste0(round(x / 1e6, 1), "M")
  } else if (x >= 1e3) {
    paste0(round(x / 1e3, 1), "K")
  } else {
    as.character(x)
  }
}

log_msg <- function(...) {
  msg <- paste(format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"), "-", sprintf(...))
  cat(msg, "\n", file = log_file, append = TRUE)
  cat(msg, "\n")  # aussi à l'écran
}

csv_path <- sprintf("output/population_%s.csv", format_number(N))
pq_path <- sprintf("output/population_%s.parquet", format_number(N))
pq_path2 <- sprintf("output/population2-age_%s.parquet", format_number(N))
