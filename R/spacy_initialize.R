#' Initialize spaCy
#' 
#' Initialize spaCy to call from R. 
#' @return NULL
#' @param lang Language package for loading spacy. Either \code{en} (English) or 
#' \code{de} (German). Default is \code{en}.
#' @param use_python set a path to the python excutable with spaCy. 
#' @param use_virtualenv set a path to the python virtual environment with spaCy. 
#'   Example: \code{use_virtualenv = "~/myenv"}
#' @param use_condaenv set a path to the anaconda virtual environment with spaCy. 
#'   Example: \code{use_condalenv = "myenv"}
#' @export
#' @author Akitaka Matsuo
spacy_initialize <- function(lang = 'en', 
                             use_python = NA,
                             use_virtualenv = NA,
                             use_condaenv = NA) {
    # here are a number of checkings
    if(!is.null(options("spacy_initialized")$spacy_initialized)){
        message("spacy is already initialized")
        return(NULL)
    }
    # once python is initialized, you cannot change the python executables
    if(!is.null(options("python_initialized")$python_initialized)) {
        message("Python space is already attached to R. You cannot switch Python.\nIf you'd like to switch to other Python, please restart R")
    } 
    # a user can specify only one
    else if(sum(!is.na(c(use_python, use_virtualenv, use_condaenv))) > 1) {
        stop(paste("Too many python environments are specified, please select only one",
                   "from use_python, use_virtualenv, and use_condaenv"))
    }
    # give warning when nothing is specified
    else if (sum(!is.na(c(use_python, use_virtualenv, use_condaenv))) == 0){
        def_python <- ifelse(Sys.info()['sysname'] == "Windows", 
                             system("where python", intern = TRUE), 
                             system("which python", intern = TRUE))
        message(paste("No python executable is specified, spacyr will use system default python\n",
                       sprintf("(system default python: %s).", def_python)))
    } 
    else {# set the path with reticulte
        if(!is.na(use_python)) reticulate::use_python(use_python, required = TRUE)
        else if(!is.na(use_virtualenv)) reticulate::use_virtualenv(use_virtualenv, required = TRUE)
        else if(!is.na(use_condaenv)) reticulate::use_condaenv(use_condaenv, required = TRUE)
    }
    options("python_initialized" = TRUE) # next line could cause non-recoverable error 
    spacyr_pyexec(pyfile = system.file("python", "spacyr_class.py",
                                       package = 'spacyr'))
    if(! lang %in% c('en', 'de')) {
        stop('value of lang option should be either "en" or "de"')
    }
    spacyr_pyassign("lang", lang)
    spacyr_pyexec(pyfile = system.file("python", "initialize_spacyPython.py",
                                       package = 'spacyr'))
    message("spacy is successfully initialized")
    options("spacy_initialized" = TRUE)
}

#' Finalize spaCy
#' 
#' Finalize spaCy.
#' @return NULL
#' @export
#' @details While running the spacy on python through R, a python process is 
#' always running in the backgroud and rsession will take
#' up a lot of memory (typically over 1.5GB). \code{spacy_finalize()} function will
#' finalize (i.e. terminate) the python process and free up the memory.
#' @author Akitaka Matsuo
spacy_finalize <- function() {
    if(is.null(getOption("spacy_initialized"))) {
        stop("Nothing to finalize. Spacy is not initialized")
    }
    spacyr_pyexec(pyfile = system.file("python", "finalize_spacyPython.py",
                                       package = 'spacyr'))
    options("spacy_initialized" = NULL)
}

