#' Vector look up
#' 
#' To be written
#' @param x a data.frame generated from spacy_parse() or from spacy_tokenize() or 
#'     a vocabulary vector (a character vector with unique elements)
#' @return a list of word vectors, named by tokens
#' @export
#' @examples
#' \donttest{
#' spacy_initialize()
#' txt <- "And now for something completely different."
#' spacy_tokenize(txt)
#' 
#' txt2 <- c(doc1 = "The fast cat catches mice.\\nThe quick brown dog jumped.", 
#'           doc2 = "This is the second document.",
#'           doc3 = "This is a \\\"quoted\\\" text." )
#' spacy_tokenize(txt2)
#' }
spacy_wordvectors_lookup <- function(x, ...) {
    UseMethod("spacy_wordvectors_lookup")
}

#' @export
spacy_wordvectors_lookup.character <- function(x, ...) {
    if(length(x) != length(unique(x))) {
        warning("The word vector contains non-unique elements. dupulcated elements will be removed")
        x <- unique(x)
    }

    if (is.null(options()$spacy_initialized)) {
        stop("spacy is not initialized. please run spacy_initialize with a model that contains word vectors")
    } else if (grepl("_sm", spacyr_pyget("model"))) {
        model <- spacyr_pyget("model")
        warning("spacy is initialized but with a model '", model, "'. This is a model probably shipped without word vectors")
    }

    spacyr_pyexec("try:\n spobj\nexcept NameError:\n spobj = spacyr()")
    
    spacyr_pyassign("tokens_vec", x)
    spacyr_pyexec("wordvectors = spobj.wordvectors_lookup(tokens_vec)")
    wordvectors <- spacyr_pyget("wordvectors")
    names(wordvectors) <- x
    return(wordvectors)
}

#' @export
spacy_wordvectors_lookup.spacyr_parsed <- function(x, ...) {
    vocab <- unique(x$token)
    wordvectors <- spacy_wordvectors_lookup.character(vocab)
    return(wordvectors)
}

