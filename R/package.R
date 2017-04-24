#' Spacy for R
#'
#'
#' @docType package
#' @name spacyr
NULL

.onLoad <- function(libname, pkgname) {
    # require(reticulate)
    # print("hello")
    # py_run_string('import sys\nprint(sys.version_info)')
    # 
    # 
    # if SPACY_PYTHON is defined then forward it to RETICULATE_PYTHON
    spacy_python <- Sys.getenv("SPACY_PYTHON", unset = NA)
    if (!is.na(spacy_python))
        Sys.setenv(RETICULATE_PYTHON = spacy_python)
}


