#' Create patterns for rule-based named entities
#'
#' Turn phrases, spaCy-style pattern lists or a data.frame of patterns into a
#' `spacyr_entity_patterns` object: a checked set of rules for spaCy's
#' `entity_ruler`, which finds named entities by matching phrases or sequences
#' of tokens. Creating the object needs neither Python nor spaCy.
#'
#' @param x the patterns to convert:
#'   * a character vector of phrases, each matched exactly as a sequence of
#'   spaCy's tokens. Labels come from the names of `x`, as in `c(ORG = "Acme
#'   Widgets")`, or from `label`.
#'   * a list of patterns in spaCy's own structure, each a list with the
#'   elements `label`, `pattern` and optionally `id`. `pattern` is either a
#'   single phrase or a list of token patterns, one per token, each a named
#'   list of token attributes such as `list(LOWER = "dr")`. See spaCy's
#'   [rule-based matching](https://spacy.io/usage/rule-based-matching) for the
#'   attributes and operators available. A single pattern may also be given on
#'   its own, rather than in a list of patterns.
#'   * a data.frame with the columns `label` and `pattern`, and optionally `id`
#'   and `case_insensitive`. `pattern` is a character column of phrases, or a
#'   list column holding phrases or token patterns.
#'   * a `spacyr_entity_patterns` object, which is checked again, since it
#'   may have been edited as a data.frame.
#' @param label character; the entity label of each phrase, such as `"PERSON"`
#'   or `"ORG"`, either one for all phrases or one per phrase. If `NULL` (the
#'   default), the names of `x` are used.
#' @param id character; an optional ID for each phrase, either one for all
#'   phrases or one per phrase. spaCy gives the ID of the pattern that matched
#'   as each entity's `ent_id_`.
#' @param case_insensitive logical; if `TRUE`, phrases match regardless of
#'   case. The default, `FALSE`, matches them exactly, as spaCy does. It does
#'   not apply to token patterns, which set case through the attribute they
#'   match, such as `ORTH` (exact) or `LOWER` (any case). For a list, it
#'   applies to the patterns that do not set `case_insensitive` themselves;
#'   for a data.frame, it applies when there is no `case_insensitive` column.
#' @param ... not used.
#' @returns A `spacyr_entity_patterns` object: a data.frame with one row per
#'   pattern and the columns
#'   * `label` the entity label;
#'   * `pattern` a list column, holding for each pattern a single phrase or a
#'   list of token patterns;
#'   * `id` the pattern's ID, or `NA`;
#'   * `case_insensitive` for phrases, whether they match regardless of case;
#'   `NA` for token patterns.
#'
#'   Duplicated patterns are removed.
#' @details
#' Token patterns are checked for their structure only: that each is a list
#' with one named list per token. spaCy checks the attribute names, operators
#' and values when the patterns are added to a pipeline, and reports any
#' errors then.
#'
#' Two conversions make patterns from R reach spaCy in the form it expects.
#' The values of the `IN` and `NOT_IN` operators are always stored as lists,
#' so that `list(LOWER = list(IN = "dr"))` stays a list of one value, rather
#' than becoming a single string. Whole numbers stored as doubles, such as `3`
#' in `list(LENGTH = 3)`, become integers, since spaCy does not accept
#' decimal numbers in token patterns.
#'
#' Patterns match spaCy's tokens, not characters. For instance, spaCy's
#' English models make "Prof." a single token, so a pattern for academic
#' titles needs to list both `"prof"` and `"prof."`, to match titles written
#' with and without a full stop.
#' @seealso [entity_patterns_read()] and [entity_patterns_write()] to read
#'   and write patterns as files
#' @examples
#' # phrases, labelled by their names or by `label`
#' as_entity_patterns(c(ORG = "Acme Widgets", GPE = "San Francisco"))
#' as_entity_patterns(c("Acme Widgets", "Globex"), label = "ORG")
#'
#' # a token pattern for people with academic titles: a title, followed by
#' # the first token of a person the model recognises (ENT_IOB "B") and the
#' # rest of that person (ENT_IOB "I"), so that it extends one entity without
#' # running into a person who follows it
#' titles <- c("dr", "dr.", "prof", "prof.")
#' as_entity_patterns(list(
#'   label = "PERSON",
#'   pattern = list(list(LOWER = list(IN = titles)),
#'                  list(ENT_TYPE = "PERSON", ENT_IOB = "B"),
#'                  list(ENT_TYPE = "PERSON", ENT_IOB = "I", OP = "*"))
#' ))
#'
#' # a data.frame of patterns
#' as_entity_patterns(data.frame(label = c("ORG", "ORG"),
#'                               pattern = c("Acme Widgets", "Globex")))
#'
#' # combine sets of patterns
#' c(as_entity_patterns(c(ORG = "Globex")),
#'   as_entity_patterns(c(PERSON = "Jane Smith")))
#' @export
as_entity_patterns <- function(x, ...) {
    UseMethod("as_entity_patterns")
}

