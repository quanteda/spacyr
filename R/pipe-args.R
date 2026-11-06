# Arguments shared by the functions that process documents with spaCy's
# nlp.pipe(): spacy_parse(), spacy_tokenize(), spacy_extract_entity() and
# spacy_extract_nounphrases().

# Warn when the deprecated multithread argument is supplied. It has had no
# effect since documents are always processed with nlp.pipe(). The warning is
# given on every call, so that output does not depend on earlier calls.
check_multithread <- function(multithread, fun) {
    if (!missing(multithread)) {
        warning(warningCondition(
            paste0("The `multithread` argument of `", fun, "()` is deprecated ",
                   "and has no effect: documents are always processed in batches ",
                   "with spaCy's nlp.pipe(). Use `n_process` to process them in ",
                   "parallel, and `batch_size` to set the number of documents in ",
                   "each batch."),
            class = c("spacyr_deprecated", "deprecatedWarning"),
            call = NULL))
    }
    invisible(NULL)
}

is_whole_number <- function(x) {
    is.numeric(x) && length(x) == 1 && !is.na(x) && is.finite(x) && x == round(x)
}

# Check n_process and batch_size and convert them for nlp.pipe(): a NULL
# batch_size uses the pipeline's default batch size.
pipe_args <- function(n_process, batch_size) {
    if (!is_whole_number(n_process) || (n_process < 1 && n_process != -1)) {
        stop("`n_process` must be a positive whole number, or -1 to use all CPUs",
             call. = FALSE)
    }
    if (!is.null(batch_size) && (!is_whole_number(batch_size) || batch_size < 1)) {
        stop("`batch_size` must be NULL or a positive whole number", call. = FALSE)
    }
    list(n_process = as.integer(n_process),
         batch_size = if (!is.null(batch_size)) as.integer(batch_size))
}
