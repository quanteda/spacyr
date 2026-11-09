#' Download spaCy language models
#'
#' @inheritParams spacy_install
#' 
#' @return Invisibly returns the installation log.
#'
#' @details Models are downloaded from GitHub. If a download fails, for
#'   instance because of a temporary server error, it is tried twice more,
#'   after 10 and 30 seconds, and a warning is given if all three attempts
#'   fail.
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
  
  if (!force & all(py_check_installed(lang_models))) {
    warning("Skipping installation. Use `force` to force installation or update.")
    return(invisible(NULL))
  } else if (!force & any(py_check_installed(lang_models))) {
    warning("Skipping installation of one or more models. Use `force` to force installation or update.")
    lang_models <- lang_models[!py_check_installed(lang_models)]
  }
  
  bin <- Sys.getenv("RETICULATE_PYTHON", unset = reticulate::virtualenv_python(
    Sys.getenv("SPACY_PYTHON", unset = "r-spacyr")
  ))
  args <- c("-m", "spacy", "download")

  invisible(lapply(lang_models, function(m) {
    message("Executing command:\n", paste(c(bin, args, m), collapse = " "))
    download_with_retries(bin, c(args, m), m)
  }))

}

# Run a model download, trying again after a pause if it fails. Downloads come
# from GitHub, which sometimes answers with a temporary server error (such as
# 504), and pip does not retry those. Returns the exit status of the last
# attempt, and warns if every attempt failed.
download_with_retries <- function(bin, args, model, waits = c(10, 30)) {
  status <- run_python(bin, args)
  for (wait in waits) {
    if (identical(as.integer(status), 0L)) break
    message("Downloading ", model, " failed; trying again in ", wait, " seconds")
    pause(wait)
    status <- run_python(bin, args)
  }
  if (!identical(as.integer(status), 0L))
    warning("Downloading ", model, " failed after ", length(waits) + 1,
            " attempts", call. = FALSE)
  status
}

# wrappers, so that tests can replace them
run_python <- function(bin, args) system2(bin, args = args)
pause <- function(seconds) Sys.sleep(seconds)


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
