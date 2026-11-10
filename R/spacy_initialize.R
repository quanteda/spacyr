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
#' @param split_hyphens logical; if `TRUE` (the default), words joined by a
#'   hyphen are split as the language model's tokenizer splits them, which for
#'   English makes three tokens of "eye-opening": "eye", "-" and "opening". If
#'   `FALSE`, the tokenizer no longer splits at a single hyphen between
#'   letters, or between a letter and a digit, so that "eye-opening" stays one
#'   token, and the rest of the pipeline, such as the tagger and lemmatizer,
#'   processes it as one. Note that the default differs from that of
#'   **quanteda**'s [quanteda::tokens()], whose `split_hyphens = FALSE` keeps
#'   hyphenated words together by default. See Details.
#' @param entity_patterns rule-based entities to add to the pipeline: a
#'   `spacyr_entity_patterns` object, or anything that [as_entity_patterns()]
#'   accepts, such as a named character vector of phrases. spacyr adds
#'   spaCy's entity ruler, as `spacyr_entity_ruler`, at the end of the
#'   pipeline, after every component that sets entities; an entity ruler saved
#'   with the model stays as it is. If the model already has a component of
#'   that name, for instance because it was saved from a pipeline with rules
#'   added by spacyr, the new ruler is named `spacyr_entity_ruler_2` (or the
#'   next free number). If `NULL` (the default), the pipeline is not changed.
#' @param overwrite_entities logical; where an entity matched by
#'   `entity_patterns` overlaps one found by an earlier component, such as the
#'   model's named entity recognizer, the rule's entity is kept if `TRUE` (the
#'   default), and the earlier one if `FALSE`, so that the rules only add
#'   entities where none were found.
#' @param ... not used.
#' @details
#' With `entity_patterns`, the entities found by the rules are returned by
#' [spacy_parse()] and [spacy_extract_entity()] like any others, also when
#' `entity = FALSE`. Patterns that ask for an entity type (`ENT_TYPE`) or for
#' tokens inside an entity (`ENT_IOB`) build on the entities of earlier
#' components, such as the model's `ner` or a ruler saved with the model, so
#' they give a warning when no earlier component sets entities, for instance
#' with `entity = FALSE`. Phrases are tokenized with the pipeline's own
#' tokenizer, and those marked `case_insensitive` match the lower case form of
#' each token. A component that changes the tokens, such as spaCy's
#' `merge_entities`, can stop phrases from matching when it comes before the
#' ruler, which gives a warning.
#'
#' With `split_hyphens = FALSE`, the tokenizer still splits wherever the
#' model's tokenizer did other than at a single hyphen within a word: between
#' numbers, so that "3-4" is still three tokens ("3", "-" and "4"), where
#' **quanteda**'s `tokens(split_hyphens = FALSE)` keeps it as one; at two or
#' more hyphens, as in "a--b"; and at the start or end of a word. The models
#' were trained on text with hyphenated words split, so their tags, lemmas and
#' dependencies for a hyphenated word kept whole can differ from those for its
#' parts. Only the language's default infix rules are changed: a model saved
#' with infix rules of its own, or whose tokenizer is not spaCy's rule-based
#' one, as for Chinese and Japanese, is left as it is. A warning is given if
#' the tokenizer still splits some hyphenated words, between letters or
#' between a letter and a digit, for whatever reason. Many languages, such as German, do not split
#' them in the first place. Phrase patterns of a ruler saved with the model,
#' such as an `entity_ruler`, were tokenized when the model was saved, so
#' those containing hyphenated words may no longer match; changing the
#' tokenizer gives a warning when an active component has phrase patterns.
#' Those of `entity_patterns` are tokenized after the change.
#'
#' Phrases are matched quickly, even many thousands of them, and so are
#' patterns of a single token with a regular expression, such as dictionary
#' values with a wildcard, which spacyr combines into one regular expression
#' for each label. Other token patterns are checked one by one, and so are
#' phrases marked `case_insensitive` when the patterns also include phrases
#' that are not, which makes parsing slower when there are many of them.
#'
#' Unless the environment variable `TOKENIZERS_PARALLELISM` is already set,
#' `spacy_initialize()` sets it to `"false"`. Pipelines that use Hugging
#' Face's **tokenizers** library, such as some built with
#' **spacy-transformers**, otherwise print a warning about disabling
#' parallelism, again and again until R is restarted, once the R process is
#' forked after the library has been used, as RStudio does when saving a file.
#' Turning off its parallelism makes little difference to speed, since the
#' transformer itself takes most of the time. The setting applies to the
#' whole R process, Python included, and stays after [spacy_finalize()]; if
#' initialization fails, the previous value is restored. A value set before
#' calling `spacy_initialize()` is kept, even an empty one, which
#' **tokenizers** reads as `"false"`. Setting
#' `Sys.setenv(TOKENIZERS_PARALLELISM = "true")` turns off the library's
#' safeguard against deadlocks: a forked process, such as a worker of
#' `parallel::mclapply()` or of `n_process` greater than 1, that uses
#' **tokenizers** after the parent has used it can then hang. Leave the
#' setting at `"false"` whenever that can happen.
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
                             split_hyphens = TRUE,
                             entity_patterns = NULL,
                             overwrite_entities = TRUE,
                             ...) {
  
  if (length(list(...)) > 0) 
    warning("Note that we have deprecated a number of parameters to simplify this function")
  
  if (!is.null(max_length) &&
      (!is.numeric(max_length) || length(max_length) != 1 || !is.finite(max_length) ||
       max_length < 1 || max_length > .Machine$integer.max || max_length != round(max_length)))
    stop("max_length must be a single whole number between 1 and ", .Machine$integer.max)

  if (!is.logical(split_hyphens) || length(split_hyphens) != 1 ||
      is.na(split_hyphens))
    stop("split_hyphens must be TRUE or FALSE")
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
  
  # Hugging Face's tokenizers, used by some transformer pipelines, warns
  # repeatedly once the R process forks after it has used its thread pool
  # (#233); a value the user has set, even an empty one (which tokenizers
  # reads as false), is kept. Python copies the environment when it starts,
  # so it is started first, and its own value taken before anything is set,
  # so that both can be restored if initialization fails.
  os <- reticulate::import("os")
  old_parallelism <- Sys.getenv("TOKENIZERS_PARALLELISM", unset = NA_character_)
  old_py_parallelism <- os$environ$get("TOKENIZERS_PARALLELISM")
  parallelism <- if (is.na(old_parallelism)) "false" else old_parallelism
  initialized <- FALSE
  on.exit(if (!initialized) {
    # Python's first, since setting os.environ also sets the process's
    try(if (is.null(old_py_parallelism)) {
      os$environ$pop("TOKENIZERS_PARALLELISM", NULL)
    } else {
      os$environ$`__setitem__`("TOKENIZERS_PARALLELISM", old_py_parallelism)
    }, silent = TRUE)
    if (is.na(old_parallelism)) Sys.unsetenv("TOKENIZERS_PARALLELISM")
    else Sys.setenv(TOKENIZERS_PARALLELISM = old_parallelism)
  }, add = TRUE)
  Sys.setenv(TOKENIZERS_PARALLELISM = parallelism)
  os$environ$`__setitem__`("TOKENIZERS_PARALLELISM", parallelism)

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
  # before the entity ruler, which tokenizes its phrases with this tokenizer
  if (!split_hyphens) {
    hyph <- spacyr_env$module$keep_hyphens(nlp)
    if (hyph$splits)
      warning("The tokenizer of '", model, "' still splits some hyphenated ",
              "words with split_hyphens = FALSE", call. = FALSE)
    saved <- unlist(hyph$phrase_rulers)
    if (length(saved))
      warning("Phrase patterns of ", paste0("'", saved, "'", collapse = ", "),
              " may not match words with hyphens, since ",
              if (length(saved) == 1) "it was" else "they were",
              " saved with a tokenizer that splits them; ",
              "use split_hyphens = TRUE to match them as saved",
              call. = FALSE)
  }
  if (!is.null(entity_patterns)) {
    ruler <- tryCatch(
      spacyr_env$module$add_entity_ruler(nlp, as.list(entity_patterns),
                                         overwrite_entities),
      error = function(e) {
        msg <- sub("\\s*Run `reticulate::py_last_error\\(\\)`.*$", "",
                   conditionMessage(e))
        stop("spaCy did not accept the entity patterns:\n", msg, call. = FALSE)
      }
    )
    if (!ruler$sets_entities && needs_entities(entity_patterns))
      warning("Some patterns need entities that an earlier component found ",
              "(ENT_TYPE or ENT_IOB), but no component before spacyr's ",
              "entity ruler sets entities, so they will not match",
              if (ruler$ner_disabled) "; use spacy_initialize(entity = TRUE)",
              call. = FALSE)
    retok <- unlist(ruler$retokenizers)
    if (length(retok) && any(vapply(entity_patterns$pattern, is.character, logical(1))))
      warning("Phrase patterns may not match, since ",
              paste0("'", retok, "'", collapse = ", "),
              if (length(retok) == 1) " changes" else " change",
              " the tokens before spacyr's entity ruler; phrases are ",
              "tokenized without ", if (length(retok) == 1) "it" else "them",
              call. = FALSE)
    spacyr_env$entity_ruler <- ruler$name
  }
  spacyr_env$nlp <- nlp
  spacyr_env$entity_patterns <- entity_patterns
  # the rules set entities even without the model's entity recognizer
  options("spacy_entity" = entity || !is.null(entity_patterns))
  initialized <- TRUE
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
  spacyr_env$entity_ruler <- NULL
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


# whether any token pattern requires entities set by an earlier component:
# a token it must match (not optional or negated) that asks for an entity type
# (ENT_TYPE as a non-empty string or IN), or for being inside an entity
# (ENT_IOB "B" or "I"); ENT_TYPE with NOT_IN, for instance, also matches
# tokens outside entities
needs_entities <- function(x) {
  any(vapply(x$pattern, function(p) {
    is.list(p) && any(vapply(p, token_needs_entities, logical(1)))
  }, logical(1)))
}

token_needs_entities <- function(tok) {
  keys <- toupper(names(tok))
  op <- if ("OP" %in% keys) tok[[match("OP", keys)]] else ""
  if (op %in% c("?", "*", "!") || grepl("^\\{0?,", op)) return(FALSE)
  # the values a token attribute asks for: a value itself, or those of IN
  asked <- function(v) {
    if (!is.list(v)) return(as.character(unlist(v)))
    ops <- toupper(names(v))
    if ("IN" %in% ops) as.character(unlist(v[[match("IN", ops)]])) else character()
  }
  ent_type <- unlist(lapply(tok[keys == "ENT_TYPE"], asked))
  ent_iob <- unlist(lapply(tok[keys == "ENT_IOB"], asked))
  any(nzchar(ent_type)) || any(ent_iob %in% c("B", "I", "1", "3"))
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
