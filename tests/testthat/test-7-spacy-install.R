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

    expect_error(spacy_install(envname = "test_wrong_version", version = "1.10.1a",
                                 prompt = FALSE),
                   "major.minor.patch specification")
    # expect_message(spacy_install(envname = "test_specific_version", version = "2.0.1",
    #                              prompt = FALSE),
    #                "Installation complete")
    expect_message(spacy_install(envname = "test_specific_version_v1", version = "1.10.1",
                                 prompt = FALSE),
                   "Installation complete")
})


test_that("spacy_upgrade works", {
    skip_on_cran()
    # skip_on_appveyor()
    skip_on_os("solaris")
    skip_if_no_python_or_no_spacy()

    expect_message(spacy_upgrade(prompt = FALSE),
                   "your spaCy is up-to-date")
    # expect_message(spacy_upgrade(envname = "test_specific_version",
    #                              prompt = FALSE),
    #                "Successfully upgraded")
    expect_message(spacy_upgrade(envname = "test_specific_version_v1",
                                 prompt = FALSE),
                   "Successfully upgraded")

})


test_that("spacy_uninstall works", {
    skip_on_cran()
    # skip_on_appveyor()
    skip_on_os("solaris")
    skip_if_no_python_or_no_spacy()

    # expect_output(spacy_uninstall(envname = "test_specific_version",
    #                                prompt = FALSE),
    #                "Uninstallation complete")
    expect_output(spacy_uninstall(envname = "test_specific_version_v1",
                                  prompt = FALSE),
                  "Uninstallation complete")
})


test_that("spacy_install_virtualenv works", {
    skip("not tested for the time being")
    # skip_on_appveyor()
    skip_on_os("solaris")
    skip_on_os("mac") # this test is travis only
    skip_if_no_python_or_no_spacy()

    expect_message(spacy_install_virtualenv(prompt = FALSE,
                                            python = paste0(path.expand("~"),
                                                            "/miniconda/bin/python")),
                   "Installation complete")
})
