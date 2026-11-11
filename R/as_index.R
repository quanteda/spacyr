#' Convert matches, entities or noun phrases to a quanteda index
#'
#' Turn the positions that [spacy_match()], [spacy_extract_entity()] or
#' [spacy_extract_nounphrases()] return into an index of \pkg{quanteda}, as
#' [quanteda::index()] makes, so that [quanteda::kwic()] can show each of them
#' in its context. Making the index needs neither \pkg{quanteda} nor spaCy.
#'
#' @param x the output of [spacy_match()], [spacy_extract_entity()] or
#'   [spacy_extract_nounphrases()]: a data.frame with the columns `doc_id`,
#'   `start_id` and `length`. It can also be `NULL`, which
#'   [spacy_extract_entity()] and [spacy_extract_nounphrases()] return when
#'   they find nothing, and which gives an index with no rows.
#' @returns An object of class `index`, as [quanteda::index()] returns: a
#'   data.frame with one row for each row of `x`, in the same order, and the
#'   columns
#'   * `docname` the document, from `doc_id`;
#'   * `from` and `to` the positions of the first and last token, from
#'   `start_id` and `length`;
#'   * `pattern` a factor: the `label` of a match, the `ent_type` of an
#'   entity, or `"nounphrase"` for a noun phrase.
#' @details
#' The positions count spaCy's tokens from 1 in each document, with its
#' tokens of whitespace. They are the positions in
#' `quanteda::as.tokens(spacy_parse(x))` for the same texts and the same
#' pipeline, and not those in `quanteda::tokens(x)`, which are
#' \pkg{quanteda}'s tokens, or in the output of [spacy_tokenize()], which by
#' default leaves out whitespace. So give [quanteda::kwic()] the tokens of
#' [spacy_parse()], as in the examples. [quanteda::kwic()] does not check
#' that an index was made from the tokens it is given: with other tokens, it
#' shows whatever is at those positions.
#'
#' A match of a dependency pattern has one row for each of its nodes, and so
#' one row in the index for each node, also when two nodes are the same
#' token. [quanteda::kwic()] keeps the rows of the index in their order, and
#' drops those of documents that the tokens do not have. When the tokens
#' have every document, row `i` of the concordance is row `i` of `x`, so the
#' other columns of `x`, such as `match_id` and `node`, can be added to it.
#'
#' The concordance shows the matches that it is given. Which matches
#' [spacy_match()] returns where they overlap is set by its `overlap`, whose
#' rule is not that of `quanteda::kwic(x, pattern)`, as the details of
#' [spacy_match()] describe. A concordance of matches keeps a "New York"
#' inside another label's "New York Times", for instance, which
#' \pkg{quanteda}'s own search for the two would drop.
#' @seealso [spacy_match()], [spacy_extract_entity()],
#'   [spacy_extract_nounphrases()], [quanteda::kwic()]
#' @examples
#' # an index needs no spaCy: here, of matches written by hand
#' m <- data.frame(doc_id = c("d1", "d1"), label = c("city", "paper"),
#'                 start_id = c(2, 2), length = c(2, 3))
#' as_index(m)
#' as_index(NULL)
#'
#' \dontrun{
#' spacy_initialize()
#' txt <- c(d1 = "The New York Times is a paper in New York.",
#'          d2 = "Jane Smith wrote the book in Boston.")
#' toks <- quanteda::as.tokens(spacy_parse(txt))
#'
#' # matches in context
#' m <- spacy_match(txt, quanteda::phrase(c("new york", "the book")))
#' quanteda::kwic(toks, index = as_index(m), window = 3)
#'
#' # entities and noun phrases
#' quanteda::kwic(toks, index = as_index(spacy_extract_entity(txt)), window = 3)
#' quanteda::kwic(toks, index = as_index(spacy_extract_nounphrases(txt)),
#'                window = 3)
#' spacy_finalize()
#' }
#' @export
as_index <- function(x) {
    if (is.null(x))
        x <- data.frame(doc_id = character(), label = character(),
                        start_id = integer(), length = integer())
    if (!is.data.frame(x))
        stop("x must be the output of spacy_match(), spacy_extract_entity() ",
             "or spacy_extract_nounphrases(), or NULL", call. = FALSE)
    missing_cols <- setdiff(c("doc_id", "start_id", "length"), names(x))
    if (length(missing_cols))
        stop("x needs the columns doc_id, start_id and length, as the output ",
             "of spacy_match(), spacy_extract_entity() and ",
             "spacy_extract_nounphrases() has; missing: ",
             paste(missing_cols, collapse = ", "), call. = FALSE)
    from <- x[["start_id"]]
    len <- x[["length"]]
    if (!is.numeric(from) || !is.numeric(len) || !all(is.finite(from)) ||
        !all(is.finite(len)) || any(from < 1) || any(len < 1) ||
        any(from != round(from)) || any(len != round(len)))
        stop("start_id and length must be whole numbers from 1", call. = FALSE)
    pattern <- if ("label" %in% names(x)) {
        as.character(x[["label"]])
    } else if ("ent_type" %in% names(x)) {
        as.character(x[["ent_type"]])
    } else if (all(c("root_text", "root_id") %in% names(x))) {
        rep("nounphrase", nrow(x))
    } else {
        stop("x has none of the columns that say what each row is: label, as ",
             "in the output of spacy_match(); ent_type, as in that of ",
             "spacy_extract_entity(); or root_text and root_id, as in that of ",
             "spacy_extract_nounphrases()", call. = FALSE)
    }
    if (anyNA(pattern) || anyNA(x[["doc_id"]]))
        stop("doc_id and the label of each row must not be missing", call. = FALSE)
    from <- as.integer(from)
    result <- data.frame(docname = as.character(x[["doc_id"]]),
                         from = from,
                         to = from + as.integer(len) - 1L,
                         pattern = factor(pattern, levels = unique(pattern)),
                         stringsAsFactors = FALSE)
    class(result) <- c("index", "data.frame")
    result
}
