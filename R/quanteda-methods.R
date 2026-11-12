#' quanteda methods for parsed texts
#'
#' Methods of \pkg{quanteda}'s functions for the output of [spacy_parse()]:
#' its tokens as a \pkg{quanteda} tokens object, and its documents and their
#' sizes. They need the \pkg{quanteda} package, and are available when both
#' packages are loaded.
#'
#' @param x the output of [spacy_parse()], or of [entity_consolidate()] or
#'   [nounphrase_consolidate()]
#' @param concatenator the character that joins a token and its part of
#'   speech, when `include_pos` is not `"none"`
#' @param include_pos which part of speech to add to each token, after
#'   `concatenator`: `"none"`, the default, for none; `"pos"` for the column
#'   `pos`; or `"tag"` for the column `tag`
#' @param use_lemma if `TRUE`, the tokens are the lemmas and not the tokens
#'   as they are in the text
#' @param ... not used
#' @returns
#' * `as.tokens()` returns a \pkg{quanteda} tokens object with the tokens of
#'   each document, with the document variables of the corpus that was
#'   parsed, if it was a corpus.
#' * `docnames()` returns the names of the documents, and `ndoc()` their
#'   number.
#' * `ntoken()`, `ntype()` and `nsentence()` return the number of tokens, of
#'   different tokens and of sentences in each document, as an integer
#'   vector named by document, in the order of `docnames()`.
#' @details
#' The tokens are spaCy's, with its tokens of whitespace, so their positions
#' are those that [spacy_match()], [spacy_extract_entity()] and
#' [spacy_extract_nounphrases()] report in `start_id`: see [as_index()].
#'
#' @section Which documents there are:
#' All six methods agree on the documents of `x`. [spacy_parse()] keeps with
#' its output the names of all the documents it was given, in their order,
#' and the document variables of a \pkg{quanteda} corpus. So a document in
#' which spaCy found no tokens, such as an empty text, is a document with no
#' tokens here, although it has no row in `x`.
#'
#' Taking rows out of `x` can leave that record as it was. It is therefore
#' used only as far as the rows agree with it:
#'
#' * When every document that had tokens still has rows, the documents are
#'   all those that were parsed. Removing some of the tokens, such as the
#'   punctuation, does not remove a document.
#' * When a document that had tokens has no rows left, documents were taken
#'   out of `x`, and the documents are those that have rows. One without
#'   tokens is then not kept either.
#' * When `x` has a document that was not parsed with the others, as after
#'   `rbind()`, or has no record, as an object saved by an earlier version
#'   of \pkg{spacyr} or one that another function made into a new
#'   data.frame, the documents are those that have rows, without document
#'   variables.
#'
#' The documents are in the order in which they were parsed, or in the order
#' of the rows of `x` when that is another, with the documents without
#' tokens last.
#'
#' @section Earlier versions:
#' Until \pkg{spacyr} 2.0 these methods were part of \pkg{quanteda}. To use
#' them on an object that was saved to a file, load \pkg{spacyr} as well as
#' \pkg{quanteda}, for instance with `library("spacyr")`: reading the object
#' does not load it.
#' @seealso [spacy_parse()], [as_index()], [quanteda::as.tokens()],
#'   [quanteda::docnames()], [quanteda::ntoken()]
#' @examples
#' \dontrun{
#' spacy_initialize()
#' corp <- quanteda::corpus(c(d1 = "And now for something different.",
#'                            d2 = "",
#'                            d3 = "Jack and Jill are children."),
#'                          docvars = data.frame(year = 2001:2003))
#' parsed <- spacy_parse(corp)
#'
#' quanteda::docnames(parsed)
#' quanteda::ntoken(parsed)
#' quanteda::nsentence(parsed)
#'
#' toks <- quanteda::as.tokens(parsed)
#' toks
#' quanteda::docvars(toks)
#' quanteda::as.tokens(parsed, include_pos = "pos")
#' spacy_finalize()
#' }
#' @name quanteda-methods
NULL

