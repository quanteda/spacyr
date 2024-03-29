#' Extract named entities from texts using spaCy
#' 
#' This function extracts named entities from texts, based on the entity tag
#' `ent` attributes of documents objects parsed by spaCy (see
#' <https://spacy.io/usage/linguistic-features#section-named-entities>).
#' 
#' @param x a character object or a TIF-compliant
#'   corpus data.frame (see <https://github.com/ropenscilabs/tif>)
#' @inheritParams spacy_parse
#' @param output type of returned object, either `"list"` or
#'   `"data.frame"`.
#' @param type type of named entities, either `named`, `extended`, or 
#'   `all`.  See 
#'   <https://spacy.io/docs/usage/entity-recognition#entity-types> for 
#'   details.
#' @param ... unused
#' @details When the option `output = "data.frame"` is selected, the
#'   function returns a `data.frame` with the following fields.
#'   \describe{\item{`text`}{contents of entity}
#'   \item{`entity_type`}{type of entity (e.g. `ORG` for
#'   organizations)} \item{`start_id`}{serial number ID of starting token.
#'   This number corresponds with the number of `data.frame` returned from
#'   `spacy_tokenize(x)` with default options.} \item{`length`}{number
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
                                 multithread = TRUE, ...) {
    UseMethod("spacy_extract_entity")
}


#' @importFrom data.table data.table
#' @export
spacy_extract_entity.character <- function(x,
                                           output = c("data.frame", "list"),
                                           type = c("all", "named", "extended"),
                                           multithread = TRUE, ...) {
    type <- match.arg(type)

    `ent_type` <- `start_id` <- `:=` <- NULL

    output <- match.arg(output)

    if (!is.null(names(x))) {
        docnames <- names(x)
    } else {
        docnames <- paste0("text", 1:length(x))
    }
    if (length(x) == 1) {
        multithread <- FALSE
    }

    if (all(!duplicated(docnames)) == FALSE) {
        stop("Docnames are duplicated.")
    } else if (all(nchar(docnames) > 0L) == FALSE) {
        stop("Some docnames are missing.")
    }

    if (is.null(options()$spacy_initialized)) spacy_initialize()
    spacyr_pyexec("try:\n del spobj\nexcept NameError:\n 1")
    spacyr_pyexec("texts = []")

    if (spacyr_pyget("py_version") != 3) {
        message("multithreading for python 2 is not supported by spacy_tokenize()")
        multithread <- FALSE
    }

    x <- gsub("\\\\n", "\\\n", x) # replace two quotes \\n with \n
    x <- gsub("\\\\t", "\\\t", x) # replace two quotes \\t with \t
    x <- gsub("\\\\", "", x) # delete unnecessary backslashes
    x <- unname(x)

    ## send documents to python
    spacyr_pyassign("texts", x)
    spacyr_pyassign("docnames", docnames)
    spacyr_pyassign("multithread", multithread)
    spacyr_pyassign("ent_type_category", type)

    ## run noun phrase extraction
    spacyr_pyexec("spobj = spacyr()")
    if (identical(output, "list")) {
        command_str <- paste("entities = spobj.extract_entity_list(texts = texts,",
                             "docnames = docnames,",
                             "multithread = multithread,
                             ent_type_category = ent_type_category)")
        spacyr_pyexec(command_str)
        return(spacyr_pyget("entities"))
    } else {
        command_str <- paste("entities = spobj.extract_entity_dataframe(texts = texts,",
                             "docnames = docnames,",
                             "multithread = multithread)")
        spacyr_pyexec(command_str)
        entities <- spacyr_pyget("entities")

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
        data_out <- data_out[, c(5, 1:4)]
        return(data_out)
    }
}


#' @method spacy_extract_entity data.frame
#' @export
spacy_extract_entity.data.frame <- function(x, ...) {

    # insert compliance check here - replace with tif package
    if (!all(c("doc_id", "text") %in% names(x)))
        stop("input data.frame does not conform to the TIF standard")

    txt <- x$text
    names(txt) <- x$doc_id
    spacy_extract_entity(txt, ...)
}
