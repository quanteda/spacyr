#' Parse a text using spaCy
#' 
#' The `spacy_parse()` function calls spaCy to both tokenize and tag the
#' texts, and returns a data.table of the results. The function provides options
#' on the types of tagsets (`tagset_` options) either  `"google"` or
#' `"detailed"`, as well as lemmatization (`lemma`). It provides a
#' functionalities of dependency parsing and named entity recognition as an
#' option. If `"full_parse = TRUE"` is provided, the function returns the
#' most extensive list of the parsing results from spaCy.
#' 
#' @param x a character object, a \pkg{quanteda} corpus, or a TIF-compliant
#'   corpus data.frame (see <https://github.com/ropenscilabs/tif>)
#' @param pos logical whether to return universal dependency POS tagset
#'   <https://universaldependencies.org/u/pos/>)
#' @param tag logical whether to return detailed part-of-speech tags, for the
#'   language model `en`, it uses the OntoNotes 5 version of the Penn
#'   Treebank tag set
#'   (<https://spacy.io/docs/usage/pos-tagging#pos-schemes>). Annotation
#'   specifications for other available languages are available on the spaCy
#'   website (<https://spacy.io/api/annotation>).
#' @param lemma logical; include lemmatized tokens in the output (the quality
#'   of lemmatization depends on the language model)
#' @param entity logical; if `TRUE`, report named entities
#' @param multithread deprecated; it no longer has any effect, and gives a
#'   warning if supplied. Documents are always processed in
#'   batches with spaCy's `nlp.pipe()`; use `n_process` and `batch_size` instead.
#' @param n_process the number of processes for spaCy's `nlp.pipe()` to use:
#'   `1` (the default) processes the documents in the current R session's Python
#'   process, a larger number starts that many Python processes, and `-1` uses
#'   all CPUs. Starting the processes and loading the model in each takes time,
#'   so more than one process helps only for large numbers of documents. A
#'   custom pipeline component must be defined in an importable Python module
#'   to be used in other processes.
#' @param batch_size the number of documents that spaCy's `nlp.pipe()`
#'   processes together; `NULL` (the default) uses the pipeline's default
#'   (`nlp.batch_size`). Larger batches can be faster, but use
#'   more memory.
#' @param dependency logical; if `TRUE`, analyse and tag dependencies
#' @param nounphrase logical; if `TRUE`, analyse and tag noun phrases
#'   tags
#' @param additional_attributes a character vector; this option is for
#'   extracting additional attributes of tokens from spaCy. When the names of
#'   attributes are supplied, the output data.frame will contain additional
#'   variables corresponding to the names of the attributes. For instance, when
#'   `additional_attributes = c("is_punct")`, the output will include an
#'   additional variable named `is_punct`, which is a Boolean (in R,
#'   logical) variable indicating whether  the token is a punctuation. A full
#'   list of available attributes is available from
#'   <https://spacy.io/api/token#attributes>.
#' @param ... not used directly
#' @return a `data.frame` of tokenized, parsed, and annotated tokens
#' @export
#' @examples
#' \dontrun{
#' spacy_initialize()
#' # See Chap 5.1 of the NLTK book, http://www.nltk.org/book/ch05.html
#' txt <- "And now for something completely different."
#' spacy_parse(txt)
#' spacy_parse(txt, pos = TRUE, tag = TRUE)
#' spacy_parse(txt, dependency = TRUE)
#' 
#' txt2 <- c(doc1 = "The fast cat catches mice.\\nThe quick brown dog jumped.", 
#'           doc2 = "This is the second document.",
#'           doc3 = "This is a \\\"quoted\\\" text." )
#' spacy_parse(txt2, entity = TRUE, dependency = TRUE)
#' 
#' txt3 <- "We analyzed the Supreme Court with three natural language processing tools." 
#' spacy_parse(txt3, entity = TRUE, nounphrase = TRUE)
#' spacy_parse(txt3, additional_attributes = c("like_num", "is_punct"))
#' }
spacy_parse <- function(x,
                        pos = TRUE,
                        tag = FALSE,
                        lemma = TRUE,
                        entity = TRUE,
                        dependency = FALSE,
                        nounphrase = FALSE,
                        multithread,
                        additional_attributes = NULL,
                        n_process = 1L,
                        batch_size = NULL,
                        ...) {
    UseMethod("spacy_parse")
}


