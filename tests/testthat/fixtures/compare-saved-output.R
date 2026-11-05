# List the cases whose accepted saved output (saved-output.rds) differs from
# the spacyr 1.4.0 baseline (saved-output-1.4.0.rds), or from another saved
# output file such as a copy made before recording again. Needs no Python.
#
#   Rscript tests/testthat/fixtures/compare-saved-output.R             # baseline
#   Rscript tests/testthat/fixtures/compare-saved-output.R OLD.rds     # OLD.rds
#
# Differences are expected for the intended changes listed in NEWS.md. When
# the accepted output was recorded with other versions of spaCy or the
# language models than the baseline, differences can also come from those.

dir <- file.path("tests", "testthat", "fixtures")
accepted <- readRDS(file.path(dir, "saved-output.rds"))
args <- commandArgs(trailingOnly = TRUE)
baseline <- readRDS(if (length(args)) args[1] else file.path(dir, "saved-output-1.4.0.rds"))

versions <- function(meta) {
  paste0("spaCy ", meta$spacy_version, ", ",
         paste(names(meta$models), meta$models, collapse = ", "))
}
label <- function(meta) {
  if (is.null(meta$revision)) paste("spacyr", meta$spacyr_version) else meta$revision
}
cat("compared with:", label(baseline$meta), "with", versions(baseline$meta), "\n")
cat("accepted:", label(accepted$meta), "with", versions(accepted$meta), "\n")
for (u in accepted$meta$updates) {
  cat("  updated from", u$revision, "on", u$recorded, ":", length(u$cases), "cases\n")
}

for (group in c("cases", "helper_cases")) {
  ids <- union(names(baseline[[group]]), names(accepted[[group]]))
  status <- vapply(ids, function(id) {
    if (is.null(baseline[[group]][[id]])) return("new")
    if (is.null(accepted[[group]][[id]])) return("removed")
    if (identical(baseline[[group]][[id]], accepted[[group]][[id]])) "same" else "changed"
  }, character(1))
  cat("\n", group, ": ", sum(status == "same"), " same", sep = "")
  for (s in c("changed", "new", "removed")) {
    if (any(status == s)) cat("\n", s, ":\n  ", paste(ids[status == s], collapse = "\n  "), sep = "")
  }
  cat("\n")
}
