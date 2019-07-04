#' Parse a text using spaCy
#' 
#' The \code{spacy_parse()} function calls spaCy to both tokenize and tag the
#' texts, and returns a data.table of the results. The function provides options
#' on the types of tagsets (\code{tagset_} options) either  \code{"google"} or
#' \code{"detailed"}, as well as lemmatization (\code{lemma}). It provides a
#' functionalities of dependency parsing and named entity recognition as an
#' option. If \code{"full_parse = TRUE"} is provided, the function returns the
#' most extensive list of the parsing results from spaCy.
#' 
#' @param x a character object, a \pkg{quanteda} corpus, or a TIF-compliant
#'   corpus data.frame (see \url{https://github.com/ropensci/tif})
#' @param pos logical whether to return universal dependency POS tagset
#'   \url{http://universaldependencies.org/u/pos/})
#' @param tag logical whether to return detailed part-of-speech tags, for the
#'   language model \code{en}, it uses the OntoNotes 5 version of the Penn
#'   Treebank tag set
#'   (\url{https://spacy.io/docs/usage/pos-tagging#pos-schemes}). Annotation
#'   specifications for other available languages are available on the spaCy
#'   website (\url{https://spacy.io/api/annotation}).
#' @param lemma logical; include lemmatized tokens in the output (lemmatization
#'   may not work properly for non-English models)
#' @param entity logical; if \code{TRUE}, report named entities
#' @param multithread logical; If \code{TRUE}, the processing is parallelized
#'   using spaCy's architecture (\url{https://spacy.io/api})
#' @param dependency logical; if \code{TRUE}, analyse and tag dependencies
#' @param nounphrase logical; if \code{TRUE}, analyse and tag noun phrases
#'   tags
#' @param additional_attributes a character vector; this option is for
#'   extracting additional attributes of tokens from spaCy. When the names of
#'   attributes are supplied, the output data.frame will contain additional
#'   variables corresponding to the names of the attributes. For instance, when
#'   \code{additional_attributes = c("is_punct")}, the output will include an
#'   additional variable named \code{is_punct}, which is a Boolean (in R,
#'   logical) variable indicating whether  the token is a punctuation. A full
#'   list of available attributes is available from
#'   \url{https://spacy.io/api/token#attributes}.
#' @param ... not used directly
#' @return a \code{data.frame} of tokenized, parsed, and annotated tokens
#' @export
#' @examples
#' \donttest{
#' spacy_initialize()
#' # See Chap 5.1 of the NLTK book, http://www.nltk.org/book/ch05.html
#' txt <- "And now for something completely different."
#' spacy_parse(txt)
#' spacy_parse(txt, pos = TRUE, tag = TRUE)
#' spacy_parse(txt, dependency = TRUE)
#' 
#' txt2 <- c(doc1 = "The fast cat catches mice.\\nThe quick brown dog jumped.", 
#'           doc2 = "This is the second document.",
#'           doc3 = "This is a \\\"quoted\\\" text." )
#' spacy_parse(txt2, entity = TRUE, dependency = TRUE)
#' 
#' txt3 <- "We analyzed the Supreme Court with three natural language processing tools." 
#' spacy_parse(txt3, entity = TRUE, nounphrase = TRUE)
#' spacy_parse(txt3, additional_attributes = c("like_num", "is_punct"))
#' }
spacy_parse <- function(x,
                        pos = TRUE,
                        tag = FALSE,
                        lemma = TRUE,
                        entity = TRUE,
                        dependency = FALSE,
                        nounphrase = FALSE,
                        multithread = TRUE,
                        additional_attributes = NULL,
                        ...) {
    UseMethod("spacy_parse")
}


