# The Python side of spacyr: the module inst/python/spacyr_bridge.py, loaded
# by spacy_initialize(), the spaCy pipeline it returns, and the object
# holding the documents parsed by the last call to process_document(), which
# the get_*() functions read. Nothing is stored in Python's __main__.
spacyr_env <- new.env(parent = emptyenv())

# Load inst/python/spacyr_bridge.py from this copy of spacyr. A module of the
# same name cached in sys.modules (for instance from another installed or
# source copy of spacyr loaded earlier in the session) is dropped first, since
# import_from_path() would otherwise return it.
load_spacyr_module <- function(name = "spacyr_bridge") {
    path <- system.file("python", package = "spacyr")
    file <- file.path(path, paste0(name, ".py"))
    if (!file.exists(file)) stop("spacyr's Python module was not found at ", file)
    sys <- reticulate::import("sys", convert = FALSE)
    sys$modules$pop(name, NULL)
    module <- reticulate::import_from_path(name, path = path)
    loaded <- tryCatch(
        reticulate::py_to_r(reticulate::py_get_attr(module, "__file__")),
        error = function(e) NULL)
    if (is.null(loaded) ||
        !identical(normalizePath(as.character(loaded), winslash = "/", mustWork = FALSE),
                   normalizePath(file, winslash = "/", mustWork = FALSE))) {
        stop("spacyr's Python module was loaded from ",
             if (is.null(loaded)) "an unknown location" else as.character(loaded),
             " instead of ", file)
    }
    module
}

spacyr_module <- function() {
    if (is.null(spacyr_env$module)) stop("spaCy is not initialized")
    spacyr_env$module
}

# a new spacyr object, holding the pipeline; it replaces the previous one
new_spobj <- function() {
    spacyr_env$spobj <- spacyr_module()$spacyr(spacyr_env$nlp)
    spacyr_env$spobj
}

# Warn about documents that spaCy's pipeline left out of the last call through
# spobj: nlp.pipe() leaves out a document when a pipeline component fails on
# it and the pipeline's error handler suppresses the error.
warn_skipped <- function(spobj) {
    skipped <- as.character(unlist(spobj$skipped))
    if (length(skipped)) {
        warning("spaCy's pipeline did not return ", length(skipped),
                if (length(skipped) == 1) " document" else " documents",
                ", which ", if (length(skipped) == 1) "is" else "are",
                " left out of the output: ",
                paste(skipped, collapse = ", "), call. = FALSE)
    }
    invisible(skipped)
}

# the spacyr object from the last call to process_document()
current_spobj <- function() {
    if (is.null(spacyr_env$spobj)) stop("no parsed documents: run spacy_parse() first")
    spacyr_env$spobj
}
