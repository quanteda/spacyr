#' Visualize the named entities of parsed documents
#'
#' Shows documents parsed by [spacy_parse()] with their named entities
#' highlighted and labelled, as HTML made by displaCy, spaCy's visualizer
#' (see <https://spacy.io/usage/visualizers#ent>).
#'
#' @param x the output of [spacy_parse()], best with `offsets = TRUE` (see
#'   Details), or of [entity_consolidate()]
#' @param labels the entity labels to highlight, as a character vector
#'   such as `c("PERSON", "ORG")`. The default, `NULL`, highlights
#'   the entities of every label, and `character(0)` highlights none. The
#'   labels are those of the language model (see its "Label scheme" on
#'   <https://spacy.io/models>) and of any entity rules, and are matched
#'   regardless of case.
#' @param colors a named character vector of colours for labels, such as
#'   `c(ORG = "#7aecec", PERSON = "lightblue")`, whose names are labels and
#'   whose values are colours in any form that CSS has. displaCy has colours
#'   of its own for the labels of spaCy's models, and shows other labels in
#'   grey.
#' @param view logical; if `TRUE`, also open the result in the browser, or
#'   in the viewer that the `browser` option is set to (see
#'   [utils::browseURL()]).
#' @details The entities are those of the `entity` column of the parse, so
#'   it needs `entity = TRUE`, the default of [spacy_parse()]. They include
#'   any from rules given to [spacy_initialize()] as `entity_patterns`. The
#'   documents are not processed again.
#'
#'   A parse does not keep the texts, so the text shown is made from the
#'   tokens. With `spacy_parse(x, offsets = TRUE)` the tokens are spaced as
#'   they were in the text. Otherwise there is a space between every two
#'   tokens, also before punctuation and within words that spaCy splits,
#'   such as `did n't`; the entities are the same, and a message, given
#'   once in a session, says how to get the spacing of the text. In the
#'   output of [entity_consolidate()] each entity is one token, shown with
#'   the `concatenator` that joined its parts.
#'
#'   The documents are shown in the order of the parse, each in a block of
#'   its own. A document without entities, or without any of the labels in
#'   `labels`, is shown as plain text. The HTML is made by spaCy, which is
#'   initialized if it has not been.
#' @return a character vector of length one, with the HTML for all the
#'   documents. It is a fragment and not a whole page, so that it can be
#'   put into a page, an R Markdown document or a Shiny app. It is returned
#'   invisibly when `view = TRUE`, and is `""` when there are no documents.
#' @seealso [spacy_parse()]; [entity_extract()] and [spacy_extract_entity()]
#'   for the entities as data.
#' @export
#' @examples
#' \dontrun{
#' spacy_initialize()
#'
#' txt <- head(data_char_sentences, 8)
#' parsed <- spacy_parse(txt, offsets = TRUE)
#'
#' # save as HTML
#' html <- entity_visualize(parsed)
#'
#' # open in the browser
#' entity_visualize(parsed, view = TRUE)
#'
#' # only some labels, and a colour of one's own
#' entity_visualize(parsed, labels = c("ORG", "GPE"), colors = c(GPE = "gold"),
#'                  view = TRUE)
#' }
entity_visualize <- function(x, labels = NULL, colors = NULL, view = FALSE) {
    UseMethod("entity_visualize")
}

#' @export
entity_visualize.default <- function(x, labels = NULL, colors = NULL, view = FALSE) {
    stop("x must be the output of spacy_parse(): for texts, use ",
         "entity_visualize(spacy_parse(x, offsets = TRUE))", call. = FALSE)
}

#' @export
entity_visualize.spacyr_parsed <- function(x, labels = NULL, colors = NULL,
                                           view = FALSE) {
    # checked before spaCy is initialized
    check_visualize_args(labels, colors, view)
    docs <- parsed_entity_docs(x)
    if (nrow(x) && !all(c("start", "end") %in% names(x)) &&
        !isTRUE(spacyr_env$told_offsets)) {
        message("The parse does not have the positions of its tokens, so they ",
                "are shown with a space between every two. ",
                "For the spacing of the text, use spacy_parse(x, offsets = TRUE).")
        spacyr_env$told_offsets <- TRUE
    }

    if (is.null(options()$spacy_initialized)) spacy_initialize()
    html <- new_spobj()$render_spans(docs = docs, labels = py_labels(labels),
                                     colors = py_colors(colors))
    html <- enc2utf8(as.character(html))
    if (view) {
        view_html(html)
        return(invisible(html))
    }
    html
}

