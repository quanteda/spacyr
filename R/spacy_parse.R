#' Parse a text using spaCy
#' 
#' The `spacy_parse()` function calls spaCy to both tokenize and tag the
#' texts, and returns a data.frame of the results, with one row per token. The
#' function provides options for universal (`pos`) and detailed (`tag`)
#' part-of-speech tags, lemmatization (`lemma`), named entity recognition
#' (`entity`), dependency parsing (`dependency`), noun phrases (`nounphrase`),
#' the position of each token in its text (`offsets`), and any other token
#' attributes from spaCy (`additional_attributes`).
#' 
#' @details
#' The components of spaCy's pipeline whose results the options do not ask
#' for are left out of the call, which makes it faster: the named entity
#' recognizer with `entity = FALSE`; the lemmatizer with `lemma = FALSE`; and
#' the tagger and the attribute ruler when `pos`, `tag`, `lemma` and
#' `nounphrase` are all `FALSE`. The output is the same as when every
#' component runs, so a component stays whenever it sets something that the
#' output has, or that a later component may read:
#'
#' * The parser always runs, since it sets the sentences.
#' * An attribute ruler stays if any of its rules sets something that is
#'   returned. That of spaCy's English models also sets the dependency of
#'   whitespace tokens, so with `dependency = TRUE` it stays, and so does
#'   the tagger, whose tags its rules read.
#' * With entity rules from `spacy_initialize(entity_patterns = )` and
#'   `entity = TRUE`, the components that the rules may read stay.
#' * Nothing is left out when `additional_attributes` are asked for, or when
#'   the pipeline has a component that is not one of spaCy's standard ones.
#'
#' See the article "Improving Performance" on the package website.
#'
#' @param x a character object, a \pkg{quanteda} corpus, or a TIF-compliant
#'   corpus data.frame (see <https://github.com/ropenscilabs/tif>)
#' @param pos logical whether to return universal dependency POS tagset
#'   (<https://universaldependencies.org/u/pos/>)
#' @param tag logical whether to return detailed part-of-speech tags; the
#'   English language models use the OntoNotes 5 version of the Penn
#'   Treebank tag set (<https://spacy.io/models/en>). The tag sets of other language
#'   models are listed under "Label scheme" on <https://spacy.io/models>.
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
#' @param offsets logical; if `TRUE`, return the position of each token in
#'   its text as it was given in `x`, in two columns after `token`: `start`,
#'   the position of the token's first character, and `end`, that of its
#'   last. Positions are counted from 1 in characters as R counts them,
#'   whitespace included, so that `substring(text, start, end)` gives the
#'   tokens of a text. Some of spaCy's tokenizers, such as the one for
#'   Korean, make a document whose whitespace differs from that of the text;
#'   the positions are still those in the text. If a tokenizer changes
#'   anything else, so that a token is not found in the text or the text
#'   has more than whitespace outside the tokens, this is an error.
#' @param ... not used directly
#' @return a `data.frame` of tokenized, parsed, and annotated tokens, of class
#'   `spacyr_parsed`. It keeps the names of all the documents of `x`, also of
#'   those in which spaCy found no tokens, and the document variables of a
#'   \pkg{quanteda} corpus, for the [quanteda methods][quanteda-methods] such
#'   as `quanteda::as.tokens()`.
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
#'
#' # the position of each token in the text
#' parsed <- spacy_parse(txt3, offsets = TRUE)
#' substring(txt3, parsed$start, parsed$end)
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
                        offsets = FALSE,
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
                                  offsets = FALSE,
                                  ...) {
    `:=` <- `.` <- `.N` <- `.I` <- NULL
    check_multithread(multithread, "spacy_parse")
    check_offsets(offsets)
    args <- pipe_args(n_process, batch_size)
    docvars <- input_docvars(x)
    input <- spacy_input(x)

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
                                n_process = args$n_process,
                                offsets = offsets)
    warn_skipped(spobj)
    cols <- parsed$columns
    if (length(cols$token) == 0) {
        empty <- empty_spacyr_parsed(lemma = lemma, pos = pos, tag = tag,
                                     dependency = dependency, entity = entity,
                                     nounphrase = nounphrase,
                                     additional_attributes = additional_attributes,
                                     offsets = offsets)
        return(set_parsed_documents(empty, input$docnames, docvars))
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
    set_parsed_documents(dt, input$docnames, docvars)
}


#' @export
spacy_parse.data.frame <- function(x, ...) {
    spacy_parse(tif_texts(x), ...)
}


#' Process documents with spaCy (deprecated)
#'
#' @description
#' This function is deprecated, and will be removed in a future version of
#' \pkg{spacyr}, together with the [get-functions] that read its result. It
#' gives a warning on every call. Use [spacy_parse()] instead, which returns
#' all the results in one data.frame.
#'
#' `process_document()` parses documents with spaCy and returns a handle on
#' the parsed documents, which are kept in Python until the handle is
#' garbage collected. They are not affected by later calls to other
#' \pkg{spacyr} functions. The handle does not keep the language model:
#' [spacy_finalize()] frees it as usual.
#' @param x a character object or a \pkg{quanteda} corpus
#' @param multithread deprecated; see [spacy_parse()]
#' @param n_process,batch_size passed to spaCy's `nlp.pipe()`; see
#'   [spacy_parse()]
#' @param ... not used
#' @return an object of class `spacy_out`, for the [get-functions]
#' @importFrom methods new
#' @examples
#' \dontrun{
#' spacy_initialize()
#' txt <- c(text1 = "This is the first sentence.\nHere is the second sentence.",
#'          text2 = "This is the second document.")
#' # instead of process_document() and get_tokens():
#' spacy_parse(txt)$token
#' }
#' @export
#' @keywords internal
process_document <- function(x, multithread, n_process = 1L, batch_size = NULL, ...) {
    deprecation_warning(paste0(
        "`process_document()` is deprecated and will be removed in a future ",
        "version of spacyr, together with the get_*() functions. Use ",
        "`spacy_parse()` instead."))
    check_multithread(multithread, "process_document")
    args <- pipe_args(n_process, batch_size)
    input <- spacy_input(x)
    spobj <- new_spobj()
    # named by document; a document that the pipeline left out has none
    timestamps <- unlist(spobj$parse(input$x, input$docnames,
                                     batch_size = args$batch_size,
                                     n_process = args$n_process))
    warn_skipped(spobj)
    # the handle keeps the parsed documents, but not the pipeline
    spobj$release_pipeline()
    spacy_out$new(docnames = as.character(names(timestamps)),
                  timestamps = as.character(timestamps),
                  spobj = spobj)
}


# zero-row result with the columns and types of a parse that has tokens;
# additional attributes are logical, since their type cannot be known
empty_spacyr_parsed <- function(lemma, pos, tag, dependency, entity, nounphrase,
                                additional_attributes, offsets = FALSE) {
    cols <- list(doc_id = character(), sentence_id = integer(),
                 token_id = integer(), token = character())
    if (offsets) {
        cols$start <- integer()
        cols$end <- integer()
    }
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