#' @export
as_entity_patterns.default <- function(x, ...) {
    stop("as_entity_patterns() cannot convert an object of class ",
         paste(class(x), collapse = "/"), call. = FALSE)
}

#' @rdname as_entity_patterns
#' @export
as_entity_patterns.character <- function(x, label = NULL, id = NULL,
                                         case_insensitive = FALSE, ...) {
    check_case_insensitive(case_insensitive)
    n <- length(x)
    if (is.null(label)) {
        label <- if (n) names(x) else character(0)
        if (n && (is.null(label) || any(is.na(label) | label == "")))
            stop("Every phrase needs a label: name the elements of x, or supply label",
                 call. = FALSE)
    }
    label <- recycle_arg(label, n, "label")
    id <- if (is.null(id)) rep(NA_character_, n) else recycle_arg(id, n, "id")
    new_entity_patterns(label, as.list(unname(x)), id,
                        rep(case_insensitive, n))
}

#' @rdname as_entity_patterns
#' @export
as_entity_patterns.list <- function(x, case_insensitive = FALSE, ...) {
    check_case_insensitive(case_insensitive)
    # a single pattern given on its own
    if (!is.null(names(x)) && all(c("label", "pattern") %in% names(x)))
        x <- list(x)
    label <- character(length(x))
    pattern <- vector("list", length(x))
    id <- rep(NA_character_, length(x))
    ci <- rep(case_insensitive, length(x))
    for (i in seq_along(x)) {
        p <- x[[i]]
        if (!is.list(p) || is.null(names(p)) || !all(c("label", "pattern") %in% names(p)))
            stop("Pattern ", i, " is not a list with the elements label and pattern",
                 call. = FALSE)
        unknown <- setdiff(names(p), c("label", "pattern", "id", "case_insensitive"))
        if (length(unknown))
            stop("Pattern ", i, " has unknown elements: ",
                 paste(unknown, collapse = ", "), call. = FALSE)
        if (!is_string(p$label))
            stop("The label of pattern ", i, " is not a single string", call. = FALSE)
        label[i] <- p$label
        pattern[i] <- list(p$pattern)
        if (!is.null(p$id)) {
            if (!is_string(p$id))
                stop("The id of pattern ", i, " is not a single string", call. = FALSE)
            id[i] <- p$id
        }
        if (!is.null(p$case_insensitive)) {
            if (!is.logical(p$case_insensitive) || length(p$case_insensitive) != 1 ||
                is.na(p$case_insensitive))
                stop("The case_insensitive element of pattern ", i,
                     " is not TRUE or FALSE", call. = FALSE)
            ci[i] <- p$case_insensitive
        }
    }
    new_entity_patterns(label, pattern, id, ci)
}

#' @rdname as_entity_patterns
#' @export
as_entity_patterns.data.frame <- function(x, case_insensitive = FALSE, ...) {
    check_case_insensitive(case_insensitive)
    missing_cols <- setdiff(c("label", "pattern"), names(x))
    if (length(missing_cols))
        stop("x needs the columns label and pattern; missing: ",
             paste(missing_cols, collapse = ", "), call. = FALSE)
    n <- nrow(x)
    pattern <- x[["pattern"]]
    if (is.factor(pattern)) pattern <- as.character(pattern)
    if (!is.character(pattern) && !is.list(pattern))
        stop("The pattern column must be a character or list column", call. = FALSE)
    id <- if ("id" %in% names(x)) as.character(x[["id"]]) else rep(NA_character_, n)
    ci <- if ("case_insensitive" %in% names(x)) {
        if (!is.logical(x[["case_insensitive"]]))
            stop("The case_insensitive column must be logical", call. = FALSE)
        x[["case_insensitive"]]
    } else {
        rep(case_insensitive, n)
    }
    new_entity_patterns(as.character(x[["label"]]), as.list(pattern), id, ci)
}

