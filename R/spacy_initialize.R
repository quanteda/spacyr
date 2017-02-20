#' Initialize spaCy via rPython
#' 
#' Initialize spaCy for use from R.
#' @return NULL
#' @export
#' @author Akitaka Matsuo
spacy_initialize <- function() {
    code <- readLines(system.file("python", "initialize_rPython.py", package = 'spacyr'))
    code <- paste(code, collapse = "\n")
    # pyrun("rpython = 0")
    pyrun(code)
    options("spacy_rcpp" = TRUE)
}
