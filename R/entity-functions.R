#' Extract or consolidate entities from parsed documents
#' 
#' From an object parsed by [spacy_parse()], extract the entities as a
#' separate object, or convert the multi-word entities into single "token"
#' consisting of the concatenated elements of the multi-word entities.
#' @param x output from [spacy_parse()].
#' @param type type of named entities, either `named`, `extended`, or 
#'   `all`.  See 
#'   <https://spacy.io/docs/usage/entity-recognition#entity-types> for 
#'   details.
#' @returns `entity_extract()` returns a data.frame of all named
#'   entities, containing the following fields: 
#'   * `doc_id` name of the document containing the entity
#'   * `sentence_id` the sentence ID containing the entity, within the document
#'   * `entity` the named entity
#'   * `entity_type` the type of named entities (e.g. PERSON, ORG, PERCENT, etc.)
#' @importFrom data.table data.table as.data.table
#' @examples
#' \dontrun{
#' spacy_initialize()
#' 
#' # entity extraction
#' txt <- "Mr. Smith of moved to San Francisco in December."
#' parsed <- spacy_parse(txt, entity = TRUE)
#' entity_extract(parsed)
#' entity_extract(parsed, type = "all")
#' }
#' @export
entity_extract <- function(x, type = c("named", "extended", "all"), concatenator = "_") {
    UseMethod("entity_extract")
}
    
#' @export
entity_extract.spacyr_parsed <- function(x, type = c("named", "extended", "all"),
                                         concatenator = "_") {

    spacy_result <- data.table::as.data.table(x)

    entity_type <- entity <- iob <- entity_id <- .SD <- `:=` <- sentence_id <- doc_id <- NULL

    type <- match.arg(type)

    if (!"entity" %in% names(spacy_result)) {
        stop("no entities in parsed object: rerun spacy_parse() with entity = TRUE")
    }
    spacy_result <- spacy_result[nchar(spacy_result$entity) > 0]
    spacy_result[, entity_type := sub("_.+", "", entity)]
    spacy_result[, iob := sub(".+_", "", entity)]
    spacy_result[, entity_id := cumsum(iob == "B")]
    entities <- spacy_result[, lapply(.SD, function(x) x[1]), by = entity_id,
                             .SDcols = c("doc_id", "sentence_id", "entity_type")]
    entities[, entity := spacy_result[, lapply(.SD, function(x) paste(x, collapse = concatenator)),
                                      by = entity_id,
                                      .SDcols = c("token")]$token]
    extended_list <- c("DATE", "TIME", "PERCENT", "MONEY", "QUANTITY", "ORDINAL",
                       "CARDINAL")
    if (type == "extended"){
        entities <- entities[entity_type %in% extended_list]
    } else if (type == "named") {
        entities <- entities[!entity_type %in% extended_list]
    }

    as.data.frame(entities[, list(doc_id, sentence_id, entity, entity_type)])
}


#' @rdname entity_extract
#' @param concatenator the character(s) used to join the elements of multi-word
#'   named entities
#' @return `entity_consolidate` returns a modified `data.frame` of
#'   parsed results, where the named entities have been combined into a single
#'   "token".  Currently, dependency parsing is removed when this consolidation
#'   occurs.
#' @importFrom data.table data.table
#' @examples
#' \dontrun{
#' # consolidating multi-word entities 
#' txt <- "The House of Representatives voted to suspend aid to South Dakota."
#' parsed <- spacy_parse(txt, entity = TRUE)
#' entity_consolidate(parsed)
#' }
#' @export
entity_consolidate <- function(x, concatenator = "_") {
    UseMethod("entity_consolidate")
}
    
#' @export
entity_consolidate.spacyr_parsed <- function(x, concatenator = "_") {

    spacy_result <- data.table::as.data.table(x)
    entity <- entity_type <- entity_count <- iob <- entity_id <- .N <- .SD <-
        `:=` <- token <- lemma <- pos <- tag <- new_token_id <- token_id <-
        sentence_id <- doc_id <- NULL

    if (!"entity" %in% names(spacy_result)) {
        stop("no entities in parsed object: rerun spacy_parse() with entity = TRUE")
    }
    spacy_result[, entity_type := sub("_.+", "", entity)]
    spacy_result[, iob := sub(".+_", "", entity)]
    extended_list <- c("DATE", "TIME", "PERCENT", "MONEY", "QUANTITY",
                       "ORDINAL", "CARDINAL")
    # if (type == 'extended'){
    #     spacy_result[entity_type != ""  & !(entity_type %in% extended_list),
    #                  c("entity_type", "iob") := ""]
    # } else if (type == 'named') {
    #     spacy_result[entity_type != ""  & (entity_type %in% extended_list),
    #                  c("entity_type", "iob") := ""]
    # }
    spacy_result[, entity_count := ifelse(iob == "B" | iob == "", 1, 0)]
    spacy_result[, entity_id := cumsum(entity_count), by = c("doc_id", "sentence_id")]
    spacy_result_modified <- spacy_result[, lapply(.SD, function(x) x[1]),
                                          by = c("doc_id", "sentence_id", "entity_id"),
                                          .SDcols = setdiff(names(spacy_result),
                                                            c("doc_id", "sentence_id", "entity_id"))]

    spacy_result_modified[
        , token := spacy_result[, lapply(.SD, function(x) paste(x, collapse = concatenator)),
                                 by = c("doc_id", "sentence_id", "entity_id"),
                                 .SDcols = "token"]$token]

    if ("lemma" %in% colnames(spacy_result)) {
        spacy_result_modified[
            , lemma := spacy_result[, lapply(.SD, function(x) paste(x, collapse = "_")),
                                    by = c("doc_id", "sentence_id", "entity_id"),
                                    .SDcols = "lemma"]$lemma]
    }
    if ("pos" %in% names(spacy_result_modified)){
        spacy_result_modified[nchar(entity_type) > 0, pos := "ENTITY"]
    }
    if ("tag" %in% names(spacy_result_modified)){
        spacy_result_modified[nchar(entity_type) > 0, tag := "ENTITY"]
    }
    spacy_result_modified[, new_token_id := entity_id]

    # for now, just obliterate dependency parsing for consolidated NEs
    if ("dep_rel" %in% names(spacy_result_modified)){
        message("Note: removing head_token_id, dep_rel for named entities")
        spacy_result_modified[, c("dep_rel", "head_token_id") := NULL]
    }

    spacy_result_modified[, token_id := NULL]
    data.table::setnames(spacy_result_modified, "new_token_id", "token_id")
    keep_cols <- intersect(c("doc_id", "sentence_id", "token_id", "token",
                             "lemma", "pos", "tag", "head_token_id", "dep_rel", "entity_type"),
                           names(spacy_result_modified))

    ret <- as.data.frame(spacy_result_modified[, keep_cols, with = FALSE])
    class(ret) <- c("spacyr_parsed", class(ret))
    ret
}
