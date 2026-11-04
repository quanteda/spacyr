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
  # pip may list packages with "_" or "-" (e.g. model names), so normalise both
  normalise <- function(p) tolower(gsub("_", "-", trimws(p)))
  if (nchar(Sys.getenv("RETICULATE_PYTHON")) > 0) {
    installed <- reticulate::py_list_packages()$package
  } else {
    installed <- reticulate::py_list_packages(
      Sys.getenv("SPACY_PYTHON", unset = "r-spacyr"))$package
  }
  return(normalise(x) %in% normalise(installed))
}

py_check_version <- function(package, ...) {
  packages <- reticulate::py_list_packages(...)
  packages$version[packages$package == package]
}
