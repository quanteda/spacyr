

spacy_out <- setRefClass(
    Class = "spacy_out",
    fields = list(
        timestamps = 'character',
        docnames = 'character',
        tokenize_only = 'logical',
        tagger = 'logical',
        entity = 'logical',
        parser = 'logical',
        python_exec = 'character'
    ),
    methods = list(
        initialize = function(tokenize_only = FALSE,
                              timestamps = NULL, docnames = NULL,
                              python_exec = 'rPython') {
            if (tokenize_only) {
                tagger <<- entity <<- parser <<- FALSE
            } else {
                tagger <<- entity <<- parser <<- TRUE
            }
            tokenize_only <<- tokenize_only
            timestamps <<- timestamps
            docnames <<- docnames
            python_exec <<- python_exec
        }
    )
)


#' get tokens
#' 
#' Extract tokens from a spacy reference object.
#' @param spacy_out a spacy_out object
#' @export
#' @keywords internal
get_tokens <- function(spacy_out) {
    spacyr_pyassign('timestamps', spacy_out$timestamps, 
                    python_exec = spacy_out$python_exec)
    spacyr_pyexec('tokens_list = spobj.tokens(timestamps)',
                  python_exec = spacy_out$python_exec)
    tokens <- spacyr_pyget("tokens_list", python_exec = spacy_out$python_exec)
    # tokens <- tokens[spacy_out$timestamps]
    # names(tokens) <- spacy_out$docnames
    # #output <- list(tokens = tokens)
    # class(tokens) <- c("tokenizedText", class(tokens))
    # attr(tokens, "what") <- "word"
    # attr(tokens, "ngrams") <- 1
    # attr(tokens, "concatenator") <- ""
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
#' @keywords internal
get_tags <- function(spacy_out, tagset = c("google", "penn")) {
    #stopifnot("tokenizedText_spacyr" %in% class(tokens))
    #spacy_out <- tokens$spacy_out
    tagset <- match.arg(tagset)
    spacyr_pyassign('timestamps', spacy_out$timestamps, python_exec = spacy_out$python_exec)
    if(spacy_out$tagger == FALSE) {
        spacyr_pyexec('tags_list = spobj.run_tagger(timestamps)', 
                      python_exec = spacy_out$python_exec)
        spacy_out$tagger <- TRUE
    }
    spacyr_pyassign('tagset', tagset, python_exec = spacy_out$python_exec)
    spacyr_pyexec('tags_list = spobj.tags(timestamps, tagset)', 
                  python_exec = spacy_out$python_exec)
    tags <- spacyr_pyget("tags_list",
                         python_exec = spacy_out$python_exec)
    # tags <- tags[spacy_out$timestamps]
    # names(tags) <- spacy_out$docnames
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
#' @keywords internal
get_attrs <- function(spacy_out, attr_name) {
    spacyr_pyassign('timestamps', spacy_out$timestamps, 
                    python_exec = spacy_out$python_exec)
    spacyr_pyassign('attr_name', attr_name, python_exec = spacy_out$python_exec)
    
    spacyr_pyexec('attrs_list = spobj.attributes(timestamps, attr_name)',
                  python_exec = spacy_out$python_exec)
    attrs <- spacyr_pyget("attrs_list",
                          python_exec = spacy_out$python_exec)
    # attrs <- attrs[spacy_out$timestamps]
    # names(attrs) <- spacy_out$docnames
    return(attrs)
}

#' Title
#'
#' @param spacy_out a spacy_out object
#' 
#' @return list of named entities in texts
#' @export
#' @keywords internal
get_named_entities <- function(spacy_out){
    spacyr_pyassign('timestamps', spacy_out$timestamps, 
                    python_exec = spacy_out$python_exec)
    if(spacy_out$entity == FALSE) {
        spacyr_pyexec('tags_list = spobj.run_entity(timestamps)',
                      python_exec = spacy_out$python_exec)
        spacy_out$entity <- TRUE
    }
    spacyr_pyexec('ents_type = spobj.attributes(timestamps, "ent_type_")',
                  python_exec = spacy_out$python_exec)
    ent_type <- spacyr_pyget("ents_type", 
                             python_exec = spacy_out$python_exec)
    # ent_type  <- ent_type[spacy_out$timestamps]
    spacyr_pyexec('ents_iob = spobj.attributes(timestamps, "ent_iob_")',
                  python_exec = spacy_out$python_exec)
    ent_iob <- spacyr_pyget("ents_iob", python_exec = spacy_out$python_exec)
    # ent_iob <- ent_iob[spacy_out$timestamps]
    
    iob <- sub("O", "", ent_iob)
    ent_type <- paste(ent_type, iob, sep = "_")
    ent_type[grepl("^_$", ent_type)] <- ""
    # names(ent_type) <- spacy_out$docnames
    # names(ent_iob) <- spacy_out$docnames
    # for(i in 1:length(ent_type)){
    #     iob <- sub("O", "", ent_iob[[i]])
    #     ent_type[[i]] <- paste(ent_type[[i]], iob, sep = "_")
    #     ent_type[[i]][grepl("^_$", ent_type[[i]])] <- ""
    # }
    return(ent_type)
}


#' Title
#'
#' @param spacy_out a spacy_out object
#'
#' @return data.frame of dependency relations
#' @export
#' @keywords internal
get_dependency <- function(spacy_out){
    # get ids of head of each token
    spacyr_pyassign('timestamps', spacy_out$timestamps,
                    python_exec = spacy_out$python_exec)
    if (spacy_out$parser == FALSE) {
        spacyr_pyexec('tags_list = spobj.run_dependency_parser(timestamps)',
                      python_exec = spacy_out$python_exec)
        spacy_out$parser <- TRUE
    }
    spacyr_pyexec('head_id = spobj.dep_head_id(timestamps)',
                  python_exec = spacy_out$python_exec)
    head_id <- spacyr_pyget("head_id",
                            python_exec = spacy_out$python_exec)
    # head_id  <- head_id[spacy_out$timestamps]
    
    dep_rel <- get_attrs(spacy_out, "dep_")
    return(list(head_id = head_id, dep_rel = dep_rel))
}

#' Title
#'
#' @param spacy_out a spacy_out object
#'
#' @return data.frame of dependency relations
#' @export
#' @keywords internal
get_ntokens <- function(spacy_out){
    # get ids of head of each token
    spacyr_pyassign('timestamps', spacy_out$timestamps,
                    python_exec = spacy_out$python_exec)
    spacyr_pyexec('ntok = spobj.ntokens(timestamps)',
                  python_exec = spacy_out$python_exec)
    ntokens <- spacyr_pyget("ntok", python_exec = spacy_out$python_exec)
    names(ntokens) <- spacy_out$timestamps
    return(ntokens)
}


#' Obtain a data of all named entities in spacy out data.table
#' 
#' Extended description to go here.
#' @param dt a data table object from 
#' @return a data.table of all named entities
#' @import data.table
#' @export
#' @keywords internal
all_named_entities <- function(dt) {
    
    # needed to stop "no visible binding" warnings
    entity_type <- named_entity <- iob <- ent_id <- NULL
    
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
    return(entities)
}


