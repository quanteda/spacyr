context("installation helpers")

test_that("python_satisfies() handles PyPI requirement strings", {
  req <- "<3.16,>=3.10"
  expect_false(spacyr:::python_satisfies("3.9.6", req))
  expect_true(spacyr:::python_satisfies("3.10.0", req))
  expect_true(spacyr:::python_satisfies("3.12.10", req))
  expect_true(spacyr:::python_satisfies("3.15.2", req))
  expect_false(spacyr:::python_satisfies("3.16.0", req))
  expect_true(spacyr:::python_satisfies("3.12.1", ">=2.7,!=3.0.*,!=3.1.*"))
  expect_false(spacyr:::python_satisfies("3.1.2", ">=2.7,!=3.0.*,!=3.1.*"))
  expect_false(spacyr:::python_satisfies("3.11.0", "~=3.10.0"))
  expect_true(spacyr:::python_satisfies("3.12.1", ""))
})

test_that("spaCy metadata is looked up for unpinned versions and exact pins", {
  expect_identical(spacyr:::spacy_pkg_spec("latest"), "spacy")
  expect_identical(spacyr:::spacy_pkg_spec("3.8.13"), "spacy==3.8.13")
  expect_identical(spacyr:::spacy_pkg_spec("v3.8.13"), "spacy==3.8.13")
  expect_identical(spacyr:::spacy_pkg_spec("apple"), "spacy[apple]")
  expect_identical(spacyr:::spacy_pkg_spec(">=3.7"), "spacy>=3.7")
  expect_null(spacyr:::spacy_pkg_version(">=3.8.13,<3.8.18"))
  expect_identical(spacyr:::spacy_pkg_version("==3.8.13"), "3.8.13")
  expect_identical(spacyr:::spacy_pypi_url("apple"),
                   "https://pypi.org/pypi/spacy/json")
  expect_identical(spacyr:::spacy_pypi_url("[apple]==3.8.13"),
                   "https://pypi.org/pypi/spacy/3.8.13/json")
  expect_null(spacyr:::spacy_pypi_url(">=3.8.13,<3.8.18"))
  expect_null(spacyr:::spacy_pypi_url("==3.8.*"))
})

test_that("the fallback installs a compatible stable Python release", {
  local_mocked_bindings(
    install_python = function(version = "3.9:latest", list = FALSE) {
      if (list) return(c("3.9.25", "3.12.9", "3.12.10", "3.13.0rc1", "3.14.0"))
      version
    },
    .package = "reticulate"
  )
  expect_identical(spacyr:::install_spacy_python(">=3.10,<3.14"), "3.12.10")
  expect_error(spacyr:::install_spacy_python(">=3.15"), "No Python version available")
})

test_that("check_env_python() stops for an unsupported Python", {
  local_mocked_bindings(virtualenv_python_version = function(envname) "3.9.6",
                        .package = "spacyr")
  expect_error(spacyr:::check_env_python("r-spacyr", "<3.16,>=3.10"),
               "uses Python 3.9.6.*spacy_uninstall")
  expect_true(spacyr:::check_env_python("r-spacyr", NULL))

  local_mocked_bindings(virtualenv_python_version = function(envname) "3.12.1",
                        .package = "spacyr")
  expect_true(spacyr:::check_env_python("r-spacyr", "<3.16,>=3.10"))

  local_mocked_bindings(virtualenv_python_version = function(envname) NA_character_,
                        .package = "spacyr")
  expect_true(spacyr:::check_env_python("r-spacyr", "<3.16,>=3.10"))
})

test_that("spacy_installed() is FALSE for a missing environment", {
  old <- Sys.getenv(c("RETICULATE_PYTHON", "SPACY_PYTHON"), unset = NA)
  on.exit({
    for (v in names(old)) {
      if (is.na(old[[v]])) Sys.unsetenv(v) else do.call(Sys.setenv, as.list(old[v]))
    }
  })
  Sys.unsetenv("RETICULATE_PYTHON")
  Sys.setenv(SPACY_PYTHON = file.path(tempdir(), "no-such-spacyr-env"))
  expect_false(spacy_installed())
  expect_false(spacy_installed("en_core_web_sm"))
})

test_that("spacy_installed() respects the Python already bound to reticulate", {
  old <- Sys.getenv("RETICULATE_PYTHON", unset = NA)
  on.exit(if (is.na(old)) Sys.unsetenv("RETICULATE_PYTHON")
          else Sys.setenv(RETICULATE_PYTHON = old))
  Sys.unsetenv("RETICULATE_PYTHON")

  configured_env <- file.path(tempdir(), "spacy-env")
  active_env <- file.path(tempdir(), "other-env")
  local_mocked_bindings(
    virtualenv_exists = function(envname) TRUE,
    virtualenv_python = function(envname) file.path(configured_env, "bin", "python"),
    py_available = function(initialize) {
      expect_false(initialize)
      TRUE
    },
    py_config = function() list(prefix = active_env),
    .package = "reticulate"
  )
  local_mocked_bindings(py_check_installed = function(x) TRUE, .package = "spacyr")

  expect_false(spacy_installed())
  active_env <- configured_env
  expect_true(spacy_installed())
})
