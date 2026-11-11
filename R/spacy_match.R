#' Match patterns in texts using spaCy
#'
#' Find the tokens that match patterns, using spaCy's rule-based matchers
#' (see <https://spacy.io/usage/rule-based-matching>). A pattern describes
#' either a sequence of adjacent tokens, or tokens that are connected in the
#' dependency parse, wherever they are in the sentence: the verb of a passive
#' clause together with its subject and its agent, for instance. A token is
#' described by its attributes, which can be those that the language model
#' assigns, such as the part of speech or the dependency relation. Phrases,
#' and the values of a **quanteda** dictionary, can be matched too. Every
#' kind of pattern gives rows of the same table. Unlike the patterns given to
#' [spacy_initialize()] as `entity_patterns`, these do not change the
#' pipeline or the entities of a document.
#'
#' @param x a character object, a **quanteda** corpus, or a TIF-compliant
#'   corpus data.frame (see <https://github.com/ropensci/tif>)
#' @param pattern the patterns to match, either:
#'   * a named list, in which each name is the label of a pattern, and each
#'     element is a pattern in spaCy's structure. The names must be unique.
#'     An element is one of two kinds, and a list can hold both:
#'       * a *token pattern*, for a sequence of adjacent tokens: a list with
#'         one named list of attributes for each token, such as
#'         `list(list(LOWER = "new"), list(LOWER = "york"))`. An element can
#'         also be a list of such token patterns, which are then alternatives
#'         for that label.
#'       * a *dependency pattern*, for tokens related in the dependency
#'         parse: a list of nodes, each a named list that describes one
#'         token, with `RIGHT_ID`, a name for the node, which labels the
#'         token it matches in the output; `RIGHT_ATTRS`, the attributes of
#'         the token as in a token pattern, such as
#'         `list(DEP = "nsubjpass")`, or an empty `list()` for any token;
#'         and, for every node but the first, `LEFT_ID` and `REL_OP`, the
#'         name of an earlier node and the operator that relates that node
#'         to this one, such as `">"` when this node is a direct dependent
#'         of the earlier one. An element whose nodes have these keys is
#'         read as a dependency pattern. Each label has one dependency
#'         pattern: give alternative patterns labels of their own.
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
#' @param overlap which matches of sequences to return where matches of the
#'   same label overlap: `"longest"` (the default) keeps the longest of them,
#'   and of those of the same length the one that starts first; `"first"`
#'   keeps the one that starts first, and of those with the same start the
#'   longest; `"all"` returns every match, including those inside or
#'   overlapping another, as spaCy does. Matches of different labels can
#'   overlap whatever the value. It does not apply to dependency patterns,
#'   all of whose matches are returned.
#' @inheritParams spacy_parse
#' @param ... not used. An argument that is not one of those above is an
#'   error.
#' @section Kinds of pattern:
#' What applies to each kind of pattern:
#'
#' |                        | Token patterns | Phrases and dictionary values | Dependency patterns |
#' |------------------------|----------------|-------------------------------|---------------------|
#' | Given in `pattern` as  | an element of a named list, or in a `spacyr_entity_patterns` object | a `spacyr_entity_patterns` object or a dictionary | an element of a named list |
#' | A match is             | a sequence of adjacent tokens | a sequence of adjacent tokens | one token for each node, anywhere in a sentence |
#' | Matched by spaCy's     | `Matcher` | `PhraseMatcher`, or `Matcher` for values with wildcards | `DependencyMatcher` |
#' | Patterns for one label | any number, as alternatives | any number, as alternatives | one |
#' | `overlap`              | applies | applies | does not apply |
#' | `n_process`, `batch_size` | apply | apply | apply |
#' | Rows for one match     | one | one | one for each node |
#' | The pipeline needs     | the components that set the attributes asked for | only its tokenizer | a dependency parse, in every document |
#'
#' Patterns of every kind are matched in one pass over the documents, so the
#' texts are parsed once for a list that holds both token and dependency
#' patterns.
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
#' which stays fast for many thousands of phrases. A phrase that matches in
#' any case, as dictionary values do, is tokenized as it is written, and
#' spaCy's tokenizer can split the same word differently in another case:
#' it keeps `"Inc."` as one token but splits `"inc."` into two, so the phrase
#' `"acme widgets, inc."` does not match the text `"Acme Widgets, Inc."`,
#' while the phrase `"Acme Widgets, Inc."` in any case does. A warning is
#' given when
#' a component of the pipeline, such as `merge_entities`, changes the tokens
#' of the documents, since phrases may then not match.
#'
#' The operators in the `REL_OP` of a dependency pattern are spaCy's: among
#' others, `"A > B"` when B is a direct dependent of A, `"A < B"` when B is
#' the head of A, `"A >> B"` when B is anywhere below A, and `"A . B"` when B
#' directly follows A; see
#' <https://spacy.io/usage/rule-based-matching#dependencymatcher> for all of
#' them. A dependency pattern can match many times in a sentence: a verb and
#' any one of its dependents gives one match for each dependent. The pipeline
#' needs a dependency parser, or another component that sets dependencies:
#' when `pattern` holds a dependency pattern that relates nodes, a document
#' that has no dependency parse is an error, rather than a document without
#' matches.
#'
#' Matching adds little to the time that parsing takes, except for many
#' token patterns: a few thousand make it much slower, so give phrases as
#' phrases where you can, not as token patterns. Dictionary values with
#' wildcards are token patterns, but those of a single word are combined
#' into one for each label. Patterns that need no entities are faster after
#' `spacy_initialize(entity = FALSE)`.
#' @section Matches and quanteda:
#' With `overlap = "longest"`, the default, the values of a dictionary match
#' as they do in [quanteda::tokens_lookup()] with its default,
#' `nested_scope = "key"`, when that is applied to spaCy's tokens,
#' `quanteda::as.tokens(spacy_parse(x))`: no token is in two matches of the
#' same key, and a value that lies inside a value of another key is a match
#' for both keys. So the number of matches of each label in each document is
#' the count that `tokens_lookup()` gives for that key.
#'
#' [quanteda::kwic()] follows a different rule, which no value of `overlap`
#' gives: it drops a match only when every one of its tokens is in another
#' match, of any pattern. So it drops "New York" inside another label's "New
#' York Times", which `overlap = "longest"` keeps, and keeps both of two
#' matches of one label that partly overlap, of which `overlap = "longest"`
#' keeps one.
#' @returns A `data.frame` with the same columns for every kind of pattern,
#'   and no rows when nothing matches. A match of a sequence is one row. A
#'   match of a dependency pattern is one row for each node of the pattern,
#'   each of `length` 1, with the same `match_id`; two nodes can match the
#'   same token, which then has a row for each.
#'   \describe{
#'   \item{`doc_id`}{the document}
#'   \item{`match_id`}{the number of the match within the document, starting
#'   at 1 in each document, so that `doc_id` and `match_id` together
#'   identify a match}
#'   \item{`label`}{the label of the pattern that matched. It does not say
#'   which of a label's alternative patterns matched, which spaCy does not
#'   report.}
#'   \item{`node`}{for a dependency pattern, the name of the node that the
#'   token matched, from `RIGHT_ID`; `NA` for a sequence}
#'   \item{`sentence_id`, `token_id`}{the sentence of the first token of the
#'   sequence, or of the node's token, and the position of that token in its
#'   sentence, both starting at 1 as in [spacy_parse()]. A sequence that
#'   crosses a sentence boundary is given the sentence of its first token.
#'   Both are `NA` when the document has no sentence boundaries, as when the
#'   pipeline has neither a parser nor a sentence segmenter.}
#'   \item{`text`}{the matched text: of the whole sequence, or of the node's
#'   token}
#'   \item{`start_id`}{the position in the document of the first token of
#'   the sequence, or of the node's token, starting at 1 and counting every
#'   token of spaCy's, as the rows of [spacy_parse()] do}
#'   \item{`length`}{the number of tokens: of the sequence, or 1 for a node}
#'   }
#'   Rows are in the order of the documents in `x`. Within a document,
#'   matches are in the order of the `start_id` of their first row: the
#'   first token of a sequence, or the token of the first node of a
#'   dependency pattern. Of the matches that start at the same token,
#'   sequences come first, by `length` (the shortest first) and then by the
#'   order of the labels in `pattern`; matches of dependency patterns follow,
#'   by the positions of the tokens of their other nodes, taken in the order
#'   of the nodes, and then by the order of the labels. `match_id` numbers
#'   the matches of a document in that order, sequences and dependency
#'   matches together, and the rows of a dependency match are in the order of
#'   the pattern's nodes. The order does not depend on `overlap`.
#' @seealso [as_entity_patterns()] and [spacy_initialize()] to make matches
#'   named entities.
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
#' passive <- list(list(DEP = "auxpass"),
#'                 list(DEP = list(IN = c("advmod", "neg", "aux", "auxpass")),
#'                      OP = "*"),
#'                 list(TAG = "VBN"))
#' spacy_match(txt, list(PASSIVE = passive))
#'
#' # two labels, the second with alternative patterns
#' spacy_match(txt, list(
#'   DET_NOUN = list(list(POS = "DET"), list(POS = "NOUN")),
#'   WRITE = list(list(list(LEMMA = "write")),
#'                list(list(LEMMA = "rewrite")))
#' ))
#'
#' # phrases, matched exactly or in any case
#' spacy_match(txt, as_entity_patterns(c(TITLE = "the book")))
#' spacy_match(txt, as_entity_patterns(c(TITLE = "the book"),
#'                                     case_insensitive = TRUE))
#'
#' # a quanteda dictionary, with its wildcards
#' dict <- quanteda::dictionary(list(writing = c("writ*", "wrote", "the book"),
#'                                   error = "mistake*"))
#' spacy_match(txt, dict)
#'
#' # a dependency pattern for passive clauses: a past participle with a
#' # passive subject and a passive auxiliary as its dependents
#' clause <- list(
#'   list(RIGHT_ID = "verb", RIGHT_ATTRS = list(TAG = "VBN")),
#'   list(LEFT_ID = "verb", REL_OP = ">", RIGHT_ID = "subject",
#'        RIGHT_ATTRS = list(DEP = "nsubjpass")),
#'   list(LEFT_ID = "verb", REL_OP = ">", RIGHT_ID = "aux",
#'        RIGHT_ATTRS = list(DEP = "auxpass"))
#' )
#' m <- spacy_match(txt, list(CLAUSE = clause))
#' m
#'
#' # one row for each match, with a column for each node
#' reshape(m[, c("doc_id", "match_id", "node", "text")],
#'         idvar = c("doc_id", "match_id"), timevar = "node",
#'         direction = "wide")
#'
#' # token and dependency patterns in one list
#' spacy_match(txt, list(PASSIVE = passive, CLAUSE = clause))
#' }
spacy_match <- function(x, pattern, overlap = c("longest", "all", "first"),
                        n_process = 1L, batch_size = NULL, ...) {
    UseMethod("spacy_match")
}

