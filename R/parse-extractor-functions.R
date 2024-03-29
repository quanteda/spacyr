

spacy_out <- setRefClass(
    Class = "spacy_out",
    fields = list(
        timestamps = "character",
        docnames = "character",
        tagger = "logical",
        entity = "logical",
        parser = "logical"
    ),
    methods = list(
        initialize = function(timestamps = NULL, docnames = NULL) {
            tagger <<- entity <<- parser <<- TRUE
            timestamps <<- timestamps
            docnames <<- docnames
        }
    )
)


#' get functions for spaCy
#' 
#' A collection of get methods for spacyr return objects (of `spacy_out` class).
#' @param spacy_out a spacy_out object
#' @return `get_tokens` returns a data.frame of tokens from spaCy.
#' @export
#' @name get-functions
#' @keywords internal
get_tokens <- function(spacy_out) {
    spacyr_pyassign("timestamps", spacy_out$timestamps)
    spacyr_pyexec("tokens_list = spobj.tokens(timestamps)")
    tokens <- spacyr_pyget("tokens_list")
    return(tokens)
}

#' @rdname get-functions
#' @return `get_tags` returns a tokenized text object with part-of-speech tags.
#' Options exist for using either the Google or Detailed tagsets. See 
#' <https://spacy.io>.
#' @param tagset character label for the tagset to use, either `"google"` 
#'   or `"detailed"` to use the simplified Google tagset, or the more detailed 
#'   scheme from the Penn Treebank (or the German Text Archive in case of German language model).  
#' @export 
#' @examples
#' \dontrun{
#' # get_tags examples
#' txt <- c(text1 = "This is the first sentence.\nHere is the second sentence.", 
#'          text2 = "This is the second document.")
#' results <- spacy_parse(txt)
#' tokens <- tokens(results)
#' tokens_with_tag <- tokens_tag(tokens)
#' 
#' }
#' @keywords internal
get_tags <- function(spacy_out, tagset = c("google", "detailed")) {
    tagset <- match.arg(tagset)
    spacyr_pyassign("timestamps", spacy_out$timestamps)
    if (spacy_out$tagger == FALSE) {
        spacyr_pyexec("tags_list = spobj.run_tagger(timestamps)")
        spacy_out$tagger <- TRUE
    }
    spacyr_pyassign("tagset", tagset)
    spacyr_pyexec("tags_list = spobj.tags(timestamps, tagset)")
    tags <- spacyr_pyget("tags_list")
    return(tags)
}


#' @rdname get-functions
#' @param attr_name name of spaCy token attributes to extract
#' @return `get_attrs` returns a list of attributes from spaCy output
#' @export
#' @keywords internal
get_attrs <- function(spacy_out, attr_name, deal_utf8 = FALSE) {
    spacyr_pyassign("timestamps", spacy_out$timestamps)
    spacyr_pyassign("attr_name", attr_name)
    spacyr_pyassign("deal_utf8", as.numeric(deal_utf8))
    spacyr_pyexec("attrs_list = spobj.attributes(timestamps, attr_name, deal_utf8)")
    attrs <- spacyr_pyget("attrs_list")
    return(attrs)
}

#' @rdname get-functions
#' @return `get_named_entities` returns a list of named entities in texts
#' @export
#' @keywords internal
get_named_entities <- function(spacy_out){
    spacyr_pyassign("timestamps", spacy_out$timestamps)
    if (spacy_out$entity == FALSE) {
        spacyr_pyexec("tags_list = spobj.run_entity(timestamps)")
        spacy_out$entity <- TRUE
    }
    spacyr_pyexec('ents_type = spobj.attributes(timestamps, "ent_type_")')
    ent_type <- spacyr_pyget("ents_type")
    spacyr_pyexec('ents_iob = spobj.attributes(timestamps, "ent_iob_")')
    ent_iob <- spacyr_pyget("ents_iob")

    iob <- sub("O", "", ent_iob)
    ent_type <- paste(ent_type, iob, sep = "_")
    ent_type[grepl("^_$", ent_type)] <- ""
    return(ent_type)
}


#' @rdname get-functions
#' @return `get_dependency` returns a data.frame of dependency relations.
#' @export
#' @keywords internal
get_dependency <- function(spacy_out) {
    # get ids of head of each token
    spacyr_pyassign("timestamps", spacy_out$timestamps)
    if (spacy_out$parser == FALSE) {
        spacyr_pyexec("tags_list = spobj.run_dependency_parser(timestamps)")
        spacy_out$parser <- TRUE
    }
    spacyr_pyexec("head_id = spobj.dep_head_id(timestamps)")
    head_id <- spacyr_pyget("head_id") + 1 # + 1 is for fixing the start index to 1

    dep_rel <- get_attrs(spacy_out, "dep_")
    return(list(head_id = head_id, dep_rel = dep_rel))
}


#' @rdname get-functions
#' @return `get_noun_phrases` returns a data.frame of noun phrases.
#' @export
#' @keywords internal
get_noun_phrases <- function(spacy_out) {
    `:=` <- start_id <- root_id <- NULL
    # get ids of head of each token
    spacyr_pyassign("timestamps", spacy_out$timestamps)
    spacyr_pyassign("docnames", spacy_out$docnames)
    command_str <- paste("noun_phrases = spobj.extract_nounphrases_dataframe(timestamps = timestamps,",
                         "docnames = docnames,",
                         "multithread = False)")
    spacyr_pyexec(command_str)
    noun_phrases <- spacyr_pyget("noun_phrases")

    doc_id <- names(noun_phrases)
    data_out <-
        data.table::rbindlist(lapply(doc_id, function(x) {
            df <- as.data.frame(noun_phrases[[x]], stringsAsFactors = FALSE)
            if (nrow(df) == 0) return(NULL)
            df$doc_id <- x
            return(df)
        }))
    if (nrow(data_out) == 0) {
        return(NULL)
    }

    data_out[, start_id := start_id + 1][, root_id := root_id + 1]
    data.table::setDF(data_out)
    data_out <- data_out[, c(6, 1:5)]
    return(data_out)
}

#' @rdname get-functions
#' @return `get_ntokens` returns a data.frame of dependency relations
#' @export
#' @keywords internal
get_ntokens <- function(spacy_out){
    spacyr_pyassign("timestamps", spacy_out$timestamps)
    spacyr_pyexec("ntok = spobj.ntokens(timestamps)")
    ntokens <- spacyr_pyget("ntok")
    names(ntokens) <- spacy_out$timestamps
    return(ntokens)
}

#' @rdname get-functions
#' @return `get_ntokens_by_sent` returns a data.frame of dependency
#'   relations, by sentence
#' @export
#' @keywords internal
get_ntokens_by_sent <- function(spacy_out){
    # get ids of head of each token
    spacyr_pyassign("timestamps", spacy_out$timestamps)
    spacyr_pyexec("ntok_by_sent = spobj.ntokens_by_sent(timestamps)")
    ntok_by_sent <- spacyr_pyget("ntok_by_sent")
    return(ntok_by_sent)
}
