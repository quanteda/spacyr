#' Extract matches of token patterns and phrases from texts using spaCy
#'
#' Find sequences of tokens that match patterns, using spaCy's rule-based
#' `Matcher` (see <https://spacy.io/usage/rule-based-matching>). A pattern
#' describes each token of a sequence by its attributes, which can be those
#' that the language model assigns, such as the part of speech or the
#' dependency relation. Phrases, and the values of a **quanteda** dictionary,
#' can be matched too. Unlike the patterns given to
#' [spacy_initialize()] as `entity_patterns`, these do not change the
#' pipeline or the entities of a document.
#'
#' @param x a character object or a TIF-compliant
#'   corpus data.frame (see <https://github.com/ropensci/tif>)
#' @param patterns the patterns to match, either:
#'   * a named list, in which each name is the label of a pattern, and each
#'     element is a token pattern in spaCy's structure: a list with one named
#'     list of attributes for each token, such as
#'     `list(list(LOWER = "new"), list(LOWER = "york"))`. An element can
#'     also be a list of such token patterns, which are then alternatives for
#'     that label. The names must be unique.
#'   * a `spacyr_entity_patterns` object from [as_entity_patterns()], whose
#'     labels become the labels of the matches. Patterns with the same label
#'     are alternatives for that label, and the IDs of the patterns are
#'     ignored. The object can hold phrases as well as token patterns; this
#'     is the way to match phrases, exactly or, with
#'     `case_insensitive = TRUE`, in any case.
#'   * a **quanteda** dictionary, which is converted with
#'     [as_entity_patterns()] and its defaults: the top-level keys are the
#'     labels, and values match in any case, with wildcards as in
#'     **quanteda**. Call [as_entity_patterns()] yourself to change these.
#' @param overlap which matches to return where matches of the same label
#'   overlap: `"all"` (the default) returns every match, including those
#'   inside or overlapping another, as spaCy does; `"longest"` keeps the
#'   longest of them, and `"first"` the one that starts first. Matches of
#'   different labels can overlap whatever the value.
#' @inheritParams spacy_parse
#' @param ... unused
#' @details
#' Patterns are matched against spaCy's tokens, and an attribute can only
#' match when a component of the pipeline sets it: `DEP` needs the parser,
#' for instance, and spaCy gives an error when the component is missing.
#' Patterns that ask for an entity type (`ENT_TYPE` or `ENT_IOB`) give a
#' warning when no component sets entities, as after
#' `spacy_initialize(entity = FALSE)`, since they then match nothing. The
#' labels of tags and dependency relations differ between language models;
#' `spacy_parse(x, tag = TRUE, dependency = TRUE)` shows those of the
#' model in use. A match is only as good as the model's annotation of the
#' text.
#'
#' The values of spaCy's set operators (`IN`, `NOT_IN`, `IS_SUBSET`,
#' `IS_SUPERSET` and `INTERSECTS`) can be vectors of any length, and whole
#' numbers need not be integers, as for [as_entity_patterns()].
#'
#' Phrases are split into tokens by spaCy's tokenizer, and match the same
#' sequence of tokens in a document, as described for
#' [as_entity_patterns()]. They are matched with spaCy's `PhraseMatcher`,
#' which stays fast for many thousands of phrases. A warning is given when
#' a component of the pipeline, such as `merge_entities`, changes the tokens
#' of the documents, since phrases may then not match.
#'
#' Matching adds little to the time that parsing takes, except for many
#' token patterns: a few thousand make it much slower, so give phrases as
#' phrases where you can, not as token patterns. Dictionary values with
#' wildcards are token patterns, but those of a single word are combined
#' into one for each label. Patterns that need no entities are faster after
#' `spacy_initialize(entity = FALSE)`.
#' @returns A `data.frame` with one row for each match, and no rows when
#'   nothing matches:
#'   \describe{
#'   \item{`doc_id`}{the document}
#'   \item{`sentence_id`, `token_id`}{the sentence of the first token of the
#'   match, and the position of that token in its sentence, both starting at
#'   1 as in [spacy_parse()]. A match that crosses a sentence boundary is
#'   given the sentence of its first token. Both are `NA` when the document
#'   has no sentence boundaries, as when the pipeline has neither a parser
#'   nor a sentence segmenter.}
#'   \item{`label`}{the label of the pattern that matched. It does not say
#'   which of a label's alternative patterns matched, which spaCy does not
#'   report.}
#'   \item{`text`}{the matched text}
#'   \item{`start_id`}{the position of the first token of the match in the
#'   document, starting at 1, as in [spacy_extract_entity()]}
#'   \item{`length`}{the number of tokens matched}
#'   }
#'   Rows are in the order of the documents in `x`; within a document, by
#'   `start_id`, then by `length` (the shortest first), then by the order of
#'   the labels in `patterns`. The order does not depend on `overlap`.
#' @seealso [spacy_extract_dependency_matches()] for tokens connected in the
#'   dependency parse; [as_entity_patterns()] and [spacy_initialize()] to make
#'   matches named entities.
#' @export
#' @examples
#' \dontrun{
#' spacy_initialize()
#'
#' txt <- c(doc1 = "The book was written by Jane. Jane wrote the book.",
#'          doc2 = "Mistakes were made, and the report is being rewritten.")
#'
#' # passive verbs, by the dependency and tag labels of the English models:
#' # a passive auxiliary, any adverbs or further auxiliaries, and a past
#' # participle
#' passive <- list(
#'   PASSIVE = list(list(DEP = "auxpass"),
#'                  list(DEP = list(IN = c("advmod", "neg", "aux", "auxpass")),
#'                       OP = "*"),
#'                  list(TAG = "VBN"))
#' )
#' spacy_extract_matches(txt, passive)
#'
#' # two labels, the second with alternative patterns
#' spacy_extract_matches(txt, list(
#'   DET_NOUN = list(list(POS = "DET"), list(POS = "NOUN")),
#'   WRITE = list(list(list(LEMMA = "write")),
#'                list(list(LEMMA = "rewrite")))
#' ))
#'
#' # phrases, matched exactly or in any case
#' spacy_extract_matches(txt, as_entity_patterns(c(TITLE = "the book")))
#' spacy_extract_matches(txt, as_entity_patterns(c(TITLE = "the book"),
#'                                               case_insensitive = TRUE))
#'
#' # a quanteda dictionary, with its wildcards
#' dict <- quanteda::dictionary(list(writing = c("writ*", "wrote", "the book"),
#'                                   error = "mistake*"))
#' spacy_extract_matches(txt, dict)
#' }
spacy_extract_matches <- function(x, patterns,
                                  overlap = c("all", "longest", "first"),
                                  n_process = 1L, batch_size = NULL, ...) {
    UseMethod("spacy_extract_matches")
}

