#' Extract all named entities from parsed documents
#' 
#' \code{entity_extract} construct a table of all named entities from the
#' results of \code{spacy_parse}
#' @param spacy_result a \code{data.frame} from \code{\link{spacy_parse}}.
#' @param type type of named entities, either \code{named}, \code{extended}, or
#'   \code{all}.  See 
#'   \url{https://spacy.io/docs/usage/entity-recognition#entity-types} for
#'   details.
#' @return A \code{data.table} of all named entities, containing the following
#'   fields: \itemize{ \item{docname}{name of the documument a named entity is
#'   found} \item{entity}{the named entity} \item{entity_type}{type of named
#'   entities (e.g. PERSON, ORG, PERCENT, etc.)} }
#' @importFrom data.table data.table
#' @examples
#' \donttest{
#' spacy_initialize()
#' 
#' parsed_sentences <- spacy_parse(data_char_sentences, entity = TRUE)
#' named_entities <- entity_extract(parsed_sentences)
#' head(named_entities, 30)
#' }
#' @export
entity_extract <- function(spacy_result, type = c("named", "extended", "all")) {
    
    entity_type <- entity <- iob <- entity_id <- .N <- .SD <- `:=` <- sentence_id <- docname <- NULL
    
    type <- match.arg(type)
    
    if(!"entity" %in% names(spacy_result)) {
        stop("Entity Recognition is not conducted\nNeed to rerun spacy_parse() with entity = TRUE") 
    }
    spacy_result <- spacy_result[nchar(spacy_result$entity) > 0]
    spacy_result[, entity_type := sub("_.+", "", entity)]
    spacy_result[, iob := sub(".+_", "", entity)]
    spacy_result[, entity_id := cumsum(iob=="B")]
    entities <- spacy_result[, lapply(.SD, function(x) x[1]), by = entity_id, 
                             .SDcols = c("docname", "sentence_id", "entity_type")]
    entities[, entity := spacy_result[, lapply(.SD, function(x) paste(x, collapse = " ")), 
                                      by = entity_id, 
                                      .SDcols = c("tokens")]$tokens] 
    extended_list <- c("DATE", "TIME", "PERCENT", "MONEY", "QUANTITY", "ORDINAL", 
                       "CARDINAL")
    if(type == 'extended'){
        entities <- entities[entity_type %in% extended_list]
    } else if (type == 'named') {
        entities <- entities[!entity_type %in% extended_list]
    }
    return(entities[, list(docname, sentence_id, entity, entity_type)])
}


#' Consolidate named entities in parsed output
#' 
#' \code{entity_consolidate} concatinate named entity in a table of
#' results of \code{spacy_parse}
#' @param spacy_result a \code{data.frame} from \code{\link{spacy_parse}}.
#' @param type type of named entities to be consolidated, either \code{named}, \code{extended}, or
#'   \code{all}.  See 
#'   \url{https://spacy.io/docs/usage/entity-recognition#entity-types} for
#'   details.
#' @return A modified \code{data.table} of spacy outputs.
#' @importFrom data.table data.table
#' @examples
#' \donttest{
#' spacy_initialize()
#' 
#' parsed_sentences <- spacy_parse(data_char_sentences, entity = TRUE, dependency = TRUE)
#' parsed_sentences_consolidated <- entity_consolidate(parsed_sentences)
#' head(parsed_sentences_consolidated, 30)
#' }
#' @export
entity_consolidate <- function(spacy_result, type = c("named", "extended", "all")) {
    
    entity_type <- entity <- iob <- entity_id <- .N <- .SD <- `:=` <- sentence_id <- docname <- NULL
    
    type <- match.arg(type)

    if(!"entity" %in% names(spacy_result)) {
        stop("Entity Recognition is not conducted\nNeed to rerun spacy_parse() with entity = TRUE") 
    }
    spacy_result[, entity_type := sub("_.+", "", entity)]
    spacy_result[, iob := sub(".+_", "", entity)]
    extended_list <- c("DATE", "TIME", "PERCENT", "MONEY", "QUANTITY", "ORDINAL",
                       "CARDINAL")
    if(type == 'extended'){
        spacy_result[entity_type != ""  & !(entity_type %in% extended_list),
                     c("entity_type", "iob") := ""]
    } else if (type == 'named') {
        spacy_result[entity_type != ""  & (entity_type %in% extended_list),
                     c("entity_type", "iob") := ""]
    }
    spacy_result[, entity_count := ifelse(iob=="B"|iob == "", 1, 0)]
    spacy_result[, entity_id := cumsum(entity_count), by = c("docname", "sentence_id")]
    spacy_result_modified <- spacy_result[, lapply(.SD, function(x) x[1]), 
                                          by = c("docname", "sentence_id", "entity_id"), 
                                          .SDcols = setdiff(names(spacy_result), 
                                                            c("docname", "sentence_id", "entity_id"))]
    
    spacy_result_modified[
        , tokens := spacy_result[, lapply(.SD, function(x) paste(x, collapse = "_")), 
                                 by = c("docname", "sentence_id", "entity_id"), 
                                 .SDcols = "tokens"]$tokens] 
    if("lemma" %in% colnames(spacy_result)) {
        spacy_result_modified[
            , lemma := spacy_result[, lapply(.SD, function(x) paste(x, collapse = "_")), 
                                    by = c("docname", "sentence_id", "entity_id"), 
                                    .SDcols = "lemma"]$lemma] 
        
    }
    if("pos" %in% names(spacy_result_modified)){
        spacy_result_modified[nchar(entity_type) > 0, pos := "ENTITY"]
    }
    if("tag" %in% names(spacy_result_modified)){
        spacy_result_modified[nchar(entity_type) > 0, tag := "ENTITY"]
    }
    spacy_result_modified[, new_token_id := entity_id]
    
    if("dep_rel" %in% names(spacy_result)) {
        message("Note: head_token_id, dep_rel for named entities will be converted to NA")
        dt_id_match <- spacy_result[, .(docname, sentence_id, token_id, entity_id)]
        data.table::setnames(dt_id_match, "token_id", "head_token_id")
        data.table::setnames(dt_id_match, "entity_id", "new_head_token_id")
        #data.table::set2keyv(dt_id_match, "head_token_id")
        spacy_result_modified[, serialn := seq(nrow(spacy_result_modified))]
        #data.table::set2keyv(spacy_result_modified, "head_token_id")
        browser()
        spacy_result_modified <- merge(spacy_result_modified, dt_id_match, 
                                       by = c("docname", "sentence_id", "head_token_id"), all.x = TRUE)
        spacy_result_modified <- spacy_result_modified[order(serialn)]
        spacy_result_modified[, head_token_id := NULL]
        data.table::setnames(spacy_result_modified, "new_head_token_id", "head_token_id")
        spacy_result_modified[nchar(entity_type) > 0, head_token_id := NA]
    }
    if("dep_rel" %in% names(spacy_result_modified)){
        spacy_result_modified[nchar(entity_type) > 0, dep_rel := NA]
    }
    
    spacy_result_modified[, token_id := NULL]
    data.table::setnames(spacy_result_modified, "new_token_id", "token_id")
    keep_cols <- intersect(c("docname", "sentence_id", "token_id", "tokens", 
                             "lemma", "pos", "tag", "head_token_id", "dep_rel", "entity_type"),
                           names(spacy_result_modified))
    return(spacy_result_modified[, keep_cols, with = FALSE])
}