check_visualize_args <- function(labels, colors, view) {
    if (!is.null(labels) && (!is.character(labels) || anyNA(labels)))
        stop("labels must be NULL or a character vector of entity labels",
             call. = FALSE)
    if (!is.null(colors) &&
        (!is.character(colors) || anyNA(colors) ||
         length(colors) && is.null(names(colors)) ||
         any(is.na(names(colors)) | !nzchar(names(colors)))))
        stop("colors must be NULL or a character vector of colours named by ",
             "entity labels", call. = FALSE)
    if (anyDuplicated(toupper(names(colors))))
        stop("colors has more than one colour for a label", call. = FALSE)
    if (!is.logical(view) || length(view) != 1 || is.na(view))
        stop("view must be TRUE or FALSE", call. = FALSE)
    invisible(NULL)
}

# Lists, so that a single label is still a list in Python, and the colours a
# dictionary.
py_labels <- function(labels) if (!is.null(labels)) as.list(unname(labels))
py_colors <- function(colors) if (length(colors)) as.list(colors)

# The documents of a parse for displaCy: for each, in the order of the
# documents, its text and its entities, each with its label and where it
# starts and ends in that text, counting characters from 0, with the end after
# its last character. The text is made from the tokens: spaced as they were
# in the text that was parsed when the parse has their positions (offsets =
# TRUE), without the whitespace before the first token, and otherwise with a
# space between every two. An entity is a token tagged _B and the tokens
# tagged _I after it or, in the output of entity_consolidate(), a token that
# has an entity_type.
parsed_entity_docs <- function(x) {
    consolidated <- !"entity" %in% names(x) && "entity_type" %in% names(x)
    if (!consolidated && !"entity" %in% names(x))
        stop("x has no column entity: rerun spacy_parse() with entity = TRUE",
             call. = FALSE)
    if (!all(c("doc_id", "token") %in% names(x)))
        stop("x has no column ", setdiff(c("doc_id", "token"), names(x))[1],
             call. = FALSE)
    token <- as.character(x[["token"]])
    token[is.na(token)] <- ""
    if (consolidated) {
        label <- as.character(x[["entity_type"]])
        label[is.na(label)] <- ""
        inside <- begins <- nzchar(label)
    } else {
        tag <- as.character(x[["entity"]])
        tag[is.na(tag)] <- ""
        label <- sub("_[BI]$", "", tag)
        inside <- nzchar(tag)
        begins <- grepl("_B$", tag)
    }
    offsets <- all(c("start", "end") %in% names(x))

    docs <- parsed_documents(x)$doc_id
    rows <- split(seq_len(nrow(x)),
                  factor(as.character(x[["doc_id"]]), levels = docs))
    unname(lapply(rows, function(i) {
        n <- length(i)
        if (!n) return(list(text = "", ents = list()))
        gap <- if (offsets) {
            c(0L, pmax(0L, x[["start"]][i][-1] - x[["end"]][i][-n] - 1L))
        } else {
            c(0L, rep(1L, n - 1L))
        }
        gap[is.na(gap)] <- 1L
        pieces <- paste0(strrep(" ", gap), token[i])
        end <- cumsum(nchar(pieces, type = "chars"))
        start <- end - nchar(token[i], type = "chars")
        # a token that is not in an entity, or that begins one, ends the
        # entity before it
        span <- cumsum(begins[i] | !inside[i])
        ents <- lapply(unique(span[inside[i]]), function(id) {
            k <- which(span == id & inside[i])
            list(start = as.integer(start[k[1]]),
                 end = as.integer(end[k[length(k)]]),
                 label = label[i][k[1]])
        })
        list(text = paste(pieces, collapse = ""), ents = ents)
    }))
}

# Write an HTML fragment to a temporary file as a whole page, which says that
# it is UTF-8, and open the page in the browser. Returns the path of the file.
view_html <- function(html, title = "Named entities") {
    page <- paste0(
        "<!DOCTYPE html>\n<html>\n<head>\n<meta charset=\"utf-8\">\n",
        "<title>", title, "</title>\n</head>\n",
        "<body style=\"font-size: 16px; font-family: -apple-system, ",
        "BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif; ",
        "padding: 4rem 2rem\">\n",
        html, "\n</body>\n</html>")
    path <- tempfile("spacyr-entities-", fileext = ".html")
    # closed, and so written in full, before the browser opens it
    con <- file(path, open = "wb")
    tryCatch(writeLines(enc2utf8(page), con, useBytes = TRUE),
             finally = close(con))
    utils::browseURL(path)
    invisible(path)
}
