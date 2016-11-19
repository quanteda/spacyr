#' Initialize spaCy via rPython
#' 
#' Initialize spaCy using an alternative method via the rPython package.
#' @return NULL
#' @export
#' @author Akitaka Matsuo
spacy_initialize <- function() {
    rPython::python.load(system.file("python", "initialize_rPython.py", package = 'spacyr'))
    rPython::python.assign("rpython", 1)
    options("spacy_rpython" = TRUE)
}
