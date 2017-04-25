#' Get all named entities in parsed documents
#' 
#' \code{get_all_named_entities} construct a table of all named entities from
#' the results of \code{spacy_parse}
#' @param spacy_result a \code{data.frame} from \code{\link{spacy_parse}}.
#' @return A \code{data.table} of all named entities, containing the following fields: 
#' \itemize{
#'   \item{docname}{name of the documument a named entity is found} 
#'   \item{entity}{the named entity}
#'   \item{entity_type}{type of named entities (e.g. PERSON, ORG, PERCENT, etc.)} 
#'   }
#' @importFrom data.table data.table
#' @examples
#' \donttest{
#' spacy_initialize()
#' 
#' parsed_sentences <- spacy_parse(data_char_sentences, full_parse = TRUE, named_entity = TRUE)
#' named_entities <- get_all_named_entities(parsed_sentences)
#' head(named_entities, 30)
#' }
#' @export
get_all_named_entities <- function(spacy_result) {
    
    entity_type <- named_entity <- iob <- entity_id <- .N <- .SD <- `:=` <- docname <- NULL
    
    if(!"named_entity" %in% names(spacy_result)) {
        stop("Named Entity Recognition is not conducted\nNeed to rerun spacy_parse() with named_entity = TRUE") 
    }
    spacy_result <- spacy_result[nchar(spacy_result$named_entity) > 0]
    spacy_result[, entity_type := sub("_.+", "", named_entity)]
    spacy_result[, iob := sub(".+_", "", named_entity)]
    spacy_result[, entity_id := cumsum(iob=="B")]
    entities <- spacy_result[, lapply(.SD, function(x) x[1]), by = entity_id, 
                   .SDcols = c("docname", "token_id", "entity_type")]
    entities[, entity := spacy_result[, lapply(.SD, function(x) paste(x, collapse = " ")), 
                            by = entity_id, 
                            .SDcols = c("tokens")]$tokens] 
    as.data.frame(entities[, list(docname, entity, entity_type)])
}


