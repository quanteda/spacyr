#' Install spaCy in conda or virtualenv environment
#'
#' @description Install spaCy in a self-contained environment, including
#'   specified language models.
#' @param version character; spaCy version to install (see details).
#' @param lang_models character; language models to be installed. Defaults
#'   `en_core_web_sm` (English model). A vector of multiple model names can
#'   be used (e.g. `c("en_core_web_sm", "de_core_news_sm")`). A list of
#'   available language models and their
#'   names is available from the [spaCy
#'   language models](https://spacy.io/usage/models) page.
#' @param ask logical; ask whether to proceed during the installation. By
#'   default, questions are only asked in interactive sessions.
#' @param force ignore if spaCy/the lang_models is already present and install
#'   it anyway.
#' @param ... not used.
#' @seealso [spacy_download_langmodel()]
#'
#' @details The function checks whether a suitable installation of Python is
#'   present on the system and installs one via
#'   [reticulate::install_python()] otherwise. "Suitable" means a version of
#'   Python supported by the spaCy release being installed, as declared on
#'   PyPI (if PyPI cannot be reached, any Python found is used). It then
#'   creates a virtual environment with the necessary packages in the default
#'   location chosen by [reticulate::virtualenv_root()].
#'   For a spaCy version range, pip selects a release compatible with the
#'   environment's Python.
#'
#'   An existing environment keeps the Python version it was created with. If
#'   that version is not supported by the spaCy release being installed,
#'   `spacy_install()` stops with an error; run [spacy_uninstall()] and then
#'   `spacy_install()` to recreate the environment with a suitable Python.
#'
#'   If you want to install a different version of Python than the default, you
#'   should call [reticulate::install_python()] directly. If you want
#'   to create or use a different virtual environment, you can use, e.g.,
#'   `Sys.setenv(SPACY_PYTHON = "path/to/directory")`.
#'
#'
#' @examples
#' \dontrun{
#' # install the latest version of spaCy
#' spacy_install()
#'
#' # update spaCy
#' spacy_install(force = TRUE)
#'
#' # install an older version
#' spacy_install(version = "3.1.0")
#'
#' # install with GPU enabled
#' spacy_install(version = "cuda-autodetect")
#'
#' # install on Apple ARM processors
#' spacy_install(version = "apple")
#'
#' # install an old custom version
#' spacy_install(version = "[cuda-autodetect]==3.2.0")
#'
#' # install several models with spaCy
#' spacy_install(lang_models = c("en_core_web_sm", "de_core_news_sm"))
#'
#'
#' # install spaCy to an existing virtual environment
#' Sys.setenv(RETICULATE_PYTHON = "path/to/python")
#' spacy_install()
#' }
#'
#' @export
spacy_install <- function(version = "latest",
                          lang_models = "en_core_web_sm",
                          ask = interactive(),
                          force = FALSE,
                          ...) {
  
  if (length(list(...)) > 0) 
    warning("spacyr 1.3 removed a number of arguments to simplify this function.")

  envname <- Sys.getenv("SPACY_PYTHON", unset = "r-spacyr")
  spacy_pkg <- spacy_pkg_spec(version)
  custom_python <- nzchar(Sys.getenv("RETICULATE_PYTHON"))
  create_env <- !custom_python && !reticulate::virtualenv_exists(envname)
  python_req <- if (create_env) spacy_python_requirement(version)

  if (custom_python) {
    message("You provided a custom RETICULATE_PYTHON, so we assume you know what you ",
            "are doing managing your virtual environments. Good luck!")
  } else if (create_env) {
    # this has turned out to be the easiest way to test if a suitable Python 
    # version is present. All other methods load Python, which creates
    # some headache.
    t <- try(reticulate::virtualenv_create(envname, version = python_req), silent = TRUE)
    if (methods::is(t, "try-error")) {
      permission <- TRUE
      if (ask) {
        permission <- utils::askYesNo(paste0(
          "No suitable Python installation was found on your system",
          if (!is.null(python_req)) paste0(" (spaCy requires Python ", python_req, ")"),
          ". Do you want to run `reticulate::install_python()` to install it?"
        ))
      }

      if (permission) {
        python <- install_spacy_python(python_req)
        reticulate::virtualenv_create(envname, python = python)
      } else {
        stop("Aborted by user")
      }
    }
  }

  # installation addresses the environment by name, so only bind the session to
  # it if Python is not running yet: once started, reticulate cannot switch
  # interpreters and use_virtualenv() errors for a different environment
  if (!custom_python && !reticulate::py_available(initialize = FALSE)) {
    reticulate::use_virtualenv(envname)
  }
  
  if (py_check_installed(spacy_pkg) & !force) {
    warning("Skipping installation. Use `force` to force installation or update. ",
            "Or use `spacy_download_langmodel()` if you just want to install a model.")
    return(invisible(NULL))
  }

  # an existing environment keeps its Python, which may not suit this spaCy
  if (!custom_python) {
    if (!create_env) python_req <- spacy_python_requirement(version)
    check_env_python(envname, python_req)
  }
  
  reticulate::py_install(spacy_pkg, envname = envname)
  spacy_download_langmodel(lang_models)
  
  message("Installation of spaCy version ", 
          py_check_version("spacy", envname = envname), 
          " complete.")
  
  invisible(NULL)
}