#' @export
spacy_extract_matches.character <- function(x, patterns,
                                            overlap = c("all", "longest", "first"),
                                            n_process = 1L, batch_size = NULL, ...) {
    # checked before spaCy is initialized
    overlap <- match.arg(overlap)
    args <- pipe_args(n_process, batch_size)
    if (missing(patterns)) stop("patterns must be supplied", call. = FALSE)
    patterns <- match_patterns(patterns)

    input <- spacy_input(x)

    module <- spacyr_module()
    if (needs_entities(list(pattern = unlist(patterns$patterns, recursive = FALSE))) &&
        !module$any_sets_entities(spacyr_env$nlp))
        warning("Some patterns need entities (ENT_TYPE or ENT_IOB), but no ",
                "component of the pipeline sets entities, so they will not match",
                call. = FALSE)

    if (length(patterns$phrases)) {
        retok <- unlist(module$retokenizers(spacyr_env$nlp))
        if (length(retok))
            warning("Phrases may not match, since ",
                    paste0("'", retok, "'", collapse = ", "),
                    if (length(retok) == 1) " changes" else " change",
                    " the tokens of the documents; phrases are tokenized without ",
                    if (length(retok) == 1) "it" else "them", call. = FALSE)
    }

    spobj <- new_spobj()
    greedy <- switch(overlap, all = NULL, longest = "LONGEST", first = "FIRST")
    res <- tryCatch(
        spobj$match_table(texts = input$x, docnames = input$docnames,
                          labels = as.list(patterns$labels),
                          patterns = patterns$patterns,
                          phrases = patterns$phrases, greedy = greedy,
                          batch_size = args$batch_size, n_process = args$n_process),
        error = function(e) {
            msg <- sub("\\s*Run `reticulate::py_last_error\\(\\)`.*$", "",
                       conditionMessage(e))
            stop("spaCy could not match the patterns:\n", msg, call. = FALSE)
        }
    )
    warn_skipped(spobj)

    int <- function(v) as.integer(unlist(v))
    chr <- function(v) as.character(unlist(v))
    out <- data.frame(doc_id = chr(res$doc_id),
                      sentence_id = int(res$sentence_id),
                      token_id = int(res$token_id),
                      label = chr(res$label),
                      text = chr(res$text),
                      start_id = int(res$start_id),
                      length = int(res$length),
                      stringsAsFactors = FALSE)
    # Python gives 0 where a document has no sentence boundaries
    out$sentence_id[out$sentence_id == 0L] <- NA_integer_
    out$token_id[out$token_id == 0L] <- NA_integer_
    out
}

