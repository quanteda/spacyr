#' Spacy for R
#'
#'
#' @docType package
#' @name spacyr
NULL


common_obj <- new.env(parent=emptyenv())

.onLoad <- function(libname, pkgname) {
    # setting up the reticulate python part is moved to spacy_initialize()
}


