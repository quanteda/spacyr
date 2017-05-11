#' Extract all named entities from parsed documents
#' 
#' \code{entity_extract} construct a table of all named entities from
#' the results of \code{spacy_parse}
#' @param spacy_result a \code{data.frame} from \code{\link{spacy_parse}}.
#' @param type type of named entities, either \code{named}, \code{extended}, or \code{all} (https://spacy.io/docs/usage/entity-recognition#entity-types)
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
#' parsed_sentences <- spacy_parse(data_char_sentences, entity = TRUE)
#' named_entities <- entity_extract(parsed_sentences)
#' head(named_entities, 30)
#' }
#' @export
entity_extract <- function(spacy_result, type = "all") {
    
    entity_type <- entity <- iob <- entity_id <- .N <- .SD <- `:=` <- docname <- NULL
    
    match.arg(type, c("named", "extended", "all"))

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


