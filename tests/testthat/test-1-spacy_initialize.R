context("test spacy_initialize")
source("utils.R")

test_that("spacy_initialize works as expected", {
  skip_on_cran()
  skip_on_os("solaris")
  spacy_install() # is skipped if installed anyway
  
  expect_message(spacy_initialize(),
                 "successfully")
  
 
  expect_error(spacy_finalize(),
               "Nothing to finalize")
})
