

#' 
#' #' @rdname covars_make_pos
#' covars_make_pos.corpus <- function(x, tagset) {
#'     covars_make_pos(texts(x), tagset)
#' }
#' 
#' #' @rdname covars_make_pos
#' covars_make_pos.snippet <- function(x, tagset) {
#'     covars_make_pos(x$text, tagset)
#' }
#' 
#' 
#' filterPOS <- function(x, tagset, verbose) UseMethod("filterPOS")
#' filterPOS.collocations <- function(x, tagset=c("penn", "google"), verbose=TRUE) {
#' 
#'     tagset <- match.arg(tagset)
#'     if (tagset=="penn") {
#'         re_NOUN_COMMON <- "^NNS*$"
#'         re_NOUN_PROPER <- "^NNPS*$"
#'         re_NOUN_ANY    <- "^NNP*S*$"
#'         re_PREPOSITION <- "^IN$"
#'         re_ADJECTIVE   <- "^JJ.*$"
#'         re_POSSESSIVE  <- "^POS$"
#'     } else stop("oops: Google tagset not yet implemented - but it would be very easy!")
#' 
#'     ## part of speech filtering
#'     x$pospattern <- "Other"
#' 
#'     ## bigram patterns
#'     # AN: linear function; lexical ambiguity; mobile phase
#'     x[, pospattern := ifelse((grepl(re_ADJECTIVE, pos1) & grepl(re_NOUN_ANY, pos2) & pos3==""), "A-N", pospattern)]
#'     # NN: regression coefficients; word sense; surface area
#'     x[, pospattern := ifelse((grepl(re_NOUN_ANY, pos1) & grepl(re_NOUN_ANY, pos2) & pos3==""), "N-N", pospattern)]
#'     # NP-NP: two proper nouns
#'     x[, pospattern := ifelse((grepl(re_NOUN_PROPER, pos1) & grepl(re_NOUN_PROPER, pos2) & pos3==""), "NP-NP", pospattern)]
#' 
#'     ## trigram patterns
#'     # AAN: Gaussian random variable; lexical conceptual paradigm; aqueous mobile phase
#'     x[, pospattern := ifelse((grepl(re_ADJECTIVE, pos1) & grepl(re_ADJECTIVE, pos2) & grepl(re_NOUN_ANY, pos3)), "A-A-N", pospattern)]
#'     # ANN: cumulative distribution function; lexical ambiguity resolution; accessible surface area
#'     x[, pospattern := ifelse((grepl(re_ADJECTIVE, pos1) & grepl(re_NOUN_ANY, pos2) & grepl(re_NOUN_ANY, pos3)), "A-N-N", pospattern)]
#'     # NAN: mean squared error; domain independent set; silica based packing
#'     x[, pospattern := ifelse((grepl(re_NOUN_ANY, pos1) & grepl(re_ADJECTIVE, pos2) & grepl(re_NOUN_ANY, pos3)), "N-A-N", pospattern)]
#'     # NNN: class probability function; text analysis system; gradient elution chromatography
#'     x[, pospattern := ifelse((grepl(re_NOUN_ANY, pos1) & grepl(re_NOUN_ANY, pos2) & grepl(re_NOUN_ANY, pos3)), "N-N-N", pospattern)]
#'     # NPN: degrees of freedom; [no example]; energy of adsorption
#'     x[, pospattern := ifelse((grepl(re_NOUN_ANY, pos1) & grepl(re_PREPOSITION, pos2) & grepl(re_NOUN_ANY, pos3)), "N-P-N", pospattern)]
#'     # NP-NP-NP: three proper nouns
#'     x[, pospattern := ifelse((grepl(re_NOUN_PROPER, pos1) & grepl(re_NOUN_PROPER, pos2) & grepl(re_NOUN_PROPER, pos3)), "NP-NP-NP", pospattern)]
#' 
#'     # bigrams with possessive as "word2"
#'     x[, pospattern := ifelse((grepl(re_NOUN_ANY, pos1) & grepl(re_POSSESSIVE, pos2) & grepl(re_NOUN_ANY, pos3)), "NPOS-N", pospattern)]
#'     # now alter them to make them bigrams
#'     x[pospattern=="NPOS-N", c("word1", "word2", "word3", "size") := list(paste0(word1, "'", word2), word3, "", 2)]
#'     # now reassign pospattern NPOS-N to just N-N
#'     x[pospattern=="NPOS-N", pospattern := "N-N"]
#' 
#'     # remove strange cases where size==3 but no word3 or pos3
#'     # nrow(x[size==3 & pos3=="" & stopword=="notSW"])
#'     startNrow <- nrow(x)
#'     x <- x[-which(size==3 & word3=="")]
#'     if (startNrow != nrow(x) & verbose)
#'         cat("Removed ", startNrow - nrow(x), " trigram",
#'             ifelse(startNrow - nrow(x)>1, "s", ""), " with no word3.\n", sep="")
#'     startNrow <- nrow(x)
#'     x <- x[-which(size==3 & pos3=="")]
#'     if (startNrow != nrow(x) & verbose)
#'         cat("Removed ", startNrow - nrow(x), " trigram",
#'             ifelse(startNrow - nrow(x)>1, "s", ""), " with no pos3.\n", sep="")
#' 
#'     # plot the frequencies
#'     if (verbose) {
#'         cat("\nPart of speech frequencies, by stopword status:")
#'         print(table(x$pospattern, x$stopword))
#'     }
#'     x
#' }


# if (tagset=="google") {
#     cat("  Doing gsub for PUNCT...")
#     # replace any punctuation tags with just the punctuation -- expected by collocations
#     x <- gsub("\\sPUNCT_(.)", "\\1", x)
# } else if (tagset=="penn") {
#     cat("  Doing gsub for punctuation ...")
#     x <- gsub("NNP_(Mr|Mrs|Dr|Ms).", "NNP_\\1", x)
#     x <- gsub("\\s([,:.]|''|``|-[lr]rb-)_.", "\\1", x)
#     #x <- gsub("\\s(POS_)", "", x)
# }