#' @export
spacy_match.character <- function(x, pattern,
                                  overlap = c("longest", "all", "first"),
                                  n_process = 1L, batch_size = NULL, ...) {
    # checked before spaCy is initialized
    check_unused_args(match.call(expand.dots = FALSE)$...)
    overlap <- match.arg(overlap)
    args <- pipe_args(n_process, batch_size)
    if (missing(pattern)) stop("pattern must be supplied", call. = FALSE)
    pattern <- match_patterns(pattern)

    input <- spacy_input(x)

    module <- spacyr_module()
    attrs <- c(unlist(pattern$patterns, recursive = FALSE),
               lapply(pattern$dependency, function(d)
                   lapply(d$pattern, `[[`, "RIGHT_ATTRS")))
    if (needs_entities(list(pattern = attrs)) &&
        !module$any_sets_entities(spacyr_env$nlp))
        warning("Some patterns need entities (ENT_TYPE or ENT_IOB), but no ",
                "component of the pipeline sets entities, so they will not match",
                call. = FALSE)

    if (length(pattern$phrases)) {
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
                          labels = as.list(pattern$labels),
                          patterns = pattern$patterns,
                          phrases = pattern$phrases,
                          dependency = pattern$dependency, greedy = greedy,
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
                      match_id = int(res$match_id),
                      label = chr(res$label),
                      node = chr(res$node),
                      sentence_id = int(res$sentence_id),
                      token_id = int(res$token_id),
                      text = chr(res$text),
                      start_id = int(res$start_id),
                      length = int(res$length),
                      stringsAsFactors = FALSE)
    # Python gives "" as the node of a sequence, and 0 where a document has
    # no sentence boundaries
    out$node[!nzchar(out$node)] <- NA_character_
    out$sentence_id[out$sentence_id == 0L] <- NA_integer_
    out$token_id[out$token_id == 0L] <- NA_integer_
    out
}

