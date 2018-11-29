#' Extract named entity
#' 
#' This function extracts named entities from texts. 
#' 
#' @param x a character object or a TIF-compliant
#'   corpus data.frame (see \url{https://github.com/ropensci/tif})
#' @param multithread logical; If true, the processing is parallelized using pipe 
#'   functionality of spacy (\url{https://spacy.io/api/pipe}).
#' @param output type of returned object, either \code{"list"} or
#'   \code{"data.frame"}.
#' @param ... unused
#' @details When the option \code{output = "data.frame"} is selected, the
#'   function returns a \code{data.frame} with the following fields.
#' \describe{\item{\code{text}}{contents of entity}
#' \describe{\item{\code{entity_type}}{type of entity (e.g. \code{ORG} for organizations)}
#' \item{\code{start_id}}{serial number ID of starting token. This number
#' corresponds with the number of \code{data.frame} returned from
#' \code{spacy_tokenize(x)} with default options.}
#' \item{\code{length}}{number of words (tokens) included in a named entity (e.g.
#' for an entity, "New York Stock Exchange"", \code{length = 4})}}
#' 
#' @return either a \code{list} or \code{data.frame} of tokens
#' @export
#' @examples
#' \donttest{
#' spacy_initialize()
#' 
#' txt <- c(doc1 = "Natural language processing is a branch of computer science.",
#'          doc2 = "Paul earned a postgraduate degree from MIT.")
#' spacy_extract_entity(txt)
#' spacy_extract_entity(txt, output = "list")
#' }
spacy_extract_entity <- function(x, output = c("data.frame", "list"),
                                 multithread = TRUE, ...) {
    UseMethod("spacy_extract_entity")
}


#' @export
#' @importFrom data.table data.table
#' @noRd
spacy_extract_entity.character <- function(x,
                                           output = c("data.frame", "list"),
                                           multithread = TRUE, ...) {
    
    `root_id` <- `start_id` <- `:=` <- NULL
    
    output <- match.arg(output)
    
    if (!is.null(names(x))) {
        docnames <- names(x)
    } else {
        docnames <- paste0("text", 1:length(x))
    }
    if (length(x) == 1) {
        multithread <- FALSE
    }
    
    if (all(!duplicated(docnames)) == FALSE) {
        stop("Docmanes are duplicated.")
    } else if (all(nchar(docnames) > 0L) == FALSE) {
        stop("Some docnames are missing.")
    }
    
    if (is.null(options()$spacy_initialized)) spacy_initialize()
    spacyr_pyexec("try:\n del spobj\nexcept NameError:\n 1")
    spacyr_pyexec("texts = []")
    
    if (spacyr_pyget("py_version") != 3) {
        message("multithreading for python 2 is not supported by spacy_tokenize()")
        multithread <- FALSE
    }
    
    
    x <- gsub("\\\\n", "\\\n", x) # replace two quotes \\n with \n
    x <- gsub("\\\\t", "\\\t", x) # replace two quotes \\t with \t
    x <- gsub("\\\\", "", x) # delete unnecessary backslashes
    x <- unname(x)
    
    ## send documents to python
    spacyr_pyassign("texts", x)
    spacyr_pyassign("docnames", docnames)
    spacyr_pyassign("multithread", multithread)
    
    
    ## run noun phrase extraction
    spacyr_pyexec("spobj = spacyr()")
    if (identical(output, "list")) {
        command_str <- paste("noun_phrases = spobj.extract_entity_list(texts = texts,",
                             "docnames = docnames,",
                             "multithread = multithread)")
        spacyr_pyexec(command_str)
        return(spacyr_pyget("noun_phrases"))
    } else {
        command_str <- paste("noun_phrases = spobj.extract_entity_dataframe(texts = texts,",
                             "docnames = docnames,",
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
spacy_extract_entity.data.frame <- function(x, ...) {
    
    # insert compliance check here - replace with tif package
    if (!all(c("doc_id", "text") %in% names(x)))
        stop("input data.frame does not conform to the TIF standard")
    
    txt <- x$text
    names(txt) <- x$doc_id
    spacy_extract_entity(txt, ...)
}
