#' Just tokenize text with spaCy
#' 
#' @param x a character object, a \pkg{quanteda} corpus, or a TIF-compliant
#'   corpus data.frame (see \url{https://github.com/ropensci/tif})
#' @param multithread logical; If true, the processing is parallelized using pipe 
#'   functionality of spacy (\url{https://spacy.io/api/pipe}). 
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
                        multithread = TRUE,
                        ...) {
    UseMethod("spacy_tokenize")
}


#' @export
#' @importFrom data.table data.table
#' @noRd
spacy_tokenize.character <- function(x, 
                                  multithread = TRUE,
                                  ...) {
    
    `:=` <- NULL
    
    if (!is.null(names(x))) {
        docnames <- names(x) 
    } else {
        docnames <- paste0("text", 1:length(x))
    }
    if(multithread) {
        message("multithread is not implemented yet.")
    }
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
    spacyr_pyexec("spobj = spacyr()")
    
    spacyr_pyexec("tokens = spobj.tokenize(texts, docnames, multithread = multithread)")
    
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


