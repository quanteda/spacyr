#' Initialize spaCy via rPython
#' 
#' Initialize spaCy using an alternative method via the rPython package.
#' @return NULL
#' @export
#' @author Akitaka Matsuo
spacy_initialize <- function(python_exec = "rPython") {
    if(python_exec == 'rPython'){
        rPython::python.load(system.file("python", "initialize_rPython.py", package = 'spacyr'))
        rPython::python.assign("rpython", 1)
        options("spacy_rpython" = TRUE)
    } else {
        code <- readLines(system.file("python", "initialize_rPython.py", package = 'spacyr'))
        code <- paste(code, collapse = "\n")
        pyrun("rpython = 0")
        pyrun(code)
        options("spacy_rcpp" = TRUE)
    }
}
