#' Just tokenize text with spaCy
#' 
#' @param x a character object, a \pkg{quanteda} corpus, or a TIF-compliant
#'   corpus data.frame (see \url{https://github.com/ropensci/tif})
#' @param remove_punct remove puctuation tokens.
#' @param remove_numbers remove tokens that look like a number (e.g. "334", "3.1415", "fifty").
#' @param remove_url remove tokens that look like a url or email address.
#' @param multithread logical; If true, the processing is parallelized using pipe 
#'   functionality of spacy (\url{https://spacy.io/api/pipe}). 
#' @param ... not used directly
#' @return a \code{data.frame} of tokenized, parsed, and annotated tokens
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
                           remove_punct = FALSE,
                           remove_url = FALSE,
                           remove_numbers = FALSE,
                           multithread = TRUE,
                           ...) {
    UseMethod("spacy_tokenize")
}


#' @export
#' @importFrom data.table data.table
#' @noRd
spacy_tokenize.character <- function(x, 
                                     remove_punct = FALSE,
                                     remove_url = FALSE,
                                     remove_numbers = FALSE,
                                     multithread = TRUE,
                                     ...) {
    
    `:=` <- NULL
    
    if (!is.null(names(x))) {
        docnames <- names(x) 
    } else {
        docnames <- paste0("text", 1:length(x))
    }
    turn_off_pipes <- if(all(!c(remove_punct, remove_url, remove_numbers))) {TRUE} else {FALSE}
    spacyr_pyassign("turn_off_pipes", turn_off_pipes)
    
    if(all(!duplicated(docnames)) == FALSE) {
        stop("Docmanes are duplicated.")
    }
    
    if (is.null(options()$spacy_initialized)) spacy_initialize()
    spacyr_pyexec("try:\n del spobj\nexcept NameError:\n 1")
    spacyr_pyexec("texts = []")
    
    x <- gsub("\\\\n","\\\n", x) # replace two quotes \\n with \n
    x <- gsub("\\\\t","\\\t", x) # replace two quotes \\t with \t
    x <- gsub("\\\\","", x) # delete unnecessary backslashes
    x <- unname(x)

    spacyr_pyassign("texts", x)
    spacyr_pyassign("docnames", docnames)
    
    spacyr_pyassign("multithread", multithread)
    spacyr_pyassign("remove_punct", remove_punct)
    spacyr_pyassign("remove_url", remove_url)
    spacyr_pyassign("remove_numbers", remove_numbers)
    
    spacyr_pyexec("spobj = spacyr()")
    command_str <- paste("tokens = spobj.tokenize(texts, docnames,",
                         "remove_punct = remove_punct,",
                         "remove_url = remove_url,",
                         "remove_numbers = remove_numbers,",
                         "turn_off_pipes = turn_off_pipes,",
                         "multithread = multithread)")
    spacyr_pyexec(command_str)
    
    tokens <- spacyr_pyget("tokens")
    
    return(tokens)
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