#' @export
spacy_match.data.frame <- function(x, ...) {
    spacy_match(tif_texts(x), ...)
}

# Stop on the arguments that a function was given through `...` and does not
# use, which would otherwise be ignored: a misspelt argument, or one that
# belongs to another function. dots holds those arguments, unevaluated, as
# match.call(expand.dots = FALSE)$... gives them.
check_unused_args <- function(dots, fun = "spacy_match") {
    n <- length(dots)
    if (n < 1L) return(invisible(TRUE))
    named <- names(dots)
    named <- named[nzchar(named)]
    unnamed <- n - length(named)
    stop(fun, "() does not use ",
         if (n == 1L) "the argument " else "the arguments ",
         paste(c(named, if (unnamed > 0L) paste(unnamed, "without a name")),
               collapse = ", "),
         if (any(c("valuetype", "case_insensitive") %in% named))
             paste0("; to set how phrases or the values of a dictionary ",
                    "match, convert them with as_entity_patterns()"),
         call. = FALSE)
}

# The labels and patterns for spaCy's matchers: labels is a character vector
# of every label, in the order given; patterns a list parallel to it with,
# for each label, the list of its alternative token patterns (which may be
# empty), each normalized as for as_entity_patterns(); phrases a list with
# the label, text and case_insensitive of each phrase, which only an entity
# patterns object or a dictionary can hold; and dependency a list with the
# label and pattern of each dependency pattern, which only a list can hold.
match_patterns <- function(x) {
    if (inherits(x, c("spacyr_entity_patterns", "dictionary2"))) {
        x <- as_entity_patterns(x)
        if (!nrow(x)) stop("pattern holds no patterns", call. = FALSE)
        phrase <- vapply(x$pattern, is.character, logical(1))
        labels <- unique(x$label)
        patterns <- lapply(labels, function(l) unname(x$pattern[x$label == l & !phrase]))
        phrases <- lapply(which(phrase), function(i)
            list(label = x$label[i], text = x$pattern[[i]],
                 case_insensitive = isTRUE(x$case_insensitive[i])))
        check_no_dependency(labels, patterns)
        return(list(labels = labels, patterns = patterns, phrases = phrases,
                    dependency = list()))
    }
    if (!is.list(x) || is.data.frame(x))
        stop("pattern must be a named list of token patterns or dependency ",
             "patterns, a spacyr_entity_patterns object or a quanteda ",
             "dictionary", call. = FALSE)
    if (!length(x)) stop("pattern holds no patterns", call. = FALSE)
    labels <- names(x)
    if (is.null(labels) || any(is.na(labels) | !nzchar(labels)))
        stop("pattern must be a named list, in which each name is the label ",
             "of a pattern", call. = FALSE)
    if (anyDuplicated(labels))
        stop("The names of pattern must be unique; give the alternative ",
             "token patterns of a label as one element, a list of token ",
             "patterns, and alternative dependency patterns labels of their ",
             "own: ", paste(unique(labels[duplicated(labels)]), collapse = ", "),
             call. = FALSE)
    labels <- enc2utf8(labels)
    patterns <- rep(list(list()), length(x))
    dependency <- list()
    for (i in seq_along(x)) {
        what <- paste0("'", labels[i], "'")
        if (is_dependency_pattern(x[[i]])) {
            dependency[[length(dependency) + 1L]] <-
                list(label = labels[i], pattern = dependency_pattern(x[[i]], what))
        } else {
            patterns[[i]] <- token_patterns(x[[i]], what)
        }
    }
    list(labels = labels, patterns = patterns, phrases = list(),
         dependency = dependency)
}

