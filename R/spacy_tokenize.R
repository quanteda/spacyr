#' Just tokenize text with spaCy
#' 
#' @param x a character object, a \pkg{quanteda} corpus, or a TIF-compliant
#'   corpus data.frame (see \url{https://github.com/ropensci/tif})
#' @param what the unit for splitting the text, available alternatives are: 
#'   \describe{ \item{\code{"word"}}{word segmenter} 
#'   \item{\code{"sentence"}}{sentence segmenter }}
#' @param remove_punct remove puctuation tokens.
#' @param remove_numbers remove tokens that look like a number (e.g. "334", "3.1415", "fifty").
#' @param remove_url remove tokens that look like a url or email address.
#' @param padding if \code{TRUE}, leave an empty string where the removed tokens 
#'   previously existed. This is useful if a positional match is needed between 
#'   the pre- and post-selected tokens, for instance if a window of adjacency 
#'   needs to be computed.
#' @param remove_whitespace_separators remove whitespaces as separators when
#'  all other remove functionalities (e.g. \code{remove_punct}) have to be set to \code{FALSE}.
#' @param multithread logical; If true, the processing is parallelized using pipe 
#'   functionality of spacy (\url{https://spacy.io/api/pipe}).
#' @param value type of returning object. Either \code{list} or \code{data.frame}. 
#' @param ... not used directly
#' @return either \code{list} or \code{data.frame} of tokens
#' @export
#' @examples
#' \donttest{
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
                           padding = FALSE,
                           remove_whitespace_separators = TRUE,
                           multithread = TRUE,
                           value = c('list', 'data.frame'),
                           ...) {
    UseMethod("spacy_tokenize")
}


#' @export
#' @importFrom data.table data.table
#' @noRd
spacy_tokenize.character <- function(x, 
                                     what = c("word", "sentence"),
                                     remove_punct = FALSE,
                                     remove_url = FALSE,
                                     remove_numbers = FALSE,
                                     padding = FALSE,
                                     remove_whitespace_separators = TRUE,
                                     multithread = TRUE,
                                     value = c('list', 'data.frame'),
                                     ...) {
    
    `:=` <- NULL
    
    value <- match.arg(value)
    what <- match.arg(what)
    
    if (!is.null(names(x))) {
        docnames <- names(x) 
    } else {
        docnames <- paste0("text", 1:length(x))
    }
    if(length(x) == 1) {
        multithread <- FALSE
    }
    
    if(all(!duplicated(docnames)) == FALSE) {
        stop("Docmanes are duplicated.")
    } else if (all(nchar(docnames) > 0L) == FALSE) {
        stop("Some docnames are missing.")
    }
    
    if (is.null(options()$spacy_initialized)) spacy_initialize()
    spacyr_pyexec("try:\n del spobj\nexcept NameError:\n 1")
    spacyr_pyexec("texts = []")
    
    x <- gsub("\\\\n","\\\n", x) # replace two quotes \\n with \n
    x <- gsub("\\\\t","\\\t", x) # replace two quotes \\t with \t
    x <- gsub("\\\\","", x) # delete unnecessary backslashes
    x <- unname(x)

    ## send documents to python
    spacyr_pyassign("texts", x)
    spacyr_pyassign("docnames", docnames)
    spacyr_pyassign("multithread", multithread)
    
    if(identical(what, "sentence")){
        spacyr_pyexec("spobj = spacyr()")
        command_str <- paste("tokens = spobj.tokenize_sentence(texts, docnames,",
                             "multithread = multithread)")
        spacyr_pyexec(command_str)
    } else {
    
        ## assign general settings for tokenizer in python
        spacyr_pyassign("padding", padding)
        turn_off_pipes <- if(all(!c(remove_punct, remove_url, remove_numbers))) {TRUE} else {FALSE}
        spacyr_pyassign("turn_off_pipes", turn_off_pipes)
        if(remove_whitespace_separators == FALSE & turn_off_pipes == FALSE) {
            stop("remove_whitespace_separators = FALSE and remove_* = TURE are not compatible", call. = FALSE)
        }
        spacyr_pyassign("remove_whitespace_separators", remove_whitespace_separators)
        
        ## assign removal settings for tokenizer in python
        spacyr_pyassign("remove_punct", remove_punct)
        spacyr_pyassign("remove_url", remove_url)
        spacyr_pyassign("remove_numbers", remove_numbers)
        
        ## run tokenizer
        spacyr_pyexec("spobj = spacyr()")
        command_str <- paste("tokens = spobj.tokenize(texts, docnames,",
                             "remove_punct = remove_punct,",
                             "remove_url = remove_url,",
                             "remove_numbers = remove_numbers,",
                             "remove_whitespace_separators = remove_whitespace_separators,",
                             "turn_off_pipes = turn_off_pipes,",
                             "padding = padding,",
                             "multithread = multithread)")
        spacyr_pyexec(command_str)
    }

    tokens <- spacyr_pyget("tokens")
    
    if (identical(value, 'list')) return(tokens)
    else {
        list_length <- sapply(tokens, length)
        docnames_vec <- rep(names(list_length), list_length)
        return(data.frame(doc_id = docnames_vec, 
                          token = unlist(tokens, use.names = FALSE), 
                          stringsAsFactors = FALSE))
    }
}


#' @noRd
#' @export
spacy_tokenize.data.frame <- function(x, ...) {
    
    # insert compliance check here - replace with tif package
    if (!all(c("doc_id", "text") %in% names(x)))
        stop("input data.frame does not conform to the TIF standard")
    
    txt <- x$text
    names(txt) <- x$doc_id
    spacy_tokenize(txt, ...)
}


