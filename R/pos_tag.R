#' tag parts of speech using spaCy
#' 
#' Tokenize a text using spaCy and tag the tokens with part-of-speech tags. 
#' Options exist for using either the Google or Penn tagsets. See
#' \url{http://spacy.io}.
#' @param x input text
#' @param tagset character label for the tagset to use, either \code{"google"}
#'   or \code{"penn"} to use the simplified Google tagset, or the more detailed
#'   scheme from the Penn Treebank
#' @section Setting the path to the python executable: Note that on some
#'   systems, notably OS X / macOS, you may have installed a different version
#'   of Python from that included in the base system.  OS X / macOS installs a
#'   slightly older version of 2.7.x by default, for instance, in
#'   \code{/usr/bin/python}.  Using homebrew, you may have installed a different
#'   version that gets placed in \code{/usr/local/bin}.  Even when this is
#'   working at a command line (e.g. bash in the Terminal), when called from R
#'   it may still look for \code{usr/bin/python}. The solution is to set the
#'   system variable \code{PYTHON_PATH} as in the examples below using
#'   \code{\link{options}}.
#' @return tagged object
#' @examples 
#' # for my system
#' options(PYTHON_PATH = "/usr/local/bin")
#' pos_tag("This is a very short sample sentence.", tagset = "penn")
#' pos_tag(data_paragraph, tagset = "google")
#' 
#' # python inst/python/posTag.py -w < inst/extdata/test.txt 
#' @export
pos_tag <- function(x, tagset) UseMethod("pos_tag")

#' @rdname pos_tag
#' @export
pos_tag.character <- function(x, tagset = c("google", "penn")) {
    tagset <- match.arg(tagset)

    # get user's path to the Python script
    PYTHON_SCRIPT <- system.file("python", "posTag.py", package = "spacyr")

    # obliterate all non-ASCII characters, as these cause problems for spaCy
    x <- iconv(x, "UTF-8", "ASCII",  sub="") 
    
    if (!is.null(options()$PYTHON_PATH)) {
        PYTHON_PATH <- paste0(options()$PYTHON_PATH, "/")
    } else {
        PYTHON_PATH <- ""
    }
        
    paste(system2(paste0(PYTHON_PATH, "python"), 
                  args = c(PYTHON_SCRIPT, "-w", ifelse(tagset=="penn", "-p", "")),
                  input = x, stdout = TRUE),
          collapse = " ")
}




