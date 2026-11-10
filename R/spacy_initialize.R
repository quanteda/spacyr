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
#' @param entity_patterns rule-based entities to add to the pipeline: a
#'   `spacyr_entity_patterns` object, or anything that [as_entity_patterns()]
#'   accepts, such as a named character vector of phrases. spacyr adds
#'   spaCy's entity ruler, as `spacyr_entity_ruler`, at the end of the
#'   pipeline, after every component that sets entities; an entity ruler saved
#'   with the model stays as it is. If `NULL` (the default), the pipeline is
#'   not changed.
#' @param overwrite_entities logical; where an entity matched by
#'   `entity_patterns` overlaps one found by an earlier component, such as the
#'   model's named entity recognizer, the rule's entity is kept if `TRUE` (the
#'   default), and the earlier one if `FALSE`, so that the rules only add
#'   entities where none were found.
#' @param ... not used.
#' @details
#' With `entity_patterns`, the entities found by the rules are returned by
#' [spacy_parse()] and [spacy_extract_entity()] like any others, also when
#' `entity = FALSE`. Patterns that use `ENT_TYPE` or `ENT_IOB` build on the
#' entities of earlier components, so they match nothing, with a warning, when
#' no component of the pipeline sets entities, for instance with
#' `entity = FALSE`. Phrases marked `case_insensitive` are tokenized with the
#' pipeline's own tokenizer, and match the lower case form of each token.
#' @seealso [as_entity_patterns()]
#' @examples
#' \dontrun{
#' # academic titles as part of a person's name
#' titles <- c("dr", "dr.", "prof", "prof.", "professor")
#' pats <- as_entity_patterns(list(
#'     label = "PERSON",
#'     pattern = list(list(LOWER = list(IN = titles)),
#'                    list(ENT_TYPE = "PERSON", ENT_IOB = "B"),
#'                    list(ENT_TYPE = "PERSON", ENT_IOB = "I", OP = "*"))))
#' spacy_initialize(entity_patterns = pats)
#' spacy_extract_entity("Prof. Jane Smith met Dr Bob Jones in Paris.")
#' spacy_finalize()
#'
#' # phrases, with labels as names
#' spacy_initialize(entity_patterns = c(ORG = "Acme Widgets", GPE = "Ruritania"))
#' spacy_finalize()
#' }
#' 
#' @export
#' @author Akitaka Matsuo, Johannes B. Gruber
spacy_initialize <- function(model = "en_core_web_sm",
                             entity = TRUE,
                             max_length = NULL,
                             entity_patterns = NULL,
                             overwrite_entities = TRUE,
                             ...) {
  
  if (length(list(...)) > 0) 
    warning("Note that we have deprecated a number of parameters to simplify this function")
  
  if (!is.null(max_length) &&
      (!is.numeric(max_length) || length(max_length) != 1 || !is.finite(max_length) ||
       max_length < 1 || max_length > .Machine$integer.max || max_length != round(max_length)))
    stop("max_length must be a single whole number between 1 and ", .Machine$integer.max)

  if (!is.logical(overwrite_entities) || length(overwrite_entities) != 1 ||
      is.na(overwrite_entities))
    stop("overwrite_entities must be TRUE or FALSE")
  if (!is.null(entity_patterns)) {
    entity_patterns <- as_entity_patterns(entity_patterns)
    if (!nrow(entity_patterns)) entity_patterns <- NULL
  }

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

  nlp <- tryCatch(
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
  if (!is.null(entity_patterns)) {
    upstream <- tryCatch(
      spacyr_env$module$add_entity_ruler(nlp, as.list(entity_patterns),
                                         overwrite_entities),
      error = function(e) {
        msg <- sub("\\s*Run `reticulate::py_last_error\\(\\)`.*$", "",
                   conditionMessage(e))
        stop("spaCy did not accept the entity patterns:\n", msg, call. = FALSE)
      }
    )
    if (!upstream && uses_entity_attrs(entity_patterns))
      warning("Patterns using ENT_TYPE or ENT_IOB will match nothing, since no ",
              "component of the pipeline sets entities; ",
              "use spacy_initialize(entity = TRUE)", call. = FALSE)
  }
  spacyr_env$nlp <- nlp
  spacyr_env$entity_patterns <- entity_patterns
  # the rules set entities even without the model's entity recognizer
  options("spacy_entity" = entity || !is.null(entity_patterns))
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
  spacyr_env$entity_patterns <- NULL
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


# whether any token pattern uses an attribute set by entity recognition
uses_entity_attrs <- function(x) {
  any(vapply(x$pattern, function(p) {
    is.list(p) && any(vapply(p, function(tok) {
      any(toupper(names(tok)) %in% c("ENT_TYPE", "ENT_IOB"))
    }, logical(1)))
  }, logical(1)))
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
