## copied and modified from tensorflow::install.R
## https://github.com/rstudio/tensorflow/blob/master/R/install.R


#' Install spacy
#'
#' @inheritParams reticulate::conda_list
#'
#' @param method 
#' 
#' @param conda the version of conda to be used
#' 
#' @param lang_models Language models to be installed. Default \code{en} (English model). 
#' A vector of multiple model names can be used (e.g. \code{c('en', 'de')})
#'
#' @param version Spacy version to install. Specify "latest" to install
#'   the latest release. 
#'
#'   You can also provide a full major.minor.patch specification (e.g. "1.1.0")
#'   
#' @param restart_session Restart R session after installing (note this will
#'   only occur within RStudio).
#' 
#' @param python_version determine python version for condaenv installation. 3.5 and 3.6 are available
#'
#' @param python_path supply path to python in virtualenv installation
#' 
#' @export
install_spacy <- function(method = c("virtualenv", "conda", "system"),
                          conda = "auto",
                          version = "latest",
                          lang_models = "en",
                          python_version = "3.6",
                          python_path = NULL,
                          restart_session = TRUE) {
    # verify os
    if (!is_windows() && !is_osx() && !is_linux()) {
        stop("This function is available only for Windows, Mac, and Linux")
    }
    
    # verify 64-bit
    # if (.Machine$sizeof.pointer != 8) {
    #     stop("Unable to install TensorFlow on this platform.",
    #          "Binary installation is only available for 64-bit platforms.")
    # }
    # 
    
    # resolve and validate method
    # method <- match.arg(method)
    if (identical(method, "system") && !is_windows()) {
        stop("Installing spaCy into the system library is only supported on Windows",
             call. = FALSE)
    }
    if (identical(method, "virtualenv") && is_windows()) {
        stop("Installing spaCy into a virtualenv is not supported on Windows",
             call. = FALSE)
    }
    
    # unroll version
    # ver <- parse_spacy_version(version)
    # version <- ver$version
    if(!identical(version, "latest")) {
        if(!(grepl("(\\d+\\.){1,2}(\\d+)?", version))){
            stop("spacy version specification error\n",
                 "Please provide a full major.minor.patch specification",
                 call. = FALSE)
        }
    }

    # flags indicating what methods are available
    method_available <- function(name) method %in% c("auto", name)
    virtualenv_available <- method_available("virtualenv")
    conda_available <- method_available("conda")
    system_available <- is_windows() && method_available("system")
    
    # resolve and look for conda
    conda <- tryCatch(conda_binary(conda), error = function(e) NULL)
    have_conda <- conda_available && !is.null(conda)
    
    # mac and linux
    if (is_unix()) {
        
        # check for explicit conda method
        if (identical(method, "conda")) {
            
            # validate that we have conda
            if (!have_conda)
                stop("Conda installation failed (no conda binary found)\n", call. = FALSE)
            
            # do install
            install_spacy_conda(conda, version, lang_models, python_version)
            
        } else {
            
            # find system python binary
            python <- if(!is.null(python_path)) python_path else python_unix_binary("python")
            if (is.null(python))
                stop("Unable to locate Python on this system.", call. = FALSE)
            
            # find other required tools
            pip <- python_unix_binary("pip")
            have_pip <- !is.null(pip)
            virtualenv <- python_unix_binary("virtualenv")
            have_virtualenv <- virtualenv_available && !is.null(virtualenv)
            
            # stop if either pip or virtualenv is not available
            if (!have_pip || !have_virtualenv) {
                install_commands <- NULL
                if (is_osx()) {
                    if (!have_pip)
                        install_commands <- c(install_commands, "$ sudo /usr/bin/easy_install pip")
                    if (!have_virtualenv) {
                        if (is.null(pip))
                            pip <- "/usr/local/bin/pip"
                        install_commands <- c(install_commands, sprintf("$ sudo %s install --upgrade virtualenv", pip))
                    }
                    if (!is.null(install_commands))
                        install_commands <- paste(install_commands, collapse = "\n")
                } else if (is_ubuntu()) {
                    if (!have_pip)
                        install_commands <- c(install_commands, "python-pip")
                    if (!have_virtualenv)
                        install_commands <- c(install_commands, "python-virtualenv")
                    if (!is.null(install_commands)) {
                        install_commands <- paste("$ sudo apt-get install",
                                                  paste(install_commands, collapse = " "))
                    }
                } else {
                    if (!have_pip)
                        install_commands <- c(install_commands, "pip")
                    if (!have_virtualenv)
                        install_commands <- c(install_commands, "virtualenv")
                    if (!is.null(install_commands)) {
                        install_commands <- paste("Please install the following Python packages before proceeding:",
                                                  paste(install_commands, collapse = ", "))
                    }
                }
                if (!is.null(install_commands)) {
                    
                    # if these are terminal commands then add special preface
                    if (grepl("^\\$ ", install_commands)) {
                        install_commands <- paste0(
                            "Execute the following at a terminal to install the prerequisites:\n\n",
                            install_commands
                        )
                    }
                    
                    stop("Prerequisites for installing spaCy not available.\n\n",
                         install_commands, "\n\n", call. = FALSE)
                }
            }
            install_spacy_virtualenv(python, virtualenv, version, lang_models)       
        }
        
        # windows installation
    } else {
        
        # determine whether we have system python
        python_versions <- py_versions_windows()
        python_versions <- python_versions[python_versions$type == "PythonCore",]
        python_versions <- python_versions[python_versions$version %in% c("3.5","3.6"),]
        python_versions <- python_versions[python_versions$arch == "x64",]
        have_system <- nrow(python_versions) > 0
        if (have_system)
            python_system_version <- python_versions[1,]
        
        # spacyr does not allow auto
        # if (identical(method, "auto")) {
        #     
        #     if (!have_system && !have_conda) {
        #         stop("spacyr only supports the installtion on a 64-bit version of Python 3.5 or 3.6\n\n",
        #              "Please install 64-bit Python 3.5 or 3.6 to continue, supported versions include:\n\n",
        #              " - Anaconda Python (Recommended): https://www.anaconda.com/download/#windows\n",
        #              " - Python Software Foundation   : https://www.python.org/downloads/\n\n",
        #              call. = FALSE)
        #     } else if (have_conda) {
        #         method <- "conda"
        #     } else if (have_system) {
        #         method <- "system"
        #     }
        # }
        # 
        if (identical(method, "conda")) {
            
            # validate that we have conda
            if (!have_conda) {
                stop("Conda installation failed (no conda binary found)\n\n",
                     "Install Anaconda 3.x for Windows (https://www.anaconda.com/download/#windows)\n",
                     "before installing spaCy",
                     call. = FALSE)
            }
            
            # do the install
            install_spacy_conda(conda, version, lang_models, python_version)
            
        } else if (identical(method, "system")) {
            
            # if we don't have it then error
            if (!have_system) {
                stop("spacyr only supports the installtion on a 64-bit version of Python 3.5 or 3.6\n\n",
                     "Please install 64-bit Python 3.5 or 3.6 this location to continue:\n\n",
                     " - https://www.python.org/downloads/\n\n",
                     call. = FALSE)
            }
            
            # do system installation
            python <- python_system_version$executable_path
            pip <- file.path(python_system_version$install_path, "Scripts", "pip.exe")
            install_tensorflow_windows_system(python, pip, version, gpu, packages)
            
        } else {
            stop("Invalid/unexpected installation method '", method, "'",
                 call. = FALSE)
        }
    }
    
    cat("\nInstallation complete.\n\n")
    
    if (restart_session && rstudioapi::hasFun("restartSession"))
        rstudioapi::restartSession()
    
    invisible(NULL)
}

