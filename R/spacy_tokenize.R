#' Tokenize text with spaCy
#' 
#' Efficient tokenization (without POS tagging, dependency parsing,
#' lemmatization, or named entity recognition) of texts using spaCy.
#' @param x a character object, a \pkg{quanteda} corpus, or a TIF-compliant
#'   corpus data.frame (see <https://github.com/ropenscilabs/tif>) 
#' @param what the unit for splitting the text, available alternatives are: 
#'   \describe{ \item{`"word"`}{word segmenter} 
#'   \item{`"sentence"`}{sentence segmenter }}
#' @param remove_punct remove punctuation tokens.
#' @param remove_numbers remove tokens that look like a number (e.g. "334", "3.1415", "fifty").
#' @param remove_url remove tokens that look like a url or email address.
#' @param remove_separators remove spaces as separators when
#'  all other remove functionalities (e.g. `remove_punct`) have to be set to `FALSE`. 
#'  When `what = "sentence"`, this option will remove trailing spaces if `TRUE`.
#' @param remove_symbols remove symbols. The symbols are either `SYM` in `pos`
#'   field, or currency symbols.
#' @param padding if `TRUE`, leave an empty string where the removed tokens 
#'   previously existed. This is useful if a positional match is needed between 
#'   the pre- and post-selected tokens, for instance if a window of adjacency 
#'   needs to be computed.
#' @inheritParams spacy_parse
#' @param output type of returning object. Either `list` or `data.frame`. 
#' @param ... not used directly
#' @return either `list` or `data.frame` of tokens
#' @export
#' @examples
#' \dontrun{
#' spacy_initialize()
#' txt <- "And now for something completely different."
#' spacy_tokenize(txt)
#' 
#' txt2 <- c(doc1 = "The fast cat catches mice.\\nThe quick brown dog jumped.", 
#'           doc2 = "This is the second document.",
#'           doc3 = "This is a \\\"quoted\\\" text." )
#' spacy_tokenize(txt2)
#' }
spacy_tokenize <- function(x,
                           what = c("word", "sentence"),
                           remove_punct = FALSE,
                           remove_url = FALSE,
                           remove_numbers = FALSE,
                           remove_separators = TRUE,
                           remove_symbols = FALSE,
                           padding = FALSE,
                           multithread = TRUE,
                           output = c("list", "data.frame"),
                           ...) {
    UseMethod("spacy_tokenize")
}

#' @importFrom data.table data.table
#' @export
spacy_tokenize.character <- function(x,
                                     what = c("word", "sentence"),
                                     remove_punct = FALSE,
                                     remove_url = FALSE,
                                     remove_numbers = FALSE,
                                     remove_separators = TRUE,
                                     remove_symbols = FALSE,
                                     padding = FALSE,
                                     multithread = TRUE,
                                     output = c("list", "data.frame"),
                                     ...) {
    x <- structure(as.character(x), names = names(x))
    output <- match.arg(output)
    what <- match.arg(what)

    if (!is.null(names(x))) {
        docnames <- names(x)
    } else {
        docnames <- paste0("text", 1:length(x))
    }


    if (all(!duplicated(docnames)) == FALSE) {
        stop("Docnames are duplicated.")
    } else if (all(nchar(docnames) > 0L) == FALSE) {
        stop("Some docnames are missing.")
    }

    if (is.null(options()$spacy_initialized)) spacy_initialize()


    x[is.na(x)] <- "" # missing documents are treated as empty
    x <- unname(x)

    spobj <- new_spobj()
    if (identical(what, "sentence")){
        tokens <- spobj$tokenize_sentence(
            x, docnames,
            remove_separators = remove_separators)
    } else {
        turn_off_pipes <- if (all(!c(remove_punct, remove_url, remove_numbers))) TRUE else FALSE
        if (remove_separators == FALSE & turn_off_pipes == FALSE) {
            stop("remove_separators = FALSE and remove_* = TRUE are not compatible", call. = FALSE)
        }
        tokens <- spobj$tokenize(
            x, docnames,
            remove_punct = remove_punct,
            remove_url = remove_url,
            remove_numbers = remove_numbers,
            remove_separators = remove_separators,
            remove_symbols = remove_symbols,
            turn_off_pipes = turn_off_pipes,
            padding = padding)
    }
    warn_skipped(spobj)

    if (identical(output, "list")) return(tokens)
    else {
        list_length <- sapply(tokens, length)
        docnames_vec <- rep(names(list_length), list_length)
        return(data.frame(doc_id = docnames_vec,
                          token = unlist(tokens, use.names = FALSE),
                          stringsAsFactors = FALSE))
    }
}


#' @export
spacy_tokenize.data.frame <- function(x, ...) {

    # insert compliance check here - replace with tif package
    if (!all(c("doc_id", "text") %in% names(x)))
        stop("input data.frame does not conform to the TIF standard")

    txt <- x$text
    names(txt) <- x$doc_id
    spacy_tokenize(txt, ...)
}
