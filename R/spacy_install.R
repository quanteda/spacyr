# copied and modified from tensorflow::install.R, https://github.com/rstudio/tensorflow/blob/master/R/install.R

#' Install spaCy in conda or virtualenv environment
#'
#' @description Install spaCy in a self-contained environment, including
#'   specified language models.  For macOS and Linux-based systems, this will
#'   also install Python itself via a "miniconda" environment, for
#'   \code{spacy_install}.  Alternatively, an existing conda installation may be
#'   used, by specifying its path.  The default setting of \code{"auto"} will
#'   locate and use an existing installation automatically, or download and
#'   install one if none exists.  
#'   
#'   For Windows, automatic installation of miniconda installation is not currently
#'   available, so the user will need to \href{https://conda.io/projects/conda/en/latest/user-guide/install/index.html}{miniconda (or Anaconda) manually}.
#'
#' @section spaCy Version Issues:
#' 
#'   The version options currently default to the latest spaCy v2 (\code{version
#'   = "latest"}). As of 2018-04, however,
#'   \href{https://github.com/explosion/spaCy/issues/1508}{some performance
#'   issues} affect the speed of the spaCy pipeline for spaCy v2.x relative to
#'   v1.x.   This can  enormously affect the performance of
#'   \code{spacy_parse()}, especially when a large number of small texts are
#'   parsed. For this reason, the \pkg{spacyr} provides an option to
#'   automatically install the latest version of spaCy v1.*, using \code{version
#'   = "latest_v1"}.
#'   
#' @inheritParams reticulate::conda_list
#' @param conda character; path to conda executable. Default "auto" which
#'   automatically find the path
#' @param pip \code{TRUE} to use pip for installing spacy. If \code{FALSE}, conda 
#' package manager with conda-forge channel will be used for installing spacy.
#' @param lang_models character; language models to be installed. Default
#'   \code{en} (English model). A vector of multiple model names can be used
#'   (e.g. \code{c("en", "de")}).  A list of available language models and their
#'   names is available from the \href{https://spacy.io/usage/models}{spaCy
#'   language models} page.
#' @param version character; spaCy version to install. Specify \code{"latest"}
#'   to install the latest release, or \code{"latest_v1"} to install the latest 
#'   release of spaCy v1.*.  See spaCy Version Issues.
#'
#'   You can also provide a full major.minor.patch specification (e.g. "1.1.0")
#' @param python_version character; determine Python version for condaenv
#'   installation. 3.5 and 3.6 are available.
#' @param python_path character; path to Python in virtualenv installation
#' @param envname character; name of the conda-environment to install spaCy. 
#'   Default is "spacy_condaenv".
#' @param prompt logical; ask whether to proceed during the installation
#' @examples 
#' \dontrun{
#' # install spaCy in a miniconda environment (macOS and Linux)
#' spacy_install(lang_models = c("en", "de"), prompt = FALSE)
#' 
#' # install spaCy to an existing conda environment
#' spacy_install(conda = "~/anaconda/bin/")
#' }
#' 
#' @export
spacy_install <- function(conda = "auto",
                          version = "latest",
                          lang_models = "en",
                          python_version = "3.6",
                          envname = "spacy_condaenv",
                          pip = FALSE,
                          python_path = NULL,
                          prompt = TRUE) {
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

    if (!(identical(version, "latest") || identical(version, "latest_v1"))) {
        if (!(grepl("^[1-9]\\.\\d{1,2}\\.\\d{1,2}\\b", version))){
            stop("spacy version specification error\n",
                 "Please provide a full major.minor.patch specification",
                 call. = FALSE)
        }
    }

    # resolve and look for conda
    conda <- tryCatch(reticulate::conda_binary(conda), error = function(e) NULL)
    have_conda <- !is.null(conda)

    # mac and linux
    if (is_unix()) {

        # check for explicit conda method

            # validate that we have conda
            if (!have_conda) {
                cat("No conda was found in the system. ")
                ans <- utils::menu(c("No", "Yes"), title = "Do you want spacyr to download miniconda in ~/miniconda?")
                if (ans == 2) {
                  install_miniconda()
                  conda <- tryCatch(reticulate::conda_binary("auto"), error = function(e) NULL)
                } else stop("Conda environment installation failed (no conda binary found)\n", call. = FALSE)
            }

            # process the installation of spacy
            process_spacy_installation_conda(conda, version, lang_models,
                                             python_version, prompt,
                                             envname = envname, pip = pip)

    # windows installation
    } else {

        # determine whether we have system python
        python_versions <- reticulate::py_versions_windows()
        python_versions <- python_versions[python_versions$type == "PythonCore", ]
        python_versions <- python_versions[python_versions$version %in% c("3.5", "3.6"), ]
        python_versions <- python_versions[python_versions$arch == "x64", ]
        have_system <- nrow(python_versions) > 0
        if (have_system)
            python_system_version <- python_versions[1, ]

        # validate that we have conda
        if (!have_conda) {
            stop("Conda installation failed (no conda binary found)\n\n",
                 "Install Anaconda 3.x for Windows (https://www.anaconda.com/download/#windows)\n",
                 "before installing spaCy",
                 call. = FALSE)
        }

        # process the installation of spacy
        process_spacy_installation_conda(conda, version, lang_models,
                                         python_version, prompt,
                                         envname = envname, pip = pip)

    }
    message("\nInstallation complete.\n",
            sprintf("Condaenv: %s; Language model(s): ", envname), lang_models, "\n")

    invisible(NULL)
}

