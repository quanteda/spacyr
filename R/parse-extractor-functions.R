# The result of process_document(): a handle on documents parsed by spaCy,
# which the get_*() functions read. It holds the Python object that keeps the
# parsed documents (spobj), so that they are not affected by later calls to
# spacyr's functions, and are released when the handle is garbage collected.
# The tagger, entity and parser fields are kept for compatibility: documents
# are always parsed by the whole pipeline.
spacy_out <- setRefClass(
    Class = "spacy_out",
    fields = list(
        timestamps = "character",
        docnames = "character",
        tagger = "logical",
        entity = "logical",
        parser = "logical",
        spobj = "ANY"
    ),
    methods = list(
        initialize = function(timestamps = NULL, docnames = NULL, spobj = NULL) {
            tagger <<- entity <<- parser <<- TRUE
            timestamps <<- timestamps
            docnames <<- docnames
            spobj <<- spobj
        }
    )
)

# the Python object holding the documents of a spacy_out handle
handle_spobj <- function(spacy_out) {
    if (!methods::is(spacy_out, "spacy_out"))
        stop("`spacy_out` must be the result of process_document()", call. = FALSE)
    if (is.null(spacy_out$spobj))
        stop("`spacy_out` holds no parsed documents; run process_document() again",
             call. = FALSE)
    spacy_out$spobj
}

# Warn that a get_*() function is deprecated, naming its replacement.
deprecate_get <- function(fun, instead) {
    deprecation_warning(paste0(
        "`", fun, "()` is deprecated and will be removed in a future version of ",
        "spacyr. Use ", instead, " instead."))
}


#' Get results from documents processed by spaCy (deprecated)
#'
#' @description
#' These functions are deprecated, and will be removed in a future version of
#' \pkg{spacyr}. They give a warning on every call. [spacy_parse()] returns all
#' of their results in one data.frame, one row per token:
#' * `get_tokens()`: the `token` column;
#' * `get_tags()`: the `pos` column, or `tag` with `spacy_parse(x, tag = TRUE)`;
#' * `get_attrs()`: `spacy_parse(x, additional_attributes = attr_name)`;
#' * `get_named_entities()`: the `entity` column;
#' * `get_dependency()`: the `head_token_id` and `dep_rel` columns of
#'   `spacy_parse(x, dependency = TRUE)`;
#' * `get_ntokens()` and `get_ntokens_by_sent()`: count the rows by `doc_id`,
#'   and by `doc_id` and `sentence_id`;
#' * `get_noun_phrases()`: [spacy_extract_nounphrases()].
#'
#' Each reads the documents held by the result of [process_document()],
#' which are not affected by later calls to other \pkg{spacyr} functions.
#' @param spacy_out the result of [process_document()]
#' @return `get_tokens()` returns a character vector of the tokens of all the
#'   documents.
#' @export
#' @name get-functions
#' @keywords internal
get_tokens <- function(spacy_out) {
    deprecate_get("get_tokens", "the `token` column of `spacy_parse()`")
    handle_spobj(spacy_out)$tokens(spacy_out$timestamps)
}

#' @rdname get-functions
#' @return `get_tags()` returns a character vector of the part-of-speech tags
#'   of all the tokens.
#' @param tagset character label for the tagset to use, either `"google"`
#'   or `"detailed"` to use the simplified Google tagset, or the more detailed
#'   scheme from the Penn Treebank (or the German Text Archive in case of German language model).
#' @export
#' @keywords internal
get_tags <- function(spacy_out, tagset = c("google", "detailed")) {
    deprecate_get("get_tags", "the `pos` or `tag` column of `spacy_parse()`")
    tagset <- match.arg(tagset)
    handle_spobj(spacy_out)$tags(spacy_out$timestamps, tagset)
}


#' @rdname get-functions
#' @param attr_name name of spaCy token attributes to extract
#' @param deal_utf8 not used; kept for compatibility
#' @return `get_attrs()` returns the values of the attribute for all the
#'   tokens.
#' @export
#' @keywords internal
get_attrs <- function(spacy_out, attr_name, deal_utf8 = FALSE) {
    deprecate_get("get_attrs", "the `additional_attributes` argument of `spacy_parse()`")
    handle_spobj(spacy_out)$attributes(spacy_out$timestamps, attr_name)
}

#' @rdname get-functions
#' @return `get_named_entities()` returns a character vector of the entity
#'   tags of all the tokens.
#' @export
#' @keywords internal
get_named_entities <- function(spacy_out){
    deprecate_get("get_named_entities", "the `entity` column of `spacy_parse()`")
    spobj <- handle_spobj(spacy_out)
    ent_type <- spobj$attributes(spacy_out$timestamps, "ent_type_")
    ent_iob <- spobj$attributes(spacy_out$timestamps, "ent_iob_")

    iob <- sub("O", "", ent_iob)
    ent_type <- paste(ent_type, iob, sep = "_")
    ent_type[grepl("^_$", ent_type)] <- ""
    return(ent_type)
}


#' @rdname get-functions
#' @return `get_dependency()` returns a list of the head token IDs
#'   (`head_id`) and the dependency relations (`dep_rel`) of all the tokens.
#' @export
#' @keywords internal
get_dependency <- function(spacy_out) {
    deprecate_get("get_dependency", "`spacy_parse(x, dependency = TRUE)`")
    spobj <- handle_spobj(spacy_out)
    head_id <- spobj$dep_head_id(spacy_out$timestamps) + 1 # + 1 is for fixing the start index to 1
    dep_rel <- spobj$attributes(spacy_out$timestamps, "dep_")
    return(list(head_id = head_id, dep_rel = dep_rel))
}


#' @rdname get-functions
#' @return `get_noun_phrases()` returns a data.frame of noun phrases.
#' @export
#' @keywords internal
get_noun_phrases <- function(spacy_out) {
    deprecate_get("get_noun_phrases", "`spacy_extract_nounphrases()`")
    `:=` <- start_id <- root_id <- NULL
    noun_phrases <- handle_spobj(spacy_out)$extract_nounphrases_dataframe(
        timestamps = spacy_out$timestamps,
        docnames = spacy_out$docnames)

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
#' @return `get_ntokens()` returns the number of tokens in each document.
#' @export
#' @keywords internal
get_ntokens <- function(spacy_out){
    deprecate_get("get_ntokens", "the number of rows of `spacy_parse()` for each `doc_id`")
    ntokens <- handle_spobj(spacy_out)$ntokens(spacy_out$timestamps)
    names(ntokens) <- spacy_out$timestamps
    return(ntokens)
}

#' @rdname get-functions
#' @return `get_ntokens_by_sent()` returns a list of the number of tokens in
#'   each sentence, for each document.
#' @export
#' @keywords internal
get_ntokens_by_sent <- function(spacy_out){
    deprecate_get("get_ntokens_by_sent",
                  "the number of rows of `spacy_parse()` for each `doc_id` and `sentence_id`")
    handle_spobj(spacy_out)$ntokens_by_sent(spacy_out$timestamps)
}
