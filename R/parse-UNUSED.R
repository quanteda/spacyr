### FROM my reading of the code, these functions are no longer required
### and can be removed?
### -- KB

#' create quanteda tokenized text object from spacy results
#'
#' @param dt a data.table output from spacy_parse()
#'
#' @return a tokenizedText object
#' @keywords internal
tokens_out <- function(dt) {
    tok <- dt$token
    output <- split(tok, dt$docname)
    class(output) <- c("tokenizedText", class(output))
    if(is.factor(tok)) {
        output <- lapply(output, as.numeric)
        types <- levels(tok)
        class(output) <- c("tokens", class(output))
        attr(output, 'types') <- types
    }
    attr(output, "what") <- "word"
    attr(output, "ngrams") <- 1
    attr(output, "concatenator") <- ""
    return(output)
}

#' create quanteda tokenized text object from spacy results with tag
#' 
#' Full description goes here.
#' @param dt a data.table output from \code{\link{spacy_parse}}
#' @param tagset character label for the tagset to use, either \code{"google"} 
#'   or \code{"penn"} to use the simplified Google tagset, or the more detailed 
#'   scheme from the Penn Treebank. 
#' @return a tokenizedText object
#' @keywords internal
tokens_tags_out <- function(dt, tagset = "penn") {
    tagset <- match.arg(tagset, c('penn', 'google'))
    output <- tokens_out(dt)
    if(tagset == 'penn'){
        tag <- dt$penn
    } else {
        tag <- dt$google
    }
    tag <- split(tag, dt$docname)
    attr(output, 'tags') <- tag
    
    class(output) <- c("tokenizedTexts_tagged", class(output))
    return(output)
}
