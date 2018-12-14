#' Extract or consolidate noun phrases from parsed documents
#' 
#' From an object parsed by \code{\link{spacy_parse}}, extract the multi-word
#' noun phrases as a separate object, or convert the multi-word noun phrases
#' into single "token" consisting of the concatenated elements of the multi-word
#' noun phrases.
#' @param x output from \code{\link{spacy_parse}}
#' @param concatenator the character(s) used to join elements of multi-word
#'   noun phrases
#' @return \code{noun} returns a \code{data.frame} of all named
#'   entities, containing the following fields: 
#'   \itemize{
#'   \item{\code{doc_id}}{ name of the document containing the noun phrase}
#'   \item{\code{sentence_id}}{ the sentence ID containing the noun phrase,
#'   within the document}
#'   \item{\code{nounphrase}}{the noun phrase}
#'   \item{\code{root}}{ the root token of the noun phrase}
#'   }
#' @importFrom data.table data.table as.data.table
#' @examples
#' \donttest{
#' spacy_initialize()
#' 
#' # entity extraction
#' txt <- "Mr. Smith of moved to San Francisco in December."
#' parsed <- spacy_parse(txt, nounphrase = TRUE)
#' entity_extract(parsed)
#' }
#' @export
nounphrase_extract <- function(x, concatenator = "_") {
    UseMethod("nounphrase_extract")
}
    
#' @export
nounphrase_extract.spacyr_parsed <- function(x, concatenator = "_") {

    nounphrase_id <- token_space <- token <- NULL

    spacy_result <- data.table::as.data.table(x)

    is_root <- nounphrase <- whitespace <- root_token <- iob <- .SD <- `:=` <-
        sentence_id <- doc_id <- NULL


    if (!"nounphrase" %in% names(spacy_result)) {
        stop("no nounphrases in parsed object: rerun spacy_parse() with nounphrase = TRUE")
    }
    spacy_result <- spacy_result[nchar(spacy_result$nounphrase) > 0]
    spacy_result[, iob := sub("_.+", "", nounphrase)]
    spacy_result[, is_root := grepl("_root", nounphrase)]
    spacy_result[, nounphrase_id := cumsum(iob == "beg")]
    spacy_result[, whitespace := ifelse(whitespace, " ", "")]
    spacy_result[, token_space := paste0(token, whitespace)]
    nounphrases <- spacy_result[, lapply(.SD, function(x) x[1]), by = nounphrase_id,
                             .SDcols = c("doc_id", "sentence_id")]
    nounphrases[, nounphrase := spacy_result[, lapply(.SD, function(x) paste(x, collapse = "")),
                                          by = nounphrase_id,
                                          .SDcols = c("token_space")]$token_space]
    nounphrases[, nounphrase := sub("\\s+$", "", nounphrase)]
    nounphrases[, nounphrase := sub("\\s+$", "", nounphrase)]
    # use concatenator instead of space
    if (concatenator != " ")
        nounphrases[, nounphrase := gsub(" ", concatenator, nounphrase)]
    as.data.frame(nounphrases[, list(doc_id, sentence_id, nounphrase, root_token)])
}


#' @rdname nounphrase_extract
#' @return \code{nounphrase_consolidate} returns a modified \code{data.frame} of
#'   parsed results, where the noun phrases have been combined into a single
#'   "token".  Currently, dependency parsing is removed when this consolidation
#'   occurs.
#' @importFrom data.table data.table
#' @examples
#' \donttest{
#' # consolidating multi-word noun phrases
#' txt <- "The House of Representatives voted to suspend aid to South Dakota."
#' parsed <- spacy_parse(txt, nounphrase = TRUE)
#' nounphrase_consolidate(parsed)
#' }
#' @export
nounphrase_consolidate <- function(x, concatenator = "_") {
    UseMethod("nounphrase_consolidate")
}
    
#' @importFrom data.table data.table
#' @export
nounphrase_consolidate.spacyr_parsed <- function(x, concatenator = "_") {

    spacy_result <- data.table::as.data.table(x)
    lemma_space <- token_space <- NULL
    nounphrase <- whitespace <- nounphrase_count <- iob <- nounphrase_id <- .N <- .SD <-
        `:=` <- token <- lemma <- pos <- tag <- new_token_id <- token_id <-
        sentence_id <- doc_id <- NULL

    if (!"nounphrase" %in% names(spacy_result)) {
        stop("no nounphrases in parsed object: rerun spacy_parse() with nounphrase = TRUE")
    }
    spacy_result[, iob := sub("_.+", "", nounphrase)]
    spacy_result[, nounphrase_count := ifelse(iob == "beg" | iob == "", 1, 0)]
    spacy_result[, nounphrase_id := cumsum(nounphrase_count), by = c("doc_id", "sentence_id")]
    spacy_result[, whitespace := ifelse(whitespace, concatenator, "")]
    spacy_result[, token_space := paste0(token, whitespace)]

    spacy_result_modified <- spacy_result[, lapply(.SD, function(x) x[1]),
                                          by = c("doc_id", "sentence_id", "nounphrase_id"),
                                          .SDcols = setdiff(names(spacy_result),
                                                            c("doc_id", "sentence_id", "nounphrase_id"))]

    spacy_result_modified[, token := spacy_result[, lapply(.SD, function(x) paste(x, collapse = "")),
                                             by = c("doc_id", "sentence_id", "nounphrase_id"),
                                             .SDcols = c("token_space")]$token_space]
    spacy_result_modified[, token := sub(paste0(concatenator, "$"), "", token)]

    if ("lemma" %in% colnames(spacy_result)) {
        spacy_result[, lemma_space := paste0(lemma, whitespace)]
        spacy_result_modified[, lemma := spacy_result[, lapply(.SD, function(x) paste(x, collapse = "")),
                                                      by = c("doc_id", "sentence_id", "nounphrase_id"),
                                                      .SDcols = c("lemma_space")]$lemma_space]
        spacy_result_modified[, lemma := sub(paste0(concatenator, "$"), "", lemma)]

    }
    if ("pos" %in% names(spacy_result_modified)){
        spacy_result_modified[nchar(nounphrase) > 0, pos := "nounphrase"]
    }
    if ("tag" %in% names(spacy_result_modified)){
        spacy_result_modified[nchar(nounphrase) > 0, tag := "nounphrase"]
    }
    spacy_result_modified[, new_token_id := nounphrase_id]

    # for now, just obliterate dependency parsing for consolidated NEs
    if ("dep_rel" %in% names(spacy_result_modified)){
        message("Note: removing head_token_id, dep_rel for nounphrases")
        spacy_result_modified[, c("dep_rel", "head_token_id") := NULL]
    }

    spacy_result_modified[, token_id := NULL]
    data.table::setnames(spacy_result_modified, "new_token_id", "token_id")
    keep_cols <- intersect(c("doc_id", "sentence_id", "token_id", "token",
                             "lemma", "pos", "tag", "head_token_id", "dep_rel"),
                           names(spacy_result_modified))

    ret <- as.data.frame(spacy_result_modified[, keep_cols, with = FALSE])
    class(ret) <- c("spacyr_parsed", class(ret))
    ret
}
