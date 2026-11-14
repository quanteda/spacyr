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
#' A class for the matrix could then have methods, such as for `%*%`, that
#' deal with the types that have no vector, which are now left to the user
#' (see "Types without a vector"), and a method for `[` that keeps the
#' `model` attribute, which a plain matrix loses when it is subsetted.
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
#' @section Types without a vector:
#' The row of a type that the model has no vector for is `NA`, and
#' `is.na(x[, 1])` says which these are. spaCy gives such a type a vector of
#' zeros, which is not a value: `NA` keeps a computation from taking it for
#' one. So before the matrix is used, decide what an unknown type should
#' count for. In the product of a dfm and the matrix, which gives a vector
#' for each document, there are two choices:
#'
#' * set the missing rows to zero, `x[is.na(x)] <- 0`: unknown types then
#'   add nothing to a document's vector but count among its tokens, as in
#'   spaCy's own document vectors;
#' * leave out the unknown types, from the matrix and from the dfm: a
#'   document's vector is then that of its known types only.
#'
#' The empty string, which is the padding of removed tokens in
#' \pkg{quanteda}, is a type without a vector.
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
#'   are left out.
#' @param what for the output of [spacy_parse()], whether to look up its
#'   tokens (`"token"`, the default) or its lemmas (`"lemma"`). It comes after
#'   `...`, so it has to be given by its full name.
#' @param ... not used
#' @return a numeric matrix with one row for each type, in the order in which
#'   the types first occur in `x`, and one column for each dimension of the
#'   model's vectors. The row names are the types. The row of a type that the
#'   model has no vector for is `NA`. The attribute `model` is a list with
#'   the `name` and the `version` of the language model, and the name of its
#'   table of `vectors`; as any attribute of a matrix, it is not kept when
#'   the matrix is subsetted.
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
#' # the types without a vector
#' is.na(vec[, 1])
#'
#' # cosine similarity between the types that have one
#' known <- vec[!is.na(vec[, 1]), ]
#' unit <- known / sqrt(rowSums(known^2))
#' round(tcrossprod(unit), 2)
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
#' # a vector for each document: the mean of the vectors of its tokens,
#' # with unknown types counting as zeros
#' dfmat <- quanteda::dfm(quanteda::as.tokens(parsed), tolower = FALSE)
#' fem <- spacy_vectors_types(dfmat)
#' fem[is.na(fem)] <- 0
#' dem <- quanteda::dfm_weight(dfmat, "prop") %*% fem
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
    info <- vectors_info()
    res <- spacyr_module()$type_vectors(spacyr_env$nlp, as.list(types))
    vectors <- res[[1]]
    if (!is.matrix(vectors))
        vectors <- matrix(as.numeric(vectors), nrow = length(types), ncol = info$width)
    storage.mode(vectors) <- "double"
    dimnames(vectors) <- list(types, NULL)
    # a type without a vector is missing, not a vector of zeros as in spaCy
    vectors[as.logical(unlist(res[[2]])), ] <- NA_real_
    attr(vectors, "model") <- info$attribute
    vectors
}

