# Record the accepted saved output used by tests/testthat/test-9-saved-output.R
# (fixtures/saved-output.rds). The 1.4.0 baseline, saved-output-1.4.0.rds, is
# never written. See README.md in this folder for when and how to record.
#
# Run from the package root, with the version of spacyr to record installed:
#
#   Rscript tests/testthat/fixtures/record-saved-output.R --revision=REV          # all cases
#   Rscript tests/testthat/fixtures/record-saved-output.R --revision=REV ID [ID…] # some cases
#
# REV names the code that is installed: a tag or commit of an accepted
# revision on main, or a pull request for an intended change. It is stored in
# the saved output's metadata. Each ID is a case id or a regular expression
# matching case ids; recording only some cases keeps the others as they are.
# The entity_*() and nounphrase_*() cases are always recomputed from the saved
# spacy_parse() output.

suppressPackageStartupMessages({
  library("spacyr")
  library("testthat")
})
source(file.path("tests", "testthat", "helper-saved-output.R"))
outfile <- file.path("tests", "testthat", "fixtures", "saved-output.rds")

args <- commandArgs(trailingOnly = TRUE)
revision <- sub("^--revision=", "", grep("^--revision=", args, value = TRUE))
patterns <- grep("^--revision=", args, value = TRUE, invert = TRUE)
if (length(revision) != 1 || !nzchar(revision)) {
  stop("name the installed revision with --revision=REV, e.g. --revision=v1.4 ",
       "or --revision=main@1a2b3c4")
}
if (!requireNamespace("quanteda", quietly = TRUE)) {
  stop("quanteda is needed to record the corpus input cases")
}

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

models <- unique(vapply(cases[selected], `[[`, "", "model"))
for (model in models) {
  try(spacy_finalize(), silent = TRUE)
  spacy_initialize(model = model)
  for (id in selected[vapply(cases[selected], `[[`, "", "model") == model]) {
    message("recording ", id)
    saved$cases[[id]] <- run_saved_output_case(cases[[id]])
  }
}

meta <- list(
  revision = revision,
  spacyr_version = as.character(utils::packageVersion("spacyr")),
  spacy_version = python_package_version("spacy"),
  models = vapply(unique(saved_output_models()), python_package_version, ""),
  python_version = as.character(reticulate::py_config()$version),
  r_version = R.version.string,
  recorded = format(Sys.time(), "%Y-%m-%d")
)
spacy_finalize()

if (length(patterns)) {
  # the cases that were not recorded again keep the versions they were
  # recorded with, so the versions must not change
  same <- identical(meta$spacy_version, saved$meta$spacy_version) &&
    identical(meta$models[names(saved$meta$models)], saved$meta$models)
  if (!same) {
    stop("spaCy or a language model differs from the saved output's versions; ",
         "record all cases from an accepted revision instead (see README.md)")
  }
  saved$meta$updates <- c(saved$meta$updates, list(c(meta, list(cases = selected))))
} else {
  # keep a record of the metadata of the output being replaced
  if (file.exists(outfile)) {
    old <- readRDS(outfile)$meta
    meta$history <- c(old$history, list(old[setdiff(names(old), "history")]))
  }
  saved$meta <- meta
}

helper_cases <- saved_output_helper_cases()
saved$helper_cases <- lapply(helper_cases, run_saved_output_helper_case,
                             parses = saved$cases)

# keep the cases in the order in which they are defined
saved$cases <- saved$cases[intersect(names(cases), names(saved$cases))]

saveRDS(saved, outfile, version = 2)
message("saved ", length(saved$cases), " cases and ", length(saved$helper_cases),
        " helper cases from ", revision, " to ", outfile)