#' @export
as_entity_patterns.spacyr_entity_patterns <- function(x, ...) {
    # the object may have been edited as a data.frame, so check it again
    cols <- c("label", "pattern", "id", "case_insensitive")
    missing_cols <- setdiff(cols, names(x))
    if (length(missing_cols))
        stop("x is missing the columns: ", paste(missing_cols, collapse = ", "),
             call. = FALSE)
    if (!is.character(x$label) || !is.list(x$pattern) || !is.character(x$id) ||
        !is.logical(x$case_insensitive))
        stop("x has columns of the wrong type: label and id must be character, ",
             "pattern a list and case_insensitive logical", call. = FALSE)
    new_entity_patterns(x$label, x$pattern, x$id, x$case_insensitive)
}

# Build the object from its columns, normalizing and checking each pattern,
# and removing duplicates. case_insensitive is kept for phrases only.
new_entity_patterns <- function(label, pattern, id, case_insensitive) {
    n <- length(pattern)
    label <- unname(label)
    pattern <- unname(pattern)
    id <- unname(id)
    case_insensitive <- unname(case_insensitive)
    bad <- is.na(label) | !nzchar(label)
    if (any(bad))
        stop("Pattern ", which(bad)[1], " has a missing or empty label", call. = FALSE)
    id[!is.na(id) & !nzchar(id)] <- NA_character_
    for (i in seq_len(n)) {
        pattern[i] <- list(normalize_pattern(pattern[[i]], i))
    }
    phrase <- vapply(pattern, is.character, logical(1))
    case_insensitive <- as.logical(case_insensitive)
    case_insensitive[!phrase] <- NA
    case_insensitive[phrase & is.na(case_insensitive)] <- FALSE
    x <- structure(
        list(label = enc2utf8(as.character(label)), pattern = pattern,
             id = enc2utf8(as.character(id)), case_insensitive = case_insensitive),
        class = c("spacyr_entity_patterns", "data.frame"),
        row.names = .set_row_names(n)
    )
    dup <- duplicated(lapply(seq_len(n), function(i)
        list(x$label[i], x$pattern[[i]], x$id[i], x$case_insensitive[i])))
    if (any(dup)) x <- x[!dup, , drop = FALSE]
    row.names(x) <- NULL
    x
}

# A phrase is returned as a UTF-8 string; a token pattern as a list of named
# lists, with IN and NOT_IN values as lists and whole-number doubles as
# integers.
normalize_pattern <- function(p, i) {
    if (is.character(p)) {
        if (length(p) != 1 || is.na(p) || !nzchar(trimws(p)))
            stop("Pattern ", i, " is not a single, non-empty phrase", call. = FALSE)
        return(enc2utf8(p))
    }
    if (!is.list(p) || !length(p))
        stop("Pattern ", i, " is neither a phrase nor a list of token patterns",
             call. = FALSE)
    if (!is.null(names(p)) && any(nzchar(names(p))))
        stop("Pattern ", i, " is a single token pattern; wrap it in list(), ",
             "since a pattern is a list with one token pattern per token",
             call. = FALSE)
    lapply(seq_along(p), function(j) {
        tok <- p[[j]]
        if (!is.list(tok) || (length(tok) && (is.null(names(tok)) ||
                                                any(!nzchar(names(tok))))))
            stop("Token ", j, " of pattern ", i, " is not a named list of attributes",
                 call. = FALSE)
        if (!length(tok)) return(structure(list(), names = character(0)))
        normalize_values(tok)
    })
}

normalize_values <- function(x) {
    nms <- names(x)
    for (k in seq_along(x)) {
        v <- x[[k]]
        # spaCy accepts the operators in either case, with an array as value
        if (!is.null(nms) && toupper(nms[k]) %in% c("IN", "NOT_IN")) {
            v <- unname(lapply(as.list(v), whole_to_integer))
        } else if (is.list(v)) {
            v <- normalize_values(v)
        } else {
            v <- whole_to_integer(v)
        }
        if (is.null(v)) x[k] <- list(NULL) else x[[k]] <- v
    }
    x
}

whole_to_integer <- function(v) {
    if (is.double(v) && length(v) && all(is.finite(v)) && all(v == round(v)) &&
        all(abs(v) <= .Machine$integer.max))
        return(as.integer(v))
    if (is.character(v)) return(enc2utf8(v))
    v
}

is_string <- function(x) {
    is.character(x) && length(x) == 1 && !is.na(x) && nzchar(x)
}

check_case_insensitive <- function(x) {
    if (!is.logical(x) || length(x) != 1 || is.na(x))
        stop("case_insensitive must be TRUE or FALSE", call. = FALSE)
}

recycle_arg <- function(x, n, name) {
    if (!is.character(x) || !(length(x) %in% c(1, n)))
        stop(name, " must be a character vector of length 1 or ", n, call. = FALSE)
    rep_len(x, n)
}

