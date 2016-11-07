#' tokenize text using spaCy
#' 
#' Tokenize text using spaCy. The results of tokenization is stored as a python object. To obtain the tokens results in R, use \code{get_tokens()}.
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
    class(output) <- c("spacy_out", class(output))
    return(output)
}

#' get tokens from tokenized texts
#'
#' @param spacy_out a spacy_out object
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
    tokens <- tokens[spacy_out$timestamps]
    names(tokens) <- spacy_out$docnames
    return(tokens)
}

#' get tags from spaCy output
#'
#' @param spacy_out a spacy_out object
#' @param tagset character label for the tagset to use, either \code{"google"} 
#'   or \code{"penn"} to use the simplified Google tagset, or the more detailed 
#'   scheme from the Penn Treebank.  
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
    
    rPython::python.assign('tagset', tagset)
    rPython::python.exec('tags_list = spobj.tags(timestamps, tagset)')
    tags <- rPython::python.get("tags_list")
    tags <- tags[spacy_out$timestamps]
    names(tags) <- spacy_out$docnames
    return(tags)
}


#' get arbitrary attributes from spacy output
#'
#' @param spacy_out a spacy_out object
#' @param attr_name name of spacy token attributes to extract
#'
#' @return a list of attributes
#' @export
get_attrs <- function(spacy_out, attr_name) {
    rPython::python.assign('timestamps', spacy_out$timestamps)
    rPython::python.assign('attr_name', attr_name)
    
    rPython::python.exec('tags_list = spobj.attributes(timestamps, attr_name)')
    tags <- rPython::python.get("tags_list")
    tags <- tags[spacy_out$timestamps]
    names(tags) <- spacy_out$docnames
    return(tags)
}

#' tag parts of speech using spaCy via rPython
#' 
#' Tokenize a text using spaCy and tag the tokens with part-of-speech tags. 
#' Options exist for using either the Google or Penn tagsets. See 
#' \url{http://spacy.io}.
#'
#' @param spacy_out a spacy_out object generated from \code{parse_spacy}
#' @param tagset character label for the tagset to use, either \code{"google"} 
#'   or \code{"penn"} to use the simplified Google tagset, or the more detailed 
#'   scheme from the Penn Treebank.  
#'
#' @return a tokenizedTexts_tagged object
#' @export
tag_new <- function(spacy_out, tagset = c("penn", "google")) {
    tags <- get_tags(spacy_out, tagset)
    tokens <- get_tokens(spacy_out)
    ret <- list(tokens = tokens, tags = tags)
    attr(ret, "tagset") <- tagset
    class(ret) <- c("tokenizedTexts_tagged", class(ret))
    return(ret)
}

#' Title
#'
#' this function will be hidden in future
#'
#' @param spacy_out a spacy_out object
#' 
#' @return list of named entities in texts
#' @export
all_entities <- function(spacy_out){
    rPython::python.assign('timestamps', spacy_out$timestamps)
    
    rPython::python.exec('ents_list = spobj.list_entities(timestamps)')
    ents <- rPython::python.get("ents_list")
    ents <- ents[spacy_out$timestamps]
    names(ents) <- spacy_out$docnames
    return(ents)
}


#' Title
#'
#' @param spacy_out a spacy_out object
#' 
#' @return list of named entities in texts
#' @export
get_entities <- function(spacy_out){
    rPython::python.assign('timestamps', spacy_out$timestamps)
    rPython::python.exec('ents_type = spobj.attributes(timestamps, "ent_type_")')
    ent_type <- rPython::python.get("ents_type")
    ent_type  <- ent_type[spacy_out$timestamps]
    rPython::python.exec('ents_iob = spobj.attributes(timestamps, "ent_iob_")')
    ent_iob <- rPython::python.get("ents_iob")
    ent_iob <- ent_iob[spacy_out$timestamps]
    
    names(ent_type) <- spacy_out$docnames
    names(ent_iob) <- spacy_out$docnames
    for(i in 1:length(ent_type)){
        iob <- sub("O", "", ent_iob[[i]])
        ent_type[[i]] <- paste(ent_type[[i]], iob, sep = "_")
        ent_type[[i]][grepl("^_$", ent_type[[i]])] <- ""
    }
    return(ent_type)
}


get_dependency_data <- function(spacy_out){
    rPython::python.assign('timestamps', spacy_out$timestamps)
    rPython::python.exec('ents_type = spobj.attributes(timestamps, "ent_type_")')
    ent_type <- rPython::python.get("ents_type")
    ent_type  <- ent_type[spacy_out$timestamps]
    rPython::python.exec('ents_iob = spobj.attributes(timestamps, "ent_iob_")')
    ent_iob <- rPython::python.get("ents_iob")
    ent_iob <- ent_iob[spacy_out$timestamps]
    
    names(ent_type) <- spacy_out$docnames
    names(ent_iob) <- spacy_out$docnames
    for(i in 1:length(ent_type)){
        iob <- sub("O", "", ent_iob[[i]])
        ent_type[[i]] <- paste(ent_type[[i]], iob, sep = "_")
        ent_type[[i]][grepl("^_$", ent_type[[i]])] <- ""
    }
    return(ent_type)
}


