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
#' @param source_bash_profile logical; if \code{TRUE}, source \code{~/.bash_profile} before trying
#'   to find python executables with spaCy installed. Most likely necessary to set \code{TRUE}, 
#'   if using anaconda python in Mac or Linux. Default is \code{NULL} 
#'   which functions as \code{TRUE} for non-Windows system (e.g. Mac/Linux) and 
#'   \code{FALSE} for Windows system.
#' @param virtualenv set a path to the python virtual environment with spaCy installed
#'   Example: \code{virtualenv = "~/myenv"}
#' @param condaenv set a path to the anaconda virtual environment with spaCy installed
#'   Example: \code{condalenv = "myenv"}
#' @param entity logical; if \code{FALSE} is selected, named entity recognition is turned off 
#'   in spaCy. This will speed up the parsing as it will exclude \code{ner} from the pipeline. 
#'   For details of spaCy pipeline, 
#'   see \url{https://spacy.io/usage/processing-pipelines}. The option \code{FALSE} is available only 
#'   for spaCy version 2.0.0 or higher.
#' @export
#' @author Akitaka Matsuo
spacy_initialize <- function(model = "en", 
                             python_executable = NULL,
                             ask = FALSE,
                             source_bash_profile = NULL,
                             virtualenv = NULL,
                             condaenv = NULL, 
                             entity = TRUE) {

    # here are a number of checkings
    if(!is.null(options("spacy_initialized")$spacy_initialized)){
        message("spaCy is already initialized")
        return(NULL)
    }
    # set an option for source_bash_profile
    if(is.null(source_bash_profile)) {
        if(Sys.info()['sysname'] == "Windows"){
            source_bash_profile <- FALSE
        } else {
            source_bash_profile <- TRUE
        }
    }
    # once python is initialized, you cannot change the python executables
    if(!is.null(options("python_initialized")$python_initialized)) {
        message("Python space is already attached.  If you want to switch to a different Python, please restart R.")
    } 
    else {
        set_spacy_python_option(python_executable, 
                                virtualenv, 
                                condaenv, 
                                ask, 
                                source_bash_profile, 
                                model)
    }
    
    if (!is.null(options("spacy_python_setting")$spacy_python_setting)) {
        ####
        type <- options("spacy_python_setting")$spacy_python_setting$type
        py_path <- options("spacy_python_setting")$spacy_python_setting$py_path
        if(type == "python_executable") {
            if(check_spacy_model(py_path, model) != "OK"){
                stop("spaCy or language model ", model, " is not installed in ", py_path)
            }
            reticulate::use_python(py_path, required = TRUE)
        }
        else if(type == "virtualenv") reticulate::use_virtualenv(py_path, required = TRUE)
        else if(type == "condaenv") reticulate::use_condaenv(py_path, required = TRUE)
    }
    options("python_initialized" = TRUE) # next line could cause non-recoverable error 
    spacyr_pyexec(pyfile = system.file("python", "spacyr_class.py",
                                       package = 'spacyr'))
    # if(! lang %in% c('en', 'de')) {
    #     stop('value of lang option should be either "en" or "de"')
    # }
    spacyr_pyassign("model", model)
    spacyr_pyassign("spacy_entity", entity)
    options("spacy_entity" = entity)
    spacyr_pyexec(pyfile = system.file("python", "initialize_spacyPython.py",
                                       package = 'spacyr'))
    # spacy_version <- system2("pip", "show spacy", stdout = TRUE, stderr = TRUE)
    # spacy_version <- grep("Version" ,spacy_version, value = TRUE)
    # 
    spacy_version <- spacyr_pyget("versions")$spacy
    if(entity == FALSE & as.integer(substr(spacy_version, 1, 1)) < 2){
        message("entity == FALSE is only available for spaCy version 2.0.0 or higher")
        options("spacy_entity" = TRUE)
    }
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
#' @param source_bash_profile logical; if \code{TRUE}, source \code{~/.bash_profile} before trying
#'   to find python executables with spaCy installed. Most likely necessary to set \code{TRUE}, 
#'   if using anaconda python in Mac or Linux. 
#' @keywords internal
#' @importFrom data.table data.table
find_spacy <- function(model = "en", ask, source_bash_profile){
    spacy_found <- `:=` <- NA
    spacy_python <- NULL
    options(warn = -1)
    if(source_bash_profile == TRUE & Sys.info()['sysname'] == "Windows"){
        message("the option, source_bash_profile == TRUE, will be ignored for windows system")
    }
    py_execs <- if(Sys.info()['sysname'] == "Windows") {
        system2("where", "python", stdout = TRUE)
    } else if(source_bash_profile == TRUE) {
        c(system2('source', '~/.bash_profile; which -a python', stdout = TRUE),
          system2('source', '~/.bash_profile; which -a python3', stdout = TRUE))
    } else {
        c(system2('which', '-a python', stdout = TRUE),
          system2('which', '-a python3', stdout = TRUE))
    }
    py_execs <- unique(py_execs)
    options(warn = 0)
    
    if (length(py_execs) == 0 | grepl("not find", py_execs[1])[1]){
        return(NA)
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
        if(py_exec %in% system2("where", "python", stdout = TRUE)) {
            py_exec
        } else {
            NULL
        }
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


set_spacy_python_option <- function(python_executable = NULL, 
                                    virtualenv = NULL, 
                                    condaenv = NULL, 
                                    ask = NULL, 
                                    source_bash_profile = NULL,
                                    model = NULL) {
    # a user can specify only one
    if(sum(!is.null(c(python_executable, virtualenv, condaenv))) > 1) {
        stop(paste("Too many python environments are specified, please select only one",
                   "from python_executable, virtualenv, and condaenv"))
    }
    # give warning when nothing is specified
    else if (sum(!is.null(c(python_executable, virtualenv, condaenv))) == 1){
        if(!is.null(python_executable)) {
            if(check_spacy_model(python_executable, model) != "OK"){
                stop("spaCy or language model ", model, " is not installed in ", python_executable)
            }
            options(spacy_python_setting = list(type = "python_executable",
                                                py_path = python_executable))
        }
        else if(!is.null(virtualenv)) {
            options(spacy_python_setting = list(type = "virtualenv",
                                                py_path = virtualenv))
            
        }
        else if(!is.null(condaenv)) {
            options(spacy_python_setting = list(type = "condaenv",
                                                py_path = condaenv))
        }
    }
    else if (!is.null(options("spacy_python_setting")$spacy_python_setting)) {
        message("python path is already set\nspacyr will use: ", 
                options("spacy_python_setting")$spacy_python_setting$type, " = ",
                options("spacy_python_setting")$spacy_python_setting$py_path)
    }
    else {
        message("Finding a python executable with spacy installed...")
        spacy_python <- find_spacy(model, ask = ask, 
                                   source_bash_profile = source_bash_profile)
        if (is.null(spacy_python)) {
            stop("spaCy or language model ", model, " is not installed in any of python executables.")
        } else if(is.na(spacy_python)) {
            stop("No python was found on system PATH")
        } else {
            options(spacy_python_setting = list(type = "python_executable",
                                                py_path = spacy_python))
        }
    }
    return(NULL)
}