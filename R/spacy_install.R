#' Install spaCy in conda or virtualenv environment
#'
#' @description Install spaCy in a self-contained environment, including
#'   specified language models.
#' @param version character; spaCy version to install (see details).
#' @param lang_models character; language models to be installed. Defaults
#'   \code{en_core_web_sm} (English model). A vector of multiple model names can
#'   be used (e.g. \code{c("en_core_web_sm", "de_core_news_sm")}). A list of
#'   available language models and their
#'   names is available from the \href{https://spacy.io/usage/models}{spaCy
#'   language models} page.
#' @param ask logical; ask whether to proceed during the installation. By
#'   default, questions are only asked in interactive sessions.
#' @seealso \code{\link{spacy_install_model}}
#' @examples 
#' \dontrun{
#' # install the latest version of spaCy
#' spacy_install()
#' 
#' # update spaCy
#' spacy_install(force = TRUE)
#' 
#' # install an older version
#' spacy_install("3.1.0")
#' 
#' # install with GPU enabled
#' spacy_install("cuda-autodetect")
#' 
#' # install on Apple ARM processors
#' spacy_install("apple")
#' 
#' # install several models with spaCy
#' spacy_install(lang_models = c("en_core_web_sm", "de_core_news_sm"))
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
    warning("Note that we have deprecated a number of parameters to simplify this function")
  
  # 1. check if there is a Python available
  # 2. check if RETICULATE_PYTHON is set, which should take precedence over other selections
  # 3. check if "r-spacyr" exists (name is suggested by reticulate convention)
  # 4. install missing packages to environment
  # 5. install missing model(s) to environment

  if (!reticulate::py_available(initialize = TRUE)) {
    if (ask) {
      choice <- utils::menu(
        c("No", "Yes"), 
        title = paste0("No Python was found on your system. ",
                       "Do you want to run `reticulate::install_python()` to install one?")
      )
    } else {
      choice <- 2
    }
    switch (choice,
      stop("Aborted by user"),
      reticulate::install_python()
    )
  } else if (nchar(Sys.getenv("RETICULATE_PYTHON")) > 0) {
    message("You provided a custom RETICULATE_PYTHON, so we assume you know what you ",
            "are doing managing your virtual environments. Good luck!")
  } else if (!reticulate::virtualenv_exists("r-spacyr")) {
    reticulate::virtualenv_create("r-spacyr")
    reticulate::use_virtualenv("r-spacyr")
  } else if (reticulate::virtualenv_exists("r-spacyr")) {
    reticulate::use_virtualenv("r-spacyr")
  }
  
  if (!identical(version, "latest")) {
    if (grepl("^v*[1-9]\\.\\d{1,2}\\.\\d{1,2}$", version)) {
      version <- regmatches(version, regexpr("[1-9]\\.\\d{1,2}\\.\\d{1,2}\\b", version))
      spacy_pkg <- paste0("spacy==", version)
    } else if (grepl("^[A-z,]+$", version)) {
      spacy_pkg <- paste0("spacy[", version, "]")
    } else {
      spacy_pkg <- paste0("spacy", version)
    }
  } else {
    spacy_pkg <- "spacy"
  }
  
  if ("spacy" %in% reticulate::py_list_packages("r-spacyr")$package &
      !force) {
    stop("Spacy is already installed. Use `force` to force installation or update.",
         "Or use `spacy_install_model()` if you just want to install a model.")
  }
  
  reticulate::py_install(spacy_pkg, "r-spacyr")
  spacy_install_model(lang_models)
  
  message("Installation complete.")
  
  invisible(NULL)
}


#' Shorthand function to upgrade spaCy
#' 
#' Upgrade spaCy (to a specific version).
#' 
#' @inherit spacy_install
#' @export
spacy_upgrade <- function(version = "latest",
                          lang_models = NULL,
                          ask = interactive(),
                          force = TRUE) {
  spacy_install(match.call(expand.dots = TRUE))
}


#' Install spaCy language models
#'
#' @inheritParams spacy_install
#' 
#' @return Invisibly returns the installation log.
#' 
#' @export
#'
#' @examples
#' \dontrun{
#' # install medium sized model
#' spacy_install_model("en_core_web_md")
#' 
#' #' # install several models with spaCy
#' spacy_install(lang_models = c("en_core_web_sm", "de_core_news_sm"))
#' 
#' # install transformer based model
#' spacy_install_model("en_core_web_trf")
#' }
spacy_install_model <- function(lang_models = "en_core_web_sm") {
  
  bin <- reticulate::virtualenv_python("r-spacyr")
  args <- c("-m", "spacy", "download")
  
  invisible(lapply(lang_models, function(m) {
    message("Executing command:\n", paste(c(bin, args, m), collapse = " "))
    system2(bin, args = c(args, m))
  }))
  
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
#' @export
spacy_uninstall <- function() {
  
  reticulate::virtualenv_remove("r-spacyr")
  
  invisible(NULL)
}

