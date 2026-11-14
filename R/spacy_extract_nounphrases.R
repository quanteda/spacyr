#' Extract noun phrases from texts using spaCy
#' 
#' This function extracts noun phrases from documents, based on the
#' `noun_chunks` attributes of documents objects parsed by spaCy (see
#' <https://spacy.io/usage/linguistic-features#noun-chunks>).
#' 
#' @param x a character object or a TIF-compliant corpus data.frame (see
#'   <https://github.com/ropenscilabs/tif>)
#' @inheritParams spacy_parse
#' @param output type of returned object, either `"data.frame"` or
#'   `"list"`
#' @param ... unused
#' @param offsets logical; if `TRUE`, also return the position of each noun
#'   phrase in its text as it was given in `x`, in the columns `start` and
#'   `end`: the positions of the noun phrase's first and last characters,
#'   counted from 1 as in [spacy_parse()], so that
#'   `substring(text, start, end)` gives the noun phrases of a text. This
#'   needs `output = "data.frame"`. It comes after `...`, so it has to be
#'   given by its full name.
#' @details When the option `output = "data.frame"` is selected, the
#'   function returns a `data.frame` with the following fields, and with
#'   `start` and `end` after them when `offsets = TRUE`.
#' \describe{\item{`text`}{contents of noun-phrase}
#' \item{`root_text`}{contents of root token}
#' \item{`start_id`}{serial number ID of starting token: its position in
#' the document, starting at 1 and counting every token of spaCy's, as the
#' rows of `spacy_parse(x)` do. Whitespace tokens are counted, so where a
#' document has them this is not the position among the tokens of
#' `spacy_tokenize(x)` with default options, which leaves them out.}
#' \item{`root_id`}{serial number ID of root token}
#' \item{`length`}{number of words (tokens) included in a noun-phrase (e.g.
#' for a noun-phrase, "individual car owners", `length = 3`)}}
#' 
#' @return either a `list` or `data.frame` of tokens
#' @export
#' @examples
#' \dontrun{
#' spacy_initialize()
#' 
#' txt <- c(doc1 = "Natural language processing is a branch of computer science.",
#'          doc2 = "Paul earned a postgraduate degree from MIT.")
#' spacy_extract_nounphrases(txt)
#' spacy_extract_nounphrases(txt, output = "list")
#' }
spacy_extract_nounphrases <- function(x, output = c("data.frame", "list"),
                                      multithread, n_process = 1L, batch_size = NULL, ...,
                                      offsets = FALSE) {
    UseMethod("spacy_extract_nounphrases")
}


#' @importFrom data.table data.table
#' @export
spacy_extract_nounphrases.character <- function(x,
                                                output = c("data.frame", "list"),
                                                multithread, n_process = 1L, batch_size = NULL, ...,
                                                offsets = FALSE) {
    # checked before spaCy is initialized
    check_multithread(multithread, "spacy_extract_nounphrases")
    args <- pipe_args(n_process, batch_size)

    `root_id` <- `start_id` <- `:=` <- NULL

    output <- match.arg(output)
    check_offsets(offsets)
    if (offsets && identical(output, "list"))
        stop("offsets = TRUE needs output = \"data.frame\"", call. = FALSE)

    input <- spacy_input(x)
    x <- input$x
    docnames <- input$docnames

    ## run noun phrase extraction
    spobj <- new_spobj()
    if (identical(output, "list")) {
        noun_phrases <- spobj$extract_nounphrases_list(texts = x, docnames = docnames,
            batch_size = args$batch_size, n_process = args$n_process)
        warn_skipped(spobj)
        return(noun_phrases)
    } else {
        noun_phrases <- spobj$extract_nounphrases_dataframe(texts = x, docnames = docnames,
            batch_size = args$batch_size, n_process = args$n_process,
            offsets = offsets)
        warn_skipped(spobj)

        doc_id <- names(noun_phrases)
        data_out <-
            data.table::rbindlist(lapply(doc_id, function(x) {
                df <- as.data.frame(noun_phrases[[x]], stringsAsFactors = FALSE)
                if (nrow(df) == 0) return(NULL)
                df$doc_id <- x
                return(df)
            }))
        if (nrow(data_out) == 0) {
            message("No noun phrase found in documents")
            return(NULL)
        }

        data_out[, start_id := start_id + 1][, root_id := root_id + 1]
        data.table::setDF(data_out)
        data_out <- data_out[, c("doc_id", setdiff(names(data_out), "doc_id"))]
        return(data_out)
    }
}


#' @export
spacy_extract_nounphrases.data.frame <- function(x, ...) {
    spacy_extract_nounphrases(tif_texts(x), ...)
}
