#' parse text using spaCy
#' 
#' Parse text using spaCy. The results of parsing is stored as a python object. To obtain the results in R, use functions such as get_tokens(), get_tags() etc.
#' \url{http://spacy.io}.
#' @param x input text
#' @param ... arguments passed to specific methods
#' @return result marker object
#' @examples
#' \donttest{initialize_spacy_rpython()
#' # the result has to be "tag() is ready to run" to run the following
#' txt <- c(text1 = "This is the first sentence.\nHere is the second sentence.", 
#'          text2 = "This is the second document.")
#' results <- parse_spacy(txt)
#' 
#' tag(txt, tagset = "penn")
#'
#' # more extensive texts
#' tag(data_paragraph)
#' tag(data_sentences[1:10])
#' }
#' @export
parse_spacy <- function(x, ...) {
    # get or set document names
    if (!is.null(names(x))) {
        docnames <- names(x) 
    } else {
        docnames <- paste0("text", 1:length(x))
    }
    
    
    x <- iconv(x, "UTF-8", "ASCII",  sub="") 
    x <- gsub("\\n", "\\n ", x)
    x <- gsub("'", "''", x, fixed = T)
    x <- gsub("\"", "", x, fixed = T)
    x <- gsub("\\", "", x, fixed = T)
    x <- unname(x)
    
    if (is.null(options()$spacy_rpython)) 
        initialize_spacy_rpython()
    rPython::python.assign("texts", x)
    rPython::python.exec("results = spobj.parse(texts)")
    timestamps = as.character(rPython::python.get("results"))
    
    output <- list(docnames = docnames, timestamps = timestamps)
    attr(output, "class") <- "spacy_out"
    return(output)
}