#' @importFrom data.table data.table setDT setnames
#' @export
spacy_parse.character <- function(x,
                                  pos = TRUE,
                                  tag = FALSE,
                                  lemma = TRUE,
                                  entity = TRUE,
                                  dependency = FALSE,
                                  nounphrase = FALSE,
                                  multithread,
                                  additional_attributes = NULL,
                                  n_process = 1L,
                                  batch_size = NULL,
                                  ...) {
    x <- structure(as.character(x), names = names(x))
    `:=` <- `.` <- `.N` <- `.I` <- NULL
    check_multithread(multithread, "spacy_parse")
    args <- pipe_args(n_process, batch_size)
    input <- parse_input(x)

    ## check the omit_entity status
    if (entity == TRUE & getOption("spacy_entity") == FALSE) {
        message("entity == TRUE is ignored because spaCy model is initialized without Entity Recognizer")
        message("In order to turn on entity recognition, run spacy_finalize(); spacy_initialize(entity = TRUE)")
        entity <- FALSE
    }

    # all the columns, from one pass over the documents as spaCy parses them
    spobj <- new_spobj()
    parsed <- spobj$parse_table(input$x, input$docnames,
                                lemma = lemma, pos = pos, tag = tag,
                                dependency = dependency, entity = entity,
                                nounphrase = nounphrase,
                                attributes = unname(as.list(additional_attributes)),
                                batch_size = args$batch_size,
                                n_process = args$n_process)
    warn_skipped(spobj)
    cols <- parsed$columns
    if (length(cols$token) == 0) {
        return(empty_spacyr_parsed(lemma = lemma, pos = pos, tag = tag,
                                   dependency = dependency, entity = entity,
                                   nounphrase = nounphrase,
                                   additional_attributes = additional_attributes))
    }
    if (dependency) cols$head_token_id <- as.numeric(cols$head_token_id)
    if (nounphrase && parsed$n_nounphrases == 0) {
        message("No noun phrase found in documents.")
        cols$nounphrase <- cols$whitespace <- NULL
    }
    dt <- data.table::as.data.table(lapply(cols, unlist))
    for (att_name in additional_attributes) {
        dt[, (att_name) := parsed$attributes[[att_name]]]
    }

    dt <- as.data.frame(dt)
    class(dt) <- c("spacyr_parsed", class(dt))
    return(dt)
}


#' @export
spacy_parse.data.frame <- function(x, ...) {

    # insert compliance check here - replace with tif package
    if (!all(c("doc_id", "text") %in% names(x)))
        stop("input data.frame does not conform to the TIF standard")

    txt <- x$text
    names(txt) <- x$doc_id
    spacy_parse(txt, ...)
}


#' Tokenize text using spaCy
#' 
#' Tokenize text using spaCy. The results of tokenization is stored as a Python
#' object. To obtain the tokens results in R, use `get_tokens()`.
#' <https://spacy.io>.
#' @param x input text
#' functionalities including the tagging, named entity recognition, dependency 
#' analysis. 
#' This slows down `spacy_parse()` but speeds up the later parsing. 
#' If FALSE, tagging, entity recognition, and dependency analysis when 
#' relevant functions are called.
#' @param multithread not used; kept for compatibility
#' @param n_process,batch_size passed to spaCy's `nlp.pipe()`
#' @param ... arguments passed to specific methods
#' @return result marker object
#' @importFrom methods new
#' @examples
#' \dontrun{
#' spacy_initialize()
#' # the result has to be "tag() is ready to run" to run the following
#' txt <- c(text1 = "This is the first sentence.\nHere is the second sentence.", 
#'          text2 = "This is the second document.")
#' results <- spacy_parse(txt)
#' }
#' @export
#' @keywords internal
process_document <- function(x, multithread, n_process = 1L, batch_size = NULL, ...) {
    # This function passes texts to python and spacy
    input <- parse_input(x)
    spobj <- new_spobj()
    # named by document; a document that the pipeline left out has none
    timestamps <- unlist(spobj$parse(input$x, input$docnames, batch_size = batch_size,
                                     n_process = n_process))
    warn_skipped(spobj)
    docnames <- as.character(names(timestamps))
    timestamps <- as.character(timestamps)
    output <- spacy_out$new(docnames = docnames,
                            timestamps = timestamps)
    return(output)
}


# Document names and texts for spaCy, initializing spaCy if needed: missing
# names are set to text1, text2, ..., and NA documents are treated as empty.
parse_input <- function(x) {
    if (!is.null(names(x))) {
        docnames <- names(x)
    } else {
        docnames <- paste0("text", 1:length(x))
    }
    if (all(!duplicated(docnames)) == FALSE) {
        stop("Docnames are duplicated.")
    } else if (all(nchar(docnames) > 0L) == FALSE) {
        stop("Some docnames are missing.")
    }

    if (is.null(options()$spacy_initialized)) spacy_initialize()
    x[is.na(x)] <- "" # missing documents are treated as empty
    list(x = unname(x), docnames = docnames)
}


# zero-row result with the columns and types of a parse that has tokens;
# additional attributes are logical, since their type cannot be known
empty_spacyr_parsed <- function(lemma, pos, tag, dependency, entity, nounphrase,
                                additional_attributes) {
    cols <- list(doc_id = character(), sentence_id = integer(),
                 token_id = integer(), token = character())
    if (lemma) cols$lemma <- character()
    if (pos) cols$pos <- character()
    if (tag) cols$tag <- character()
    if (dependency) {
        cols$head_token_id <- numeric()
        cols$dep_rel <- character()
    }
    if (entity) cols$entity <- character()
    if (nounphrase) message("No noun phrase found in documents.")
    for (att_name in additional_attributes) cols[[att_name]] <- logical()
    dt <- as.data.frame(cols, stringsAsFactors = FALSE, check.names = FALSE)
    class(dt) <- c("spacyr_parsed", class(dt))
    dt
}
