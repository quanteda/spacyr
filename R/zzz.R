#' @useDynLib spacyr
#' @importFrom Rcpp sourceCpp
NULL

.onLoad <- function(libname, pkgname) {
  config <- py_config()
  py_initialize(config$libpython);
}