# pip requirement for the spaCy version requested in spacy_install()
spacy_pkg_spec <- function(version) {
  if (identical(version, "latest")) {
    "spacy"
  } else if (grepl("^v*[1-9]\\.\\d{1,2}\\.\\d{1,2}$", version)) {
    paste0("spacy==", sub("^v+", "", version))
  } else if (grepl("^[A-z,-]+$", version)) {
    paste0("spacy[", version, "]")
  } else {
    paste0("spacy", version)
  }
}

# Extract a single pinned release from the version argument.
spacy_pkg_version <- function(version) {
  spacy_pkg <- spacy_pkg_spec(version)
  exact_pin <- "^spacy(\\[[^]]+\\])?==\\s*([0-9]+(\\.[0-9]+)*)$"
  if (grepl(exact_pin, spacy_pkg)) sub(exact_pin, "\\2", spacy_pkg) else NULL
}

# Use PyPI metadata for a single release. Leave version ranges to pip.
spacy_pypi_url <- function(version) {
  if (grepl("^spacy(\\[[^]]+\\])?$", spacy_pkg_spec(version)))
    return("https://pypi.org/pypi/spacy/json")

  pin <- spacy_pkg_version(version)
  if (!is.null(pin)) paste0("https://pypi.org/pypi/spacy/", pin, "/json")
}

spacy_python_requirement <- function(version) {
  url <- spacy_pypi_url(version)
  if (is.null(url)) return(NULL)
  json <- tryCatch(
    suppressWarnings(paste(readLines(url, warn = FALSE), collapse = "")),
    error = function(e) NULL
  )
  if (is.null(json)) return(NULL)
  # the first match is the release's own requirement in the "info" section
  req <- regmatches(json, regexpr('"requires_python":\\s*"[^"]*"', json))
  if (!length(req)) return(NULL)
  req <- sub('^"requires_python":\\s*"([^"]*)"$', "\\1", req)
  if (nzchar(req)) req else NULL
}

# does a Python version satisfy a requirement such as "<3.16,>=3.10"?
# specifiers that cannot be parsed are ignored
python_satisfies <- function(python_version, requirement) {
  v <- numeric_version(python_version)
  for (spec in trimws(strsplit(requirement, ",", fixed = TRUE)[[1]])) {
    if (grepl("^(==|!=)\\s*[0-9]+(\\.[0-9]+)*\\.\\*$", spec)) {
      prefix <- sub("^(==|!=)\\s*(.*)\\*$", "\\2", spec)
      matches <- startsWith(paste0(python_version, "."), prefix)
      if (matches != startsWith(spec, "==")) return(FALSE)
      next
    }
    m <- regmatches(spec, regexec("^(>=|<=|==|!=|~=|>|<)\\s*([0-9]+(\\.[0-9]+)*)$", spec))[[1]]
    if (!length(m)) next
    target <- numeric_version(m[3])
    ok <- switch(m[2],
                 ">=" = v >= target, "<=" = v <= target,
                 ">" = v > target, "<" = v < target,
                 "==" = v == target, "!=" = v != target,
                 "~=" = v >= target && startsWith(paste0(python_version, "."),
                                                   sub("[0-9]+$", "", m[3])))
    if (!ok) return(FALSE)
  }
  TRUE
}

# reticulate's default Python can be outside spaCy's supported range
install_spacy_python <- function(requirement) {
  if (is.null(requirement)) return(reticulate::install_python())

  versions <- reticulate::install_python(list = TRUE)
  versions <- grep("^[0-9]+\\.[0-9]+\\.[0-9]+$", versions, value = TRUE)
  compatible <- vapply(versions, python_satisfies, logical(1), requirement = requirement)
  versions <- versions[compatible]
  if (!length(versions))
    stop("No Python version available through reticulate satisfies ", requirement,
         ". Install a compatible Python and try again.", call. = FALSE)

  reticulate::install_python(version = as.character(max(numeric_version(versions))))
}

