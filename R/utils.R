# checking os functions, thanks to r-tensorflow

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

is_ubuntu <- function() {
    if (is_unix() && file.exists("/etc/lsb-release")) {
        lsbrelease <- readLines("/etc/lsb-release")
        any(grepl("Ubuntu", lsbrelease))
    } else {
        FALSE
    }
}

py_check_installed <- function(x) {
  if (is.null(x)) return(FALSE)
  x <- gsub("_", "-", x) # for model names
  if (nchar(Sys.getenv("RETICULATE_PYTHON")) > 0) {
    return(x %in% reticulate::py_list_packages()$package)
  } else {
    return(x %in% trimws(reticulate::py_list_packages(
      Sys.getenv("SPACY_PYTHON", unset = "r-spacyr"))$package
    ))
  }
}

py_check_version <- function(package, ...) {
  packages <- reticulate::py_list_packages(...)
  packages$version[packages$package == package]
}
