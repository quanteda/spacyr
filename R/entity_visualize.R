#' Visualize the named entities of texts
#'
#' Shows texts with their named entities highlighted and labelled, as HTML
#' made by displaCy, spaCy's visualizer (see
#' <https://spacy.io/usage/visualizers#ent>).
#'
#' @param x a character object, a \pkg{quanteda} corpus, or a TIF-compliant
#'   corpus data.frame (see <https://github.com/ropenscilabs/tif>)
#' @param ents the labels of the entities to highlight, as a character
#'   vector such as `c("PERSON", "ORG")`. The default, `NULL`, highlights
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
#' @inheritParams spacy_parse
#' @details The entities are those that the active pipeline finds in the
#'   texts, including any from rules given to [spacy_initialize()] as
#'   `entity_patterns`. The texts are processed for this, so `x` is the
#'   texts themselves and not the output of [spacy_parse()], which does not
#'   keep them.
#'
#'   The documents are shown in the order of `x`, each in a block of its
#'   own. A document without entities, or without any of the labels in
#'   `ents`, is shown as plain text.
#' @return a character vector of length one, with the HTML for all the
#'   documents. It is a fragment and not a whole page, so that it can be
#'   put into a page, an R Markdown document or a Shiny app. It is returned
#'   invisibly when `view = TRUE`, and is `""` when there are no documents.
#' @seealso [spacy_extract_entity()] for the entities as data.
#' @export
#' @examples
#' \dontrun{
#' spacy_initialize()
#'
#' txt <- c(doc1 = "The Supreme Court is located in Washington D.C.",
#'          doc2 = "Paul earned a postgraduate degree from MIT.")
#' html <- entity_visualize(txt)
#'
#' # open in the browser, with only some labels and a colour of one's own
#' entity_visualize(txt, ents = c("ORG", "GPE"), colors = c(GPE = "gold"),
#'                  view = TRUE)
#' }
entity_visualize <- function(x, ents = NULL, colors = NULL, view = FALSE,
                             n_process = 1L, batch_size = NULL) {
    UseMethod("entity_visualize")
}

#' @export
entity_visualize.character <- function(x, ents = NULL, colors = NULL, view = FALSE,
                                       n_process = 1L, batch_size = NULL) {
    # checked before spaCy is initialized
    args <- pipe_args(n_process, batch_size)
    if (!is.null(ents) && (!is.character(ents) || anyNA(ents)))
        stop("ents must be NULL or a character vector of entity labels",
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

    input <- spacy_input(x)

    spobj <- new_spobj()
    # lists, so that a single label is still a list in Python, and the
    # colours a dictionary
    html <- spobj$render_entities(
        texts = input$x, docnames = input$docnames,
        ents = if (!is.null(ents)) as.list(unname(ents)),
        colors = if (length(colors)) as.list(colors),
        batch_size = args$batch_size, n_process = args$n_process)
    warn_skipped(spobj)
    html <- enc2utf8(as.character(html))

    if (view) {
        view_html(html)
        return(invisible(html))
    }
    html
}

#' @method entity_visualize data.frame
#' @export
entity_visualize.data.frame <- function(x, ...) {
    entity_visualize(tif_texts(x), ...)
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
