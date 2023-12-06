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
#'   [reticulate::install_python()] otherwise. It then creates a
#'   virtual environment with the necessary packages in the default location
#'   chosen by [reticulate::virtualenv_root()].
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

  if (nchar(Sys.getenv("RETICULATE_PYTHON")) > 0) {
    message("You provided a custom RETICULATE_PYTHON, so we assume you know what you ",
            "are doing managing your virtual environments. Good luck!")
  } else if (!reticulate::virtualenv_exists(Sys.getenv("SPACY_PYTHON", unset = "r-spacyr"))) {
    # this has turned out to be the easiest way to test if a suitable Python 
    # version is present. All other methods load Python, which creates
    # some headache.
    t <- try(reticulate::virtualenv_create(Sys.getenv("SPACY_PYTHON", unset = "r-spacyr")), silent = TRUE)
    if (methods::is(t, "try-error")) {
      permission <- TRUE
      if (ask) {
        permission <- utils::askYesNo(paste0(
          "No suitable Python installation was found on your system. ",
          "Do you want to run `reticulate::install_python()` to install it?"
        ))
      }
      
      if (permission) {
        if (utils::packageVersion("reticulate") < "1.19") 
          stop("Your version or reticulate is too old for this action. Please update")
        python <- reticulate::install_python()
        reticulate::virtualenv_create(Sys.getenv("SPACY_PYTHON", unset = "r-spacyr"),
                                      python = python)
      } else {
        stop("Aborted by user")
      }
    }
    reticulate::use_virtualenv(Sys.getenv("SPACY_PYTHON", unset = "r-spacyr"))
  } else {
    reticulate::use_virtualenv(Sys.getenv("SPACY_PYTHON", unset = "r-spacyr"))
  }
  
  if (!identical(version, "latest")) {
    if (grepl("^v*[1-9]\\.\\d{1,2}\\.\\d{1,2}$", version)) {
      version <- regmatches(version, regexpr("[1-9]\\.\\d{1,2}\\.\\d{1,2}\\b", version))
      spacy_pkg <- paste0("spacy==", version)
    } else if (grepl("^[A-z,-]+$", version)) {
      spacy_pkg <- paste0("spacy[", version, "]")
    } else {
      spacy_pkg <- paste0("spacy", version)
    }
  } else {
    spacy_pkg <- "spacy"
  }
  
  if (py_check_installed(spacy_pkg) & !force) {
    warning("Skipping installation. Use `force` to force installation or update. ",
            "Or use `spacy_download_langmodel()` if you just want to install a model.")
    return(invisible(NULL))
  }
  
  reticulate::py_install(spacy_pkg, envname = Sys.getenv("SPACY_PYTHON", unset = "r-spacyr"))
  spacy_download_langmodel(lang_models)
  
  message("Installation of spaCy version ", 
          py_check_version("spacy", envname = Sys.getenv("SPACY_PYTHON", unset = "r-spacyr")), 
          " complete.")
  
  invisible(NULL)
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
