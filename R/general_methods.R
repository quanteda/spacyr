##
## general methods for tokenizedTexts_tagged class
##

#' get or set document names
#' 
#' Get or set the document names from a corpus or a document-feature matrix.
#' of the \link{dfm} object.
#' @param x the object with docnames
#' @keywords internal
#' @importFrom quanteda docnames
#' @export
docnames.tokenizedTexts_tagged <- function(x) {
    names(x)
}


#' get the number of documents
#' 
#' \code{ndoc} returns an integer count of the number of documents
#' @param x a tokenizedTexts object
#' @keywords internal
#' @importFrom quanteda ndoc
#' @export
ndoc.tokenizedTexts_tagged <- function(x) {
    length(x)
}

#' count the number of tokens or types
#' 
#' Return the count of tokens (total features) or types (unique features) in a
#' tokenizedText object
#' @param x object whose tokens or types will be counted
#' @param ... not used
#' @keywords internal
#' @importFrom quanteda ntoken
#' @export
ntoken.tokenizedTexts_tagged <- function(x, ...) {
    lengths(x)
}

#' @rdname ntoken.tokenizedTexts_tagged
#' @keywords internal
#' @importFrom quanteda ntype
#' @export
ntype.tokenizedTexts_tagged <- function(x, ...) {
    lengths(lapply(x, unique))
}

#' print a tokenizedTexts objects
#' 
#' print method for a \link{tokenize}dText object
#' @param x a tokenizedText_tagged object created by \link{tokens_tags_out}
#' @param sep separator for printing tokens and tags, default is \code{"_"}.  If
#'   \code{NULL}, print tokens and tags separately.
#' @param ... further arguments passed to base print method
#' @export
#' @keywords internal
#' @method print tokenizedTexts_tagged
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


#' summarize a tagged tokenizedTexts object
#' 
#' Generate frequency counts of POS by document, returning a data.frame.
#' @param object tokenizedTexts_tagged object to be summarized
#' @param ... unused
#' @importFrom data.table rbindlist
#' @export
#' @method summary tokenizedTexts_tagged
summary.tokenizedTexts_tagged <- function(object, ...) {
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
