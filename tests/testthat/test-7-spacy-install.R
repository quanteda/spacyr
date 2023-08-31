context("spacy install")
source("utils.R")

tmp <- tempfile(pattern = "test-env")

test_that("lanugage model download works", {
  skip_on_cran()
  skip_on_appveyor()
  skip_on_os("solaris")
  try_spacy_initialize()
  
  expect_warning({
    spacy_download_langmodel("de_core_news_sm")
    spacy_download_langmodel("de_core_news_sm")
  }, "Skipping installation")
})


test_that("spacy_install worked", {
  skip_on_cran()
  skip_on_appveyor()
  skip_on_os("solaris")
  
  expect_warning({
    spacy_install()
    spacy_install()
  }, "Skipping installation")
})



test_that("spacy_install specific version of spacy works", {
  skip_on_cran()
  skip_on_appveyor()
  skip_on_os("solaris")
  
  expect_error(spacy_install(version = "1.10.1a"),
               "spacy1.10.1a")
  
  Sys.setenv("SPACY_PYTHON" = tmp)
  
  expect_message(spacy_install(version = "2.3.9"),
                 "Installation of spaCy version 2.3.9 complete.")
  
  on.exit(Sys.unsetenv("SPACY_PYTHON"), add = TRUE, after = FALSE)
})


test_that("spacy_upgrade works", {
  skip_on_cran()
  skip_on_appveyor()
  skip_on_os("solaris")
  
  Sys.setenv("SPACY_PYTHON" = tmp)
  
  expect_message(spacy_upgrade(),
                 "Upgraded to spaCy version")
  
  on.exit(Sys.unsetenv("SPACY_PYTHON"), add = TRUE, after = FALSE)
})


test_that("spacy_uninstall works", {
  skip_on_cran()
  skip_on_appveyor()
  skip_on_os("solaris")
  
  Sys.setenv("SPACY_PYTHON" = tmp)
  
  expect_message(spacy_uninstall(confirm = FALSE),
                 "Deinstallation complete")
  
  on.exit(Sys.unsetenv("SPACY_PYTHON"), add = TRUE, after = FALSE)
})

