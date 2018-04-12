#' Initialize spaCy
#' 
#' Initialize spaCy to call from R. 
#' @return NULL
#' @param model Language package for loading spaCy. Example: \code{en} (English) and
#' \code{de} (German). Default is \code{en}.
#' @param python_executable the full path to the Python excutable, for which
#'   spaCy is installed
#' @param ask logical; if \code{FALSE}, use the first spaCy installation found;
#'   if \code{TRUE}, list available spaCy installations and prompt the user for
#'   which to use. If another (e.g. \code{python_executable}) is set, then this
#'   value will always be treated as \code{FALSE}.
#' @param virtualenv set a path to the Python virtual environment with spaCy
#'   installed Example: \code{virtualenv = "~/myenv"}
#' @param condaenv set a path to the anaconda virtual environment with spaCy
#'   installed Example: \code{condalenv = "myenv"}
#' @param entity logical; if \code{FALSE} is selected, named entity recognition
#'   is turned off in spaCy. This will speed up the parsing as it will exclude
#'   \code{ner} from the pipeline. For details of spaCy pipeline, see
#'   \url{https://spacy.io/usage/processing-pipelines}. The option \code{FALSE}
#'   is available only for spaCy version 2.0.0 or higher.
#' @param check_env logical; check whether conda/virtual environment generated
#'   by \code{spacyr_istall()} exists
#' @param refresh_settings logical; if \code{TRUE}, spacyr will ignore the seved
#'   settings in the profile and initiate a search of new settings.
#' @param save_profile logical; if \code{TRUE}, the current spaCy setting will
#'   be saved for the future use.
#' @export
#' @author Akitaka Matsuo
spacy_initialize <- function(model = "en", 
                             python_executable = NULL,
                             virtualenv = NULL,
                             condaenv = NULL, 
                             ask = FALSE,
                             refresh_settings = FALSE,
                             save_profile = FALSE,
                             check_env = TRUE, 
                             entity = TRUE) {

    # here are a number of checkings
    if (!is.null(options("spacy_initialized")$spacy_initialized)) {
        message("spaCy is already initialized")
        return(NULL)
    }
    # set an option for source_bash_profile
    # source_bash_profile is retired
    # if(is.null(source_bash_profile)) {
    #     if(is_windows()){
    #         source_bash_profile <- FALSE
    #     } else {
    #         source_bash_profile <- TRUE
    #     }
    # }
    

    
    # once python is initialized, you cannot change the python executables
    if (!is.null(options("python_initialized")$python_initialized)) {
        message("Python space is already attached.  If you want to switch to a different Python, please restart R.")
    }
    # NEW: if spacy_condaenv exists use it
    else {
        set_spacy_python_option(python_executable,
                                virtualenv,
                                condaenv,
                                check_env,
                                refresh_settings,
                                ask,
                                model)
    }

    ## check settings and start reticulate python
    settings <- check_spacy_python_options()
    if (!is.null(settings)) {
        ####
        if (settings$key == "spacy_python_executable") {
            if (check_spacy_model(settings$val, model) != "OK") {
                stop("spaCy or language model ", model, " is not installed in ", settings$val)
            }
            reticulate::use_python(settings$val, required = TRUE)
        }
        else if (settings$key == "spacy_virtualenv") reticulate::use_virtualenv(settings$val, required = TRUE)
        else if (settings$key == "spacy_condaenv") {
            #spacy_upgrade(lang_models = model)
            reticulate::use_condaenv(settings$val, required = TRUE)
        }
    }
    options("python_initialized" = TRUE) # next line could cause non-recoverable error 
    spacyr_pyexec(pyfile = system.file("python", "spacyr_class.py",
                                       package = "spacyr"))
    
    spacyr_pyassign("model", model)
    spacyr_pyassign("spacy_entity", entity)
    options("spacy_entity" = entity)
    spacyr_pyexec(pyfile = system.file("python", "initialize_spacyPython.py",
                                       package = "spacyr"))

    spacy_version <- spacyr_pyget("versions")$spacy
    if(entity == FALSE && as.integer(substr(spacy_version, 1, 1)) < 2){
        message("entity == FALSE is only available for spaCy version 2.0.0 or higher")
        options("spacy_entity" = TRUE)
    }
    message("successfully initialized (spaCy Version: ", spacy_version, ", language model: ", model, ")")
    settings <- check_spacy_python_options()
    message('(python options: type = "', sub("spacy_", "", settings$key), '", value = "', settings$val, '")')
    options("spacy_initialized" = TRUE)
    
    if(save_profile == TRUE){
        save_spacy_options(settings$key, settings$val)    
    }
}