#' @rdname quanteda-methods
#' @exportS3Method quanteda::as.tokens
as.tokens.spacyr_parsed <- function(x, concatenator = "/",
                                    include_pos = c("none", "pos", "tag"),
                                    use_lemma = FALSE, ...) {
    include_pos <- match.arg(include_pos)
    column <- if (use_lemma) "lemma" else "token"
    if (!column %in% names(x))
        stop("x has no column ", column,
             if (use_lemma) ": rerun spacy_parse() with lemma = TRUE",
             call. = FALSE)
    if (include_pos != "none" && !include_pos %in% names(x))
        stop("x has no column ", include_pos, ": rerun spacy_parse() with ",
             include_pos, " = TRUE", call. = FALSE)
    docs <- parsed_documents(x)
    tokens <- as.character(x[[column]])
    if (include_pos != "none")
        tokens <- paste(tokens, x[[include_pos]], sep = concatenator)
    result <- quanteda::as.tokens(
        split(tokens, factor(as.character(x[["doc_id"]]), levels = docs$doc_id))
    )
    if (!is.null(docs$docvars) && ncol(docs$docvars))
        quanteda::docvars(result) <- docs$docvars
    result
}

#' @rdname quanteda-methods
#' @exportS3Method quanteda::docnames
docnames.spacyr_parsed <- function(x) {
    parsed_documents(x)$doc_id
}

#' @rdname quanteda-methods
#' @exportS3Method quanteda::ndoc
ndoc.spacyr_parsed <- function(x) {
    length(parsed_documents(x)$doc_id)
}

#' @rdname quanteda-methods
#' @exportS3Method quanteda::ntoken
ntoken.spacyr_parsed <- function(x, ...) {
    count_by_document(x, function(rows) length(rows))
}

#' @rdname quanteda-methods
#' @exportS3Method quanteda::ntype
ntype.spacyr_parsed <- function(x, ...) {
    count_by_document(x, function(rows) length(unique(x[["token"]][rows])))
}

#' @rdname quanteda-methods
#' @exportS3Method quanteda::nsentence
nsentence.spacyr_parsed <- function(x) {
    count_by_document(x, function(rows) length(unique(x[["sentence_id"]][rows])))
}

# integer vector named by document, from fun() applied to the row numbers of
# each document of parsed_documents(), which are none for one without tokens
count_by_document <- function(x, fun) {
    ids <- parsed_documents(x)$doc_id
    rows <- split(seq_len(nrow(x)),
                  factor(as.character(x[["doc_id"]]), levels = ids))
    vapply(rows, fun, integer(1))
}

# The record that spacy_parse() keeps with its output: the names of all the
# documents it was given, how many tokens each had, and the document variables
# of a quanteda corpus, or NULL.
set_parsed_documents <- function(x, doc_id, docvars = NULL) {
    ntoken <- tabulate(match(x[["doc_id"]], doc_id), length(doc_id))
    attr(x, "documents") <- list(doc_id = doc_id, ntoken = ntoken,
                                 docvars = docvars)
    x
}

# document variables of a quanteda corpus, or NULL for any other input
input_docvars <- function(x) {
    if (!inherits(x, "corpus") || !requireNamespace("quanteda", quietly = TRUE))
        return(NULL)
    docvars <- quanteda::docvars(x)
    if (!is.data.frame(docvars) || !ncol(docvars)) return(NULL)
    docvars
}

# The documents of a parse, as list(doc_id, docvars), on which as.tokens(),
# docnames(), ndoc(), ntoken(), ntype() and nsentence() agree. Row subsetting
# can keep the record of set_parsed_documents() as it was, so it is used only
# as far as the rows agree with it: see "Which documents there are" in
# ?`quanteda-methods`.
parsed_documents <- function(x) {
    in_rows <- unique(as.character(x[["doc_id"]]))
    from_rows <- list(doc_id = in_rows, docvars = NULL)
    record <- attr(x, "documents", exact = TRUE)
    if (!is.list(record) || !is.character(record$doc_id) ||
        anyDuplicated(record$doc_id) ||
        length(record$ntoken) != length(record$doc_id) ||
        !all(in_rows %in% record$doc_id))
        return(from_rows)
    docvars <- record$docvars
    if (!is.null(docvars) &&
        (!is.data.frame(docvars) || nrow(docvars) != length(record$doc_id)))
        docvars <- NULL
    # documents were taken out when one that had tokens has no rows left
    keep <- record$doc_id %in% in_rows
    if (all(keep[record$ntoken > 0])) keep[] <- TRUE
    ids <- record$doc_id[keep]
    # rows in another order: theirs, then the documents without tokens
    if (!identical(ids[ids %in% in_rows], in_rows))
        ids <- c(in_rows, setdiff(ids, in_rows))
    if (!is.null(docvars)) {
        docvars <- docvars[match(ids, record$doc_id), , drop = FALSE]
        rownames(docvars) <- NULL
    }
    list(doc_id = ids, docvars = docvars)
}
