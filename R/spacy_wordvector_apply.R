#' Word vector apply
#' 
#' To be written
#' @param x a data.frame generated from spacy_parse()
#' @param wordvectors returned object from spacy_wordvectors_lookup(). If \code{NULL}, spacyr trys to get vectors 
#'   by calling \code{spacy_wordvectors_lookup()}.
#' @return an unnamed matrix where each row corresponds with the word vector for input data.frame
#' @export
#' @examples
#' \donttest{
#' spacy_initialize(model = "en_core_web_md")
#' 
#' txt2 <- c(doc1 = "The fast cat catches mice.\\nThe quick brown dog jumped.", 
#'           doc2 = "This is the second document.",
#'           doc3 = "This is a \\\"quoted\\\" text." )
#' spacy_output <- spacy_parse(txt2)
#' wordvector_matrix <- spacy_wordvectors_apply(spacy_output)
#' }
spacy_wordvectors_apply <- function(x, 
                                    wordvectors = NULL,
                                    ...) {
    UseMethod("spacy_wordvectors_apply")
}

#' @export
spacy_wordvectors_apply.spacyr_parsed <- function(x, 
                                                  wordvectors = NULL, 
                                                  ...) {
    if(is.null(wordvectors)){
        vocab <- unique(x$token)
        wordvectors <- spacy_wordvectors_lookup.character(vocab)
    } else if(!"spacy_wordvectors" %in% class(wordvectors)) {
        stop("The provided wordvectors object is not compatible with this function.")
    }
    
    wordvector_matrix <- matrix(unlist(wordvectors[x$token]), nrow = length(x$token), byrow = T)
    return(wordvector_matrix)
}