#' @rdname spacy_install
#' @description If you wish to install Python ion a "virtualenv", use the
#'   \code{spacy_install_virtualenv} function.
#' @examples
#' \dontrun{
#' # install spaCy in a virtualenv environment
#' spacy_install_virtualenv(lang_models = c("en"))
#' }
#' @export
spacy_install_virtualenv <- function(version = "latest",
                                     lang_models = "en",
                                     python_version = "3.6",
                                     python_path = NULL,
                                     prompt = TRUE) {
    # verify os
    if (!is_osx() && !is_linux()) {
        stop("This function is available only for Mac and Linux", call. = FALSE)
    }

    if (!(identical(version, "latest") || identical(version, "latest_v1"))) {
        if (!(grepl("(\\d+\\.){1,2}(\\d+)?", version))){
            stop("spaCy version specification error\n",
                 "Please provide a full major.minor.patch specification",
                 call. = FALSE)
        }
    }

    # mac and linux

    # check for explicit conda method

    # find system python binary
    python <- if (!is.null(python_path)) python_path else python_unix_binary("python")
    if (is.null(python))
        stop("Unable to locate Python on this system.", call. = FALSE)

    # find other required tools
    pip <- python_unix_binary("pip")
    have_pip <- !is.null(pip)
    virtualenv <- python_unix_binary("virtualenv")
    have_virtualenv <- !is.null(virtualenv)

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
                    "Execute the following at a terminal to install the prerequisites:\n",
                    install_commands
                )
            }

            stop("Prerequisites for installing spaCy not available.\n\n",
                 install_commands, "\n\n", call. = FALSE)
        }
    }
    process_spacy_installation_virtualenv(python, virtualenv, version, lang_models, prompt)

    cat("\nInstallation complete.\n\n")

    invisible(NULL)
}

