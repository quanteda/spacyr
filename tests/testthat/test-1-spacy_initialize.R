context("test spacy_initialize")
source("utils.R")

test_that("spacy_initialize works as expected", {
  skip_on_cran()
  skip_on_os("solaris")
  suppressWarnings(spacy_install()) # is skipped if installed anyway
  
  expect_message(spacy_initialize(),
                 "successfully")

  expect_no_condition(spacy_finalize())
  
  expect_error(spacy_finalize(),
               "Nothing to finalize")
})
