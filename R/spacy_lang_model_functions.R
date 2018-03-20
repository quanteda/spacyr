#' install language moden in conda virtual environment
#' 
#' @param envname Name of conda environment. Default "spacy_condaenv" (the name used by spacyr)
#' 
#' @param conda
#' 
#' @param lang_model name of the laguage model to be installed
#'
#' @export
spacy_download_lang_model_conda <- function(envname = "spacy_condaenv", 
                                            model = "en",
                                            conda = "auto") {
    
    # resolve conda binary
    conda <- conda_binary(conda)
    
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
