#' Install a language model in a virtual environment
#' 
#' Installs one or more language models in a conda or virtualenv Python virtual
#' environment as installed by \code{\link{spacy_install}}.
#' @param envname name of the virtual environment
#' @param conda Path to conda executable.  Default \code{"auto"} which
#'   automatically finds the path.
#' @param model name of the language model to be installed
#' @export
spacy_download_lang_model_conda <- function(envname = "spacy_condaenv", 
                                            model = "en",
                                            conda = "auto") {
    message(sprintf("installing model \"%s\"\n", model))
    # resolve conda binary
    conda <- reticulate::conda_binary(conda)
    
    # 
    condaenv_bin <- function(bin) path.expand(file.path(dirname(conda), bin))
    cmd <- sprintf("%s%s %s && python -m spacy download %s%s",
                   ifelse(is_windows(), "", ifelse(is_osx(), "source ", "/bin/bash -c \"source ")),
                   shQuote(path.expand(condaenv_bin("activate"))),
                   envname,
                   model,
                   ifelse(is_windows(), "", ifelse(is_osx(), "", "\"")))
    result <- system(cmd)

    # check for errors
    if (result != 0L) {
        stop("Error ", result, " occurred installing packages into conda environment ", 
             envname, call. = FALSE)
    }
    
    invisible(NULL)
}


#' @rdname spacy_download_lang_model_conda
#' @param virtualenv_root path to the virtualenv environment to install spaCy
#'   language model. If \code{NULL}, the default path \code{"~/.virtualenvs"}
#'   will be used.
#' @export
spacy_download_lang_model_virtualenv <- function(envname = "spacy_virtualenv", 
                                                 model = "en",
                                                 virtualenv_root = NULL) {
    message(sprintf("installing model \"%s\"\n", model))
    if (is.null(virtualenv_root)) {
        virtualenv_root <- "~/.virtualenvs"
    }
    virtualenv_bin <- function(bin) path.expand(file.path(virtualenv_path, "bin", bin))
    
    # create virtualenv if necessary
    virtualenv_path <- file.path(virtualenv_root, "spacy_virtualenv")

    if (!file.exists(virtualenv_path) || !file.exists(virtualenv_bin("activate"))) {
        stop("The virtual environemnt ", virtualenv_path, " does not exist\n")
    } 
    
    cmd <- sprintf("%s%s && python -m spacy download %s%s",
                   ifelse(is_windows(), "", ifelse(is_osx(), "source ", "/bin/bash -c \"source ")),
                   shQuote(path.expand(virtualenv_bin("activate"))),
                   model,
                   ifelse(is_windows(), "", ifelse(is_osx(), "", "\"")))
    result <- system(cmd)
    
    # check for errors
    if (result != 0L) {
        stop("Error ", result, " occurred installing packages into virtual environment ", 
             envname, call. = FALSE)
    }
    
    invisible(NULL)
}
