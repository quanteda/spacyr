#' Initialize spaCy
#' 
#' Initialize spaCy to call from R.
#' @return NULL
#' @param lang Language package for loading spacy. Either \code{en} (English) or 
#' \code{de} (German). Default is \code{en}.
#' @export
#' @author Akitaka Matsuo
spacy_initialize <- function(lang = 'en') {
    if(! lang %in% c('en', 'de')) {
        stop('value of lang option should be either "en" or "de"')
    }
    pyrun(sprintf("lang = '%s'", lang))
    code <- readLines(system.file("python", "initialize_rPython.py", package = 'spacyr'))
    code <- paste(code, collapse = "\n")
    # pyrun("rpython = 0")
    pyrun(code)
    options("spacy_initialized" = TRUE)
}

#' Finalize spaCy
#' 
#' Finalize spaCy.
#' @return NULL
#' @export
#' @details While running the spacy on python through R, a python process is 
#' always running in the backgroud and rsession will take
#' up a lot of memory (typically over 1.5GB). \code{spacy_finalize()} function will
#' finalize (i.e. terminate) the python process and free up the memory.
#' @author Akitaka Matsuo
spacy_finalize <- function() {
    finalize_python()
    options("spacy_initialized" = NULL)
}