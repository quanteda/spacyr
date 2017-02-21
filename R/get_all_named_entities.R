#' Get all named entities in parsed documents
#' 
#' \code{get_all_named_entities} construct a list of all named entities from
#' the results of \code{spacy_parse}
#' @param spacy_result A data.table object from \code{spacy_parse()}
#' @return A data.table of all named entities. The data.table contains following fields: 
#' \item{ent_id}{serial numbers of named entity} 
#'   \item{docname}{name of the documument a named entity is found} 
#'   \item{id}{index of the starting word of a named entity with in a document.
#'   The index starts from 0} \item{entity_type}{type of named entities (e.g. ORG, PERCENT)} 
#'   \item{entity}{content of named entity}
#' @import data.table
#' @examples
#' \donttest{
#' spacy_initialize()
#' data(data_sentences)
#' 
#' parsed_sentences <- spacy_parse(data_sentences, full_parse = TRUE, named_entity = TRUE, 
#' dependency = TRUE)
#' named_entities <- get_all_named_entities(parsed_sentences)
#' dim(named_entities)
#' head(named_entities, 30)
#' }
#' @export
get_all_named_entities <- function(spacy_result) {
    
    entity_type <- named_entity <- iob <- ent_id <- NULL
    
    if(!"named_entity" %in% names(spacy_result)) {
        stop("Named Entity Recognition is not conducted
Need to rerun spacy_parse() with named_entity = TRUE") 
    }
    spacy_result <- spacy_result[nchar(spacy_result$named_entity) > 0]
    spacy_result[, entity_type := sub("_.+", "", named_entity)]
    spacy_result[, iob := sub(".+_", "", named_entity)]
    spacy_result[, ent_id := cumsum(iob=="B")]
    entities <- spacy_result[, lapply(.SD, function(x) x[1]), by = ent_id, 
                   .SDcols = c("docname", "id", "entity_type")]
    entities[, entity := spacy_result[, lapply(.SD, function(x) paste(x, collapse = " ")), 
                            by = ent_id, 
                            .SDcols = c("tokens")]$tokens] 
    return(entities)
}