# The alternative token patterns of one label of a list, each normalized as
# for as_entity_patterns(): p is one token pattern, or a list of them.
token_patterns <- function(p, what) {
    if (is.character(p))
        stop("Pattern ", what, " is a phrase; in a list, patterns are ",
             "token patterns or dependency patterns. Give phrases as an ",
             "as_entity_patterns() object", call. = FALSE)
    if (!is.list(p) || !length(p))
        stop("Pattern ", what, " is not a list of tokens (a token pattern) ",
             "or of nodes (a dependency pattern)", call. = FALSE)
    # one token pattern, or a list of alternative token patterns
    if (all(vapply(p, is_token_pattern, logical(1))))
        return(list(normalize_pattern(p, what)))
    if (!is.null(names(p)) && any(nzchar(names(p))))
        return(list(normalize_pattern(p, what)))     # gives the error
    lapply(seq_along(p), function(j) {
        alt <- paste0(what, " (alternative ", j, ")")
        if (is.character(p[[j]]))
            stop("Pattern ", alt, " is a phrase; in a list, patterns are ",
                 "token patterns or dependency patterns. Give phrases as an ",
                 "as_entity_patterns() object", call. = FALSE)
        normalize_pattern(p[[j]], alt)
    })
}

# a token of a token pattern: a named list of attributes, or an empty list,
# which matches any token
is_token_pattern <- function(tok) {
    is.list(tok) && (!length(tok) ||
                         (!is.null(names(tok)) && all(nzchar(names(tok)))))
}

