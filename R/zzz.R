.onLoad <- function(libname, pkgname) {
    # setting up the reticulate python part is moved to spacy_initialize()
    # clear options
    options("spacy_initialized" = NULL)
    options("python_initialized" = NULL)
}
