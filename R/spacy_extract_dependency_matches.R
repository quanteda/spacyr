#' Extract matches of dependency patterns from texts using spaCy
#'
#' Find tokens that are connected in the dependency parse in the way a
#' pattern describes, using spaCy's `DependencyMatcher` (see
#' <https://spacy.io/usage/rule-based-matching#dependencymatcher>). Where
#' [spacy_extract_matches()] finds sequences of adjacent tokens, a dependency
#' pattern finds tokens by their relations, wherever they are in the
#' sentence, and returns each of them: the verb of a passive clause together
#' with its subject and its agent, for instance.
#'
#' @param x a character object or a TIF-compliant
#'   corpus data.frame (see <https://github.com/ropensci/tif>)
#' @param patterns a named list of dependency patterns in spaCy's structure,
#'   in which each name is the label of a pattern. A pattern is a list of
#'   nodes, each a named list that describes one token:
#'   * `RIGHT_ID`: a name for the node, which labels the token it matches in
#'     the output;
#'   * `RIGHT_ATTRS`: the attributes of the token, as for a token of
#'     [spacy_extract_matches()], such as `list(DEP = "nsubjpass")`; an
#'     empty `list()` matches any token;
#'   * `LEFT_ID` and `REL_OP`, for every node but the first: the name of an
#'     earlier node, and the operator that relates that node to this one,
#'     such as `">"` when this node is a direct dependent of the earlier one.
#'
#'   The names must be unique, and each label has one pattern: give
#'   alternative patterns labels of their own.
#' @inheritParams spacy_parse
#' @param ... unused
#' @details
#' The operators in `REL_OP` are spaCy's: among others, `"A > B"` when B is
#' a direct dependent of A, `"A < B"` when B is the head of A, `"A >> B"`
#' when B is anywhere below A, and `"A . B"` when B directly follows A. See
#' the link above for all of them.
#'
#' The pipeline needs a dependency parser. The labels of dependency
#' relations and tags differ between language models;
#' `spacy_parse(x, tag = TRUE, dependency = TRUE)` shows those of the model
#' in use. A match is only as good as the model's parse of the text.
#'
#' A pattern can match many times in a sentence: a verb and any one of its
#' dependents gives one match for each dependent. Patterns that ask for an
#' entity type (`ENT_TYPE` or `ENT_IOB`) give a warning when no component
#' sets entities, since they then match nothing.
#' @returns A `data.frame` with one row for each token of each match, and no
#'   rows when nothing matches:
#'   \describe{
#'   \item{`doc_id`}{the document}
#'   \item{`match_id`}{the number of the match within the document, starting
#'   at 1}
#'   \item{`label`}{the label of the pattern}
#'   \item{`node`}{the name of the node that the token matched, from
#'   `RIGHT_ID`}
#'   \item{`sentence_id`, `token_id`}{the sentence of the token, and its
#'   position in that sentence, both starting at 1 as in [spacy_parse()]}
#'   \item{`start_id`}{the position of the token in the document, starting
#'   at 1}
#'   \item{`token`}{the text of the token}
#'   }
#'   Rows are in the order of the documents in `x`. Within a document,
#'   matches are ordered by the positions of their tokens, taken in the
#'   order of the pattern's nodes (so first by the token of the first node),
#'   then by the order of the labels in `patterns`; `match_id` numbers them
#'   in that order. The rows of a match are in the order of the nodes.
#' @seealso [spacy_extract_matches()] for sequences of adjacent tokens.
#' @export
#' @examples
#' \dontrun{
#' spacy_initialize()
#'
#' txt <- c(doc1 = "The book was written by Jane. Jane wrote the book.",
#'          doc2 = "Mistakes were made, and the report is being rewritten.")
#'
#' # passive clauses, by the labels of the English models: a past participle
#' # with a passive subject and a passive auxiliary as its dependents
#' passive <- list(
#'   list(RIGHT_ID = "verb", RIGHT_ATTRS = list(TAG = "VBN")),
#'   list(LEFT_ID = "verb", REL_OP = ">", RIGHT_ID = "subject",
#'        RIGHT_ATTRS = list(DEP = "nsubjpass")),
#'   list(LEFT_ID = "verb", REL_OP = ">", RIGHT_ID = "aux",
#'        RIGHT_ATTRS = list(DEP = "auxpass"))
#' )
#' # the same, with the agent: "by" and its object
#' agent <- c(passive, list(
#'   list(LEFT_ID = "verb", REL_OP = ">", RIGHT_ID = "by",
#'        RIGHT_ATTRS = list(DEP = "agent")),
#'   list(LEFT_ID = "by", REL_OP = ">", RIGHT_ID = "agent",
#'        RIGHT_ATTRS = list(DEP = "pobj"))
#' ))
#' m <- spacy_extract_dependency_matches(txt, list(PASSIVE = passive,
#'                                                 PASSIVE_AGENT = agent))
#' m
#'
#' # one row for each match, with a column for each node
#' reshape(m[m$label == "PASSIVE", c("doc_id", "match_id", "node", "token")],
#'         idvar = c("doc_id", "match_id"), timevar = "node",
#'         direction = "wide")
#' }
spacy_extract_dependency_matches <- function(x, patterns, n_process = 1L,
                                             batch_size = NULL, ...) {
    UseMethod("spacy_extract_dependency_matches")
}

