context("test spacy_initialize")
source("utils.R")

test_that("spacy_initialize() with non-existent python (#49)", {
    skip_on_os("solaris")
    expect_error(
        spacy_initialize(python_executable = "/usr/local/bin/notpython", check_env = FALSE,
                         refresh_settings = TRUE),
        "notpython is not a python executable"
    )
})

test_that("spacy_initialize works as expected", {
    skip_on_cran()
    skip_on_os("solaris")
    skip_if_no_python_or_no_spacy()

    options(spacy_prompt = FALSE)
    expect_message(spacy_initialize(refresh_settings = TRUE),
                   "successfully")

    spacy_finalize()
})

test_that("find_spacy() works", {
    skip_on_os("solaris")
    skip_on_cran()
    skip_on_os("windows")

    expect_warning(
        find_spacy(ask = FALSE)
    )
})
