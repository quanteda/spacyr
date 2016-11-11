##
## general methods for tokenizedTexts_tagged class
##

#' extensions of methods defind in the quanteda package
#' 
#' Extensions to quanteda functions.  You must have attached \pkg{quanteda} for these
#' to work.
#' @name quanteda-methods
#' @section Usage:
#' \code{docnames(x)} returns the document names
#' 
#' \code{ndoc(x)} returns the number of documents
#' 
#' \code{ntoken(x, ...)} returns the number of tokens by document
#' 
#' \code{ntype(x, ...)} returns the number of types (unique tokens) by document
#' 
#' @param x the \code{spacyr_parsed} object returned by \code{\link{spacy_parse}}
#' @param ... unused
#' @examples 
#' \dontrun{
#' require(quanteda)
#' spacy_initialize()
#' txt <- c(doc1 = "And now, now, now for something completely different.",
#'          doc2 = "Jack and Jill ran up the hill.")
#' parsed <- spacy_parse(txt)
#' ntype(parsed)
#' ntoken(parsed)
#' ndoc(parsed)
#' docnames(parsed)
#' }
NULL

#' @rdname quanteda-methods
#' @details
#' \code{docnames} returns the document names
#' 
#' @importFrom quanteda docnames
#' @method docnames spacyr_parsed
#' @noRd
#' @export
docnames.spacyr_parsed <- function(x) {
    docname <- NULL
    unique(x[, docname])
}


#' @rdname quanteda-methods
#' @details
#' \code{ndoc} returns the number of documents
#' 
#' @importFrom quanteda ndoc
#' @method ndoc spacyr_parsed
#' @noRd
#' @export
ndoc.spacyr_parsed <- function(x) {
    length(docnames(x))
}

#' @rdname quanteda-methods
#' @details
#' \code{ntoken} returns the number of tokens by document
#' 
#' @importFrom quanteda ntoken
#' @method ntoken spacyr_parsed
#' @noRd
#' @export
ntoken.spacyr_parsed <- function(x, ...) {
    N <- docname <- NULL
    ret <- x[, .N, by = docname][, N]
    names(ret) <- docnames(x)
    ret
}

#' @rdname quanteda-methods
#' @details
#' \code{ntype} returns the number of types (unique tokens) by document
#' 
#' @importFrom quanteda ntype
#' @method ntype spacyr_parsed
#' @noRd
#' @export
ntype.spacyr_parsed <- function(x, ...) {
    docname <- tokens <- NULL
    ntoken(x[, .N, by = list(docname, tokens)])
}

# print a tokenizedTexts objects
# 
# print method for a \link{tokenize}dText object
# param x a tokenizedText_tagged object created by \link{tokens_tags_out}
# @param sep separator for printing tokens and tags, default is \code{"_"}.  If
#   \code{NULL}, print tokens and tags separately.
# @param ... further arguments passed to base print method
# @export
# @keywords internal
# @method print tokenizedTexts_tagged
print.tokenizedTexts_tagged <- function(x, sep = "_", ...) {
    ndocuments <- ifelse(is.list(x), length(x), 1)
    if( "tokens" %in% class(x)) {
        x <- as.tokenizedTexts(x)
        class(x) <- c("tokenizedTexts_tagged", class(x))   
    }
    cat("tokenizedText_tagged object from ", ndocuments, " document", 
        ifelse(ndocuments > 1, "s", ""), 
        " (tagset = ", attr(x, "tagset"), ").\n", 
        sep = "")
    
    if (!is.null(sep)) {
        
        docs <- factor(rep(docnames(x), times = ntoken(x)), levels = docnames(x))
        tmp <- split(paste(unlist(x), unlist(attr(x, "tags")), sep = sep),  docs)
        class(tmp) <- "listof"
        print(tmp)
        
    } else {
        
        for (e in docnames(x)) {
            cat(paste0(e, ":\n"))
            if (is.list(x[[tolower(e)]])) { 
                class(x[[tolower(e)]]) <- "listof"
                print(x[[tolower(e)]], ...)
            } else {
                print(as.character(x[[tolower(e)]]), ...)
            }
        }
        
    }
}


# summarize a tagged tokenizedTexts object
# 
# Generate frequency counts of POS by document, returning a data.frame.
# @param object tokenizedTexts_tagged object to be summarized
# @param ... unused
# @importFrom data.table rbindlist
# @export
# @method summary spacyr_parsed
summary.spacyr_parsed <- function(object, ...) {
    result <- data.frame(
        data.table::rbindlist(lapply(attr(object, "tags"), function(doc) as.list(table(doc))), 
                              use.names = TRUE, fill = TRUE)
    )
    result[is.na(result)] <- 0
    row.names(result) <- docnames(object)
    
    # cat("Part of speech summary (", attr(object, "tagset"), " tagset):\n\n", sep = "")
    # print(result)
    
    # invisible(result)
    result
}