#' @export
c.spacyr_entity_patterns <- function(..., recursive = FALSE, use.names = TRUE) {
    # recursive and use.names are c()'s own arguments, and do not apply here;
    # the names of the arguments are dropped
    parts <- lapply(unname(list(...)), as_entity_patterns)
    new_entity_patterns(
        unlist(lapply(parts, `[[`, "label"), use.names = FALSE),
        unlist(lapply(parts, `[[`, "pattern"), recursive = FALSE, use.names = FALSE),
        unlist(lapply(parts, `[[`, "id"), use.names = FALSE),
        unlist(lapply(parts, `[[`, "case_insensitive"), use.names = FALSE)
    )
}

#' @export
as.list.spacyr_entity_patterns <- function(x, ...) {
    lapply(seq_len(nrow(x)), function(i) {
        p <- list(label = x$label[i], pattern = x$pattern[[i]])
        if (!is.na(x$id[i])) p$id <- x$id[i]
        if (isTRUE(x$case_insensitive[i])) p$case_insensitive <- TRUE
        p
    })
}

#' @export
as.data.frame.spacyr_entity_patterns <- function(x, ...) {
    class(x) <- "data.frame"
    x
}

#' @export
print.spacyr_entity_patterns <- function(x, n = 10, ...) {
    np <- nrow(x)
    cat("Entity patterns: ", np, if (np == 1) " pattern" else " patterns", sep = "")
    if (np) {
        counts <- table(factor(x$label, levels = unique(x$label)))
        cat(" (", paste0(names(counts), ": ", counts, collapse = ", "), ")", sep = "")
    }
    cat("\n")
    show <- seq_len(min(n, np))
    if (length(show)) {
        lab <- format(x$label[show])
        for (i in show) {
            cat("  ", lab[i], "  ", format_pattern(x$pattern[[i]]), sep = "")
            if (isTRUE(x$case_insensitive[i])) cat(" (any case)")
            if (!is.na(x$id[i])) cat(" [id: ", x$id[i], "]", sep = "")
            cat("\n")
        }
    }
    if (np > length(show))
        cat("  ... and ", np - length(show), " more\n", sep = "")
    invisible(x)
}

# A pattern as one readable line: a phrase in quotes, or one [ ] per token.
format_pattern <- function(p) {
    if (is.character(p)) return(paste0('"', p, '"'))
    paste(vapply(p, format_token, character(1)), collapse = " ")
}

format_token <- function(tok) {
    op <- tok$OP
    tok$OP <- NULL
    parts <- vapply(names(tok), function(a) format_attr(a, tok[[a]]), character(1))
    paste0("[", paste(parts, collapse = ", "), "]", if (is.null(op)) "" else op)
}

format_attr <- function(attr, v) {
    if (!is.list(v)) return(paste(attr, "=", format_value(v)))
    ops <- c(IN = "in", NOT_IN = "not in", REGEX = "~", FUZZY = "~=")
    parts <- vapply(names(v), function(o) {
        val <- v[[o]]
        if (o %in% c("IN", "NOT_IN"))
            return(paste0(attr, " ", ops[[o]], " (",
                          paste(vapply(val, format_value, character(1)), collapse = ", "),
                          ")"))
        if (o == "REGEX") return(paste0(attr, " ~ /", val, "/"))
        paste(attr, if (o %in% names(ops)) ops[[o]] else o, format_value(val))
    }, character(1))
    paste(parts, collapse = ", ")
}

format_value <- function(v) {
    if (is.list(v)) return(paste0("(", paste(vapply(v, format_value, character(1)),
                                             collapse = ", "), ")"))
    if (is.logical(v)) return(tolower(as.character(v)))
    paste(as.character(v), collapse = ", ")
}


