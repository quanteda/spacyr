# Input handling shared by spacy_parse(), spacy_tokenize(),
# spacy_extract_entity(), spacy_extract_nounphrases() and process_document().

# Texts and document names to pass to spaCy, from a character vector or a
# quanteda corpus, initializing spaCy if needed. Missing names are set to
# text1, text2, ..., and missing (NA) documents are treated as empty.
spacy_input <- function(x) {
    docnames <- names(x)
    if (is.null(docnames)) docnames <- sprintf("text%d", seq_along(x))
    if (anyDuplicated(docnames)) stop("Docnames are duplicated.", call. = FALSE)
    if (any(is.na(docnames) | !nzchar(docnames)))
        stop("Some docnames are missing.", call. = FALSE)

    if (is.null(options()$spacy_initialized)) spacy_initialize()
    x <- as.character(x)
    x[is.na(x)] <- ""
    list(x = x, docnames = docnames)
}

# Named character vector of texts from a TIF corpus data.frame, whose columns
# doc_id and text may be of any type that converts to character, such as
# factors or numbers.
tif_texts <- function(x) {
    if (!all(c("doc_id", "text") %in% names(x)))
        stop("input data.frame does not conform to the TIF standard", call. = FALSE)
    structure(as.character(x$text), names = as.character(x$doc_id))
}
