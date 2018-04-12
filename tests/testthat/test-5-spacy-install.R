context("spacy install")
source("utils.R")

test_that("lanugage model download works", {
    skip_on_cran()
    # skip_on_appveyor()
    skip_on_os("solaris")
    skip_if_no_python_or_no_spacy()
    
    expect_message(spacy_download_langmodel("de"), "successfully")
})
