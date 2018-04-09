context("test spacy_initialize")

test_that("spacy_initialize() with non-existent python (#49)", {
    skip_on_os("solaris")
    expect_error(
        spacy_initialize(python_executable = "/usr/local/bin/notpython", check_env = FALSE),
        "notpython is not a python executable"
    )
})