#' Finalize spaCy
#' 
#' While running spaCy on Python through R, a Python process is always running
#' in the backgroud and rsession will take up a lot of memory (typically over
#' 1.5GB). \code{spacy_finalize()} terminates the Python process and frees up
#' the memory it was using.
#' @return NULL
#' @export
#' @author Akitaka Matsuo
spacy_finalize <- function() {
    if (is.null(getOption("spacy_initialized"))) {
        stop("Nothing to finalize. spaCy is not initialized")
    }
    spacyr_pyexec(pyfile = system.file("python", "finalize_spacyPython.py",
                                       package = "spacyr"))
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
#'  
#' @keywords internal
#' @importFrom data.table data.table
find_spacy <- function(model = "en", ask){
    spacy_found <- `:=` <- NA
    spacy_python <- NULL
    options(warn = -1)
    # if(source_bash_profile == TRUE & is_windows()){
    #     message("the option, source_bash_profile == TRUE, will be ignored for windows system")
    # }
    py_execs <- if(is_windows()) {
        system2("where", "python", stdout = TRUE)
    } else if(is_osx() && file.exists("~/.bash_profile")) {
        c(system2("source", "~/.bash_profile; which -a python", stdout = TRUE),
          system2("source", "~/.bash_profile; which -a python3", stdout = TRUE))
    } else {
        c(system2("which", "-a python", stdout = TRUE),
          system2("which", "-a python3", stdout = TRUE))
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
        if (sys_message == "OK") {
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
        # message(paste(seq_along(spacy_pythons), spacy_pythons, sep = ": ", collapse = "\n"))
        # number <- NA
        # while (is.na(number)) {
        #     number <- readline(prompt = "Please select python: ")
        #     number <- as.integer(number)
        #     if (is.na(number) | number < 1 | number > length(spacy_pythons)) {
        #         number <- NA
        #     }
        # }
        number <- utils::menu(spacy_pythons, title = "Please select python:")
        if(number == 0) {
            stop("Initialization was canceled by user", call. = FALSE)
        }
        spacy_python <- spacy_pythons[number]
        message("spacyr will use: ", spacy_python)
    }
    return(spacy_python)
}    


#' Find spaCy env
#' 
#' check whether conda/virtual environment for spaCy exists
#' @export
#'  
#' @keywords internal
find_spacy_env <- function(){
    if(is.null(tryCatch(reticulate::conda_binary("auto"), error = function(e) NULL))){
        return(FALSE)        
    }
    found <- if("spacy_condaenv" %in% reticulate::conda_list(conda = "auto")$name) {
        TRUE
    } else if(file.exists(file.path( "~/.virtualenvs", "spacy_virtualenv", "bin", "activate"))) {
        TRUE
    } else {
        FALSE
    }
    return(found)
}
    

check_spacy_model <- function(py_exec, model) {
    options(warn = -1)
    py_exist <- if(is_windows()) {
        if(py_exec %in% system2("where", "python", stdout = TRUE)) {
            py_exec
        } else {
            NULL
        }
    } else {
        system2("which", py_exec, stdout = TRUE)
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
                                    check_env = TRUE,
                                    refresh_settings = FALSE,
                                    ask = NULL, 
                                    model = NULL) {
    if(refresh_settings) clear_spacy_options()
    
    if (!is.null(check_spacy_python_options())) {
        settings <- check_spacy_python_options()
        message("spacy python option is already set, spacyr will use:\n\t",
                sub("spacy_", "", settings$key), ' = "', settings$val, '"')
    } else if(check_env && 
              !(is.null(tryCatch(reticulate::conda_binary("auto"), error = function(e) NULL))) && 
              "spacy_condaenv" %in% reticulate::conda_list(conda = "auto")$name) {
        message("Found 'spacy_condaenv'. spacyr will use this environment")
        clear_spacy_options()
        options(spacy_condaenv = "spacy_condaenv")
    }
    else if(check_env && file.exists(file.path( "~/.virtualenvs", "spacy_virtualenv", "bin", "activate"))) {
        message("Found 'spacy_virtualenv'. spacyr will use this environment")
        clear_spacy_options()
        options(spacy_virtualenv = "~/.virtualenvs/spacy_virtualenv")
    }
    # a user can specify only one
    else if(sum(!is.null(c(python_executable, virtualenv, condaenv))) > 1) {
        stop(paste("Too many python environments are specified, please select only one",
                   "from python_executable, virtualenv, and condaenv"))
    }
    # give warning when nothing is specified
    else if (sum(!is.null(c(python_executable, virtualenv, condaenv))) == 1){
        if(!is.null(python_executable)) {
            if(check_spacy_model(python_executable, model) != "OK"){
                stop("spaCy or language model ", model, " is not installed in ", python_executable)
            }
            clear_spacy_options()
            options(spacy_python_executable = python_executable)
        }
        else if(!is.null(virtualenv)) {
            clear_spacy_options()
            options(spacy_virtualenv = virtualenv)
        }
        else if(!is.null(condaenv)) {
            clear_spacy_options()
            options(spacy_condaenv = condaenv)
        }
    } else {
        message("Finding a python executable with spaCy installed...")
        spacy_python <- find_spacy(model, ask = ask)
        if (is.null(spacy_python)) {
            stop("spaCy or language model ", model, " is not installed in any of python executables.")
        } else if(is.na(spacy_python)) {
            stop("No python was found on system PATH")
        } else {
            options(spacy_python_executable = spacy_python)
        }
    }
    return(NULL)
}

clear_spacy_options <- function(){
    options(spacy_python_executable = NULL)
    options(spacy_condaenv = NULL)
    options(spacy_virtualenv = NULL)
}

check_spacy_python_options <- function() {
    settings <- NULL
    for(k in c("spacy_python_executable",
               "spacy_condaenv",
               "spacy_virtualenv")) {
        if(!is.null(getOption(k))) {
            settings$key <- k
            settings$val <- getOption(k)
        }
    }
    return(settings)
}

save_spacy_options <- function(key, val) {
    prof_file <- "~/.Rprofile"
    # prof_file_bak <- sprintf("%s_bak%s", prof_file, as.numeric(Sys.time()))
    # file.copy(prof_file, prof_file_bak)
    # ans <- utils::menu(c("No", "Yes"), title = "Proceed?")
    
    ans <- utils::menu(c("No", "Yes"), title = sprintf('Do you want to set the option, \'%s = "%s"\' , as a default (y|[n])? ', 
                                    key, val))
    if(ans == 2) {
        rprofile <- if (file.exists(prof_file)) readLines(prof_file) else NULL
        rprofile <- grep("options\\(\\s*spacy_.+\\)", rprofile, value = TRUE, invert = TRUE)
        rprofile <- c(rprofile, sprintf('options(%s = "%s")', key, val))
        write(rprofile, file = prof_file)
        message("The option was saved. The option will be used in spacy_initialize() in future")  
    } else {
        message("The option was not saved (user cancelled)")
    }

}