process_spacy_installation_conda <- function(conda, version, lang_models, python_version,
                                             prompt = TRUE,
                                             envname = "spacy_condaenv",
                                             pip = FALSE) {

    conda_envs <- reticulate::conda_list(conda = conda)
    if (prompt) {
        ans <- utils::menu(c("No", "Yes"), title = "Proceed?")
        if (ans == 1) stop("condaenv setup is cancelled by user", call. = FALSE)
    }
    conda_env <- subset(conda_envs, conda_envs$name == envname)
    if (nrow(conda_env) == 1) {
        cat("Using existing conda environment ", envname, " for spaCy installation\n.",
            "\nspaCy and language model(s):",
            paste(lang_models, collapse = ", "), "will be installed.  ")
        python <- conda_env$python
    }
    else {
        cat("A new conda environment", paste0('"', envname, '"'), "will be created and \nspaCy and language model(s):",
            paste(lang_models, collapse = ", "), "will be installed.  ")
        cat("Creating", envname, "conda environment for spaCy installation...\n")
        python_packages <- ifelse(is.null(python_version), "python=3.6",
                                  sprintf("python=%s", python_version))
        python <- reticulate::conda_create(envname, packages = python_packages, conda = conda)
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

    # this function generates a forced pip error to get a version spaCy highest within a major version
    # e.g. if major_version == 1, it will return 1.10.1
    pip_get_version_conda <- function(major_version) {
        condaenv_bin <- function(bin) path.expand(file.path(dirname(conda), bin))
        cmd <- sprintf("%s%s %s && pip install --upgrade %s %s%s",
                       ifelse(is_windows(), "", ifelse(is_osx(), "source ", "/bin/bash -c \"source ")),
                       shQuote(path.expand(condaenv_bin("activate"))),
                       envname,
                       "--ignore-installed",
                       paste(shQuote("spacy==random"), collapse = " "),
                       ifelse(is_windows(), "", ifelse(is_osx(), "", "\"")))
        pip_get_version(cmd = cmd, major_version = major_version)
    }
    # install base spaCy using pip
    if (version == "latest_v1") {
        version <- ifelse(pip, pip_get_version_conda(1),
                          conda_get_version(1, conda, envname))
        cat("Option \"version = version_v1\" is supplied, spaCy", version, "will be installed\n")
    }
    cat("Installing spaCy...\n")
    packages <- spacy_pkgs(version)
    reticulate::conda_install(envname, packages, pip = pip, conda = conda)

    for (model in lang_models) spacy_download_langmodel(model = model, conda = conda,
                                                        envname = envname)

}

process_spacy_installation_virtualenv <- function(python, virtualenv, version, lang_models, prompt = TRUE) {

    # determine python version to use
    is_python3 <- python_version(python) >= "3.0"
    if (!is_python3) {
        stop("spacyr does not support virtual environment installation for python 2.*", call. = FALSE)
    }
    pip_version <- ifelse(is_python3, "pip3", "pip")

    virtualenv_root <- Sys.getenv("WORKON_HOME", unset = "~/.virtualenvs")
    virtualenv_path <- file.path(virtualenv_root, "spacy_virtualenv")

    cat(sprintf('A new virtual environment "%s" will be created and, \nspaCy and language model(s), "%s", will be installed.\n ',
                virtualenv_path,
                paste(lang_models, collapse = ", ")))
    if (prompt) {
        ans <- utils::menu(c("No", "Yes"), title = "Proceed?")
        if (ans == 1) stop("Virtualenv setup is cancelled by user", call. = FALSE)
    }

    # create virtualenv
    if (!file.exists(virtualenv_root))
        dir.create(virtualenv_root, recursive = TRUE)

    # helper to construct paths to virtualenv binaries
    virtualenv_bin <- function(bin) path.expand(file.path(virtualenv_path, "bin", bin))

    # create virtualenv if necessary
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

    # this function generates a forced pip error to get a version spaCy highest within a major version
    # e.g. if major_version == 1, it will return 1.10.1
    pip_get_version_virtualenv <- function(major_version) {
        cmd <- sprintf("%ssource %s && %s install --ignore-installed --upgrade %s%s",
                       ifelse(is_osx(), "", "/bin/bash -c \""),
                       shQuote(path.expand(virtualenv_bin("activate"))),
                       shQuote(path.expand(virtualenv_bin(pip_version))),
                       paste(shQuote("spacy==random"), collapse = " "),
                       ifelse(is_osx(), "", "\""))
        pip_get_version(cmd, major_version)
    }

    # upgrade pip so it can find spaCy
    pip_install("pip", "Upgrading pip")

    # install updated version of the wheel package
    pip_install("wheel", "Upgrading wheel")

    # upgrade setuptools so it can use wheels
    pip_install("setuptools", "Upgrading setuptools")

    if (version == "latest_v1") {
        version <- pip_get_version_virtualenv(1, major_version = 1)
        cat("Option \"version = version_v1\" is supplied, spaCy", version, "will be installed\n")
    }
    pkgs <- spacy_pkgs(version)
    pip_install(pkgs, "Installing spaCy...")

    for (model in lang_models) {
        spacy_download_langmodel_virtualenv(model = model)
    }
}

python_unix_binary <- function(bin) {
    locations <- file.path(c( "/usr/local/bin", "/usr/bin"), bin)
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

#' Uninstall spaCy conda environment
#'
#' Removes the conda environment created by spacy_install()
#' @inheritParams reticulate::conda_list
#' @param conda Path to conda executable, default to "auto" which automatically
#'   finds the path
#' @param prompt logical; ask whether to proceed during the installation
#' @param envname character; name of conda environment to remove
#' @export
spacy_uninstall <- function(conda = "auto",
                            prompt = TRUE,
                            envname = "spacy_condaenv") {
    conda <- tryCatch(reticulate::conda_binary(conda), error = function(e) NULL)
    have_conda <- !is.null(conda)

    if (!have_conda)
        stop("Conda installation failed (no conda binary found)\n", call. = FALSE)

    conda_envs <- reticulate::conda_list(conda = conda)
    conda_env <- subset(conda_envs, conda_envs$name == envname)
    if (nrow(conda_env) != 1) {
        stop("conda environment", envname, "is not found", call. = FALSE)
    }
    cat("A conda environment", envname, "will be removed\n")
    ans <- ifelse(prompt, utils::menu(c("No", "Yes"), title = "Proceed?"), 2)
    if (ans == 1) stop("condaenv removal is cancelled by user", call. = FALSE)
    python <- reticulate::conda_remove(envname = envname)

    cat("\nUninstallation complete.\n\n")

    invisible(NULL)
}


#' Upgrade spaCy in conda environment
#'
#' @inheritParams reticulate::conda_list
#' @param conda Path to conda executable. Default "auto" which automatically
#'   find the path
#' @param pip \code{TRUE} to use pip for installing spacy. If \code{FALSE}, conda 
#' package manager with conda-forge channel will be used for installing spacy.

#' @param lang_models Language models to be upgraded. Default NULL (No upgrade). 
#'   A vector of multiple model names can be used (e.g. \code{c("en", "de")})
#' @param prompt logical; ask whether to proceed during the installation
#' @param envname character; name of conda environment to upgrade spaCy
#' @export
spacy_upgrade  <- function(conda = "auto",
                           envname = "spacy_condaenv",
                           prompt = TRUE,
                           pip = FALSE,
                           lang_models = "en") {

    message("checking spaCy version")
    conda <- reticulate::conda_binary(conda)
    if (!(envname %in% reticulate::conda_list(conda = conda)$name)) {
        message("Conda evnronment", envname, "does not exist")
    }

    condaenv_bin <- function(bin) path.expand(file.path(dirname(conda), bin))
    cmd <- sprintf("%s%s %s && pip search spacy%s",
                   ifelse(is_windows(), "", ifelse(is_osx(), "source ", "/bin/bash -c \"source ")),
                   shQuote(path.expand(condaenv_bin("activate"))),
                   envname,
                   ifelse(is_windows(), "", ifelse(is_osx(), "", "\"")))
    result <- system(cmd, intern = TRUE, ignore.stderr = TRUE)
    spacy_index <- grep("^spacy \\(", result)
    latest_spacy <- sub("spacy \\((.+?)\\).+", "\\1", result[spacy_index])
    installed_spacy <- sub(".+?(\\d.+\\d).*", "\\1", result[spacy_index + 1])
    if (!pip) {
        latest_spacy <- conda_get_version(major_version = NA, conda, envname)
    }
    if (latest_spacy == installed_spacy) {
        message("Your spaCy version is the latest available.")
        return(invisible(NULL))
    } else if (substr(installed_spacy, 0, 2) == "1.") {
        cat(sprintf("The version spacy installed is %s\n",
                    installed_spacy))
        ans <- if (prompt) utils::menu(c("v1.*", "v2.*"), title = sprintf("Do you want to upgrade to v1.* or lastest v2.*?")) else 2
        if (ans == 2) {
            cat("spaCy will be upgraded to version", latest_spacy, "\n")
            process_spacy_installation_conda(conda = conda,
                                             envname = envname,
                                             version = "latest",
                                             lang_models = lang_models,
                                             python_version = "3.6",
                                             prompt = FALSE)
            message("\nSuccessfully upgraded\n",
                    sprintf("Condaenv: %s; Langage model(s): ", envname), lang_models, "\n")
        } else {
            if (pip == TRUE) {
                cmd <- sprintf("%s%s %s && pip install --upgrade %s %s%s",
                               ifelse(is_windows(), "", ifelse(is_osx(), "source ", "/bin/bash -c \"source ")),
                               shQuote(path.expand(condaenv_bin("activate"))),
                               envname,
                               "--ignore-installed",
                               paste(shQuote("spacy==random"), collapse = " "),
                               ifelse(is_windows(), "", ifelse(is_osx(), "", "\"")))
                latest_spacy_v1 <- pip_get_version(cmd, major_version = 1)
            } else {
                latest_spacy_v1 <- conda_get_version(major_version = 1, conda, envname)
            }
            if (latest_spacy_v1 == installed_spacy){
                message("your spaCy is the latest v1")
                return(invisible(NULL))
            } else {
                cat(sprintf("A new version of spaCy v1 (%s) will be installed (installed version: %s)\n",
                            latest_spacy_v1, installed_spacy))
                process_spacy_installation_conda(conda = conda,
                                                 envname = envname,
                                                 version = "latest_v1",
                                                 lang_models = lang_models,
                                                 python_version = "3.6",
                                                 prompt = FALSE,
                                                 pip = pip)
            }
        }
    } else {
        cat(sprintf("A new version of spaCy (%s) was found (installed version: %s)\n",
                    latest_spacy, installed_spacy))
        ans <- if (prompt) utils::menu(c("No", "Yes"), title = sprintf("Do you want to upgrade?")) else 2
        if (ans == 2) {
            cat('"Yes" was chosen. spaCy will be upgraded.\n\n')
            if (!is.null(lang_models)) {
                ans <- ifelse(prompt, utils::menu(c("No", "Yes"),
                                                  title = sprintf("Do you also want to re-download language model %s?",
                                                  paste(lang_models, collapse = ", "))), 2)
                if (ans == 1) lang_models <- NULL
            }
            process_spacy_installation_conda(conda = conda,
                                             envname = envname,
                                             version = "latest",
                                             lang_models = lang_models,
                                             python_version = "3.6",
                                             prompt = FALSE,
                                             pip = pip)
            message("\nSuccessfully upgraded\n",
                    sprintf("Condaenv: %s; Langage model(s): ", envname), lang_models, "\n")

        } else {
            message("No upgrade is chosen")
        }

    }

    invisible(NULL)
}

install_miniconda <- function() {
    if (is_osx()) {
        message("Downloading installation script")
        system(paste(
            "curl https://repo.continuum.io/miniconda/Miniconda3-latest-MacOSX-x86_64.sh -o ~/miniconda.sh;",
            "echo \"Running installation script\";",
            "bash ~/miniconda.sh -b -p $HOME/miniconda"))
        system('echo \'export PATH="$PATH:$HOME/miniconda/bin"\' >> $HOME/.bash_profile; rm ~/miniconda.sh')
        message("Installation of miniconda complete")
    } else if (is_linux()) {
        message("Downloading installation script")
        system(paste(
            "wget -nv https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh;",
            "echo \"Running installation script\";",
            "bash ~/miniconda.sh -b -p $HOME/miniconda"))
        system('echo \'export PATH="$PATH:$HOME/miniconda/bin"\' >> $HOME/.bashrc; rm ~/miniconda.sh')
        message("Installation of miniconda complete")
    } else {
        stop("miniconda installation is available only for Mac or Linux")
    }
}

pip_get_version <- function(cmd, major_version) {
    regex <- "^(\\S+)\\s?(.*)$"
    cmd1 <- sub(regex, "\\1", cmd)
    cmd2 <- sub(regex, "\\2", cmd)
    oldw <- getOption("warn")
    options(warn = -1)
    result <- paste(system2(cmd1, cmd2, stdout = TRUE, stderr = TRUE),
                    collapse = " ")
    options(warn = oldw)
    version_check_regex <- sprintf(".+(%s.\\d+\\.\\d+).+", major_version)
    return(sub(version_check_regex, "\\1", result))
}


conda_get_version <- function(major_version = NA, conda, envname) {
    condaenv_bin <- function(bin) path.expand(file.path(dirname(conda), bin))
    cmd <- sprintf("%s%s %s && conda search spacy -c conda-forge%s",
                   ifelse(is_windows(), "", ifelse(is_osx(), "source ", "/bin/bash -c \"source ")),
                   shQuote(path.expand(condaenv_bin("activate"))),
                   envname,
                   ifelse(is_windows(), "", ifelse(is_osx(), "", "\"")))
    regex <- "^(\\S+)\\s?(.*)$"
    cmd1 <- sub(regex, "\\1", cmd)
    cmd2 <- sub(regex, "\\2", cmd)
    oldw <- getOption("warn")
    result <- system2(cmd1, cmd2, stdout = TRUE, stderr = TRUE)
    result <- sub("\\S+\\s+(\\S+)\\s.+", "\\1", result)
    if (!is.na(major_version)) {
        result <- grep(paste0("^", major_version, "\\."), result, value = T)
    }
    #version_check_regex <- sprintf(".+(%s.\\d+\\.\\d+).+", major_version)
    return(result[length(result)])
}