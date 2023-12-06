#' Initialize spaCy
#' 
#' Initialize spaCy to call from R. 
#' 
#' @return NULL
#' @param model Language package for loading spaCy. Example: `en_core_web_sm` (English) and
#' `de_core_web_sm` (German). Default is `en_core_web_sm`.
#' @param entity logical; if `FALSE` is selected, named entity recognition
#'   is turned off in spaCy. This will speed up the parsing as it will exclude
#'   `ner` from the pipeline. For details of spaCy pipeline, see
#'   <https://spacy.io/usage/processing-pipelines>. The option `FALSE`
#'   is available only for spaCy version 2.0.0 or higher.
#' @param ... not used.
#' 
#' @export
#' @author Akitaka Matsuo, Johannes B. Gruber
spacy_initialize <- function(model = "en_core_web_sm",
                             entity = TRUE,
                             ...) {
  
  if (length(list(...)) > 0) 
    warning("Note that we have deprecated a number of parameters to simplify this function")
  
  if (!is.null(options("spacy_initialized")$spacy_initialized)) {
    message("spaCy is already initialized")
    return(NULL)
  }
  
  if (!nchar(Sys.getenv("RETICULATE_PYTHON")) > 0) {
    if (!reticulate::virtualenv_exists(Sys.getenv("SPACY_PYTHON", unset = "r-spacyr"))) 
      stop("No spaCy environment found. Use `spacy_install()` to get started.")
    
    if (!"spacy" %in% reticulate::py_list_packages(Sys.getenv("SPACY_PYTHON", unset = "r-spacyr"))$package) 
      stop("spaCy was not found in your environment. Use `spacy_install()`",
           "to get started.")
    
    reticulate::use_virtualenv(Sys.getenv("SPACY_PYTHON", unset = "r-spacyr"))
  }
  
  spacyr_pyexec(pyfile = system.file("python", "spacyr_class.py",
                                     package = "spacyr"))
  
  spacyr_pyassign("model", model)
  spacyr_pyassign("spacy_entity", entity)
  options("spacy_entity" = entity)
  spacyr_pyexec(pyfile = system.file("python", "initialize_spacyPython.py",
                                     package = "spacyr"))
  
  spacy_version <- spacyr_pyget("spacy_version")
  if (entity == FALSE && as.integer(substr(spacy_version, 1, 1)) < 2){
    message("entity == FALSE is only available for spaCy version 2.0.0 or higher")
    options("spacy_entity" = TRUE)
  }
  message("successfully initialized (spaCy Version: ", spacy_version, ", language model: ", model, ")")
  options("spacy_initialized" = TRUE)
  
}

#' Finalize spaCy
#' 
#' While running spaCy on Python through R, a Python process is always running
#' in the background and Rsession will take up a lot of memory (typically over
#' 1.5GB). `spacy_finalize()` terminates the Python process and frees up
#' the memory it was using.
#' @return NULL
#' @export
#' @author Akitaka Matsuo
spacy_finalize <- function() {
  if (is.null(getOption("spacy_initialized"))) {
    stop("Nothing to finalize. spaCy is not initialized")
  }
  spacyr_pyexec(pyfile = system.file("python", "finalize_spacyPython.py",
                                     package = "spacyr"))
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

