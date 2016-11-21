#' parse a text using spaCy
#' 
#' Full description awaits.
#' @param x a character or \pkg{quanteda} corpus object
#' @param pos_tag logical; if \code{TRUE}, tag parts of speech
#' @param named_entity logical; if \code{TRUE}, report named entities
#' @param dependency logical; if \code{TRUE}, analyze and return dependencies
#' @param tagset character label for the tagset to use, either \code{"google"} 
#'   or \code{"penn"} to use the simplified Google tagset, or the more detailed 
#'   scheme from the Penn Treebank. \code{"both"} returns both google and penn 
#'   tagsets.
#' @param lemma logical; inlucde lemmatized tokens in the output
#' @param python_exec character; select backend implementation spacy from 
#' "rPython" or "Rcpp". 
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
                        tagset = NA, 
                        lemma = FALSE,
                        named_entity = FALSE, 
                        dependency = FALSE,
                        full_parse = FALSE, 
                        python_exec = 'rPython',
                        # data.table = TRUE, 
                        ...) {
    UseMethod("spacy_parse")
}


#' @export
#' @importFrom data.table data.table
#' @noRd
spacy_parse.character <- function(x, pos_tag = TRUE, 
                                  tagset = NA,
                                  lemma = FALSE,
                                  named_entity = FALSE, 
                                  dependency = FALSE,
                                  full_parse = FALSE, 
                                  python_exec = 'rPython',
                                  # data.table = TRUE, 
                                  ...) {
    
    
    if(pos_tag == TRUE & is.na(tagset)) {
        tagset = "both"
    }
    python_exec <- match.arg(python_exec, c("rPython", "Rcpp"))
    
    # only set tokenize_only flag to TRUE if nothing else is requested
    tokenize_only <- ifelse(any(pos_tag, lemma, named_entity, dependency) | 
                                full_parse, FALSE, TRUE)
                             
    spacy_out <- process_document(x, tokenize_only = tokenize_only, python_exec = python_exec)
    if (is.null(spacy_out$timestamps)) {
        stop("Document parsing failed")
    }
    
    tokens <- get_tokens(spacy_out)
    ntokens <- get_ntokens(spacy_out)
    
    dt <- data.table(docname = rep(spacy_out$docnames, ntokens), 
                     id = get_attrs(spacy_out, "i"),
                     tokens = tokens)
    
    ## add lemma, tags in google and penn (lemmatization in spacy is 
    ## a part of pos_tagging, so without pos_tag, lemma cannot be done.)
    if (lemma) {
        dt[, "lemma" := get_attrs(spacy_out, "lemma_")]
    }
    if (pos_tag) {
        if(tagset %in% c("google", "both")){
            dt[, "google" := get_tags(spacy_out, "google")]
        }
        if(tagset %in% c("penn", "both")){
            dt[, "penn" := get_tags(spacy_out, "penn")]
        }
    }

    ## add dependency data fields
    if (dependency) {
        deps <- get_dependency(spacy_out)
        dt[, c("head_id", "dep_rel") := list(deps$head_id,
                                             deps$dep_rel)]
    }
    
    ## named entity fields
    if (named_entity) {
        dt[, named_entity := get_named_entities(spacy_out)]
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
#' @param python_exec character; select backend implementation spacy from 
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
process_document <- function(x, tokenize_only = FALSE, python_exec,  ...) {
    # This function passes texts to python and spacy
    # get or set document names
    if (!is.null(names(x))) {
        docnames <- names(x) 
    } else {
        docnames <- paste0("text", 1:length(x))
    }

    x <- gsub("\\\\n","\\\n", x) # replace two quotes \\n with \n
    x <- gsub("\\\\t","\\\t", x) # replace two quotes \\t with \t
    x <- gsub("\\\\","", x) # delete unnecessary backslashes
    x <- gsub("\\n","\\\\n", x) # reescape \n (convert to \\n)
    x <- gsub("\\t","\\\\t", x) # reescape \t (convert to \\t)
    x <- gsub("'","\\\\'", x) # escape single quotes
    x <- gsub('"','\\\\"', x) # escape double quotes
    x <- unname(x)
    
    # construct a python statement for variable declaration
    text_modified <- sprintf("[%s]", 
                     paste(sapply(x, function(x) sprintf("\"%s\"", x)),
                           collapse = ", "))
    rpytnon <- ifelse(python_exec == "rPython", TRUE, FALSE)
    
    if (is.null(options()$spacy_rpython)) spacy_initialize()
    spacyr_pyexec("try:\n del spobj\nexcept NameError:\n 1", python_exec = python_exec)
    spacyr_pyexec("texts = []", python_exec = python_exec)
    spacyr_pyexec(paste0("texts = ", text_modified), python_exec = python_exec)
    
    # initialize spacyr() object
    spacyr_pyexec("spobj = spacyr()", python_exec = python_exec)
    
    spacyr_pyassign("tokenize_only", tokenize_only, python_exec = python_exec)
    spacyr_pyexec("timestamps = spobj.parse(texts, tokenize_only)", python_exec = python_exec)
    
    timestamps = as.character(spacyr_pyget("timestamps"))
    output <- spacy_out$new(docnames = docnames, 
                            timestamps = timestamps,
                            tokenize_only = tokenize_only,
                            python_exec = python_exec)
    return(output)
}

spacyr_pyassign <- function(pyvarname, values, python_exec = 'rPython') {
    if(python_exec == 'rPython') {
        rPython::python.assign(pyvarname, values)
    }
}

spacyr_pyget <- function(pyvarname, python_exec = 'rPython') {
    if(python_exec == 'rPython') {
        return(rPython::python.get(pyvarname))
    }    
}

spacyr_pyexec <- function(pystring, python_exec = 'rPython') {
    if(python_exec == 'rPython') {
        rPython::python.exec(pystring)
    }
}

