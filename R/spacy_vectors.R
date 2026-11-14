#' Word vectors for types (experimental)
#'
#' Get the pre-trained word vector of each type, from the table of vectors
#' of the spaCy language model, as a matrix with one row for each type. A
#' type is a unique token, as in \pkg{quanteda}.
#'
#' @section Experimental:
#' This function is experimental: its arguments and what it returns may
#' change. It is meant to work with the feature-embedding matrix planned for
#' \pkg{quanteda}, whose rows are features and whose columns are the
#' dimensions of an embedding, and may return that object once it exists.
#'
#' @details
#' The vectors are those of the model's vector table. There is one for each
#' type, whatever its context, so that the same spelling has the same vector
#' wherever it occurs: unlike the contextual embeddings of a transformer
#' model, they do not tell apart the senses of a word. They are looked up for
#' the types exactly as given, without parsing any text. Which spellings a
#' model has vectors for is up to the model; several, such as `"cat"` and
#' `"Cat"`, may share one vector.
#'
#' The language model needs to have word vectors. Those of spaCy whose names
#' end in `md` or `lg` do, and those ending in `sm` or `trf` do not: for a
#' model without them, this is an error. Install a model with
#' [spacy_download_langmodel()], and name it in [spacy_initialize()].
#'
#' The columns are the dimensions of the model's vector space. They have no
#' names, since a dimension means nothing by itself: vectors can only be
#' compared with those of the same model.
#'
#' @param x the types to look up, as one of:
#'   * a character vector, each element a type;
#'   * the output of [spacy_parse()], for its tokens or its lemmas;
#'   * a list of character vectors, such as [spacy_tokenize()] returns;
#'   * a \pkg{quanteda} tokens object, for the types of its documents, or
#'     a dfm, for its features: one row for each feature, in their order, so
#'     that `x %*% spacy_vectors_types(x)` is a vector for each document.
#'
#'   Each type is looked up once, however often it occurs. Missing values
#'   are left out. The empty string, which is the padding of removed tokens
#'   in \pkg{quanteda}, is a type without a vector.
#' @param what for the output of [spacy_parse()], whether to look up its
#'   tokens (`"token"`, the default) or its lemmas (`"lemma"`). It comes after
#'   `...`, so it has to be given by its full name.
#' @param ... not used
#' @return a numeric matrix with one row for each type, in the order in which
#'   the types first occur in `x`, and one column for each dimension of the
#'   model's vectors. The row names are the types. It has two attributes:
#'   * `oov`: a logical vector, named by the types, that is `TRUE` for a type
#'     that the model has no vector for. Its row is all zeros.
#'   * `model`: a list with the `name` and the `version` of the language
#'     model, and the name of its table of `vectors`.
#' @seealso [spacy_parse()], whose `additional_attributes` can be
#'   `"has_vector"`, `"is_oov"` and `"vector_norm"`
#' @export
#' @examples
#' \dontrun{
#' # a model with word vectors
#' spacy_download_langmodel("en_core_web_md")
#' spacy_initialize(model = "en_core_web_md")
#'
#' vec <- spacy_vectors_types(c("king", "queen", "banana", "zxqv"))
#' dim(vec)
#' attr(vec, "oov")
#'
#' # cosine similarity between types
#' unit <- vec / sqrt(rowSums(vec^2))
#' round(tcrossprod(unit[1:3, ]), 2)
#'
#' # the types of parsed texts, and one row for each token
#' parsed <- spacy_parse("The king spoke to the queen.")
#' vec <- spacy_vectors_types(parsed)
#' rownames(vec)
#' by_token <- vec[parsed$token, ]
#'
#' # the lemmas, and the types of a quanteda tokens object
#' spacy_vectors_types(parsed, what = "lemma")
#' spacy_vectors_types(quanteda::as.tokens(parsed))
#'
#' spacy_finalize()
#' }
spacy_vectors_types <- function(x, ...) {
    UseMethod("spacy_vectors_types")
}

#' @export
spacy_vectors_types.default <- function(x, ...) {
    stop("x must be a character vector, the output of spacy_parse(), a list ",
         "of character vectors, or a quanteda tokens or dfm object, not an ",
         "object of class ", paste0("'", class(x)[1], "'"), call. = FALSE)
}

#' @export
spacy_vectors_types.character <- function(x, ...) {
    check_unused_args(match.call(expand.dots = FALSE)$..., "spacy_vectors_types")
    types <- unique(as.character(x))
    types <- types[!is.na(types)]
    if (is.null(getOption("spacy_initialized"))) spacy_initialize()
    module <- spacyr_module()
    info <- module$vectors_info(spacyr_env$nlp)
    if (info$rows == 0L || info$width == 0L)
        stop("The language model '", info$model, "' has no word vectors. ",
             "Initialize a model that has them, such as 'en_core_web_md' ",
             "(install it with spacy_download_langmodel(\"en_core_web_md\")): ",
             "spacy_finalize(); spacy_initialize(model = \"en_core_web_md\")",
             call. = FALSE)
    res <- module$type_vectors(spacyr_env$nlp, as.list(types))
    vectors <- res[[1]]
    if (!is.matrix(vectors))
        vectors <- matrix(as.numeric(vectors), nrow = length(types), ncol = info$width)
    storage.mode(vectors) <- "double"
    dimnames(vectors) <- list(types, NULL)
    attr(vectors, "oov") <- structure(as.logical(unlist(res[[2]])), names = types)
    attr(vectors, "model") <- list(name = info$model, version = info$version,
                                   vectors = info$vectors)
    vectors
}

#' @rdname spacy_vectors_types
#' @export
spacy_vectors_types.spacyr_parsed <- function(x, ..., what = c("token", "lemma")) {
    what <- match.arg(what)
    if (!what %in% names(x))
        stop("x has no column ", what,
             if (what == "lemma") ": rerun spacy_parse() with lemma = TRUE",
             call. = FALSE)
    spacy_vectors_types(as.character(x[[what]]), ...)
}

#' @export
spacy_vectors_types.list <- function(x, ...) {
    # a document without tokens is an empty list in the output of spacy_tokenize()
    if (!all(vapply(x, function(v) is.character(v) || length(v) == 0, logical(1))))
        stop("a list must hold character vectors only, as spacy_tokenize() returns",
             call. = FALSE)
    spacy_vectors_types(as.character(unlist(x, use.names = FALSE)), ...)
}

#' @export
spacy_vectors_types.tokens <- function(x, ...) {
    need_quanteda(x)
    # the types of the documents that x has now, in the order in which they
    # first occur: quanteda::types() can keep those of documents that were
    # removed, in another order
    spacy_vectors_types(as.character(unlist(as.list(x), use.names = FALSE)), ...)
}

#' @export
spacy_vectors_types.dfm <- function(x, ...) {
    need_quanteda(x)
    # one row for each feature, in their order, so that x %*% the result is
    # a vector for each document
    spacy_vectors_types(quanteda::featnames(x), ...)
}

# quanteda is a suggested package
need_quanteda <- function(x) {
    if (!requireNamespace("quanteda", quietly = TRUE))
        stop("the quanteda package is needed for an object of class '",
             class(x)[1], "'", call. = FALSE)
    invisible(TRUE)
}
