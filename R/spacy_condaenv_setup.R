#' spaCy conda envirnonment setup
#' 
#' create a conda environment for spacyr
#' @return NULL
#' @param models Language model(s) for spacy to install. Example: \code{en} (English) and
#' \code{de} (German). Default is \code{en}. 
#' Possible to install multiple models at once (e.g. \code{models = c('en', 'de')}).
#' @param refresh_condaenv logical. If \code{TRUE} the previous environment (if exists) will be deleted.
#' Default is \code{FALSE}. 
#' @export
#' @author Akitaka Matsuo
spacy_condaenv_setup <- function(models = c("en"), 
                                 refresh_condaenv = FALSE) {
    if(Sys.info()['sysname'] == "Windows") {
        stop("This function is not available for Windows systems yet.")
    }
    
    conda_list <- system2("source", "~/.bash_profile; conda env list", stdout = TRUE)
    if(refresh_condaenv == FALSE){
        if (sum(grepl("spacy_condaenv", conda_list)) > 0){
            stop("conda enviroment already exists: spacy_condaenv\nIf you want to refresh the enviroment, use refresh_condaenv = TRUE")
        }
    } else {
        if (sum(grepl("spacy_condaenv", conda_list)) > 0){
            system2("source", "~/.bash_profile; conda env remove --name spacy_condaenv -y")
        }
    }
    yml_filename <- tempfile(fileext = ".yml")
    write(c("name: spacy_condaenv", 
            "dependencies:",
            "- python=3.6",
            "- spacy=2.0"), yml_filename)
    system2("source", paste("~/.bash_profile; conda env create --file ", yml_filename))
    file.remove(yml_filename)
    
    for(model in models){
        system2("source", paste("~/.bash_profile; source activate spacy_condaenv; python -m spacy download", model))
    }
    
    rprofile <- readLines("~/.Rprofile")
    write(c(grep("spacy_condaenv = TRUE", rprofile, value = TRUE, invert = TRUE),
            "options(spacy_condaenv = TRUE)"),
          file = "~/.Rprofile")
    options(spacy_condaenv = TRUE)
    message("spacy_condaenv is successfully created. Please restart R in order to reflect the changes")
}


#' remove spaCy conda envirnonment
#' 
#' remove a conda environment for spacyr
#' @return NULL
#' @param modify_rprofile logical remove a line in .Rprofile describing the condaenv
#' @export
#' @author Akitaka Matsuo
spacy_condaenv_remove <- function(modify_rprofile = TRUE) {
    if(Sys.info()['sysname'] == "Windows") {
        stop("This function is not available for Windows systems yet.")
    }
    tmp <- system2("source", "~/.bash_profile; conda env remove --name spacy_condaenv -y", stdout = TRUE)
    if(modify_rprofile) {
        rprofile <- readLines("~/.Rprofile")
        write(grep("spacy_condaenv = TRUE", rprofile, value = TRUE, invert = TRUE), 
              file = "~/.Rprofile")
    }
    message("spacy_condaenv is successfully removed. Please restart R in order to reflect the changes")
}


#' Add language models to spaCy conda envirnonment
#' 
#' add language models
#' @return NULL
#' @param models Language model(s) for spacy to install. Example: \code{en} (English) and
#' \code{de} (German). Default is \code{en}. 
#' Possible to install multiple models at once (e.g. \code{models = c('en', 'de')}).
#' @export
#' @author Akitaka Matsuo
spacy_condaenv_add_models <- function(models = c("en")) {
    if(Sys.info()['sysname'] == "Windows") {
        stop("This function is not available for Windows systems yet.")
    }
    
    for(model in models){
        system2("source", paste("~/.bash_profile; source activate spacy_condaenv; python -m spacy download", model))
    }
}


