#' install language moden in conda virtual environment
#' 
#' @param envname Name of conda environment. Default "spacy_condaenv" (the name used by spacyr)
#' 
#' @param conda
#' 
#' @param model name of the laguage model to be installed
#'
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


#' install language moden in python virtual environment
#' 
#' @param envname Name of virtual environment. Default "spacy_virtualenv" (the name used by spacyr)
#' 
#' @param model name of the laguage model to be installed
#' 
#' @param virtualenv_root path to the virtualenv environment to install spacy language model
#' if \code{NULL}, spacyr will use the default path ("~/.virtualenvs").
#'
#' @export
spacy_download_lang_model_virtualenv <- function(envname = "spacy_virtualenv", 
                                                 model = "en",
                                                 virtualenv_root = NULL) {
    message(sprintf("installing model \"%s\"\n", model))
    if(is.null(virtualenv_root)){
        virtualenv_root <- "~/.virtualenvs"
    }
    virtualenv_bin <- function(bin) path.expand(file.path(virtualenv_path, "bin", bin))
    
    # create virtualenv if necessary
    virtualenv_path <- file.path(virtualenv_root, "spacy_virtualenv")

    
    if (!file.exists(virtualenv_path) || !file.exists(virtualenv_bin("activate"))) {
        stop("The virtual environemnt ", virtualenv_path, " does not exist\n")
    } 
    
    # 
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
