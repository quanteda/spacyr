#' Spacy for R
#'
#'
#' @docType package
#' @name spacyr
NULL


common_obj <- new.env(parent=emptyenv())

.onLoad <- function(libname, pkgname) {
    # if SPACY_PYTHON is defined then forward it to RETICULATE_PYTHON
    spacyr_pyexec(pyfile = system.file("python", "spacyr_class.py",
                                       package = 'spacyr'))
    spacy_python <- Sys.getenv("SPACY_PYTHON", unset = NA)
    if (!is.na(spacy_python))
        Sys.setenv(RETICULATE_PYTHON = spacy_python)
}


