#' parse a text using spaCy
#' 
#' The spacy_parse() function calls spaCy to both tokenize and tag the texts,
#' and returns a data.table of the results. 
#' The function provides options on the types of tagsets (\code{tagset_} options)
#' either  \code{"google"} or \code{"detailed"}, as well
#' as lemmatization (\code{lemma}).
#' It provides a functionalities of dependency parsing and named entity 
#' recognition as an option. If \code{"full_parse = TRUE"} is provided, 
#' the function returns the most extensive list of the parsing results from spaCy.
#' 
#' @param x a character or \pkg{quanteda} corpus object
#' @param pos_tag logical; if \code{TRUE}, tag parts of speech
#' @param named_entity logical; if \code{TRUE}, report named entities
#' @param dependency logical; if \code{TRUE}, analyze and return dependencies
#' @param tagset_detailed logical whether a detailed tagset outcome is included in the result.
#'   In the case of using \code{"en"} model, default tagset is scheme from the Penn Treebank. 
#'   In the case of using \code{"de"} model, default tagset is scheme from the German Text Archive (http://www.deutschestextarchiv.de/doku/pos). 
#' @param tagset_google logical whether a simplified \code{"google"} tagset will be 
#'   returned.
#' @param lemma logical; inlucde lemmatized tokens in the output
#' @param full_parse  logical; if \code{TRUE}, conduct the one-shot parse 
#'   regardless of the value of other parameters. This  option exists because 
#'   the parsing outcomes of named entities are slightly different different 
#'   when named entities are run separately from the parsing.
# @param data.table logical; if \code{TRUE}, return a data.table, otherwise
#   return a data.frame
#' @param ... not used directly
#' @import quanteda
#' @return an tokenized text object
#' @export
#' @examples
#' \donttest{
#' spacy_initialize()
#' # See Chap 5.1 of the NLTK book, http://www.nltk.org/book/ch05.html
#' txt <- "And now for something completely different."
#' spacy_parse(txt)
#' spacy_parse(txt, pos_tag = FALSE)
#' spacy_parse(txt, dependency = TRUE)
#' 
#' txt2 <- c(doc1 = "The fast cat catches mice.\\nThe quick brown dog jumped.", 
#'           doc2 = "This is the second document.",
#'           doc3 = "This is a \\\"quoted\\\" text." )
#' spacy_parse(txt2, full_parse = TRUE, named_entity = TRUE, dependency = TRUE)
#' }
spacy_parse <- function(x, pos_tag = TRUE,
                        tagset_detailed = TRUE, 
                        tagset_google = TRUE, 
                        lemma = FALSE,
                        named_entity = FALSE, 
                        dependency = FALSE,
                        full_parse = FALSE, 
                        ...) {
    UseMethod("spacy_parse")
}


#' @export
#' @importFrom data.table data.table
#' @noRd
spacy_parse.character <- function(x, pos_tag = TRUE, 
                                  tagset_detailed = TRUE, 
                                  tagset_google = TRUE, 
                                  lemma = FALSE,
                                  named_entity = FALSE, 
                                  dependency = FALSE,
                                  full_parse = FALSE, 
                                  ...) {
    
    `:=` <- NULL
    
    if(full_parse == TRUE) {
        pos_tag <- tagset_detailed <- tagset_google <- lemma <-
            named_entity <- dependency <- TRUE
    }
    
    spacy_out <- process_document(x)
    if (is.null(spacy_out$timestamps)) {
        stop("Document parsing failed")
    }
    
    tokens <- get_tokens(spacy_out)
    ntokens <- get_ntokens(spacy_out)
    ntokens_by_sent <- get_ntokens_by_sent(spacy_out)

    dt <- data.table(docname = rep(spacy_out$docnames, ntokens), 
                     sentence_id = unlist(lapply(ntokens_by_sent, function(x) rep(1:length(x), x))),
                     token_id = get_attrs(spacy_out, "i") + 1, ## + 1 for shifting the first id = 1
                     tokens = tokens)
    
    if (lemma) {
        dt[, "lemma" := get_attrs(spacy_out, "lemma_")]
    }
    if (pos_tag) {
        if(tagset_detailed){
            dt[, "tag_detailed" := get_tags(spacy_out, "detailed")]
        }
        if(tagset_google){
            dt[, "tag_google" := get_tags(spacy_out, "google")]
            
        }
    }

    ## add dependency data fields
    if (dependency) {
        deps <- get_dependency(spacy_out)
        dt[, c("head_token_id", "dep_rel") := list(deps$head_id,
                                                   deps$dep_rel)]
    }
    
    ## named entity fields
    if (named_entity) {
        dt[, named_entity := get_named_entities(spacy_out)]
    }
    
    class(dt) <- c("spacyr_parsed", class(dt))
    return(dt)
}


#' @noRd
#' @export
spacy_parse.corpus <- function(x, ...) {
    spacy_parse(texts(x), ...)
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

