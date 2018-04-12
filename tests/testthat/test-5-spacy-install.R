context("spacy install")
source("utils.R")

test_that("lanugage model download works", {
    skip_on_cran()
    # skip_on_appveyor()
    skip_on_os("solaris")
    skip_if_no_python_or_no_spacy()
    
    expect_message(spacy_download_langmodel("de"), "successfully")
})


test_that("spacy_install works", {
    skip_on_cran()
    # skip_on_appveyor()
    skip_on_os("solaris")
    skip_if_no_python_or_no_spacy()
    
    expect_message(spacy_install(envname = "test_latest"), "Installation complete")
})

test_that("spacy_install spacy version 1 works", {
    skip_on_cran()
    # skip_on_appveyor()
    skip_on_os("solaris")
    skip_if_no_python_or_no_spacy()
    
    expect_message(spacy_install(envname = "test_v1", version = "latest_v1"), 
                   "Installation complete")
})

test_that("spacy_uninstall works", {
    skip_on_cran()
    # skip_on_appveyor()
    skip_on_os("solaris")
    skip_if_no_python_or_no_spacy()
    
    expect_message(spacy_uninstall(envname = "test_latest"), 
                   "Uninstallation complete")
})
