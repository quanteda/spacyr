#' Initialize spaCy
#' 
#' Initialize spaCy to call from R. 
#' @return NULL
#' @param model Language package for loading spacy. Example: \code{en} (English) and
#' \code{de} (German). Default is \code{en}.
#' @param python_executable the full path to the python excutable, for which spaCy is installed
#' @param ask logical; if \code{FALSE}, use the first spaCy installation found; 
#'   if \code{TRUE}, list available spaCy installations and prompt the user 
#'   for which to use. If another (e.g. \code{python_executable}) is set, then 
#'   this value will always be treated as \code{FALSE}.
#' @param virtualenv set a path to the python virtual environment with spaCy installed
#'   Example: \code{virtualenv = "~/myenv"}
#' @param condaenv set a path to the anaconda virtual environment with spaCy installed
#'   Example: \code{condalenv = "myenv"}
#' @export
#' @author Akitaka Matsuo
spacy_initialize <- function(model = "en", 
                             python_executable = NULL,
                             ask = FALSE,
                             virtualenv = NULL,
                             condaenv = NULL) {

    # here are a number of checkings
    if(!is.null(options("spacy_initialized")$spacy_initialized)){
        message("spaCy is already initialized")
        return(NULL)
    }
    # once python is initialized, you cannot change the python executables
    if(!is.null(options("python_initialized")$python_initialized)) {
        message("Python space is already attached.  If you want to swtich to a different Python, please restart R.")
    } 
    # a user can specify only one
    else if(sum(!is.null(c(python_executable, virtualenv, condaenv))) > 1) {
        stop(paste("Too many python environments are specified, please select only one",
                   "from python_executable, virtualenv, and condaenv"))
    }
    # give warning when nothing is specified
    else if (sum(!is.null(c(python_executable, virtualenv, condaenv))) == 0){
        # def_python <- ifelse(Sys.info()['sysname'] == "Windows", 
        #                      system("where python", intern = TRUE), 
        #                      system("which python", intern = TRUE))
        message("Finding a python executable with spacy installed...")
        spacy_python <- find_spacy(model, ask = ask)
        if(!is.null(spacy_python)){
            reticulate::use_python(spacy_python, required = TRUE)
        } else {
            stop("spaCy or language model ", model, " is not installed in any of python executables.")
        }
    } 
    else {# set the path with reticulte
        if(!is.null(python_executable)) {
            if(check_spacy_model(python_executable, model) != "OK"){
                stop("spaCy or language model ", model, " is not installed in ", python_executable)
            }
            reticulate::use_python(python_executable, required = TRUE)
        }
        else if(!is.null(virtualenv)) reticulate::use_virtualenv(virtualenv, required = TRUE)
        else if(!is.null(condaenv)) reticulate::use_condaenv(condaenv, required = TRUE)
    }
    options("python_initialized" = TRUE) # next line could cause non-recoverable error 
    spacyr_pyexec(pyfile = system.file("python", "spacyr_class.py",
                                       package = 'spacyr'))
    # if(! lang %in% c('en', 'de')) {
    #     stop('value of lang option should be either "en" or "de"')
    # }
    spacyr_pyassign("model", model)
    spacyr_pyexec(pyfile = system.file("python", "initialize_spacyPython.py",
                                       package = 'spacyr'))
    # spacy_version <- system2("pip", "show spacy", stdout = TRUE, stderr = TRUE)
    # spacy_version <- grep("Version" ,spacy_version, value = TRUE)
    # 
    spacy_version <- spacyr_pyget("versions")$spacy

    message("successfully initialized (spaCy Version: ", spacy_version,', language model: ', model, ')')
    options("spacy_initialized" = TRUE)
}

#' Finalize spaCy
#' 
#' While running the spacy on python through R, a python process is 
#' always running in the backgroud and rsession will take
#' up a lot of memory (typically over 1.5GB). \code{spacy_finalize()} terminates the 
#' Python process and frees up the memory it was using.
#' @return NULL
#' @export
#' @author Akitaka Matsuo
spacy_finalize <- function() {
    if(is.null(getOption("spacy_initialized"))) {
        stop("Nothing to finalize. Spacy is not initialized")
    }
    spacyr_pyexec(pyfile = system.file("python", "finalize_spacyPython.py",
                                       package = 'spacyr'))
    options("spacy_initialized" = NULL)
}

#' Find spaCy
#' 
#' Locate the user's version of Python for which spaCy installed.
#' @return spacy_python
#' @export
#' @param model name of the language model
#' @param ask logical; if \code{FALSE}, use the first spaCy installation found; 
#'   if \code{TRUE}, list available spaCy installations and prompt the user 
#'   for which to use. If another (e.g. \code{python_executable}) is set, then 
#'   this value will always be treated as \code{FALSE}.
#' @keywords internal
#' @importFrom data.table data.table
find_spacy <- function(model = "en", ask){
    spacy_found <- `:=` <- NA
    spacy_python <- NULL
    options(warn = -1)
    py_execs <- if(Sys.info()['sysname'] == "Windows") {
        system2("where", "python", stdout = TRUE)
    } else {
        c(system2('which', '-a python', stdout = TRUE),
          system2('which', '-a python3', stdout = TRUE))
    }
    options(warn = 0)
    
    if (length(py_execs) == 0 | grepl("not find", py_execs[1])[1]){
        stop("No python was found on system PATH")
    }
    df_python_check <- data.table::data.table(py_execs, spacy_found = 0)
    for (i in 1:nrow(df_python_check)) {
        py_exec <- df_python_check[i, py_execs]
        sys_message <- check_spacy_model(py_exec, model)
        if (sys_message == 'OK') {
            df_python_check[i, spacy_found := 1]
        }
    }
    
    if (df_python_check[, sum(spacy_found)] == 0) {
        return(NULL)
    } else if (df_python_check[, sum(spacy_found)] == 1) {
        spacy_python <- df_python_check[spacy_found == 1, py_execs]
        message("spaCy (language model: ", model, ") is installed in ", spacy_python)
    } else if (ask == FALSE) {
        spacy_python <- df_python_check[spacy_found == 1, py_execs][1]
        message("spaCy (language model: ", model, ") is installed in more than one python")
        message("spacyr will use ", spacy_python, " (because ask = FALSE)")
    } else {
        spacy_pythons <- df_python_check[spacy_found == 1, py_execs]
        message("spaCy (language model: ", model, ") is installed in more than one python")
        message(paste(seq_along(spacy_pythons), spacy_pythons, sep = ': ', collapse = "\n"))
        number <- NA
        while(is.na(number)){
            number <- readline(prompt = "Please select python: ")
            number <- as.integer(number)
            if(is.na(number) | number < 1 | number > length(spacy_pythons)){
                number <- NA
            }
        }
        spacy_python <- spacy_pythons[number]
        message("spacyr will use: ", spacy_python)
    }
    return(spacy_python)
}    


check_spacy_model <- function(py_exec, model) {
    options(warn = -1)
    py_exist <- if(Sys.info()['sysname'] == "Windows") {
        system2("where", py_exec, stdout = TRUE)
    } else {
        system2('which', py_exec, stdout = TRUE)
    }
    
    if(length(py_exist) == 0) {
        stop(py_exec, " is not a python executable")
    }
    tryCatch({
        sys_message <- 
            system2(py_exec, c(sprintf("-c \"import spacy; spacy.load('%s'); print('OK')\"", model)), 
                    stderr = TRUE, stdout = TRUE)
    })
    options(warn = 0)
    return(paste(sys_message, collapse = " "))
}
