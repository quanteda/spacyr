#' Initialize spaCy
#' 
#' Initialize spaCy to call from R. 
#' 
#' @return NULL
#' @param model Language package for loading spaCy. Example: `en_core_web_sm` (English) and
#' `de_core_news_sm` (German). Default is `en_core_web_sm`. This can also be
#' the path to a model directory.
#' @param entity logical; if `FALSE` is selected, named entity recognition
#'   is turned off in spaCy. This will speed up the parsing as it will exclude
#'   `ner` from the pipeline. For details of spaCy pipeline, see
#'   <https://spacy.io/usage/processing-pipelines>.
#' @param max_length integer; the maximum number of characters in a single
#'   document that spaCy will accept (`nlp.max_length`), a whole number no
#'   larger than `.Machine$integer.max`. If `NULL` (the
#'   default), spaCy's default of 1,000,000 is used. Larger values require
#'   roughly 1GB of temporary memory per 100,000 characters for the parser
#'   and entity recogniser.
#' @param ... not used.
#' 
#' @export
#' @author Akitaka Matsuo, Johannes B. Gruber
spacy_initialize <- function(model = "en_core_web_sm",
                             entity = TRUE,
                             max_length = NULL,
                             ...) {
  
  if (length(list(...)) > 0) 
    warning("Note that we have deprecated a number of parameters to simplify this function")
  
  if (!is.null(max_length) &&
      (!is.numeric(max_length) || length(max_length) != 1 || !is.finite(max_length) ||
       max_length < 1 || max_length > .Machine$integer.max || max_length != round(max_length)))
    stop("max_length must be a single whole number between 1 and ", .Machine$integer.max)

  if (!is.null(options("spacy_initialized")$spacy_initialized)) {
    message("spaCy is already initialized")
    return(NULL)
  }
  
  if (!nchar(Sys.getenv("RETICULATE_PYTHON")) > 0) {
    if (!reticulate::virtualenv_exists(Sys.getenv("SPACY_PYTHON", unset = "r-spacyr"))) 
      stop("No spaCy environment found. Use `spacy_install()` to get started.")
    
    if (!py_check_installed("spacy")) 
      stop("spaCy was not found in your environment. Use `spacy_install()` ",
           "to get started.")
    
    reticulate::use_virtualenv(Sys.getenv("SPACY_PYTHON", unset = "r-spacyr"))
  }
  
  spacyr_env$module <- load_spacyr_module()
  spacy_version <- spacyr_env$module$spacy_version()
  check_spacy_version(spacy_version)

  options("spacy_entity" = entity)
  spacyr_env$nlp <- tryCatch(
    spacyr_env$module$load_model(
      model, entity,
      if (is.null(max_length)) NULL else as.integer(max_length)),
    error = function(e) {
      if (grepl("E050", conditionMessage(e), fixed = TRUE)) {
        stop("The language model '", model, "' is not installed. ",
             "Install it with `spacy_download_langmodel(\"", model, "\")`, ",
             "or supply the path to a model directory.", call. = FALSE)
      }
      stop(e)
    }
  )
  message("successfully initialized (spaCy Version: ", spacy_version, ", language model: ", model, ")")
  options("spacy_initialized" = TRUE)
  
}

#' Finalize spaCy
#' 
#' Removes the spaCy language model and any parsed documents from the Python
#' session, so that their memory can be released, and allows
#' [spacy_initialize()] to be called again, for instance with a different
#' language model or options.
#'
#' Python itself remains loaded in the R session: once started, it cannot be
#' shut down or switched to a different Python installation or environment
#' without restarting R.
#' @return NULL
#' @export
#' @author Akitaka Matsuo
spacy_finalize <- function() {
  if (is.null(getOption("spacy_initialized"))) {
    stop("Nothing to finalize. spaCy is not initialized")
  }
  # drop the reference to the pipeline, then let Python release its memory
  spacyr_env$nlp <- NULL
  gc()
  reticulate::import("gc")$collect()
  options("spacy_initialized" = NULL)
}

#' Find spaCy
#' 
#' Locate the user's version of Python for which spaCy installed.
#' @return spacy_python
#' @export
#' @param model name of the language model
#' @param ask logical; if `FALSE`, use the first spaCy installation found; 
#'   if `TRUE`, list available spaCy installations and prompt the user 
#'   for which to use. If another (e.g. `python_executable`) is set, then 
#'   this value will always be treated as `FALSE`.
#'  
#' @keywords internal
#' @importFrom data.table data.table
find_spacy <- function(model = "en_core_web_sm", ask){
  
  .Deprecated(msg = c(
    "spacy now uses the virutal environment 'r-spacyr' by default. ",
    "You can use `reticulate::virtualenv_root()` to find it or set ",
    "the variable RETICULATE_PYTHON to manage your own environment."
  ))
  
}

clear_spacy_options <- function(){
  options(spacy_python_executable = NULL)
  options(spacy_condaenv = NULL)
  options(spacy_virtualenv = NULL)
}


# spacyr requires spaCy 3 or later
check_spacy_version <- function(version, installing = FALSE) {
  major <- suppressWarnings(as.integer(sub("^v*(\\d+)\\..*$", "\\1", version)))
  if (!is.na(major) && major < 3) {
    if (installing) {
      stop("spacyr requires spaCy 3.0.0 or later; version ", version,
           " cannot be installed.", call. = FALSE)
    }
    stop("spacyr requires spaCy 3.0.0 or later, but version ", version,
         " is installed. Use `spacy_upgrade()` to upgrade it.", call. = FALSE)
  }
  invisible(version)
}
