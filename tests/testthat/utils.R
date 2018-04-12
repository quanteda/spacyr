skip_if_no_python_or_no_spacy <- function() {
    if (Sys.info()['sysname'] == "Windows"){
        source_bash_profile <- FALSE
    } else {
        source_bash_profile <- TRUE
    }
    if (find_spacy_env()) return(NULL)
    spacy_path <- find_spacy(ask = FALSE)
    if (is.null(spacy_path)) {
        skip("Skip the test as spaCy is not found")
    } else if (is.na(spacy_path)) {
        skip("Skip the test as python is not found")
    }
}
