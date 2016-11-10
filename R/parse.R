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
process_document <- function(x, tokenize_only = FALSE,  ...) {
    # This function passes texts to python and spacy
    # get or set document names
    if (!is.null(names(x))) {
        docnames <- names(x) 
    } else {
        docnames <- paste0("text", 1:length(x))
    }
    
    
    #x <- iconv(x, "UTF-8", "ASCII",  sub="")
    x <- gsub("\\n", "\\n ", x)
    x <- gsub("'", "''", x, fixed = T)
    x <- gsub("\"", "", x, fixed = T)
    x <- gsub("\\", "", x, fixed = T)
    x <- unname(x)

    
    if (is.null(options()$spacy_rpython)) spacy_initialize()
    rPython::python.assign("texts", x)
    rPython::python.assign("tokenize_only", tokenize_only)
    rPython::python.exec("results = spobj.parse(texts, tokenize_only)")
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
        parser = 'logical'
    ),
    methods = list(
        initialize = function(tokenize_only = FALSE,
                              timestamps = NULL, docnames = NULL) {
            if(tokenize_only){
                tagger <<- entity <<- parser <<- FALSE
            } else {
                tagger <<- entity <<- parser <<- TRUE
            }
            tokenize_only <<- tokenize_only
            timestamps <<- timestamps
            docnames <<- docnames
        }
    )
)

#' Tokens 
#' 
#' @rdname spacy_parse
#' @param x objet to be parsed
#' @param ... additional arguments not used
#' @export
spacy_parse <- function(x, ...) {
    UseMethod("spacy_parse")
}

#' get tokens from a text vector
#' @param x a text vector
#' @param pos_tag Logical. Part of speech tagging
#' @param named_entity Logical. Conduct nemed entity recognition
#' @param dependency Logical. Conduct dependency analysis.
#' @param hash_tokens Logical. Hash tokens.
#' @import quanteda
#' @return an tokenized text object 
#' @export
#'
#' @examples
#' \donttest{
#' txt <- c(text1 = "This is the first sentence.\nHere is the second sentence.", 
#'          text2 = "This is the second document.")
#' results <- spacy_parse(txt)
#' tokens <- tokens(results)
#' }
spacy_parse.character <- function(x, pos_tag = TRUE, 
                   named_entity = FALSE, 
                   dependency = FALSE,
                   hash_tokens = FALSE, 
                   full_parse = FALSE, ...) {
    tokenize_only <- ifelse(sum(pos_tag, named_entity, dependency) == 3 | 
                                full_parse == T, 
                            FALSE, TRUE)
    spacy_out <- process_document(x, tokenize_only = tokenize_only)
    tokens <- get_tokens(spacy_out)
    if (hash_tokens) tokens <- quanteda::tokens_hash(tokens)
    
    
    ## initialize data table with three fields
    for(i in 1:length(tokens)){
        names(tokens[[i]]) <- NA
    }
    tok <- unlist(tokens)
    docname <- sub("\\.NA", "", names(tok))
    if("tokens" %in% class(tokens)){
        #tokens <- quanteda::as.tokenizedTexts(tokens)
        types <- attr(tokens, "types")
        tok <- factor(tok, labels = types)
    }
    dt <- data.table(docname = docname, 
                         id = unlist(get_attrs(spacy_out, "i"), use.names = F),
                         tokens = tok)
    
    ## add lemma, tags in google and penn (lemmatization in spacy is 
    ## a part of pos_tagging, so without pos_tag, lemma cannot be done.)
    
    if(pos_tag) {
        #
        gl <- get_tags(spacy_out, "google")
        pn <- get_tags(spacy_out, "penn")
        lem <- get_attrs(spacy_out, "lemma_")
        
        gl <- unlist(gl, use.names = F)
        pn <- unlist(pn, use.names = F)
        lem <- unlist(lem, use.names = F)
        
        dt[, lemma := lem][, google := gl][, penn:= pn]
    }
    ## add dependency data fields
    if (dependency) {
        de <- get_dependency(spacy_out)
        hid <- unlist(de$head_id, use.names = F)
        depl <- unlist(de$dep_rel, use.names = F)
        dt[, head_id := hid ][, dep_rel := depl]
    }
    ## named entity fields
    if (named_entity) {
        ne <- get_named_entities(spacy_out)
        ne <- unlist(ne, use.names = F)
        dt[, named_entity := ne]
    }
    
    class(dt) <- c("spacyr_data_table", class(dt))
    ##attr(output, "id") <- get_attrs(spacy_out, "i")
    ## there will be a cleaning up functionality
    return(dt)
}


