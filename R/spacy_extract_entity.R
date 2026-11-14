#' Extract named entities from texts using spaCy
#' 
#' This function extracts named entities from texts, based on the entity tag
#' `ent` attributes of documents objects parsed by spaCy (see
#' <https://spacy.io/usage/linguistic-features#named-entities>).
#' 
#' @param x a character object or a TIF-compliant
#'   corpus data.frame (see <https://github.com/ropenscilabs/tif>)
#' @inheritParams spacy_parse
#' @param output type of returned object, either `"list"` or
#'   `"data.frame"`.
#' @param type type of named entities, either `named`, `extended`, or
#'   `all`. Extended entities are those of types `DATE`, `TIME`, `PERCENT`,
#'   `MONEY`, `QUANTITY`, `ORDINAL` and `CARDINAL`, and named entities are those
#'   of all other types. The entity types are those of the language model;
#'   see its "Label scheme" on <https://spacy.io/models>.
#' @param offsets logical; if `TRUE`, also return the position of each
#'   entity in its text as it was given in `x`, in the columns `start` and
#'   `end`: the positions of the entity's first and last characters, counted
#'   from 1 as in [spacy_parse()], so that `substring(text, start, end)` gives
#'   the entities of a text. This needs `output = "data.frame"`.
#' @param ... unused
#' @details When the option `output = "data.frame"` is selected, the
#'   function returns a `data.frame` with the following fields, and with
#'   `start` and `end` after them when `offsets = TRUE`.
#'   \describe{\item{`text`}{contents of entity}
#'   \item{`ent_type`}{type of entity (e.g. `ORG` for
#'   organizations)} \item{`start_id`}{serial number ID of starting token:
#'   its position in the document, starting at 1 and counting every token
#'   of spaCy's, as the rows of `spacy_parse(x)` do. Whitespace tokens are
#'   counted, so where a document has them this is not the position among
#'   the tokens of `spacy_tokenize(x)` with default options, which leaves
#'   them out.} \item{`length`}{number
#'   of words (tokens) included in a named entity (e.g. for an entity, "New York
#'   Stock Exchange"", `length = 4`)}}
#' 
#' @return either a `list` or `data.frame` of tokens
#' @export
#' @examples
#' \dontrun{
#' spacy_initialize()
#' 
#' txt <- c(doc1 = "The Supreme Court is located in Washington D.C.",
#'          doc2 = "Paul earned a postgraduate degree from MIT.")
#' spacy_extract_entity(txt)
#' spacy_extract_entity(txt, output = "list")
#' }
spacy_extract_entity <- function(x, output = c("data.frame", "list"),
                                 type = c("all", "named", "extended"),
                                 multithread, n_process = 1L, batch_size = NULL,
                                 offsets = FALSE, ...) {
    UseMethod("spacy_extract_entity")
}


#' @importFrom data.table data.table
#' @export
spacy_extract_entity.character <- function(x,
                                           output = c("data.frame", "list"),
                                           type = c("all", "named", "extended"),
                                           multithread, n_process = 1L, batch_size = NULL,
                                           offsets = FALSE, ...) {
    # checked before spaCy is initialized
    check_multithread(multithread, "spacy_extract_entity")
    args <- pipe_args(n_process, batch_size)
    type <- match.arg(type)

    `ent_type` <- `start_id` <- `:=` <- NULL

    output <- match.arg(output)
    check_offsets(offsets)
    if (offsets && identical(output, "list"))
        stop("offsets = TRUE needs output = \"data.frame\"", call. = FALSE)

    input <- spacy_input(x)
    x <- input$x
    docnames <- input$docnames

    ## run entity extraction
    spobj <- new_spobj()
    if (identical(output, "list")) {
        entities <- spobj$extract_entity_list(texts = x, docnames = docnames,
                                              ent_type_category = type,
            batch_size = args$batch_size, n_process = args$n_process)
        warn_skipped(spobj)
        return(entities)
    } else {
        entities <- spobj$extract_entity_dataframe(texts = x, docnames = docnames,
            batch_size = args$batch_size, n_process = args$n_process,
            offsets = offsets)
        warn_skipped(spobj)

        doc_id <- names(entities)
        data_out <-
            data.table::rbindlist(lapply(doc_id, function(x) {
                df <- as.data.frame(entities[[x]], stringsAsFactors = FALSE)
                if (nrow(df) == 0) return(NULL)
                df$doc_id <- x
                return(df)
            }))
        if (nrow(data_out) == 0) {
            message("No entity found in documents")
            return(NULL)
        }
        data_out[, start_id := start_id + 1]
        extended_list <- c("DATE", "TIME", "PERCENT", "MONEY", "QUANTITY", "ORDINAL",
                           "CARDINAL")
        if (type == "extended"){
            data_out <- data_out[ent_type %in% extended_list]
        } else if (type == "named") {
            data_out <- data_out[!ent_type %in% extended_list]
        }

        data.table::setDF(data_out)
        data_out <- data_out[, c("doc_id", setdiff(names(data_out), "doc_id"))]
        return(data_out)
    }
}


#' @method spacy_extract_entity data.frame
#' @export
spacy_extract_entity.data.frame <- function(x, ...) {
    spacy_extract_entity(tif_texts(x), ...)
}
