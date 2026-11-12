#' Convert entity patterns of phrases to a quanteda dictionary
#'
#' A method of [quanteda::as.dictionary()] for the entity patterns that
#' [as_entity_patterns()] makes, when all of them are phrases: each label
#' becomes a key, and the phrases with that label become its values. It needs
#' the \pkg{quanteda} package, and is available when \pkg{quanteda} is
#' loaded.
#'
#' @param x a `spacyr_entity_patterns` object, as [as_entity_patterns()] or
#'   [entity_patterns_read()] returns, whose patterns are all phrases
#' @param ... not used; any argument given here is an error
#' @returns A \pkg{quanteda} dictionary with one key for each label of `x`, in
#'   the order in which the labels first occur. Its values are the different
#'   phrases with that label, in the case in which they are written.
#' @details
#' A dictionary holds words and phrases, so `x` can hold only phrases. Token
#' patterns have no counterpart in a dictionary: when `x` has any, the
#' conversion stops with an error that names their labels.
#'
#' A dictionary has less than the entity patterns have, so the conversion
#' keeps the different pairs of a label and a phrase, and nothing else:
#'
#' * The `id` of a pattern is dropped.
#' * So is `case_insensitive`. A dictionary does not say how its values are
#'   matched: that is set where it is used, as by `case_insensitive` in
#'   [quanteda::tokens_lookup()] or in [as_entity_patterns()].
#' * [quanteda::dictionary()] removes the whitespace at the start and the end
#'   of a value, and a phrase that occurs more than once under a label is
#'   kept once.
#' * The values are grouped by key, so their order is not the order of the
#'   patterns when the patterns of a label are not next to each other.
#'
#' \pkg{quanteda} reads `*` and `?` in a dictionary value as wildcards, since
#' its default is `valuetype = "glob"`, while in a phrase of an entity
#' pattern they are those characters themselves. The conversion gives a
#' warning when a phrase has one. To match such values as they are written,
#' use `valuetype = "fixed"`, as in
#' `quanteda::tokens_lookup(x, dictionary, valuetype = "fixed")`.
#'
#' An object with no patterns gives a dictionary with no keys, which
#' [as_entity_patterns()] makes into no patterns again. \pkg{quanteda} takes
#' such a dictionary in [quanteda::kwic()] and [quanteda::dfm_lookup()], but
#' [quanteda::tokens_lookup()] stops with an error for it (in
#' \pkg{quanteda} 4.5.1), so check `length()` of the dictionary first where
#' it can be empty.
#'
#' To make entity patterns of the dictionary again, with the phrases as they
#' are written and matched in their own case, use
#' `as_entity_patterns(d, valuetype = "fixed", case_insensitive = FALSE)`.
#' Without those arguments, [as_entity_patterns()] reads the values of a
#' dictionary as \pkg{quanteda} does: as globs, matched in any case.
#' @seealso [as_entity_patterns()], [quanteda::dictionary()],
#'   [quanteda::tokens_lookup()]
#' @examplesIf requireNamespace("quanteda", quietly = TRUE)
#' pat <- as_entity_patterns(c(ORG = "Acme Widgets", ORG = "Globex",
#'                             GPE = "New York"))
#' d <- quanteda::as.dictionary(pat)
#' d
#'
#' # and back, as phrases matched in their own case
#' as_entity_patterns(d, valuetype = "fixed", case_insensitive = FALSE)
#' @exportS3Method quanteda::as.dictionary
as.dictionary.spacyr_entity_patterns <- function(x, ...) {
    check_unused_args(match.call(expand.dots = FALSE)$...,
                      fun = "as.dictionary")
    # an object that was edited as a data.frame keeps its class: check it
    x <- as_entity_patterns(x)
    is_phrase <- vapply(x$pattern, is.character, logical(1))
    if (!all(is_phrase))
        stop("a dictionary holds only phrases, and x has token patterns ",
             "with the label",
             if (length(unique(x$label[!is_phrase])) > 1L) "s", " ",
             paste(unique(x$label[!is_phrase]), collapse = ", "),
             call. = FALSE)
    phrases <- unlist(x$pattern, use.names = FALSE)
    wild <- grepl("[*?]", phrases)
    if (any(wild))
        warning("quanteda reads * and ? in a dictionary value as wildcards ",
                "unless valuetype = \"fixed\", as in tokens_lookup(); ",
                sum(wild), if (sum(wild) == 1L) " phrase has" else " phrases have",
                " one, with the label",
                if (length(unique(x$label[wild])) > 1L) "s", " ",
                paste(unique(x$label[wild]), collapse = ", "),
                call. = FALSE)
    values <- if (length(phrases)) {
        lapply(split(phrases, factor(x$label, levels = unique(x$label))),
               unique)
    } else {
        empty_dict()
    }
    quanteda::dictionary(values, tolower = FALSE)
}
