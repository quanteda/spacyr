#' Check the availability of spaCy and initialize paths
#' 
#' Check the availablity of spaCy on the user's system, as well as the 
#' availability of spaCy model for English. This function has to be executed 
#' before running \code{tag()}.  This function not only checks the availability,
#' but also sets options to the path where spaCy is installed, in case the user
#' has more than one version of Python installed, or is using a virtualenv.
#' @param which_python specific python path you want to test the availability of
#'   spacy. If you do not specify, this fuction looks for all python intallation
#'   on the computer
#' @return NULL
#' @export
#' @section Setting the path to the python executable: Note that on some 
#'   systems, notably OS X / macOS, you may have installed a different version 
#'   of Python from that included in the base system.  OS X / macOS installs a 
#'   slightly older version of 2.7.x by default, for instance, in 
#'   \code{/usr/bin/python}.  Using homebrew, you may have installed a different
#'   version that gets placed in \code{/usr/local/bin}.  Even when this is 
#'   working at a command line (e.g. bash in the Terminal), when called from R 
#'   it may still look for \code{usr/bin/python}. This function finds the python
#'   executable with spaCy and set the path to it.
#' @importFrom quanteda docnames
#' @author Akitaka Matsuo
initialize_spacy <- function(which_python = NA) {
    all_python <- NULL
    
    if (is.na(which_python)) {
        tryCatch({all_python <- system2(ifelse(Sys.info()['sysname'] == "Windows", "where", "which"),
                                        c(ifelse(Sys.info()['sysname'] == "Windows", NULL, "-a"), "python"),
                                        stdout = TRUE)}, 
                 warning = function(e) {
                     if (is.atomic(all_python)) {
                         stop("No python found in the system")
                     }
                 })
        
    } else {
        all_python <- which_python
    }
    all_python <- unique(all_python)
    spacy_found <- rep(NA, length(all_python))
    for (i in 1:length(all_python)){
        python_full <- all_python[i]
        suppressWarnings({msg <- paste0(system2(python_full, 
                                                args = c("-c", "\"import os; import spacy\""), 
                                                stdout = TRUE,
                                                stderr = TRUE), collapse = '\n')})
        if (grepl("Error:", msg)[1]) {
            spacy_found[i] <- FALSE
        } else {
            spacy_found[i] <- TRUE
        }
    }
    if (sum(spacy_found) == 1) {
        python_path <- dirname(all_python[which(spacy_found)])
        options("PYTHON_PATH" = python_path)
    } else if (sum(spacy_found) > 1) {
        stop(paste("More than one python installation with spacy was found",
                   "Run check_spacy() again with \"which_python\" specified", 
                   sep = "\n"))
    } else {
        stop(paste("Could not find spacy installation.",
                   "Please install spacy following the instruction at",
                   "https://spacy.io/docs/#getting-started", sep = "\n")) 
    }
    # test whether English lagunage pack is available
    
    PYTHON_SCRIPT <- system.file("python", "posTag.py", package = "spacyr")
    x <- "Sample Text"
    
    # get the path to the correct python executable
    PYTHON_PATH <- paste0(options()$PYTHON_PATH, "/")
    
    # call the Python code
    ret <- ""
    suppressWarnings(ret <- paste0(system2(paste0(PYTHON_PATH, "python"),
                                           args = c(PYTHON_SCRIPT, "-w", "-p"),
                                           input = x, stdout = TRUE, 
                                           stderr = TRUE),
                                   collapse = "\n"))
    if (grepl("RuntimeError", ret)) {
        err_msg <- sub(".+(RuntimeError.+)", "\\1", ret)
        options("PYTHON_PATH" = NULL) # delete the option so that tag() will not run
        stop(err_msg)
    } else {
        cat("tag() is ready to run\n")
    }
}