install_spacy_conda <- function(conda, version, lang_models, python_version) {
    
    # create conda environment if we need to
    envname <- "spacy_condaenv"
    conda_envs <- conda_list(conda = conda)
    conda_env <- subset(conda_envs, conda_envs$name == envname)
    if (nrow(conda_env) == 1) {
        cat("Using", envname, "conda environment for spaCy installation\n")
        python <- conda_env$python
    }
    else {
        cat("Creating", envname, "conda environment for spaCy installation...\n")
        python_packages <- ifelse(is.null(python_version), "python=3.6", 
                                  sprintf("python=", python_version))
        python <- conda_create(envname, packages = python_packages, conda = conda)
    }
    
    # Short circuit to install everything with conda when no custom packages
    # (typically tf-nightly or a daily build URL) and no gpu-enabled build
    # is requested (conda doesn't currently have GPU enabled builds.
    #
    # This avoids any use of pip, which addresses the following issue:
    # https://github.com/rstudio/keras/issues/147
    #
    # This issue is in turn created by two other issues:
    #
    # 1) TensorBoard appears to rely on an older version of html5lib which is
    #    force installed, and which as a result breaks pip:
    #    https://github.com/tensorflow/tensorboard/issues/588
    #
    # 2) Anaconda 5.0.0 is unable to recover from this because the installation
    #    of the old version of html5lib actually propagates to the root
    #    environment, which permantely breaks pip for *all* conda environments:
    #    https://github.com/conda/conda/issues/6079
    #
    # Hopefully these two issues will be addressed and we can return to using
    # pip in all scenarios (as that is the officially supported version)
    #
    # if (is_windows() && is.null(packages)) {
    #     conda_forge_install(
    #         envname,
    #         spacy_pkgs(version),
    #         conda = conda
    #     )
    #     return(invisible(NULL))
    # }
    # 

    # install base spaCy using pip
    cat("Installing Spacy...\n")
    packages <- spacy_pkgs(version)
    conda_install(envname, packages, pip = TRUE, conda = conda)
    
    for(model in lang_models) spacy_download_lang_model_conda(model = model, condal = conda)
    
}


