context("saved output")
source("utils.R")

# Compare the output of the main functions with the output saved from
# spacyr 1.4.0 (see helper-saved-output.R and fixtures/README.md). A difference
# is a bug, unless the change is intended: then record the new output with
# fixtures/record-saved-output.R and describe the change in NEWS.md.

saved <- readRDS(saved_output_file())

test_that("every defined case has saved output", {
  expect_setequal(names(saved$cases), names(saved_output_cases()))
  expect_setequal(names(saved$helper_cases), names(saved_output_helper_cases()))
})

# entity_*() and nounphrase_*() take a saved parse as input, so need no Python
for (case in saved_output_helper_cases()) {
  local({
    case <- case
    test_that(paste("saved output:", case$id), {
      expect_identical(run_saved_output_helper_case(case, saved$cases),
                       saved$helper_cases[[case$id]])
    })
  })
}

saved_model <- new.env()
use_saved_output_model <- function(model) {
  skip_on_cran()
  skip_on_os("solaris")
  skip_if_not(spacy_installed(model), paste(model, "is not installed"))
  if (!identical(saved_model$current, model) ||
      is.null(getOption("spacy_initialized"))) {
    try(spacy_finalize(), silent = TRUE)
    saved_model$current <- NULL
    suppressMessages(spacy_initialize(model = model))
    saved_model$current <- model
  }
  installed <- python_package_version(model)
  skip_if_not(identical(installed, saved$meta$models[[model]]),
              paste0("output was saved with ", model, " ", saved$meta$models[[model]],
                     ", but ", installed, " is installed"))
}

for (case in saved_output_cases()) {
  local({
    case <- case
    test_that(paste("saved output:", case$id), {
      if (case$input_type == "corpus") skip_if_not_installed("quanteda")
      use_saved_output_model(case$model)
      expect_identical(run_saved_output_case(case), saved$cases[[case$id]])
    })
  })
}

test_that("finalize after the saved output tests", {
  skip_on_cran()
  skip_on_os("solaris")
  if (!is.null(getOption("spacy_initialized"))) spacy_finalize()
  succeed()
})