#' @export
spacy_extract_dependency_matches.character <- function(x, patterns, n_process = 1L,
                                                       batch_size = NULL, ...) {
    # checked before spaCy is initialized
    args <- pipe_args(n_process, batch_size)
    if (missing(patterns)) stop("patterns must be supplied", call. = FALSE)
    patterns <- dependency_patterns(patterns)

    input <- spacy_input(x)

    module <- spacyr_module()
    attrs <- lapply(patterns$patterns, function(p) lapply(p, `[[`, "RIGHT_ATTRS"))
    if (needs_entities(list(pattern = attrs)) &&
        !module$any_sets_entities(spacyr_env$nlp))
        warning("Some patterns need entities (ENT_TYPE or ENT_IOB), but no ",
                "component of the pipeline sets entities, so they will not match",
                call. = FALSE)

    spobj <- new_spobj()
    res <- tryCatch(
        spobj$dependency_match_table(texts = input$x, docnames = input$docnames,
                                     labels = as.list(patterns$labels),
                                     patterns = patterns$patterns,
                                     batch_size = args$batch_size,
                                     n_process = args$n_process),
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
                      start_id = int(res$start_id),
                      token = chr(res$token),
                      stringsAsFactors = FALSE)
    # Python gives 0 where a document has no sentence boundaries
    out$sentence_id[out$sentence_id == 0L] <- NA_integer_
    out$token_id[out$token_id == 0L] <- NA_integer_
    out
}

#' @export
spacy_extract_dependency_matches.data.frame <- function(x, ...) {
    spacy_extract_dependency_matches(tif_texts(x), ...)
}

# The labels and patterns for spaCy's DependencyMatcher: labels is a
# character vector, and patterns a list with the one pattern of each label,
# normalized as for as_entity_patterns(). Each node must have a name
# (RIGHT_ID), since the output is labelled by it, and its attributes
# (RIGHT_ATTRS), without which spaCy gives a bare KeyError; the relations
# between the nodes are left to spaCy to check.
dependency_patterns <- function(x) {
    if (inherits(x, "spacyr_entity_patterns"))
        stop("patterns holds entity patterns, which describe sequences of ",
             "tokens; use spacy_extract_matches()", call. = FALSE)
    if (!is.list(x) || is.data.frame(x))
        stop("patterns must be a named list of dependency patterns", call. = FALSE)
    if (!length(x)) stop("patterns holds no patterns", call. = FALSE)
    labels <- names(x)
    if (is.null(labels) || any(is.na(labels) | !nzchar(labels)))
        stop("patterns must be a named list, in which each name is the label ",
             "of a pattern", call. = FALSE)
    if (anyDuplicated(labels))
        stop("The names of patterns must be unique; give alternative patterns ",
             "labels of their own: ",
             paste(unique(labels[duplicated(labels)]), collapse = ", "),
             call. = FALSE)
    labels <- enc2utf8(labels)
    keys <- c("RIGHT_ID", "RIGHT_ATTRS", "LEFT_ID", "REL_OP")
    patterns <- lapply(seq_along(x), function(i) {
        p <- x[[i]]
        what <- paste0("'", labels[i], "'")
        if (!is.list(p) || !length(p))
            stop("Pattern ", what, " is not a list of nodes", call. = FALSE)
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
        if (!any(vapply(p, function(node) any(names(node) %in% keys), logical(1))))
            stop("Pattern ", what, " is a token pattern, without RIGHT_ID and ",
                 "RIGHT_ATTRS; use spacy_extract_matches() for sequences of ",
                 "tokens", call. = FALSE)
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
    })
    list(labels = labels, patterns = patterns)
}
