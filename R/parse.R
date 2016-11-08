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
#' @examples
#' \donttest{spacy_initialize()
#' # the result has to be "tag() is ready to run" to run the following
#' txt <- c(text1 = "This is the first sentence.\nHere is the second sentence.", 
#'          text2 = "This is the second document.")
#' results <- spacy_parse(txt)
#' 
#' }
#' @export
spacy_parse <- function(x, tokenize_only = FALSE,  ...) {
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
    
    # output <- list(docnames = docnames, timestamps = timestamps)
    # class(output) <- c("spacy_out", class(output))
    output <- spacy_out$new(docnames = docnames, 
                            timestamps = timestamps,
                            tokenize_only = tokenize_only)
    return(output)
}

spacy_out <- setRefClass(
    Class = "spacy_out",
    fields = list(
        timestamps = 'character',
        docnames = 'character',
        tokenize_only = 'logical',
        tagger = 'logical',
        entity = 'logical',
        parse = 'logical'
    ),
    methods = list(
        initialize = function(tokenize_only = FALSE,
                              timestamps = NULL, docnames = NULL) {
            if(tokenize_only){
                tagger <<- entity <<- parse <<- FALSE
            } else {
                tagger <<- entity <<- parse <<- TRUE
            }
            tokenize_only <<- tokenize_only
            timestamps <<- timestamps
            docnames <<- docnames
        }
    )
)



#' get tokens from tokenized texts
#'
#' @return an tokenized text object in tokenizedText_spacyr class
#' @export
#'
#' @examples
#' \donttest{
#' txt <- c(text1 = "This is the first sentence.\nHere is the second sentence.", 
#'          text2 = "This is the second document.")
#' results <- spacy_parse(txt)
#' tokens <- tokens(results)
#' }
tokens <- function(x, ...) {
    UseMethod("tokens")
}

#' @describeIn tokens Get tokens using spacy_out object
#' @param spacy_out a spacy_out object
#' @export
tokens.spacy_out <- function(spacy_out) {
    rPython::python.assign('timestamps', spacy_out$timestamps)
    rPython::python.exec('tokens_list = spobj.tokens(timestamps)')
    tokens <- rPython::python.get("tokens_list")
    tokens <- tokens[spacy_out$timestamps]
    names(tokens) <- spacy_out$docnames
    output <- list(tokens = tokens, 
                   spacy_out = spacy_out)
    class(output) <- c("tokenizedText", 'tokenizedText_spacyr', class(output))
    return(output)
}

#' tag parts of speech using spaCy via rPython
#' 
#' Tokenize a text using spaCy and tag the tokens with part-of-speech tags. 
#' Options exist for using either the Google or Penn tagsets. See 
#' \url{http://spacy.io}.
#'
#' @return a tokenized text object with tags
#' @param tokens a tokenizedText_spacyr object
#' @param tagset character label for the tagset to use, either \code{"google"} 
#'   or \code{"penn"} to use the simplified Google tagset, or the more detailed 
#'   scheme from the Penn Treebank.  
#' @export 
#' @examples
#' \donttest{
#' txt <- c(text1 = "This is the first sentence.\nHere is the second sentence.", 
#'          text2 = "This is the second document.")
#' results <- spacy_parse(txt)
#' tokens <- tokens(results)
#' tokens_with_tag <- tokens_tag(tokens)
#' }
tokens_tag <- function(tokens,  tagset = c("google", "penn")) {
    stopifnot("tokenizedText_spacyr" %in% class(tokens))
    spacy_out <- tokens$spacy_out
    tagset <- match.arg(tagset)
    rPython::python.assign('timestamps', spacy_out$timestamps)
    
    rPython::python.assign('tagset', tagset)
    rPython::python.exec('tags_list = spobj.tags(timestamps, tagset)')
    tags <- rPython::python.get("tags_list")
    tags <- tags[spacy_out$timestamps]
    names(tags) <- spacy_out$docnames
    tokens$tags <- tags
    class(tokens) <- union(class(tokens), "tokenizedTexts_tagged")
    return(tokens)
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
    
    rPython::python.exec('attrs_list = spobj.attributes(timestamps, attr_name)')
    attrs <- rPython::python.get("attrs_list")
    attrs <- attrs[spacy_out$timestamps]
    names(attrs) <- spacy_out$docnames
    return(attrs)
}


#' Title
#'
#' this function may be hidden in future
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
tokens_named_entities <- function(spacy_out){
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


#' Title
#'
#' @param spacy_out a spacy_out object
#'
#' @return data.frame of dependency relations
#' @export
get_dependency_data <- function(spacy_out){
    id <- get_attrs(spacy_out, "i")
    token <- get_attrs(spacy_out, "orth_")
    lemma <-  get_attrs(spacy_out, "lemma_")
    google <-  get_attrs(spacy_out, "pos_")
    penn <-  get_attrs(spacy_out, "tag_")
    
    # get ids of head of each token
    rPython::python.assign('timestamps', spacy_out$timestamps)
    rPython::python.exec('head_id = spobj.dep_head_id(timestamps)')
    head_id <- rPython::python.get("head_id")
    head_id  <- head_id[spacy_out$timestamps]
    
    dep_rel <- get_attrs(spacy_out, "dep_")
    
    out_data <- NULL
    for(i in seq(length(spacy_out$timestamps))){
        #ts <- spacy_out$timestamps[i]
        docname <- spacy_out$docnames[i]
        tmp_data <- data.frame(docname, 
                               id = id[[i]],
                               token = token[[i]], 
                               lemma = lemma[[i]], 
                               google = google[[i]], 
                               penn = penn[[i]], 
                               head_id = head_id[[i]], 
                               dep_rel = dep_rel[[i]])
        out_data <- rbind(out_data, tmp_data)
    }
        
    
    return(out_data)
}