# The keys of the nodes of a dependency pattern, which tell it from a token
# pattern: spaCy's Matcher would reject them as unknown attributes.
dependency_keys <- c("RIGHT_ID", "RIGHT_ATTRS", "LEFT_ID", "REL_OP")

is_dependency_node <- function(node) {
    is.list(node) && any(toupper(names(node)) %in% dependency_keys)
}

# Whether an element of a list of patterns is a dependency pattern: one of
# its nodes has a key of a dependency pattern. So has a single node given
# without list(), and a node of one of several patterns given as
# alternatives, which dependency_pattern() then rejects.
is_dependency_pattern <- function(p) {
    if (!is.list(p)) return(FALSE)
    is_dependency_node(p) || any(vapply(p, function(node) {
        is_dependency_node(node) ||
            (is.list(node) && is.null(names(node)) &&
                 any(vapply(node, is_dependency_node, logical(1))))
    }, logical(1)))
}

# An entity patterns object holds patterns for the entity ruler, which are
# sequences of tokens.
check_no_dependency <- function(labels, patterns) {
    dep <- vapply(patterns, function(alternatives) {
        any(vapply(alternatives, is_dependency_pattern, logical(1)))
    }, logical(1))
    if (any(dep))
        stop("Pattern '", labels[dep][1], "' is a dependency pattern (with ",
             "RIGHT_ID and RIGHT_ATTRS), which entity patterns cannot hold; ",
             "give dependency patterns in a named list", call. = FALSE)
    invisible(TRUE)
}

# The dependency pattern of one label of a list, normalized as for
# as_entity_patterns(). Each node must have a name (RIGHT_ID), since the
# output is labelled by it, and its attributes (RIGHT_ATTRS), without which
# spaCy gives a bare KeyError; the relations between the nodes are left to
# spaCy to check.
dependency_pattern <- function(p, what) {
    if (!is.null(names(p)) && any(nzchar(names(p))))
        stop("Pattern ", what, " is a single node; wrap it in list(), ",
             "since a pattern is a list with one node per token", call. = FALSE)
    is_node <- vapply(p, is_token_pattern, logical(1))
    # a list of patterns: unnamed lists that themselves hold lists
    if (!all(is_node) && all(vapply(p[!is_node], function(q)
        is.list(q) && all(vapply(q, is.list, logical(1))), logical(1))))
        stop("Pattern ", what, " holds more than one pattern; each label ",
             "has one dependency pattern, so give alternative patterns ",
             "labels of their own", call. = FALSE)
    if (!all(is_node))
        stop("Node ", which(!is_node)[1], " of pattern ", what,
             " is not a named list", call. = FALSE)
    for (j in seq_along(p)) {
        node <- p[[j]]
        if (!is_string(node$RIGHT_ID))
            stop("Node ", j, " of pattern ", what, " has no RIGHT_ID, a ",
                 "name for the node", call. = FALSE)
        if (!is.list(node$RIGHT_ATTRS) || !is_token_pattern(node$RIGHT_ATTRS))
            stop("Node ", j, " of pattern ", what, " ('", node$RIGHT_ID,
                 "') has no RIGHT_ATTRS, a named list of token attributes ",
                 "or an empty list()", call. = FALSE)
    }
    ids <- vapply(p, function(node) node$RIGHT_ID, character(1))
    if (anyDuplicated(ids))
        stop("Pattern ", what, " names more than one node '",
             ids[duplicated(ids)][1], "'; each RIGHT_ID must be unique",
             call. = FALSE)
    normalize_pattern(p, what)
}