# conda_forge_install <- function(envname, packages, conda = "auto") {
#     
#     # resolve conda binary
#     conda <- conda_binary(conda)
#     
#     # use native conda package manager with conda forge enabled
#     result <- system2(conda, shQuote(c("install", "-c", "conda-forge", "--yes", "--name", envname, packages)))
#     
#     # check for errors
#     if (result != 0L) {
#         stop("Error ", result, " occurred installing packages into conda environment ",
#              envname, call. = FALSE)
#     }
#     
#     invisible(NULL)
# }



install_spacy_virtualenv <- function(python, virtualenv, version, lang_models) {
    
    # determine python version to use
    is_python3 <- python_version(python) >= "3.0"
    if(!is_python3) {
        stop("spacyr does not support virtual environment installation for python 2.*", call. = FALSE)
    }
    pip_version <- ifelse(is_python3, "pip3", "pip")
    
    # create virtualenv
    virtualenv_root <- Sys.getenv("WORKON_HOME", unset = "~/.virtualenvs")
    if (!file.exists(virtualenv_root))
        dir.create(virtualenv_root, recursive = TRUE)
    
    # helper to construct paths to virtualenv binaries
    virtualenv_bin <- function(bin) path.expand(file.path(virtualenv_path, "bin", bin))
    
    # create virtualenv if necessary
    virtualenv_path <- file.path(virtualenv_root, "spacy_virtualenv")
    if (!file.exists(virtualenv_path) || !file.exists(virtualenv_bin("activate"))) {
        cat("Creating virtualenv for spaCy at ", virtualenv_path, "\n")
        result <- system2(virtualenv, shQuote(c(
            #"--system-site-packages",
            "--python", python,
            path.expand(virtualenv_path)))
        )
        if (result != 0L)
            stop("Error ", result, " occurred creating virtualenv at ", virtualenv_path,
                 call. = FALSE)
    } else {
        cat("Using existing virtualenv at ", virtualenv_path, "\n")
    }
    
    # function to call pip within virtual env
    pip_install <- function(pkgs, message) {
        cmd <- sprintf("%ssource %s && %s install --ignore-installed --upgrade %s%s",
                       ifelse(is_osx(), "", "/bin/bash -c \""),
                       shQuote(path.expand(virtualenv_bin("activate"))),
                       shQuote(path.expand(virtualenv_bin(pip_version))),
                       paste(shQuote(pkgs), collapse = " "),
                       ifelse(is_osx(), "", "\""))
        cat(message, "...\n")
        result <- system(cmd)
        if (result != 0L)
            stop("Error ", result, " occurred installing spaCy", call. = FALSE)
    }
    
    # upgrade pip so it can find spaCy
    pip_install("pip", "Upgrading pip")
    
    # install updated version of the wheel package
    pip_install("wheel", "Upgrading wheel")
    
    # upgrade setuptools so it can use wheels
    pip_install("setuptools", "Upgrading setuptools")
    
    # install tensorflow and related dependencies
    pkgs <- spacy_pkgs(version)
    pip_install(pkgs, "Installing spaCy")
    
    for(model in lang_models) {
        spacy_download_lang_model_virtualenv(model = model)
    }
}