# stop if the environment's Python does not satisfy spaCy's requirement
check_env_python <- function(envname, python_req) {
  if (is.null(python_req)) return(invisible(TRUE))
  env_python <- virtualenv_python_version(envname)
  if (!is.na(env_python) && !python_satisfies(env_python, python_req)) {
    stop("The environment '", envname, "' uses Python ", env_python,
         ", but this version of spaCy requires Python ", python_req, ". ",
         "Run `spacy_uninstall()` and then `spacy_install()` to recreate the ",
         "environment with a suitable version of Python.", call. = FALSE)
  }
  invisible(TRUE)
}

# Python version of a virtual environment, without initialising Python
virtualenv_python_version <- function(envname) {
  out <- tryCatch(
    suppressWarnings(system2(reticulate::virtualenv_python(envname), "-EV",
                             stdout = TRUE, stderr = TRUE)),
    error = function(e) character()
  )
  out <- out[grepl("^Python [0-9]", out)]
  if (!length(out)) return(NA_character_)
  sub("^Python ([0-9.]+).*$", "\\1", out[1])
}


#' Shorthand function to upgrade spaCy
#' 
#' Upgrade spaCy (to a specific version).
#' 
#' @param ... passed on to [spacy_install()]
#' 
#' @inherit spacy_install
#' @export
spacy_upgrade <- function(version = "latest",
                          lang_models = NULL,
                          ask = interactive(),
                          force = TRUE,
                          ...) {

  spacy_install(version = version,
                lang_models = lang_models,
                ask = ask,
                force = force,
                ...)
  
  message("Upgraded to spaCy version ", py_check_version("spacy", envname = Sys.getenv("SPACY_PYTHON", unset = "r-spacyr")), ".")
  
}


#' @title Install spaCy to a virtual environment
#' 
#' @description
#'  Deprecated. `spacy_install` now installs to a virtual environment by default.
#'  
#' @param ... not used
#' 
#' @export
spacy_install_virtualenv <- function(...) {
  
  .Deprecated(msg = "`spacy_install` now installs to a virtual environment by default")
  
}


#' Uninstall the spaCy environment
#'
#' Removes the virtual environment created by spacy_install()
#' 
#' @param confirm logical; confirm before uninstalling spaCy?
#' 
#' @export
spacy_uninstall <- function(confirm = interactive()) {
  
  reticulate::virtualenv_remove(Sys.getenv("SPACY_PYTHON", unset = "r-spacyr"),
                                confirm = confirm)
  
  message("Deinstallation complete.")
  invisible(NULL)
}


#' Check whether spaCy is installed
#'
#' Checks, without starting Python, whether spaCy (and optionally one or more
#' language models) is installed in the environment that [spacy_initialize()]
#' will use: the one set by `RETICULATE_PYTHON` if set, or otherwise the
#' virtual environment named by `SPACY_PYTHON` (by default `"r-spacyr"`). This
#' is useful, for instance, to skip examples or tests when spaCy is not
#' available. If a different interpreter is already running in the R session
#' and prevents use of the named virtual environment, returns `FALSE`.
#'
#' @param lang_models character; names of language models that must also be
#'   installed, e.g. `"en_core_web_sm"`. If `NULL` (the default), only spaCy
#'   itself is checked.
#' @return `TRUE` if spaCy and all `lang_models` are installed, `FALSE`
#'   otherwise.
#' @seealso [spacy_install()], [spacy_download_langmodel()]
#' @examples
#' spacy_installed()
#' spacy_installed("en_core_web_sm")
#' @export
spacy_installed <- function(lang_models = NULL) {
  if (!nzchar(Sys.getenv("RETICULATE_PYTHON"))) {
    envname <- Sys.getenv("SPACY_PYTHON", unset = "r-spacyr")
    if (!reticulate::virtualenv_exists(envname)) return(FALSE)

    if (reticulate::py_available(initialize = FALSE)) {
      active_env <- reticulate::py_config()$prefix
      # The interpreter lives in bin/ or Scripts/ inside the virtualenv.
      configured_env <- dirname(dirname(reticulate::virtualenv_python(envname)))
      if (!identical(normalizePath(active_env, winslash = "/", mustWork = FALSE),
                     normalizePath(configured_env, winslash = "/", mustWork = FALSE)))
        return(FALSE)
    }
  }
  installed <- tryCatch(py_check_installed(c("spacy", lang_models)),
                        error = function(e) FALSE)
  all(installed)
}
