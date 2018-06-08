#' Extract noun phrases
#' 
#' @param x a character object, a \pkg{quanteda} corpus, or a TIF-compliant
#'   corpus data.frame (see \url{https://github.com/ropensci/tif})
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
spacy_extract_nounphrases <- function(x, 
                                      multithread = TRUE,
                                      value = c('list', 'data.frame'),
                                      ...) {
    UseMethod("spacy_extract_nounphrases")
}


#' @export
#' @importFrom data.table data.table
#' @noRd
spacy_extract_nounphrases.character <- function(x, 
                                                remove_whitespace_separators = TRUE,
                                                multithread = TRUE,
                                                value = c('list', 'data.frame'),
                                                ...) {
    
    `:=` <- NULL
    
    value <- match.arg(value)
    
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
    
    if(spacyr_pyget("py_version") != 3) {
        message("multithreading for python 2 is not supported by spacyr::spacy_tokenize()")
        multithread <- FALSE
    }
    
    
    x <- gsub("\\\\n","\\\n", x) # replace two quotes \\n with \n
    x <- gsub("\\\\t","\\\t", x) # replace two quotes \\t with \t
    x <- gsub("\\\\","", x) # delete unnecessary backslashes
    x <- unname(x)
    
    ## send documents to python
    spacyr_pyassign("texts", x)
    spacyr_pyassign("docnames", docnames)
    spacyr_pyassign("multithread", multithread)
    
    
    ## run noun phrase extraction
    spacyr_pyexec("spobj = spacyr()")
    if(identical(value, "list")){
        command_str <- paste("noun_phrases = spobj.extract_nounphrases_list(texts, docnames,",
                             "multithread = multithread)")
        spacyr_pyexec(command_str)
        return(spacyr_pyget("noun_phrases"))
    } else {
        command_str <- paste("noun_phrases = spobj.extract_nounphrases_dataframe(texts, docnames,",
                             "multithread = multithread)")
        spacyr_pyexec(command_str)
        noun_phrases <- spacyr_pyget("noun_phrases")
        
        doc_id <- names(noun_phrases)
        data_out <- 
            data.table::rbindlist(lapply(doc_id, function(x) {
                df <- as.data.frame(noun_phrases[[x]], stringsAsFactors = FALSE)
                df$doc_id <- x
                return(df)
            }))
        data_out[, start_id := start_id + 1][, root_id := root_id + 1]
        data.table::setDF(data_out)
        data_out <- data_out[, c(6, 1:5)]
        return(data_out)
    }
}


#' @noRd
#' @export
spacy_extract_nounphrases.data.frame <- function(x, ...) {
    
    # insert compliance check here - replace with tif package
    if (!all(c("doc_id", "text") %in% names(x)))
        stop("input data.frame does not conform to the TIF standard")
    
    txt <- x$text
    names(txt) <- x$doc_id
    spacy_extract_nounphrases(txt, ...)
}


