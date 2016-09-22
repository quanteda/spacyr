#' tag parts of speech using spaCy
#'
#' Tokenize a text using spaCy and tag the tokens with part-of-speech tags. 
#' Options exist for using either the Google or Penn tagsets.
#' See \url{http://spacy.io}.
#' @param x input text
#' @param tagset character label for the tagset to use, either \code{"google"} or \code{"penn"} to use
#' the simplified Google tagset, or the more detailed scheme from the Penn Treebank
#' @return tagged object
#' @examples 
#' # fails on my system:
#' pos_tag("This is a very short sample sentence.", tagset = "google")
#' 
#' # Note: This works from my command line:
#' # python inst/python/posTag.py -w < inst/extdata/test.txt 
#' @export
pos_tag <- function(x, tagset) UseMethod("pos_tag")

#' @rdname pos_tag
pos_tag.character <- function(x, tagset = c("google", "penn")) {
    tagset <- match.arg(tagset)

    # get user's path to the Python script
    PYTHON_SCRIPT <- system.file("python", "posTag.py", package = "spacyr")

    # obliterate all non-ASCII characters, as these cause problems for spaCy
    x <- iconv(x, "UTF-8", "ASCII",  sub="") 
    
    paste(system2("python", 
                  args = c(PYTHON_SCRIPT, "-w", ifelse(tagset=="penn", "-p", "")),
                  input = x, stdout = TRUE),
          collapse = " ")
}




