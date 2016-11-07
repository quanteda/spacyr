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

#' get tokens from spaCy output
#'
#' @param spacy_out an spacy out object
#'
#' @return a list of tokens
#' @export
#'
#' @examples
#' \donttest{
#' txt <- c(text1 = "This is the first sentence.\nHere is the second sentence.", 
#'          text2 = "This is the second document.")
#' results <- parse_spacy(txt)
#' get_tags(results)
#' }
get_tokens <- function(spacy_out) {
    rPython::python.assign('timestamps', spacy_out$timestamps)
    rPython::python.exec('tokens_list = spobj.tokens(timestamps)')
    tokens <- rPython::python.get("tokens_list")
    names(tokens) <- spacy_out$docnames
    return(tokens)
}

#' get tags from spaCy output
#'
#' @param spacy_out an spacy out object
#'
#' @return a list of tags
#' @export
#'
#' @examples
#' \donttest{
#' txt <- c(text1 = "This is the first sentence.\nHere is the second sentence.", 
#'          text2 = "This is the second document.")
#' results <- parse_spacy(txt)
#' get_tags(results)
#' }
get_tags <- function(spacy_out,  tagset = c("google", "penn")) {
    tagset <- match.arg(tagset)
    rPython::python.assign('timestamps', spacy_out$timestamps)
    rPython::python.assign('tag_type', tag_type)
    rPython::python.exec('tags_list = spobj.tags(timestamps, tag_type)')
    tags <- rPython::python.get("tags_list")
    names(tags) <- spacy_out$docnames
    return(tags)
}


#' get arbitrary attributes from spacy output
#'
#' @param spacy_out 
#' @param attr_name 
#'
#' @return a list of attributes
#' @export
get_attrs <- function(spacy_out, attr_name) {
    rPython::python.assign('timestamps', spacy_out$timestamps)
    rPython::python.assign('attr_name', attr_name)
    
    rPython::python.exec('tags_list = spobj.attributes(timestamps, attr_name)')
    tags <- rPython::python.get("tags_list")
    names(tags) <- spacy_out$docnames
    return(tags)
}