#' @export
spacy_extract_matches.data.frame <- function(x, ...) {
    spacy_extract_matches(tif_texts(x), ...)
}

# The labels and patterns for spaCy's matchers: labels is a character vector;
# patterns a list with, for each label, the list of its alternative token
# patterns (which may be empty), each normalized as for as_entity_patterns();
# and phrases a list with the label, text and case_insensitive of each
# phrase, which only an entity patterns object or a dictionary can hold.
match_patterns <- function(x) {
    if (inherits(x, c("spacyr_entity_patterns", "dictionary2"))) {
        x <- as_entity_patterns(x)
        if (!nrow(x)) stop("patterns holds no patterns", call. = FALSE)
        phrase <- vapply(x$pattern, is.character, logical(1))
        labels <- unique(x$label)
        patterns <- lapply(labels, function(l) unname(x$pattern[x$label == l & !phrase]))
        phrases <- lapply(which(phrase), function(i)
            list(label = x$label[i], text = x$pattern[[i]],
                 case_insensitive = isTRUE(x$case_insensitive[i])))
        check_no_dependency(labels, patterns)
        return(list(labels = labels, patterns = patterns, phrases = phrases))
    }
    if (!is.list(x) || is.data.frame(x))
        stop("patterns must be a named list of token patterns, a ",
             "spacyr_entity_patterns object or a quanteda dictionary",
             call. = FALSE)
    if (!length(x)) stop("patterns holds no patterns", call. = FALSE)
    labels <- names(x)
    if (is.null(labels) || any(is.na(labels) | !nzchar(labels)))
        stop("patterns must be a named list, in which each name is the label ",
             "of a pattern", call. = FALSE)
    if (anyDuplicated(labels))
        stop("The names of patterns must be unique; give the alternative ",
             "patterns of a label as one element, a list of token patterns: ",
             paste(unique(labels[duplicated(labels)]), collapse = ", "),
             call. = FALSE)
    labels <- enc2utf8(labels)
    patterns <- lapply(seq_along(x), function(i) {
        p <- x[[i]]
        what <- paste0("'", labels[i], "'")
        if (is.character(p))
            stop("Pattern ", what, " is a phrase; in a list, patterns are ",
                 "token patterns. Give phrases as an as_entity_patterns() ",
                 "object", call. = FALSE)
        if (!is.list(p) || !length(p))
            stop("Pattern ", what, " is not a list of token patterns", call. = FALSE)
        # one token pattern, or a list of alternative token patterns
        if (all(vapply(p, is_token_pattern, logical(1))))
            return(list(normalize_pattern(p, what)))
        if (!is.null(names(p)) && any(nzchar(names(p))))
            return(list(normalize_pattern(p, what)))     # gives the error
        lapply(seq_along(p), function(j) {
            alt <- paste0(what, " (alternative ", j, ")")
            if (is.character(p[[j]]))
                stop("Pattern ", alt, " is a phrase; in a list, patterns are ",
                     "token patterns. Give phrases as an as_entity_patterns() ",
                     "object", call. = FALSE)
            normalize_pattern(p[[j]], alt)
        })
    })
    check_no_dependency(labels, patterns)
    list(labels = labels, patterns = patterns, phrases = list())
}

# a token of a token pattern: a named list of attributes, or an empty list,
# which matches any token
is_token_pattern <- function(tok) {
    is.list(tok) && (!length(tok) ||
                         (!is.null(names(tok)) && all(nzchar(names(tok)))))
}

# Dependency patterns are for spaCy's DependencyMatcher; the Matcher would
# reject their keys as unknown attributes.
check_no_dependency <- function(labels, patterns) {
    keys <- c("RIGHT_ID", "RIGHT_ATTRS", "LEFT_ID", "REL_OP")
    dep <- vapply(patterns, function(alternatives) {
        any(vapply(alternatives, function(p) {
            any(vapply(p, function(tok) any(toupper(names(tok)) %in% keys),
                       logical(1)))
        }, logical(1)))
    }, logical(1))
    if (any(dep))
        stop("Pattern '", labels[dep][1], "' is a dependency pattern (with ",
             "RIGHT_ID and RIGHT_ATTRS); use ",
             "spacy_extract_dependency_matches()", call. = FALSE)
    invisible(TRUE)
}
