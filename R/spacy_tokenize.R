#' Tokenize text with spaCy
#' 
#' Efficient tokenization (without POS tagging, dependency parsing,
#' lemmatization, or named entity recognition) of texts using spaCy.
#' @param x a character object, a \pkg{quanteda} corpus, or a TIF-compliant
#'   corpus data.frame (see <https://github.com/ropenscilabs/tif>) 
#' @param what the unit for splitting the text, available alternatives are: 
#'   \describe{ \item{`"word"`}{word segmenter} 
#'   \item{`"sentence"`}{sentence segmenter }}
#' @param remove_punct remove punctuation tokens.
#' @param remove_numbers remove tokens that look like a number (e.g. "334", "3.1415", "fifty").
#' @param remove_url remove tokens that look like a url or email address.
#' @param remove_separators remove spaces as separators when
#'  all other remove functionalities (e.g. `remove_punct`) have to be set to `FALSE`. 
#'  When `what = "sentence"`, this option will remove trailing spaces if `TRUE`.
#' @param remove_symbols remove symbols. The symbols are either `SYM` in `pos`
#'   field, or currency symbols. Since this needs the part-of-speech tags, it
#'   runs all the components of the pipeline, which makes tokenization much
#'   slower; the other `remove_*` options do not.
#' @param padding if `TRUE`, leave an empty string where the removed tokens 
#'   previously existed. This is useful if a positional match is needed between 
#'   the pre- and post-selected tokens, for instance if a window of adjacency 
#'   needs to be computed.
#' @inheritParams spacy_parse
#' @param n_process the number of processes for spaCy's `nlp.pipe()` to use,
#'   as in [spacy_parse()]: `1` (the default) uses the current R session's
#'   Python process, a larger number starts that many Python processes, and
#'   `-1` uses all CPUs. It is used only when components of the pipeline run,
#'   which is for `what = "sentence"` and for `remove_symbols = TRUE`.
#'   Splitting texts into words runs no components, so more processes would
#'   only add the time to start them: the words are always tokenized in one
#'   process, whatever `n_process` is.
#' @param output type of returning object. Either `list` or `data.frame`. 
#' @param ... not used directly
#' @return either `list` or `data.frame` of tokens
#' @export
#' @examples
#' \dontrun{
#' spacy_initialize()
#' txt <- "And now for something completely different."
#' spacy_tokenize(txt)
#' 
#' txt2 <- c(doc1 = "The fast cat catches mice.\\nThe quick brown dog jumped.", 
#'           doc2 = "This is the second document.",
#'           doc3 = "This is a \\\"quoted\\\" text." )
#' spacy_tokenize(txt2)
#' }
spacy_tokenize <- function(x,
                           what = c("word", "sentence"),
                           remove_punct = FALSE,
                           remove_url = FALSE,
                           remove_numbers = FALSE,
                           remove_separators = TRUE,
                           remove_symbols = FALSE,
                           padding = FALSE,
                           multithread,
                           output = c("list", "data.frame"),
                           n_process = 1L,
                           batch_size = NULL,
                           ...) {
    UseMethod("spacy_tokenize")
}

#' @importFrom data.table data.table
#' @export
spacy_tokenize.character <- function(x,
                                     what = c("word", "sentence"),
                                     remove_punct = FALSE,
                                     remove_url = FALSE,
                                     remove_numbers = FALSE,
                                     remove_separators = TRUE,
                                     remove_symbols = FALSE,
                                     padding = FALSE,
                                     multithread,
                                     output = c("list", "data.frame"),
                                     n_process = 1L,
                                     batch_size = NULL,
                                     ...) {
    # checked before spaCy is initialized
    check_multithread(multithread, "spacy_tokenize")
    flags <- list(remove_punct = remove_punct, remove_url = remove_url,
                  remove_numbers = remove_numbers,
                  remove_separators = remove_separators,
                  remove_symbols = remove_symbols, padding = padding)
    for (flag in names(flags)) {
        value <- flags[[flag]]
        if (!is.logical(value) || length(value) != 1 || is.na(value))
            stop("`", flag, "` must be TRUE or FALSE", call. = FALSE)
    }
    args <- pipe_args(n_process, batch_size)
    output <- match.arg(output)
    what <- match.arg(what)
    input <- spacy_input(x)
    x <- input$x
    docnames <- input$docnames

    spobj <- new_spobj()
    if (identical(what, "sentence")){
        tokens <- spobj$tokenize_sentence(
            x, docnames,
            remove_separators = remove_separators,
            batch_size = args$batch_size, n_process = args$n_process)
    } else {
        if (!remove_separators && any(remove_punct, remove_url, remove_numbers)) {
            stop("remove_separators = FALSE and remove_* = TRUE are not compatible", call. = FALSE)
        }
        # only remove_symbols needs a pipeline component (the tagger, for the
        # SYM tag); punctuation, numbers and URLs are properties of the tokens
        turn_off_pipes <- !remove_symbols
        # with no component to run, more processes would only add the time
        # to start them and to load the model in each (#289)
        if (turn_off_pipes) args$n_process <- 1L
        tokens <- spobj$tokenize(
            x, docnames,
            remove_punct = remove_punct,
            remove_url = remove_url,
            remove_numbers = remove_numbers,
            remove_separators = remove_separators,
            remove_symbols = remove_symbols,
            turn_off_pipes = turn_off_pipes,
            padding = padding,
            batch_size = args$batch_size, n_process = args$n_process)
    }
    warn_skipped(spobj)

    if (identical(output, "list")) return(tokens)
    else {
        list_length <- sapply(tokens, length)
        docnames_vec <- rep(names(list_length), list_length)
        return(data.frame(doc_id = docnames_vec,
                          token = unlist(tokens, use.names = FALSE),
                          stringsAsFactors = FALSE))
    }
}


#' @export
spacy_tokenize.data.frame <- function(x, ...) {
    spacy_tokenize(tif_texts(x), ...)
}
