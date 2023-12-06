#' Download spaCy language models
#'
#' @inheritParams spacy_install
#' 
#' @return Invisibly returns the installation log.
#' 
#' @export
#'
#' @examples
#' \dontrun{
#' # install medium sized model
#' spacy_download_langmodel("en_core_web_md")
#' 
#' #' # install several models with spaCy
#' spacy_install(lang_models = c("en_core_web_sm", "de_core_news_sm"))
#' 
#' # install transformer based model
#' spacy_download_langmodel("en_core_web_trf")
#' }
spacy_download_langmodel <- function(lang_models = "en_core_web_sm",
                                     force = FALSE) {
  
  if (!force & py_check_installed(lang_models)) {
    warning("Skipping installation. Use `force` to force installation or update.")
    return(invisible(NULL))
  }
  
  
  bin <- Sys.getenv("RETICULATE_PYTHON", unset = reticulate::virtualenv_python(
    Sys.getenv("SPACY_PYTHON", unset = "r-spacyr")
  ))
  args <- c("-m", "spacy", "download")
  
  invisible(lapply(lang_models, function(m) {
    message("Executing command:\n", paste(c(bin, args, m), collapse = " "))
    system2(bin, args = c(args, m))
  }))
  
}


#' Install a language model in a conda or virtual environment
#'
#' @description Deprecated. `spacyr` now always uses a virtual environment,
#'   making this function redundant.
#'
#' @param ... not used
#'
#' @export
spacy_download_langmodel_virtualenv <- function(...) {
  
  .Deprecated(new = "spacy_download_langmodel")
  
}
