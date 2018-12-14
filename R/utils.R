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