install_tensorflow_windows_system <- function(python, pip, version, gpu, packages) {
    
    # ensure pip is up to date
    cat("Preparing for installation (updating pip if necessary)\n")
    result <- system2(python, c("-m", "pip", "install", "--upgrade", "pip"))
    if (result != 0L)
        stop("Error ", result, " occurred updating pip", call. = FALSE)
    
    # install tensorflow and dependencies (don't install scipy b/c it requires
    # native code compilation)
    cat("Installing TensorFlow...\n")
    pkgs <- spacy_pkgs(version)
    result <- system2(pip, c("install", "--upgrade --ignore-installed",
                             paste(shQuote(pkgs), collapse = " ")))
    if (result != 0L)
        stop("Error ", result, " occurred installing tensorflow package", call. = FALSE)
    
    cat("\nInstallation of TensorFlow complete.\n\n")
}


python_unix_binary <- function(bin) {
    locations <- file.path(c("/usr/bin", "/usr/local/bin"), bin)
    locations <- locations[file.exists(locations)]
    if (length(locations) > 0)
        locations[[1]]
    else
        NULL
}

python_version <- function(python) {
    
    # check for the version
    result <- system2(python, "--version", stdout = TRUE, stderr = TRUE)
    
    # check for error
    error_status <- attr(result, "status")
    if (!is.null(error_status))
        stop("Error ", error_status, " occurred while checking for python version", call. = FALSE)
    
    # parse out the major and minor version numbers
    matches <- regexec("^[^ ]+\\s+(\\d+)\\.(\\d+).*$", result)
    matches <- regmatches(result, matches)[[1]]
    if (length(matches) != 3)
        stop("Unable to parse Python version '", result[[1]], "'", call. = FALSE)
    
    # return as R numeric version
    numeric_version(paste(matches[[2]], matches[[3]], sep = "."))
}


# form list of tf pkgs
spacy_pkgs <- function(version, packages = NULL) {
    if (is.null(packages))
        packages <- sprintf("spacy%s",
                            ifelse(version == "latest", "", paste0("==", version)))
    return(packages)
}

# # additional dependencies to install (required by some features of keras)
# tf_extra_pkgs <- function(scipy = TRUE, extra_packages = NULL) {
#     pkgs <- c("h5py", "pyyaml",  "requests",  "Pillow")
#     pkgs <- c(pkgs, extra_packages)
#     if (scipy)
#         c(pkgs, "scipy")
#     else
#         pkgs
# }



# 
# virtualenv_install <- function(envname, packages) {
#     
#     # TODO: refactor to share code between this and install_tensorflow_virtualenv
#     # (we added this code late in the v1.0 cycle so didn't want to do the
#     # refactor then)
#     
#     # determine path to virtualenv
#     virtualenv_root <- Sys.getenv("WORKON_HOME", unset = "~/.virtualenvs")
#     virtualenv_path <- file.path(virtualenv_root, envname)
#     
#     # helper to construct paths to virtualenv binaries
#     virtualenv_bin <- function(bin) path.expand(file.path(virtualenv_path, "bin", bin))
#     
#     # determine pip version to use
#     python <- virtualenv_bin("python")
#     is_python3 <- python_version(python) >= "3.0"
#     pip_version <- ifelse(is_python3, "pip3", "pip")
#     
#     # build and execute install command
#     cmd <- sprintf("%ssource %s && %s install --ignore-installed --upgrade %s%s",
#                    ifelse(is_osx(), "", "/bin/bash -c \""),
#                    shQuote(path.expand(virtualenv_bin("activate"))),
#                    shQuote(path.expand(virtualenv_bin(pip_version))),
#                    paste(shQuote(packages), collapse = " "),
#                    ifelse(is_osx(), "", "\""))
#     result <- system(cmd)
#     if (result != 0L)
#         stop("Error ", result, " occurred installing packages", call. = FALSE)
# }
# 
# 
# windows_system_install <- function(python, packages) {
#     
#     # TODO: refactor to share code with install_tensorflow_windows_system
#     
#     # determine pip location from python binary location
#     pip <- file.path(dirname(python), "Scripts", "pip.exe")
#     
#     # execute the installation
#     result <- system2(pip, c("install", "--upgrade --ignore-installed",
#                              paste(shQuote(packages), collapse = " ")))
#     if (result != 0L)
#         stop("Error ", result, " occurred installing tensorflow package", call. = FALSE)
# }
# 

## checking os


is_windows <- function() {
    identical(.Platform$OS.type, "windows")
}

is_unix <- function() {
    identical(.Platform$OS.type, "unix")
}

is_osx <- function() {
    Sys.info()["sysname"] == "Darwin"
}

is_linux <- function() {
    identical(tolower(Sys.info()[["sysname"]]), "linux")
}

