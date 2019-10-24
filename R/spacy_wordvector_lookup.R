#' Word vector lookup
#' 
#' To be written
#' @param x a data.frame generated from spacy_parse() or 
#'     a vocabulary vector (a character vector with unique elements)
#' @return a list of word vectors, named by tokens
#' @details This function looks up the word vector tables pre-trained and shipped with spacyr language models. Since "small" models
#'   do not come with word vectors, this function will give a warning when spaCy is initialized with a model with a name "_sm" at 
#'   the end. 
#'   When a lookup table in a spaCy language model does not have a key provided as a token, 
#'   the returned vector for the non-existent token is a vector of zeros.
#' @export
#' @examples
#' \donttest{
#' spacy_initialize(model = "en_core_web_md")
#' 
#' txt2 <- c(doc1 = "The fast cat catches mice.\\nThe quick brown dog jumped.", 
#'           doc2 = "This is the second document.",
#'           doc3 = "This is a \\\"quoted\\\" text." )
#' spacy_output <- spacy_parse(txt2)
#' word_vectors <- spacy_wordvectors_lookup(spacy_output)
#' }
spacy_wordvectors_lookup <- function(x, ...) {
    UseMethod("spacy_wordvectors_lookup")
}

#' @export
spacy_wordvectors_lookup.character <- function(x, ...) {
    if(length(x) != length(unique(x))) {
        warning("The word vector contains non-unique elements. duplicated elements will be removed")
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
    class(wordvectors) <- c("spacy_wordvectors", class(wordvectors))
    return(wordvectors)
}

#' @export
spacy_wordvectors_lookup.spacyr_parsed <- function(x, ...) {
    vocab <- unique(x$token)
    wordvectors <- spacy_wordvectors_lookup.character(vocab)
    return(wordvectors)
}