# The width of the vectors of the pipeline and the model attribute of the
# matrices, or an error when the model has no table of vectors. spaCy must
# be initialized.
vectors_info <- function() {
    info <- spacyr_module()$vectors_info(spacyr_env$nlp)
    if (info$rows == 0L || info$width == 0L)
        stop("The language model '", info$model, "' has no word vectors. ",
             "Initialize a model that has them, such as 'en_core_web_md' ",
             "(install it with spacy_download_langmodel(\"en_core_web_md\")): ",
             "spacy_finalize(); spacy_initialize(model = \"en_core_web_md\")",
             call. = FALSE)
    list(width = info$width,
         attribute = list(name = info$model, version = info$version,
                          vectors = info$vectors))
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


#' Vectors for documents (experimental)
#'
#' Get a vector for each document from the pre-trained word vectors of the
#' spaCy language model: the mean of the vectors of the document's tokens,
#' as spaCy computes it, in a matrix with one row for each document.
#'
#' @section Experimental:
#' This function is experimental: its arguments and what it returns may
#' change. It is meant to work with the document-embedding matrix planned
#' for \pkg{quanteda}, whose rows are documents and whose columns are the
#' dimensions of an embedding, and may return that object once it exists.
#'
#' @details
#' The vector of a document is spaCy's `Doc.vector`: the mean of the vectors
#' of all the tokens that spaCy's tokenizer finds in it, whitespace tokens
#' included. A token that the model has no vector for counts as a vector of
#' zeros, so it pulls the mean towards zero; a document whose tokens are all
#' unknown has a vector of zeros. To leave unknown types out of the mean, or
#' to weight or select the tokens, multiply a dfm by the vectors of its
#' features (see [spacy_vectors_types()]).
#'
#' With the missing rows of [spacy_vectors_types()] set to zero, the
#' document vectors are the proportions of the types in each document times
#' the vectors of the types:
#' ```
#' dfmat <- quanteda::dfm(quanteda::as.tokens(spacy_parse(x)), tolower = FALSE)
#' fem <- spacy_vectors_types(dfmat)
#' fem[is.na(fem)] <- 0
#' quanteda::dfm_weight(dfmat, "prop") %*% fem
#' ```
#'
#' The language model needs to have word vectors, as for
#' [spacy_vectors_types()]: a model without them is an error.
#'
#' No component of spaCy's pipeline runs, since the vectors need the tokens
#' only, which makes this many times faster than [spacy_parse()]. Every
#' component runs when the pipeline has a component, a tokenizer or a
#' language class that is not spaCy's own, which can set its own vector for
#' a document: that vector is then returned.
#'
#' @param x a character object, a \pkg{quanteda} corpus, or a TIF-compliant
#'   corpus data.frame (see <https://github.com/ropenscilabs/tif>)
#' @param n_process,batch_size passed to spaCy's `nlp.pipe()`, as in
#'   [spacy_parse()]. `n_process` is used only when the components of the
#'   pipeline run: without them, more processes would only add the time to
#'   start them.
#' @param ... not used
#' @return a numeric matrix with one row for each document, named by the
#'   documents, and one column for each dimension of the model's vectors,
#'   without names. The row of a document without tokens, such as an empty
#'   text, is `NA`. The attribute `model` is as for [spacy_vectors_types()].
#' @seealso [spacy_vectors_types()]
#' @export
#' @examples
#' \dontrun{
#' spacy_initialize(model = "en_core_web_md")
#'
#' txt <- c(d1 = "The king spoke to the queen.",
#'          d2 = "The queen answered the king.",
#'          d3 = "Bananas are yellow.")
#' vec <- spacy_vectors_docs(txt)
#' dim(vec)
#'
#' # cosine similarity between documents
#' unit <- vec / sqrt(rowSums(vec^2))
#' round(tcrossprod(unit), 2)
#'
#' spacy_finalize()
#' }
spacy_vectors_docs <- function(x, n_process = 1L, batch_size = NULL, ...) {
    UseMethod("spacy_vectors_docs")
}

#' @export
spacy_vectors_docs.character <- function(x, n_process = 1L, batch_size = NULL, ...) {
    check_unused_args(match.call(expand.dots = FALSE)$..., "spacy_vectors_docs")
    args <- pipe_args(n_process, batch_size)
    input <- spacy_input(x)
    info <- vectors_info()
    spobj <- new_spobj()
    res <- spobj$doc_vectors(input$x, input$docnames,
                             batch_size = args$batch_size,
                             n_process = args$n_process)
    warn_skipped(spobj)
    ids <- as.character(unlist(res$ids))
    vectors <- res$matrix
    if (!is.matrix(vectors))
        vectors <- matrix(as.numeric(vectors), nrow = length(ids), ncol = info$width)
    storage.mode(vectors) <- "double"
    dimnames(vectors) <- list(ids, NULL)
    # a document without tokens has no vector, not one of zeros as in spaCy
    vectors[as.logical(unlist(res$empty)), ] <- NA_real_
    attr(vectors, "model") <- info$attribute
    vectors
}

#' @export
spacy_vectors_docs.data.frame <- function(x, ...) {
    spacy_vectors_docs(tif_texts(x), ...)
}
