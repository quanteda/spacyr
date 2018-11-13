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
    
    expect_message(spacy_install(envname = "test_latest", prompt = FALSE), 
                   "Installation complete")
})

test_that("spacy_install specific version of spacy works", {
    skip_on_cran()
    # skip_on_appveyor()
    skip_on_os("solaris")
    skip_if_no_python_or_no_spacy()
    
    expect_message(spacy_install(envname = "test_specific_version", version = "1.10.1", 
                                 prompt = FALSE), 
                   "Installation complete")
})

# # Comment out for the time being
# test_that("spacy_install_virtualenv works", {
#     skip_on_cran()
#     # skip_on_appveyor()
#     skip_on_os("solaris")
#     skip_on_os("mac") # this test is travis only
#     skip_if_no_python_or_no_spacy()
# 
#     expect_message(spacy_install_virtualenv(prompt = FALSE, 
#                                             python = paste0(path.expand("~"), 
#                                                             "/miniconda/bin/python")),
#                    "Installation complete")
# })