#' @rdname spacy_parse
#' @export
spacy_parse.corpus <- function(x, ...) {
    tokens(texts(x), ...)
}

#' get tokens
#' 
#' 
#' @param spacy_out a spacy_out object
#' @export
get_tokens <- function(spacy_out) {
    rPython::python.assign('timestamps', spacy_out$timestamps)
    rPython::python.exec('tokens_list = spobj.tokens(timestamps)')
    tokens <- rPython::python.get("tokens_list")
    tokens <- tokens[spacy_out$timestamps]
    names(tokens) <- spacy_out$docnames
    #output <- list(tokens = tokens)
    class(tokens) <- c("tokenizedText", class(tokens))
    attr(tokens, "what") <- "word"
    attr(tokens, "ngrams") <- 1
    attr(tokens, "concatenator") <- ""
    return(tokens)
}

#' tag parts of speech using spaCy via rPython
#' 
#' Tokenize a text using spaCy and tag the tokens with part-of-speech tags. 
#' Options exist for using either the Google or Penn tagsets. See 
#' \url{http://spacy.io}.
#'
#' @return a tokenized text object with tags
#' @param spacy_out a spacy_out object
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
get_tags <- function(spacy_out, tagset = c("google", "penn")) {
    #stopifnot("tokenizedText_spacyr" %in% class(tokens))
    #spacy_out <- tokens$spacy_out
    tagset <- match.arg(tagset)
    rPython::python.assign('timestamps', spacy_out$timestamps)
    if(spacy_out$tagger == FALSE) {
        rPython::python.exec('tags_list = spobj.run_tagger(timestamps)')
        spacy_out$tagger <- TRUE
    }
    rPython::python.assign('tagset', tagset)
    rPython::python.exec('tags_list = spobj.tags(timestamps, tagset)')
    tags <- rPython::python.get("tags_list")
    tags <- tags[spacy_out$timestamps]
    names(tags) <- spacy_out$docnames
    #tokens$tags <- tags
    #class(tokens) <- union(class(tokens), "tokenizedTexts_tagged")
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
    
    rPython::python.exec('attrs_list = spobj.attributes(timestamps, attr_name)')
    attrs <- rPython::python.get("attrs_list")
    attrs <- attrs[spacy_out$timestamps]
    names(attrs) <- spacy_out$docnames
    return(attrs)
}

#' Title
#'
#' @param spacy_out a spacy_out object
#' 
#' @return list of named entities in texts
#' @export
get_named_entities <- function(spacy_out){
    rPython::python.assign('timestamps', spacy_out$timestamps)
    if(spacy_out$entity == FALSE) {
        rPython::python.exec('tags_list = spobj.run_entity(timestamps)')
        spacy_out$entity <- TRUE
    }
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
get_dependency <- function(spacy_out){
    # get ids of head of each token
    rPython::python.assign('timestamps', spacy_out$timestamps)
    if(spacy_out$parser == FALSE) {
        rPython::python.exec('tags_list = spobj.run_dependency_parser(timestamps)')
        spacy_out$parser <- TRUE
    }
    rPython::python.exec('head_id = spobj.dep_head_id(timestamps)')
    head_id <- rPython::python.get("head_id")
    head_id  <- head_id[spacy_out$timestamps]
    
    dep_rel <- get_attrs(spacy_out, "dep_")
    return(list(head_id = head_id, dep_rel = dep_rel))
}


#' Obtain a data of all named entities in spacy out data.table
#'
#' @param dt a data table object from 
#'
#' @return a data.table of all named entities
#' @export
all_named_entities <- function(dt) {
    if(!"named_entity" %in% names(dt)) {
        stop("Named Entity Recognition is not conducted")
    }
    dt <- dt[nchar(dt$named_entity) > 0]
    dt[, entity_type := sub("_.+", "", named_entity)]
    dt[, iob := sub(".+_", "", named_entity)]
    dt[, ent_id := cumsum(iob=="B")]
    entities <- dt[, lapply(.SD, function(x) x[1]), by = ent_id, 
                   .SDcols = c("docname", "id", "entity_type")]
    entities[, entity := dt[, lapply(.SD, function(x) paste(x, collapse = " ")), 
                            by = ent_id, 
                            .SDcols = c("tokens")]$tokens]    
}

