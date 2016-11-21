#' Initialize spaCy via rPython
#' 
#' Initialize spaCy for use from R.
#' @param python_exec character; select connection type to spaCy, either 
#'   \code{"rPython"} or \code{"Rcpp"}.
#' @return NULL
#' @export
#' @importFrom rPython python.load python.assign
#' @author Akitaka Matsuo
spacy_initialize <- function(python_exec = c("rPython", "Rcpp")) {
    python_exec <- match.arg(python_exec)
    if (python_exec == 'rPython') {
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
