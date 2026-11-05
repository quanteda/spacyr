# Record the saved output used by tests/testthat/test-9-saved-output.R.
#
# Run from the package root, with the version of spacyr to record installed:
#
#   Rscript tests/testthat/fixtures/record-saved-output.R           # all cases
#   Rscript tests/testthat/fixtures/record-saved-output.R ID [ID…]  # some cases
#
# where each ID is a case id or a regular expression matching case ids. Recording
# only some cases keeps the others as they are, so an intended change can be
# recorded without overwriting the 1.4.0 output of the other cases. The
# entity_*() and nounphrase_*() cases are always recomputed from the saved
# spacy_parse() output. See README.md in this folder.

suppressPackageStartupMessages({
  library("spacyr")
  library("testthat")
})
source(file.path("tests", "testthat", "helper-saved-output.R"))
outfile <- file.path("tests", "testthat", "fixtures", "saved-output.rds")

patterns <- commandArgs(trailingOnly = TRUE)
cases <- saved_output_cases()
if (length(patterns)) {
  selected <- names(cases)[vapply(names(cases), function(id) {
    any(id == patterns) || any(vapply(patterns, grepl, logical(1), x = id))
  }, logical(1))]
  if (!length(selected)) stop("no case matches ", paste(patterns, collapse = ", "))
  saved <- readRDS(outfile)
} else {
  selected <- names(cases)
  saved <- list(cases = list())
}
if (!requireNamespace("quanteda", quietly = TRUE)) {
  stop("quanteda is needed to record the corpus input cases")
}

models <- unique(vapply(cases[selected], `[[`, "", "model"))
for (model in models) {
  try(spacy_finalize(), silent = TRUE)
  spacy_initialize(model = model)
  for (id in selected[vapply(cases[selected], `[[`, "", "model") == model]) {
    message("recording ", id)
    saved$cases[[id]] <- run_saved_output_case(cases[[id]])
  }
}
spacy_finalize()

helper_cases <- saved_output_helper_cases()
saved$helper_cases <- lapply(helper_cases, run_saved_output_helper_case,
                             parses = saved$cases)

# keep the cases in the order in which they are defined
saved$cases <- saved$cases[intersect(names(cases), names(saved$cases))]

meta <- list(
  spacyr_version = as.character(utils::packageVersion("spacyr")),
  spacy_version = python_package_version("spacy"),
  models = vapply(unique(saved_output_models()), python_package_version, ""),
  python_version = reticulate::py_config()$version,
  r_version = R.version.string,
  recorded = format(Sys.time(), "%Y-%m-%d")
)
if (length(patterns)) {
  saved$meta$updates <- c(saved$meta$updates,
                          list(c(meta, list(cases = selected))))
} else {
  saved$meta <- meta
}

saveRDS(saved, outfile, version = 2)
message("saved ", length(saved$cases), " cases and ", length(saved$helper_cases),
        " helper cases to ", outfile)
