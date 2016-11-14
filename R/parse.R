#' parse a text using spaCy
#' 
#' Full description awaits.
#' @param x a character or \pkg{quanteda} corpus object
#' @param pos_tag logical; if \code{TRUE}, tag parts of speech
#' @param named_entity logical; if \code{TRUE}, report named entities
#' @param dependency logical; if \code{TRUE}, analyze and return dependencies
#' @param hash_tokens logical; if \code{TRUE}, hash the tokens
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
#' tokens(results)
#' }
spacy_parse <- function(x, pos_tag = TRUE, 
                        named_entity = FALSE, 
                        dependency = FALSE,
                        hash_tokens = FALSE, 
                        full_parse = FALSE, 
                        # data.table = TRUE, 
                        ...) {
    UseMethod("spacy_parse")
}


#' @export
#' @importFrom data.table data.table
#' @noRd
spacy_parse.character <- function(x, pos_tag = TRUE, 
                                  named_entity = FALSE, 
                                  dependency = FALSE,
                                  hash_tokens = FALSE, 
                                  full_parse = FALSE, 
                                  # data.table = TRUE, 
                                  ...) {
    
    lemma <- google <- penn <- head_id <- dep_rel <- NULL
    
    tokenize_only <- ifelse(sum(pos_tag, named_entity, dependency) == 3 | 
                                full_parse == T, 
                            FALSE, TRUE)
    spacy_out <- process_document(x, tokenize_only = tokenize_only)
    
    tokens <- get_tokens(spacy_out)

    dt <- data.table(docname = rep(names(tokens), lengths(tokens)), 
                     id = unlist(get_attrs(spacy_out, "i"), use.names = FALSE),
                     tokens = unlist(tokens, use.names = FALSE))
    
    ## add lemma, tags in google and penn (lemmatization in spacy is 
    ## a part of pos_tagging, so without pos_tag, lemma cannot be done.)
    if (pos_tag) {
        dt[, c("lemma", "google", "penn") := 
               list(unlist(get_attrs(spacy_out, "lemma_"), use.names = FALSE),
                    unlist(get_tags(spacy_out, "google"), use.names = FALSE),
                    unlist(get_tags(spacy_out, "penn"), use.names = FALSE))]
    }

    ## add dependency data fields
    if (dependency) {
        deps <- get_dependency(spacy_out)
        dt[, c("head_id", "dep_rel") := list(unlist(deps$head_id, use.names = FALSE),
                                             unlist(deps$dep_rel, use.names = FALSE))]
    }
    
    ## named entity fields
    if (named_entity) {
        dt[, named_entity := unlist(get_named_entities(spacy_out), use.names = FALSE)]
    }
    
    # coerce to a data.frame if a data.table-ly challeged user pitifully requests it 
    # if (!data.table) dt <- as.data.frame(dt)

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
#' @param tokenize_only Logical. If TRUE, spaCy will run all parsing 
#' functionalities including the tagging, named entity recognisiton, dependency 
#' analysis. 
#' This slows down \code{spacy_parse()} but speeds up the later parsing. 
#' If FALSE, tagging, entity recogitions, and dependendcy analysis when 
#' relevant functions are called.
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
process_document <- function(x, tokenize_only = FALSE,  ...) {
    # This function passes texts to python and spacy
    # get or set document names
    if (!is.null(names(x))) {
        docnames <- names(x) 
    } else {
        docnames <- paste0("text", 1:length(x))
    }

    x <- gsub("\\\\","", x)
    x <- gsub("\\n","\\\\n", x)
    x <- gsub("\\t","\\\\t", x)
    x <- gsub("'","\\\\'", x)
    x <- gsub('"','\\\\"', x)
    x <- unname(x)
    text_modified <- sprintf("[%s]", 
                     paste(sapply(x, function(x) sprintf("\"%s\"", x)),
                           collapse = ", "))
    
    if (is.null(options()$spacy_rpython)) spacy_initialize()
    rPython::python.exec("spobj = spacyr()")
    exec_out <- rPython::python.exec(paste0("texts = ", text_modified),
                                     get.exception = F)
    if(exec_out == -1) {
        stop("Failed to assign text values")
    }
    rPython::python.assign("tokenize_only", tokenize_only)
    rPython::python.exec("results = spobj.parse(texts, tokenize_only)")
    
    timestamps = as.character(rPython::python.get("results"))
    rPython::python.exec("del results")
    
    # output <- list(docnames = docnames, timestamps = timestamps)
    # class(output) <- c("spacy_out", class(output))
    output <- spacy_out$new(docnames = docnames, 
                            timestamps = timestamps,
                            tokenize_only = tokenize_only)
    return(output)
}