#' Read and write entity patterns
#'
#' Read entity patterns from a file, or write them to one, for instance to
#' keep them with a project, edit them by hand, or share them with users of
#' spaCy in Python.
#'
#' @param file the path of the file to read or write. Its extension sets the
#'   format, and must be `.jsonl` for writing:
#'   * `.jsonl`: spaCy's own format, one pattern per line, each a JSON object
#'   with the keys `label`, `pattern` and optionally `id`, as written by
#'   spaCy's `EntityRuler.to_disk()`;
#'   * `.json`: a JSON array of the same patterns;
#'   * `.txt` (reading only): one phrase per line, all with the label given by
#'   `label`. Empty lines are skipped.
#' @param label character; for a `.txt` file, the label of its phrases.
#' @param case_insensitive logical; for phrases, whether they match regardless
#'   of case. See [as_entity_patterns()].
#' @param x patterns to write: a `spacyr_entity_patterns` object, or anything
#'   that [as_entity_patterns()] accepts.
#' @returns `entity_patterns_read()` returns a `spacyr_entity_patterns`
#'   object. `entity_patterns_write()` returns `file`, invisibly.
#' @details
#' Reading and writing JSON needs the **jsonlite** package.
#'
#' `entity_patterns_write()` writes JSONL only, so `file` must end in `.jsonl`.
#' It checks the patterns before opening `file`, so an existing file is left
#' as it was if they are not valid. A phrase that matches regardless of case is written with the extra
#' key `"case_insensitive": true`, which `entity_patterns_read()` reads back.
#' spaCy itself ignores that key, and matches the phrase exactly.
#'
#' Patterns written and read back are identical to the originals.
#' @seealso [as_entity_patterns()]
#' @examples
#' \donttest{
#' if (requireNamespace("jsonlite", quietly = TRUE)) {
#'   pats <- as_entity_patterns(list(
#'     list(label = "PERSON",
#'          pattern = list(list(LOWER = list(IN = c("dr", "dr."))),
#'                         list(ENT_TYPE = "PERSON", ENT_IOB = "B"),
#'                         list(ENT_TYPE = "PERSON", ENT_IOB = "I", OP = "*"))),
#'     list(label = "ORG", pattern = "Acme Widgets", id = "acme")
#'   ))
#'   file <- tempfile(fileext = ".jsonl")
#'   entity_patterns_write(pats, file)
#'   readLines(file)
#'   identical(entity_patterns_read(file), pats)
#' }
#' }
#' @export
entity_patterns_read <- function(file, label = NULL, case_insensitive = FALSE) {
    check_case_insensitive(case_insensitive)
    if (!is.character(file) || length(file) != 1 || is.na(file))
        stop("file must be a single file path", call. = FALSE)
    if (!file.exists(file)) stop("File not found: ", file, call. = FALSE)
    ext <- file_extension(file)
    if (!ext %in% c("jsonl", "json", "txt"))
        stop("file must have the extension .jsonl, .json or .txt", call. = FALSE)
    lines <- readLines(file, encoding = "UTF-8", warn = FALSE)
    if (ext == "txt") {
        if (is.null(label))
            stop("Reading phrases from a .txt file needs a label", call. = FALSE)
        lines <- lines[nzchar(trimws(lines))]
        return(as_entity_patterns(lines, label = label,
                                  case_insensitive = case_insensitive))
    }
    if (!is.null(label))
        warning("label is used only for .txt files, and is ignored", call. = FALSE)
    check_jsonlite()
    if (ext == "jsonl") {
        keep <- which(nzchar(trimws(lines)))
        x <- lapply(keep, function(i) {
            tryCatch(jsonlite::fromJSON(lines[i], simplifyVector = FALSE),
                     error = function(e)
                         stop("Line ", i, " of ", file, " is not valid JSON: ",
                              conditionMessage(e), call. = FALSE))
        })
    } else {
        x <- tryCatch(jsonlite::fromJSON(paste(lines, collapse = "\n"),
                                         simplifyVector = FALSE),
                      error = function(e)
                          stop(file, " is not valid JSON: ", conditionMessage(e),
                               call. = FALSE))
        if (!is.list(x) || (!is.null(names(x)) && !all(c("label", "pattern") %in% names(x))))
            stop(file, " does not hold a JSON array of patterns", call. = FALSE)
    }
    as_entity_patterns(x, case_insensitive = case_insensitive)
}

#' @rdname entity_patterns_read
#' @export
entity_patterns_write <- function(x, file) {
    if (!is.character(file) || length(file) != 1 || is.na(file))
        stop("file must be a single file path", call. = FALSE)
    if (file_extension(file) != "jsonl")
        stop("file must have the extension .jsonl", call. = FALSE)
    check_jsonlite()
    x <- as_entity_patterns(x)
    lines <- vapply(as.list(x), function(p)
        as.character(jsonlite::toJSON(p, auto_unbox = TRUE, digits = NA)),
        character(1))
    writeLines(enc2utf8(lines), file, useBytes = TRUE)
    invisible(file)
}

# The extension after the last ".", or "" if there is none: a file named
# "jsonl" has no extension.
file_extension <- function(file) {
    base <- basename(file)
    if (!grepl(".", base, fixed = TRUE)) return("")
    tolower(sub(".*\\.", "", base))
}

check_jsonlite <- function() {
    if (!requireNamespace("jsonlite", quietly = TRUE))
        stop("Reading and writing JSON patterns needs the jsonlite package: ",
             "install it with install.packages(\"jsonlite\")", call. = FALSE)
}