#' @importFrom data.table data.table setDT setnames
#' @export
spacy_parse.character <- function(x,
                                  pos = TRUE,
                                  tag = FALSE,
                                  lemma = TRUE,
                                  entity = TRUE,
                                  dependency = FALSE,
                                  nounphrase = FALSE,
                                  multithread = TRUE,
                                  additional_attributes = NULL,
                                  ...) {

    `:=` <- `.` <- `.N` <- NULL
    spacy_out <- process_document(x, multithread)
    if (is.null(spacy_out$timestamps)) {
        stop("Document parsing failed")
    }

    ## check the omit_entity status
    if (entity == TRUE & getOption("spacy_entity") == FALSE) {
        message("entity == TRUE is ignored because spaCy model is initialized without Entity Recognizer")
        message("In order to turn on entity recognition, run spacy_finalize(); spacy_initialize(entity = TURE)")
        entity <- FALSE
    }

    tokens <- get_tokens(spacy_out)
    ntokens <- get_ntokens(spacy_out)
    ntokens_by_sent <- get_ntokens_by_sent(spacy_out)

    dt <- data.table(doc_id = rep(spacy_out$docnames, ntokens),
                     sentence_id = unlist(lapply(ntokens_by_sent, function(x) rep(seq_along(x), x))),
                     token_id = unlist(lapply(unlist(ntokens_by_sent), function(x) seq(to = x))),
                     token = tokens)

    if (lemma) {
        model <- spacyr_pyget("model")
        dt[, "lemma" := get_attrs(spacy_out, "lemma_", TRUE)]
        if (model != "en"){
            warning("lemmatization may not work properly in model '", model, "'")
        }
    }
    if (pos) {
        dt[, "pos" := get_tags(spacy_out, "google")]
    }
    if (tag) {
        dt[, "tag" := get_tags(spacy_out, "detailed")]
    }

    ## add dependency data fields
    if (dependency) {
        subtractor <- unlist(lapply(ntokens_by_sent, function(x) {
            if (length(x) == 0) return(NULL)
            csumx <- cumsum(c(0, x[-length(x)]))
            return(rep(csumx, x))
        }))
        deps <- get_dependency(spacy_out)
        dt[, c("head_token_id", "dep_rel") := list(deps$head_id - subtractor,
                                                   deps$dep_rel)]
    }

    ## named entity fields
    if (entity) {
        dt[, entity := get_named_entities(spacy_out)]
    }

    ## noun phrases
    if (nounphrase) {
        doc_id <- start_id <- nounphrase <- w_id <- root_id <- whitespace <- NULL

        dt_nounphrases <- data.table::data.table(get_noun_phrases(spacy_out))
        if (nrow(dt_nounphrases) > 0) {
            dt_nounphrases <- dt_nounphrases[rep(1:nrow(dt_nounphrases), times = length)]
            dt_nounphrases[, w_id := seq(start_id[1], length.out = length[1]), by = .(doc_id, start_id)]
            dt_nounphrases <- data.table::setorder(dt_nounphrases, w_id, -length)
            dt_nounphrases <- unique(dt_nounphrases, by = c("doc_id", "w_id"))
            dt_nounphrases[, nounphrase := ifelse(w_id == start_id, "beg",
                                          ifelse(w_id == max(w_id), "end", "mid")), by = .(doc_id, start_id)]
            dt_nounphrases[, nounphrase := ifelse(w_id == root_id, paste0(nounphrase, "_root"), nounphrase)]
            dt[, w_id := seq_len(.N), by = doc_id]
            dt <- merge(dt, dt_nounphrases, by  = c("doc_id", "w_id"), all.x = TRUE)
            # dt[ !is.na(start_id), start_token_id := token_id[w_id == start_id][1],
            #     by = .(doc_id, root_id)]
            # dt[ !is.na(start_id), root_token_id := token_id[w_id == root_id][1],
            #     by = .(doc_id, root_id)]
            dt[, c("w_id", "start_id", "root_id", "text", "root_text", "length") := NULL]
            dt[, whitespace := ifelse(nchar(get_attrs(spacy_out, "whitespace_")), TRUE, FALSE)]
            dt[, nounphrase := ifelse(is.na(nounphrase), "", nounphrase)]
        } else {
            message("No noun phrase found in documents.")
        }
    }

    if (!is.null(additional_attributes)) {
        for (att_name in additional_attributes){
            dt[, (att_name) := get_attrs(spacy_out, att_name, deal_utf8 = TRUE)]
        }
    }

    dt <- as.data.frame(dt)
    class(dt) <- c("spacyr_parsed", class(dt))
    return(dt)
}


#' @export
spacy_parse.data.frame <- function(x, ...) {

    # insert compliance check here - replace with tif package
    if (!all(c("doc_id", "text") %in% names(x)))
        stop("input data.frame does not conform to the TIF standard")

    txt <- x$text
    names(txt) <- x$doc_id
    spacy_parse(txt, ...)
}


#' Tokenize text using spaCy
#' 
#' Tokenize text using spaCy. The results of tokenization is stored as a Python
#' object. To obtain the tokens results in R, use \code{get_tokens()}.
#' \url{http://spacy.io}.
#' @param x input text
#' functionalities including the tagging, named entity recognition, dependency 
#' analysis. 
#' This slows down \code{spacy_parse()} but speeds up the later parsing. 
#' If FALSE, tagging, entity recognition, and dependency analysis when 
#' relevant functions are called.
#' @param multithread logical;
#' @param ... arguments passed to specific methods
#' @return result marker object
#' @importFrom methods new
#' @examples
#' \donttest{
#' spacy_initialize()
#' # the result has to be "tag() is ready to run" to run the following
#' txt <- c(text1 = "This is the first sentence.\nHere is the second sentence.", 
#'          text2 = "This is the second document.")
#' results <- spacy_parse(txt)
#' }
#' @export
#' @keywords internal
process_document <- function(x, multithread, ...) {
    # This function passes texts to python and spacy
    # get or set document names
    if (!is.null(names(x))) {
        docnames <- names(x)
    } else {
        docnames <- paste0("text", 1:length(x))
    }
    if (all(!duplicated(docnames)) == FALSE) {
        stop("Docmanes are duplicated.")
    } else if (all(nchar(docnames) > 0L) == FALSE) {
        stop("Some docnames are missing.")
    }

    if (is.null(options()$spacy_initialized)) spacy_initialize()
    spacyr_pyexec("try:\n del spobj\nexcept NameError:\n 1")
    spacyr_pyexec("texts = []")

    x <- gsub("\\\\n", "\\\n", x) # replace two quotes \\n with \n
    x <- gsub("\\\\t", "\\\t", x) # replace two quotes \\t with \t
    x <- gsub("\\\\", "", x) # delete unnecessary backslashes
    x <- unname(x)

    spacyr_pyassign("texts", x)
    spacyr_pyassign("multithread", multithread)
    spacyr_pyexec("spobj = spacyr()")

    spacyr_pyexec("timestamps = spobj.parse(texts, multithread = multithread)")

    timestamps <- as.character(spacyr_pyget("timestamps"))
    output <- spacy_out$new(docnames = docnames,
                            timestamps = timestamps)
    return(output)
}
