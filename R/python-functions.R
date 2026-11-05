# The Python side of spacyr: the module inst/python/spacyr_class.py, loaded
# by spacy_initialize(), the spaCy pipeline it returns, and the object
# holding the documents parsed by the last call to process_document(), which
# the get_*() functions read. Nothing is stored in Python's __main__.
spacyr_env <- new.env(parent = emptyenv())

spacyr_module <- function() {
    if (is.null(spacyr_env$module)) stop("spaCy is not initialized")
    spacyr_env$module
}

# a new spacyr object, holding the pipeline; it replaces the previous one
new_spobj <- function() {
    spacyr_env$spobj <- spacyr_module()$spacyr(spacyr_env$nlp)
    spacyr_env$spobj
}

# the spacyr object from the last call to process_document()
current_spobj <- function() {
    if (is.null(spacyr_env$spobj)) stop("no parsed documents: run spacy_parse() first")
    spacyr_env$spobj
}
