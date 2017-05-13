#' parse a text using spaCy
#' 
#' The spacy_parse() function calls spaCy to both tokenize and tag the texts, 
#' and returns a data.table of the results. The function provides options on the
#' types of tagsets (\code{tagset_} options) either  \code{"google"} or
#' \code{"detailed"}, as well as lemmatization (\code{lemma}). It provides a
#' functionalities of dependency parsing and named entity recognition as an
#' option. If \code{"full_parse = TRUE"} is provided, the function returns the
#' most extensive list of the parsing results from spaCy.
#' 
#' @param x a character object, a \pkg{quanteda} corpus, or a TIF-compliant
#'   corpus data.frame (see \url{https://github.com/ropensci/tif})
#' @param pos logical whether to return universal dependency POS tagset
#'   (http://universaldependencies.org/u/pos/all.html)
#' @param tag logical whether to return detailed part-of-speech tags, for the
#'   langage model \code{en}, it uses the OntoNotes 5 version of the Penn
#'   Treebank tag set (https://spacy.io/docs/usage/pos-tagging#pos-schemes)
#' @param lemma logical; inlucde lemmatized tokens in the output
#' @param entity logical; if \code{TRUE}, report named entities
#' @param dependency logical; if \code{TRUE}, analyze and return dependencies
#' @param ... not used directly
#' @return a \code{data.frame} of tokenized, parsed, and annotated tokens
#' @export
#' @examples
#' \donttest{
#' spacy_initialize()
#' # See Chap 5.1 of the NLTK book, http://www.nltk.org/book/ch05.html
#' txt <- "And now for something completely different."
#' spacy_parse(txt)
#' spacy_parse(txt, pos = TRUE, tag = TRUE)
#' spacy_parse(txt, dependency = TRUE)
#' 
#' txt2 <- c(doc1 = "The fast cat catches mice.\\nThe quick brown dog jumped.", 
#'           doc2 = "This is the second document.",
#'           doc3 = "This is a \\\"quoted\\\" text." )
#' spacy_parse(txt2, entity = TRUE, dependency = TRUE)
#' }
spacy_parse <- function(x, 
                        pos = TRUE,
                        tag = FALSE,
                        lemma = TRUE,
                        entity = TRUE, 
                        dependency = FALSE,
                        ...) {
    UseMethod("spacy_parse")
}


#' @export
#' @importFrom data.table data.table
#' @noRd
spacy_parse.character <- function(x, 
                                  pos = TRUE,
                                  tag = FALSE,
                                  lemma = TRUE,
                                  entity = TRUE, 
                                  dependency = FALSE,
                                  ...) {
    
    `:=` <- NULL
    
    spacy_out <- process_document(x)
    if (is.null(spacy_out$timestamps)) {
        stop("Document parsing failed")
    }
    
    tokens <- get_tokens(spacy_out)
    ntokens <- get_ntokens(spacy_out)
    ntokens_by_sent <- get_ntokens_by_sent(spacy_out)
    #browser()
    subtractor <- unlist(lapply(ntokens_by_sent, function(x) {
        csumx <- cumsum(c(0, x[-length(x)]))
        return(rep(csumx, x))
    }))
    dt <- data.table(doc_id = rep(spacy_out$docnames, ntokens), 
                     sentence_id = unlist(lapply(ntokens_by_sent, function(x) rep(1:length(x), x))),
                     token_id = unlist(lapply(unlist(ntokens_by_sent), function(x) 1:x)), 
                     token = tokens)
    
    if (lemma) {
        dt[, "lemma" := get_attrs(spacy_out, "lemma_")]
    }
    if (pos) {
        dt[, "pos" := get_tags(spacy_out, "google")]
    }
    if (tag) {
        dt[, "tag" := get_tags(spacy_out, "detailed")]
    }

    ## add dependency data fields
    if (dependency) {
        deps <- get_dependency(spacy_out)
        dt[, c("head_token_id", "dep_rel") := list(deps$head_id - subtractor,
                                                   deps$dep_rel)]
    }
    
    ## named entity fields
    if (entity) {
        dt[, entity := get_named_entities(spacy_out)]
    }
    
    dt <- as.data.frame(dt)
    class(dt) <- c("spacyr_parsed", class(dt))
    return(dt)
}


#' @noRd
#' @export
spacy_parse.data.frame <- function(x, ...) {
    
    # insert compliance check here - replace with tif package
    if (!all(c("doc_id", "text") %in% names(x)))
        stop("input data.frame does not conform to the TIF standard")

    txt <- x$text
    names(txt) <- x$doc_id
    spacy_parse(txt, ...)
}


#' tokenize text using spaCy
#' 
#' Tokenize text using spaCy. The results of tokenization is stored as a python object. To obtain the tokens results in R, use \code{get_tokens()}.
#' \url{http://spacy.io}.
#' @param x input text
#' functionalities including the tagging, named entity recognisiton, dependency 
#' analysis. 
#' This slows down \code{spacy_parse()} but speeds up the later parsing. 
#' If FALSE, tagging, entity recogitions, and dependendcy analysis when 
#' relevant functions are called.
#' @param python_exec character; select connection type to spaCy, either 
#' "rPython" or "Rcpp". 
#' @param ... arguments passed to specific methods
#' @return result marker object
#' @importFrom methods new
#' @examples
#' \donttest{spacy_initialize()
#' # the result has to be "tag() is ready to run" to run the following
#' txt <- c(text1 = "This is the first sentence.\nHere is the second sentence.", 
#'          text2 = "This is the second document.")
#' results <- spacy_parse(txt)
#' 
#' }
#' @export
#' @keywords internal
process_document <- function(x,  ...) {
    # This function passes texts to python and spacy
    # get or set document names
    if (!is.null(names(x))) {
        docnames <- names(x) 
    } else {
        docnames <- paste0("text", 1:length(x))
    }

    if (is.null(options()$spacy_initialized)) spacy_initialize()
    spacyr_pyexec("try:\n del spobj\nexcept NameError:\n 1")
    spacyr_pyexec("texts = []")
    
    x <- gsub("\\\\n","\\\n", x) # replace two quotes \\n with \n
    x <- gsub("\\\\t","\\\t", x) # replace two quotes \\t with \t
    x <- gsub("\\\\","", x) # delete unnecessary backslashes
    x <- unname(x)
    
    spacyr_pyassign("texts", x)
    spacyr_pyexec("spobj = spacyr()")
    
    spacyr_pyexec("timestamps = spobj.parse(texts)")
    
    timestamps = as.character(spacyr_pyget("timestamps"))
    output <- spacy_out$new(docnames = docnames, 
                            timestamps = timestamps)
    return(output)
}

