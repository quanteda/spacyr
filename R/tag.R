#' tag parts of speech using spaCy
#' 
#' Tokenize a text using spaCy and tag the tokens with part-of-speech tags. 
#' Options exist for using either the Google or Penn tagsets. See 
#' \url{http://spacy.io}.
#' @param x input text
#' @param tagset character label for the tagset to use, either \code{"google"} 
#'   or \code{"penn"} to use the simplified Google tagset, or the more detailed 
#'   scheme from the Penn Treebank.  
#' @param ... arguments passed to specific methods
#' @return tagged object
#' @examples
#' \donttest{initialize_spacy()
#' # the result has to be "tag() is ready to run" to run the following
#' txt <- c(text1 = "This is the first sentence.\nHere is the second sentence.", 
#'          text2 = "This is the second document.")
#' tag(txt)
#' tag(txt, tagset = "penn")
#'
#' # more extensive texts
#' tag(data_paragraph)
#' tag(data_sentences[1:10])
#' }
#' @export
tag <- function(x, ...) UseMethod("tag")

#' @rdname tag
#' @export
tag.corpus <- function(x, ...) {
    tag(quanteda::texts(x), ...)
}

#' @rdname tag
#' @export
tag.character <- function(x, tagset = c("google", "penn"), ...) {
    tagset <- match.arg(tagset)

    # get or set document names
    if (!is.null(names(x))) {
        docnames <- names(x) 
    } else {
        docnames <- paste0("text", 1:length(x))
    }

    # get user's path to the Python script
    PYTHON_SCRIPT <- system.file("python", "posTag.py", package = "spacyr")

    # obliterate all non-ASCII characters, as these cause problems for spaCy
    x <- iconv(x, "UTF-8", "ASCII",  sub="") 
    
    # get the path to the correct python executable
    if (!is.null(options()$PYTHON_PATH)) {
        PYTHON_PATH <- paste0(options()$PYTHON_PATH, "/")
    } else {
        # PYTHON_PATH <- ""
        stop("Availability of spaCy has not been checked. Please run check_spacy()")    
    }
        
    # tag for distinguishing documents
    x <- paste(x, collapse = " \n_###_\n ")
    
    # call the Python code
    ret <- paste0(system2(paste0(PYTHON_PATH, "python"), 
                          args = c(PYTHON_SCRIPT, "-w", ifelse(tagset=="penn", "-p", "")),
                          input = x, stdout = TRUE),
                     collapse = "\n")
    
    # split back into documents
    if (tagset == "google") {
        ret <- unlist(strsplit(ret, "\nPUNCT__###_\n", fixed = TRUE))
    } else if (tagset == "penn") {
        ret <- unlist(strsplit(ret, "\n.__###_\n", fixed = TRUE))
    }
    
    # add back docnames
    if (!is.null(docnames)) names(ret) <- docnames
    
    # now split tokens from tags
    tokens <- quanteda::tokenize(ret, what = "fasterword")
    tokens <- lapply(tokens, strsplit, "_", fixed = TRUE)
    tags <- lapply(tokens, function(splittoks) sapply(splittoks, "[", 1))
    tokens <- lapply(tokens, function(splittoks) sapply(splittoks, "[", 2))
    
    # add a tagset value
    ret <- list(tokens = tokens, tags = tags)
    attr(ret, "tagset") <- tagset
    class(ret) <- c("tokenizedTexts_tagged", class(ret))
    ret
}





