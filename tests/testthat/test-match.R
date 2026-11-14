source("utils.R")

passive <- list(
    PASSIVE = list(list(DEP = "auxpass"),
                   list(DEP = list(IN = c("advmod", "neg", "aux", "auxpass")), OP = "*"),
                   list(TAG = "VBN")))
txt <- c(doc1 = "The book was written by Jane. Jane wrote the book.",
         doc2 = "Mistakes were made, and the report is being rewritten.")
clause <- list(
    list(RIGHT_ID = "verb", RIGHT_ATTRS = list(TAG = "VBN")),
    list(LEFT_ID = "verb", REL_OP = ">", RIGHT_ID = "subject",
         RIGHT_ATTRS = list(DEP = "nsubjpass")),
    list(LEFT_ID = "verb", REL_OP = ">", RIGHT_ID = "aux",
         RIGHT_ATTRS = list(DEP = "auxpass")))
# the columns of every result, whatever the kind of pattern
match_columns <- c(doc_id = "character", match_id = "integer", label = "character",
                   node = "character", sentence_id = "integer", token_id = "integer",
                   text = "character", start_id = "integer", length = "integer")

# match_patterns() needs no Python, so these tests also run on CRAN

test_that("match_patterns takes one pattern or alternatives for each label", {
    m <- match_patterns(list(
        A = list(list(LOWER = "new"), list(LOWER = "york")),
        B = list(list(list(LEMMA = "write")),
                 list(list(LEMMA = "rewrite"), list(OP = "?"))),
        C = list(list())))
    expect_identical(m$labels, c("A", "B", "C"))
    expect_identical(m$patterns[[1]], list(list(list(LOWER = "new"), list(LOWER = "york"))))
    expect_identical(m$patterns[[2]], list(list(list(LEMMA = "write")),
                                           list(list(LEMMA = "rewrite"), list(OP = "?"))))
    # an empty token, which matches any token, stays a dict
    expect_identical(m$patterns[[3]], list(list(structure(list(), names = character(0)))))
})

test_that("match_patterns normalizes patterns as as_entity_patterns does", {
    m <- match_patterns(list(
        X = list(list(MORPH = list(IS_SUPERSET = "Voice=Pass")), list(LENGTH = 3)),
        Y = list(list(list(LOWER = list(IN = "a"))))))
    expect_identical(m$patterns[[1]][[1]],
                     list(list(MORPH = list(IS_SUPERSET = list("Voice=Pass"))),
                          list(LENGTH = 3L)))
    expect_identical(m$patterns[[2]][[1]], list(list(LOWER = list(IN = list("a")))))
})

test_that("match_patterns groups entity patterns with the same label", {
    ep <- as_entity_patterns(list(
        list(label = "W", pattern = list(list(LEMMA = "write"))),
        list(label = "B", pattern = list(list(LOWER = "book"))),
        list(label = "W", pattern = list(list(LEMMA = "rewrite")), id = "re")))
    m <- match_patterns(ep)
    expect_identical(m$labels, c("W", "B"))
    expect_identical(m$patterns, list(list(list(list(LEMMA = "write")),
                                           list(list(LEMMA = "rewrite"))),
                                      list(list(list(LOWER = "book")))))
    expect_identical(m$phrases, list())
    expect_identical(m$dependency, list())
    expect_identical(match_patterns(list(A = list(list(LOWER = "a"))))$phrases, list())
})

test_that("match_patterns separates the phrases of entity patterns", {
    ep <- c(as_entity_patterns(c(ORG = "Acme Widgets", GPE = "New York")),
            as_entity_patterns(c(ORG = "globex"), case_insensitive = TRUE),
            as_entity_patterns(list(label = "GPE", pattern = list(list(LOWER = "paris")))))
    m <- match_patterns(ep)
    expect_identical(m$labels, c("ORG", "GPE"))
    # a label can have phrases only, token patterns only, or both
    expect_identical(m$patterns, list(list(), list(list(list(LOWER = "paris")))))
    expect_identical(m$phrases, list(
        list(label = "ORG", text = "Acme Widgets", case_insensitive = FALSE),
        list(label = "GPE", text = "New York", case_insensitive = FALSE),
        list(label = "ORG", text = "globex", case_insensitive = TRUE)))
})

test_that("match_patterns converts a quanteda dictionary", {
    skip_if_not_installed("quanteda")
    d <- quanteda::dictionary(list(tax = c("tax*", "new york"), org = "acme widgets"))
    m <- match_patterns(d)
    expect_identical(m, match_patterns(as_entity_patterns(d)))
    expect_identical(m$labels, c("tax", "org"))
    expect_identical(vapply(m$phrases, `[[`, "", "text"), c("new york", "acme widgets"))
    expect_true(all(vapply(m$phrases, `[[`, NA, "case_insensitive")))
    expect_length(m$patterns[[1]], 1)
    expect_length(m$patterns[[2]], 0)
})

test_that("match_patterns labels the values of nested dictionary keys", {
    skip_if_not_installed("quanteda")
    d <- quanteda::dictionary(list(
        writing = c("writ*", "wrote"),
        place = list(us = c("new york", "new york city"), error = "mistake*")))
    m <- expect_silent(match_patterns(d))
    expect_identical(m$labels, c("writing", "place"))
    expect_identical(vapply(m$phrases, `[[`, "", "label"),
                     c("writing", "place", "place"))
    expect_length(m$patterns[[1]], 1)
    expect_length(m$patterns[[2]], 1)
})

test_that("match_patterns takes token and dependency patterns in one list", {
    tok <- list(list(LOWER = "a"))
    m <- match_patterns(list(A = tok, P = clause, B = list(tok, tok)))
    # every label, in the order given
    expect_identical(m$labels, c("A", "P", "B"))
    expect_identical(m$patterns, list(list(tok), list(), list(tok, tok)))
    expect_identical(m$dependency, list(list(label = "P", pattern = clause)))
    expect_identical(m$phrases, list())
    # a token pattern is told from a dependency pattern by the keys of its
    # tokens, not by those of a custom attribute
    ext <- match_patterns(list(X = list(list(`_` = list(RIGHT_ID = "x")))))
    expect_identical(ext$dependency, list())
    expect_length(ext$patterns[[1]], 1)
})

test_that("match_patterns rejects patterns it cannot use", {
    tok <- list(list(LOWER = "a"))
    expect_error(match_patterns(list(tok)), "must be a named list")
    expect_error(match_patterns(list(A = tok, tok)), "must be a named list")
    expect_error(match_patterns(list(A = tok, A = tok)), "must be unique.*: A$")
    expect_error(match_patterns(list()), "holds no patterns")
    expect_error(match_patterns(1:2), "must be a character vector, a phrase")
    expect_error(match_patterns(data.frame(label = "A")), "must be a character vector")
    expect_error(match_patterns(character()), "holds no patterns")
    expect_error(match_patterns(list(A = list())),
                 "'A' is not a list of tokens \\(a token pattern\\) or of nodes")
    expect_error(match_patterns(list(A = list(LOWER = "a"))),
                 "Pattern 'A' is a single token pattern")
    expect_error(match_patterns(list(A = list(tok, "b"))),
                 "Pattern 'A' \\(alternative 2\\) is a character vector")
    expect_error(match_patterns(list(A = list(tok, list(1)))),
                 "Token 1 of pattern 'A' \\(alternative 2\\)")
    # entity patterns are for sequences of tokens
    expect_error(match_patterns(as_entity_patterns(list(label = "P", pattern = clause))),
                 "Pattern 'P' is a dependency pattern.*entity patterns cannot hold")
})

test_that("spacy_match checks its arguments before starting spaCy", {
    try(spacy_finalize(), silent = TRUE)
    expect_error(spacy_match("a", passive, overlap = "none"), "should be one of")
    expect_error(spacy_match("a", passive, n_process = 0), "n_process")
    expect_error(spacy_match("a"), "pattern must be supplied")
    expect_error(spacy_match("a", list(passive$PASSIVE)), "must be a named list")
    expect_null(getOption("spacy_initialized"))
})

test_that("an overlap that is not one of the three is an error", {
    try(spacy_finalize(), silent = TRUE)
    # whatever the kinds of pattern, and from a TIF data.frame
    tif <- data.frame(doc_id = "d1", text = "a")
    for (pattern in list(passive, list(CLAUSE = clause), c(passive, list(CLAUSE = clause)))) {
        expect_error(spacy_match("a", pattern, overlap = "none"), "should be one of")
        expect_error(spacy_match(tif, pattern, overlap = "none"), "should be one of")
    }
    expect_null(getOption("spacy_initialized"))
})

test_that("spacy_match stops on arguments it does not use", {
    try(spacy_finalize(), silent = TRUE)
    expect_error(spacy_match("a", passive, nonsense = 1),
                 "spacy_match\\(\\) does not use the argument nonsense$")
    # a misspelt argument, and the name that pattern had at first
    expect_error(spacy_match("a", passive, overlaps = "all"),
                 "does not use the argument overlaps$")
    expect_error(spacy_match("a", patterns = passive),
                 "does not use the argument patterns$")
    # an argument without a name, after all of those that spacy_match() has
    expect_error(spacy_match("a", passive, "glob", TRUE, "all", 1L, NULL, FALSE, "extra",
                             nonsense = 1),
                 "does not use the arguments nonsense, 1 without a name$")
    expect_null(getOption("spacy_initialized"))
})

# lexical patterns: character vectors, phrase() objects and lists of
# character vectors, collocations and dictionaries

# what quanteda.textstats::textstat_collocations() returns, as far as
# spacy_match() reads it
collocations <- function(x) {
    structure(data.frame(collocation = x, count = 1L, stringsAsFactors = FALSE),
              class = c("collocations", "textstat", "data.frame"))
}

test_that("a character vector is one token for each element", {
    m <- match_patterns(c("tax", "new york", B = "b*", B = "c", "Tax"))
    # labelled by the name, or else by the text
    expect_identical(m$labels, c("tax", "new york", "B", "Tax"))
    # without a wildcard, the words of a phrase: an element with a space is
    # still one word
    expect_identical(m$phrases, list(
        list(label = "tax", words = list("tax"), case_insensitive = TRUE),
        list(label = "new york", words = list("new york"), case_insensitive = TRUE),
        list(label = "B", words = list("c"), case_insensitive = TRUE),
        list(label = "Tax", words = list("Tax"), case_insensitive = TRUE)))
    # with a wildcard, a token pattern
    expect_identical(m$patterns, list(list(), list(),
                                      list(list(list(LOWER = list(REGEX = "\\Ab[\\s\\S]*\\Z")))),
                                      list()))
    expect_identical(m$dependency, list())
    # the same text without a name is the same label
    expect_identical(match_patterns(c("a", "a", "b"))$labels, c("a", "b"))
})

test_that("valuetype and case_insensitive set how each string matches", {
    tokens_of <- function(...) match_patterns(...)$patterns[[1]][[1]]
    # glob: the lower case form, or the text when case matters
    expect_identical(tokens_of("Tax*"), list(list(LOWER = list(REGEX = "\\Atax[\\s\\S]*\\Z"))))
    expect_identical(tokens_of("Tax?", case_insensitive = FALSE),
                     list(list(ORTH = list(REGEX = "\\ATax[\\s\\S]\\Z"))))
    # other characters of a glob are literal
    expect_identical(tokens_of("a.b*"), list(list(LOWER = list(REGEX = "\\Aa\\.b[\\s\\S]*\\Z"))))
    # regex: on the text, with (?i) for any case
    expect_identical(tokens_of("^Tax", "regex"), list(list(TEXT = list(REGEX = "(?i)^Tax"))))
    expect_identical(tokens_of("^Tax", "regex", FALSE),
                     list(list(TEXT = list(REGEX = "^Tax"))))
    # fixed: always the words of a phrase, wildcards included
    m <- match_patterns(c("Tax*", "a"), "fixed", FALSE)
    expect_identical(m$patterns, list(list(), list()))
    expect_identical(m$phrases, list(
        list(label = "Tax*", words = list("Tax*"), case_insensitive = FALSE),
        list(label = "a", words = list("a"), case_insensitive = FALSE)))
})

test_that("phrase() objects and lists of character vectors are sequences", {
    skip_if_not_installed("quanteda")
    p <- quanteda::phrase(c("new york*", "the big apple"))
    m <- match_patterns(p)
    # labelled by the strings joined by a space
    expect_identical(m$labels, c("new york*", "the big apple"))
    # one token for each string where any has a wildcard, the strings as
    # they are otherwise
    expect_identical(m$patterns, list(
        list(list(list(LOWER = "new"), list(LOWER = list(REGEX = "\\Ayork[\\s\\S]*\\Z")))),
        list()))
    expect_identical(m$phrases, list(
        list(label = "the big apple", words = list("the", "big", "apple"),
             case_insensitive = TRUE)))
    # a list is the same, and its names are labels
    expect_identical(match_patterns(list(c("new", "york*"), c("the", "big", "apple"))), m)
    named <- match_patterns(list(NY = c("new", "york*"), NY = c("the", "big", "apple"),
                                 c("Acme", ",", "Inc.")), case_insensitive = FALSE)
    expect_identical(named$labels, c("NY", "Acme , Inc."))
    expect_identical(named$patterns, list(
        list(list(list(ORTH = "new"), list(ORTH = list(REGEX = "\\Ayork[\\s\\S]*\\Z")))), list()))
    expect_identical(vapply(named$phrases, `[[`, "", "label"), c("NY", "Acme , Inc."))
    expect_identical(named$phrases[[2]]$words, list("Acme", ",", "Inc."))
    # names given to a phrase() object are labels too
    names(p) <- c("NY", "NYC")
    expect_identical(match_patterns(p)$labels, c("NY", "NYC"))
    # the strings are never split again
    expect_identical(match_patterns(list(c("new york", "city")))$phrases[[1]]$words,
                     list("new york", "city"))
})

test_that("collocations are sequences of their words, taken literally", {
    col <- collocations(c("new york", "a * b", "York?"))
    m <- match_patterns(col)
    expect_identical(m$labels, c("new york", "a * b", "York?"))
    # a * is a *, and nothing is a token pattern
    expect_identical(m$patterns, list(list(), list(), list()))
    expect_identical(lapply(m$phrases, `[[`, "words"),
                     list(list("new", "york"), list("a", "*", "b"), list("York?")))
    expect_true(all(vapply(m$phrases, `[[`, NA, "case_insensitive")))
    # only case_insensitive applies
    expect_false(match_patterns(col, case_insensitive = FALSE,
                                explicit = "case_insensitive")$phrases[[1]]$case_insensitive)
    expect_identical(match_patterns(col, "fixed", explicit = "valuetype"), m)
    expect_error(match_patterns(col, "glob", explicit = "valuetype"),
                 "valuetype = \"glob\" does not apply to collocations.*phrase\\(pattern\\)")
    expect_error(match_patterns(col, "regex", explicit = "valuetype"),
                 "valuetype = \"regex\" does not apply to collocations")
    # phrase() on collocations gives the wildcard reading
    skip_if_not_installed("quanteda")
    g <- match_patterns(quanteda::phrase(col))
    expect_identical(g$patterns[[2]], list(list(list(LOWER = "a"),
                                                list(LOWER = list(REGEX = "\\A[\\s\\S]*\\Z")),
                                                list(LOWER = "b"))))
})

test_that("a dictionary is converted with valuetype and case_insensitive", {
    skip_if_not_installed("quanteda")
    dict <- quanteda::dictionary(list(tax = c("Tax*", "income tax")), tolower = FALSE)
    m <- match_patterns(dict, "glob", FALSE, c("valuetype", "case_insensitive"))
    expect_identical(m$patterns, list(list(list(list(ORTH = list(REGEX = "\\ATax[\\s\\S]*\\Z"))))))
    expect_identical(m$phrases, list(list(label = "tax", text = "income tax",
                                          case_insensitive = FALSE)))
    r <- match_patterns(dict, "regex", TRUE, "valuetype")
    expect_identical(r$patterns[[1]][[1]], list(list(TEXT = list(REGEX = "(?i)Tax*"))))
    f <- match_patterns(dict, "fixed")
    expect_identical(vapply(f$phrases, `[[`, "", "text"), c("Tax*", "income tax"))
    # the defaults are those of as_entity_patterns() for a dictionary
    expect_identical(match_patterns(dict),
                     match_patterns(as_entity_patterns(dict)))
})

test_that("a list can hold character vectors with spaCy's patterns", {
    tok <- list(list(LOWER = "a"))
    m <- match_patterns(list(A = tok, c("new", "york*"), A = c("b", "c"), P = clause, "d"))
    expect_identical(m$labels, c("A", "new york*", "P", "d"))
    expect_identical(m$patterns[[1]], list(tok))
    expect_length(m$patterns[[2]], 1)
    expect_identical(vapply(m$phrases, `[[`, "", "label"), c("A", "d"))
    expect_identical(m$dependency, list(list(label = "P", pattern = clause)))
    # spaCy's patterns still need names, which must be unique among them
    expect_error(match_patterns(list(tok, "a")), "must be a named list")
    expect_error(match_patterns(list(A = tok, A = tok, "a")), "must be unique.*: A$")
})

test_that("strings of lexical patterns must be non-empty", {
    expect_error(match_patterns(c("a", NA)), "Element 2 of pattern is not a character")
    expect_error(match_patterns(c("a", "")), "Element 2 of pattern is not a character")
    expect_error(match_patterns(list(A = c("a", ""))),
                 "Element 1 of pattern \\('A'\\) is not a character")
    expect_error(match_patterns(list("a", character())), "Element 2 of pattern")
    # a space is a string: spaCy makes tokens of spaces
    expect_identical(match_patterns(" ")$phrases[[1]]$words, list(" "))
})

test_that("lexical options that cannot apply are an error", {
    try(spacy_finalize(), silent = TRUE)
    tif <- data.frame(doc_id = "d1", text = "a")
    ep <- as_entity_patterns(c(ORG = "Acme"))
    # token patterns, dependency patterns, both, and entity patterns
    expect_error(spacy_match("a", passive, valuetype = "regex"),
                 "^valuetype does not apply to pattern, which holds only spaCy's token")
    expect_error(spacy_match("a", passive, case_insensitive = TRUE),
                 "^case_insensitive does not apply to pattern")
    expect_error(spacy_match("a", list(CLAUSE = clause), case_insensitive = FALSE,
                             valuetype = "fixed"),
                 "^valuetype and case_insensitive do not apply to pattern")
    expect_error(spacy_match("a", c(passive, list(CLAUSE = clause)), valuetype = "glob"),
                 "^valuetype does not apply to pattern")
    expect_error(spacy_match("a", ep, case_insensitive = TRUE),
                 "case_insensitive does not apply to pattern, which holds only a spacyr_entity_patterns object.*as_entity_patterns\\(\\)")
    expect_error(spacy_match("a", ep, valuetype = "fixed"), "^valuetype does not apply")
    # also from a TIF data.frame, whose method passes its arguments on
    expect_error(spacy_match(tif, passive, valuetype = "regex"),
                 "^valuetype does not apply to pattern")
    # a value that is not valid is an error whatever the patterns
    expect_error(spacy_match("a", passive, valuetype = "wild"), "should be one of")
    expect_error(spacy_match("a", "a", valuetype = "wild"), "should be one of")
    expect_error(spacy_match("a", "a", case_insensitive = NA),
                 "case_insensitive must be TRUE or FALSE")
    expect_error(spacy_match("a", collocations("a b"), valuetype = "glob"),
                 "does not apply to collocations")
    # overlap is accepted whatever the patterns
    expect_error(spacy_match("a", list(CLAUSE = clause), overlap = "all",
                             valuetype = "glob"), "^valuetype does not apply")
    expect_null(getOption("spacy_initialized"))
    # the pattern functions agree: no error once anything lexical is there
    expect_silent(match_patterns(c(passive, list("a")), "regex", FALSE,
                                 c("valuetype", "case_insensitive")))
    expect_silent(match_patterns(passive))
    expect_silent(match_patterns(ep))
})

test_that("spacy_match finds passives by dependency and tag", {
    skip_on_cran()
    skip_on_os("solaris")
    try_spacy_initialize()

    m <- spacy_match(txt, passive)
    expect_s3_class(m, "data.frame", exact = TRUE)
    expect_identical(vapply(m, typeof, ""), match_columns)
    expect_identical(m$doc_id, c("doc1", "doc2", "doc2"))
    # numbered from 1 in each document; a sequence has no node
    expect_identical(m$match_id, c(1L, 1L, 2L))
    expect_identical(m$node, rep(NA_character_, 3))
    expect_identical(m$text, c("was written", "were made", "being rewritten"))
    expect_identical(m$label, rep("PASSIVE", 3))
    expect_identical(m$start_id, c(3L, 2L, 9L))
    expect_identical(m$length, c(2L, 2L, 2L))

    # the same from a TIF data.frame and with two processes
    tif <- data.frame(doc_id = names(txt), text = unname(txt))
    expect_identical(spacy_match(tif, passive), m)
    expect_identical(spacy_match(txt, passive, n_process = 2), m)
})

test_that("positions agree with spacy_parse, also across sentences", {
    skip_on_cran()
    skip_on_os("solaris")
    try_spacy_initialize()

    pats <- list(BOOK = list(list(LOWER = "book")),
                 # crosses the sentence boundary
                 CROSS = list(list(IS_PUNCT = TRUE), list(POS = "PROPN")))
    m <- spacy_match(txt["doc1"], pats)
    expect_identical(m$label, c("BOOK", "CROSS", "BOOK"))
    expect_identical(m$text, c("book", ". Jane", "book"))
    expect_identical(m$sentence_id, c(1L, 1L, 2L))
    expect_identical(m$token_id, c(2L, 7L, 4L))
    expect_identical(m$start_id, c(2L, 7L, 11L))

    parsed <- spacy_parse(txt["doc1"])
    joined <- merge(m, parsed, by = c("doc_id", "sentence_id", "token_id"), sort = FALSE)
    expect_identical(joined$token, c("book", ".", "book"))
    # start_id counts the tokens of the document
    expect_identical(parsed$token[m$start_id], c("book", ".", "book"))
})

test_that("overlap keeps all, the longest or the first matches of a label", {
    skip_on_cran()
    skip_on_os("solaris")
    try_spacy_initialize()

    pats <- list(B = list(list(LOWER = "red"), list(LOWER = "shiny")),
                 A = list(list(POS = "ADJ", OP = "+"), list(POS = "NOUN")))
    big <- "A big red shiny ball."
    all <- spacy_match(big, pats, overlap = "all")
    # by start, then length, then the order of the labels
    expect_identical(all$text, c("big red shiny ball", "red shiny", "red shiny ball",
                                 "shiny ball"))
    expect_identical(all$label, c("A", "B", "A", "A"))
    expect_identical(all$match_id, 1:4)
    for (overlap in c("longest", "first")) {
        m <- spacy_match(big, pats, overlap = overlap)
        # matches of different labels still overlap
        expect_identical(m$text, c("big red shiny ball", "red shiny"), info = overlap)
        expect_identical(m$label, c("A", "B"), info = overlap)
        expect_identical(m$match_id, 1:2, info = overlap)
    }
    # the longest is the default
    expect_identical(spacy_match(big, pats), spacy_match(big, pats, overlap = "longest"))
    # where the match that starts first is the shorter one, "first" and
    # "longest" differ
    alt <- list(X = list(list(list(LOWER = "a"), list(LOWER = "b")),
                         list(list(LOWER = "b"), list(LOWER = "c"),
                              list(LOWER = "d"), list(LOWER = "e"))))
    expect_identical(spacy_match("a b c d e", alt, overlap = "all")$text,
                     c("a b", "b c d e"))
    expect_identical(spacy_match("a b c d e", alt, overlap = "first")$text, "a b")
    expect_identical(spacy_match("a b c d e", alt, overlap = "longest")$text,
                     "b c d e")
    expect_identical(spacy_match("a b c d e", alt)$text, "b c d e")
    # the shortest of the matches with the same start comes first
    starts <- spacy_match("a b c", list(
        LONG = list(list(LOWER = "a"), list(LOWER = "b"), list(LOWER = "c")),
        SHORT = list(list(LOWER = "a"))))
    expect_identical(starts$label, c("SHORT", "LONG"))
    # equal spans are ordered by label
    same <- spacy_match("red", list(Z = list(list(LOWER = "red")),
                                              A = list(list(IS_ALPHA = TRUE))))
    expect_identical(same$label, c("Z", "A"))
})

test_that("alternatives, entity patterns and set operators match", {
    skip_on_cran()
    skip_on_os("solaris")
    try_spacy_initialize()

    alt <- list(WRITE = list(list(list(LEMMA = "write")), list(list(LEMMA = "rewrite"))))
    m <- spacy_match(txt, alt)
    expect_identical(m$text, c("written", "wrote", "rewritten"))
    ep <- as_entity_patterns(list(
        list(label = "WRITE", pattern = list(list(LEMMA = "write"))),
        list(label = "WRITE", pattern = list(list(LEMMA = "rewrite")))))
    expect_identical(spacy_match(txt, ep), m)

    # a set operator with one value, which spaCy accepts as an array only
    past <- spacy_match("Jane wrote books.", list(
        PAST = list(list(MORPH = list(IS_SUPERSET = "Tense=Past")))))
    expect_identical(past$text, "wrote")
    # an empty token matches any token
    any <- spacy_match("Jane wrote books.", list(ANY = list(list())))
    expect_identical(any$text, c("Jane", "wrote", "books", "."))
})

test_that("custom attributes named like operators are not read as operators", {
    skip_on_cran()
    skip_on_os("solaris")
    try_spacy_initialize()
    reticulate::py_run_string(paste(
        "from spacy.tokens import Token",
        "Token.set_extension('is_subset', default = 'x', force = True)",
        "Token.set_extension('spacyr_tags', default = ['a', 'b'], force = True)",
        "Token.set_extension('REGEX', default = 'x', force = True)",
        sep = "\n"))
    on.exit(reticulate::py_run_string(paste(
        "Token.remove_extension('is_subset')",
        "Token.remove_extension('spacyr_tags')",
        "Token.remove_extension('REGEX')", sep = "\n")))

    run <- function(...) spacy_match("red ball", list(X = list(list(`_` = list(...)))))
    expect_identical(run(is_subset = "x")$text, c("red", "ball"))
    expect_identical(nrow(run(is_subset = "y")), 0L)
    # operators still apply within the value of a custom attribute
    expect_identical(run(is_subset = list(IN = "x"))$text, c("red", "ball"))
    expect_identical(run(spacyr_tags = list(IS_SUPERSET = "a"))$text, c("red", "ball"))
    expect_identical(nrow(run(spacyr_tags = list(IS_SUPERSET = "z"))), 0L)

    # an extension called REGEX: its alternatives are equality checks, which
    # must not be merged into one regular expression
    alt <- list(X = list(list(list(`_` = list(REGEX = "x"))),
                         list(list(`_` = list(REGEX = "y")))))
    expect_identical(spacy_match("red ball", alt)$text, c("red", "ball"))
    none <- list(X = list(list(list(`_` = list(REGEX = "y"))),
                          list(list(`_` = list(REGEX = "z")))))
    expect_identical(nrow(spacy_match("red ball", none)), 0L)
    # a regular expression on a custom attribute still works
    rx <- list(X = list(list(list(`_` = list(is_subset = list(REGEX = "^[xy]$")))),
                        list(list(LOWER = list(REGEX = "^b"))),
                        list(list(LOWER = list(REGEX = "^r")))))
    expect_identical(spacy_match("red ball", rx)$text, c("red", "ball"))
})

test_that("phrases of entity patterns match exactly or in any case", {
    skip_on_cran()
    skip_on_os("solaris")
    try_spacy_initialize()

    x <- c(d1 = "Acme Widgets sued ACME WIDGETS in New York.",
           d2 = "Trade between new york and Paris.")
    ep <- c(as_entity_patterns(c(ORG = "Acme Widgets", GPE = "New York")),
            as_entity_patterns(list(label = "GPE", pattern = list(list(LOWER = "paris")))))
    m <- spacy_match(x, ep)
    expect_named(m, names(match_columns))
    expect_identical(m$text, c("Acme Widgets", "New York", "Paris"))
    expect_identical(m$label, c("ORG", "GPE", "GPE"))
    expect_identical(m$start_id, c(1L, 7L, 6L))
    expect_identical(m$length, c(2L, 2L, 1L))

    any <- spacy_match(x, as_entity_patterns(c(ORG = "acme widgets", GPE = "NEW YORK"),
                                                       case_insensitive = TRUE))
    expect_identical(any$text, c("Acme Widgets", "ACME WIDGETS", "New York", "new york"))
    # exact and any-case phrases together, with two processes
    both <- c(as_entity_patterns(c(ORG = "Acme Widgets")),
              as_entity_patterns(c(GPE = "new york"), case_insensitive = TRUE))
    m <- spacy_match(x, both)
    expect_identical(m$text, c("Acme Widgets", "New York", "new york"))
    expect_identical(spacy_match(x, both, n_process = 2), m)

    # case can change how spaCy tokenizes a phrase: "Inc." is one token,
    # "inc." two
    inc <- "We sued Acme Widgets, Inc. today."
    expect_identical(nrow(spacy_match(inc, as_entity_patterns(
        c(ORG = "acme widgets, inc."), case_insensitive = TRUE))), 0L)
    expect_identical(spacy_match(inc, as_entity_patterns(
        c(ORG = "ACME Widgets, Inc."), case_insensitive = TRUE))$text, "Acme Widgets, Inc.")

    # phrases are split into spaCy's tokens, not at spaces
    comma <- spacy_match("We met Smith, Jones and Brown.",
                                   as_entity_patterns(c(NAMES = "Smith, Jones")))
    expect_identical(comma$text, "Smith, Jones")
    expect_identical(comma$length, 3L)

    # the same span found by a phrase and a token pattern is one match
    twice <- c(as_entity_patterns(c(GPE = "New York")),
               as_entity_patterns(list(label = "GPE", pattern = list(
                   list(LOWER = "new"), list(LOWER = "york")))))
    m <- spacy_match(x, twice)
    expect_identical(m$text, c("New York", "new york"))
    expect_identical(nrow(spacy_match("Nothing here.", twice)), 0L)
})

test_that("overlap applies to the phrases and token patterns of a label together", {
    skip_on_cran()
    skip_on_os("solaris")
    try_spacy_initialize()

    ep <- c(as_entity_patterns(c(X = "a b", Y = "b c")),
            as_entity_patterns(list(label = "X", pattern = list(
                list(LOWER = "b"), list(LOWER = "c"), list(LOWER = "d"), list(LOWER = "e")))))
    all <- spacy_match("a b c d e", ep, overlap = "all")
    expect_identical(all$text, c("a b", "b c", "b c d e"))
    expect_identical(all$label, c("X", "Y", "X"))
    first <- spacy_match("a b c d e", ep, overlap = "first")
    expect_identical(first$text, c("a b", "b c"))
    longest <- spacy_match("a b c d e", ep, overlap = "longest")
    expect_identical(longest$text, c("b c", "b c d e"))
    expect_identical(longest$label, c("Y", "X"))
})

test_that("overlap agrees with the greedy option of spaCy's Matcher", {
    skip_on_cran()
    skip_on_os("solaris")
    try_spacy_initialize()

    x <- paste("The big red shiny ball and a small blue box sat on the old",
               "brown wooden kitchen table near a very large open window.")
    pats <- list(A = list(list(POS = "ADJ", OP = "+"), list(POS = "NOUN", OP = "+")),
                 B = list(list(list(POS = "DET"), list(POS = "ADJ", OP = "*")),
                          list(list(POS = "ADJ"), list(POS = "ADJ"))),
                 C = list(list(), list(OP = "?"), list(POS = "NOUN")))
    spacy_greedy <- reticulate::py_eval(paste(
        "lambda nlp, text, labels, patterns, greedy:",
        "(lambda m, d: [m.add(l, p, greedy = greedy) for l, p in zip(labels, patterns)] and",
        "sorted([nlp.vocab.strings[k], s + 1, e - s] for k, s, e in m(d)))",
        "(__import__('spacy').matcher.Matcher(nlp.vocab), nlp(text))"))
    mp <- match_patterns(pats)
    for (overlap in c("first", "longest")) {
        ours <- spacy_match(x, pats, overlap = overlap)
        theirs <- spacy_greedy(spacyr:::spacyr_env$nlp, x, as.list(mp$labels), mp$patterns,
                               toupper(overlap))
        theirs <- do.call(rbind, lapply(theirs, function(r)
            data.frame(label = r[[1]], start_id = r[[2]], length = r[[3]])))
        ours <- ours[order(ours$label, ours$start_id, ours$length), ]
        expect_gt(nrow(ours), 5)
        expect_identical(ours$label, theirs$label, info = overlap)
        expect_identical(ours$start_id, as.integer(theirs$start_id), info = overlap)
        expect_identical(ours$length, as.integer(theirs$length), info = overlap)
    }
})

test_that("a quanteda dictionary is matched with its wildcards", {
    skip_on_cran()
    skip_on_os("solaris")
    skip_if_not_installed("quanteda")
    try_spacy_initialize()

    x <- c(d1 = "Taxes rose in New York.", d2 = "The taxation of Acme Widgets.")
    d <- quanteda::dictionary(list(tax = c("tax*", "new york"), org = "acme widgets"))
    m <- spacy_match(x, d)
    expect_identical(m$text, c("Taxes", "New York", "taxation", "Acme Widgets"))
    expect_identical(m$label, c("tax", "tax", "tax", "org"))
    # many wildcard values of a label are matched as one regular expression
    many <- quanteda::dictionary(list(t = c("tax*", "ros?", "wid*")))
    expect_identical(spacy_match(x, many)$text,
                     c("Taxes", "rose", "taxation", "Widgets"))
    # entities are not changed
    expect_false("tax" %in% spacy_extract_entity(x)$ent_type)
})

test_that("phrases warn when a component changes the tokens", {
    skip_on_cran()
    skip_on_os("solaris")
    try(spacy_finalize(), silent = TRUE)
    try_spacy_initialize()
    on.exit(spacy_finalize())
    spacyr:::spacyr_env$nlp$add_pipe("merge_entities")

    expect_warning(spacy_match("He lives in New York.",
                                         as_entity_patterns(c(GPE = "New York"))),
                   "Phrases may not match, since 'merge_entities' changes the tokens")
    expect_silent(spacy_match("He lives in New York.",
                                        list(GPE = list(list(LOWER = "new york")))))
})

test_that("no matches give a data.frame with no rows", {
    skip_on_cran()
    skip_on_os("solaris")
    try_spacy_initialize()

    for (x in list(character(0), "Nothing here.", c(a = "", b = NA))) {
        # the same columns for sequences, dependency patterns and both
        for (pattern in list(passive, list(CLAUSE = clause),
                             c(passive, list(CLAUSE = clause)))) {
            m <- spacy_match(x, pattern)
            expect_s3_class(m, "data.frame", exact = TRUE)
            expect_identical(nrow(m), 0L)
            expect_identical(vapply(m, typeof, ""), match_columns)
        }
    }
})

test_that("sequences and dependency patterns give rows of one table", {
    skip_on_cran()
    skip_on_os("solaris")
    try_spacy_initialize()

    book <- list(BOOK = list(list(LOWER = "book")))
    seq_only <- spacy_match(txt, c(passive, book))
    dep_only <- spacy_match(txt, list(CLAUSE = clause))
    both <- spacy_match(txt, c(passive, list(CLAUSE = clause), book))
    for (m in list(seq_only, dep_only, both)) {
        expect_s3_class(m, "data.frame", exact = TRUE)
        expect_identical(vapply(m, typeof, ""), match_columns)
    }
    # a sequence is one row without a node; a dependency match is one row
    # of length 1 for each node
    expect_identical(seq_only$node, rep(NA_character_, 5))
    expect_identical(dep_only$node, rep(c("verb", "subject", "aux"), 3))
    expect_identical(dep_only$length, rep(1L, 9))

    # matched in one pass, the matches are those of each kind alone
    key <- c("doc_id", "label", "node", "sentence_id", "token_id", "text",
             "start_id", "length")
    rows <- function(m) {
        m <- m[order(m$doc_id, m$label, m$start_id, m$node), key]
        rownames(m) <- NULL
        m
    }
    expect_identical(rows(both), rows(rbind(seq_only, dep_only)))

    # in each document, matches are in the order of the position of their
    # first row, and numbered in that order, both kinds together
    d1 <- both[both$doc_id == "doc1", ]
    expect_identical(d1$label, c("BOOK", "PASSIVE", rep("CLAUSE", 3), "BOOK"))
    expect_identical(d1$match_id, c(1L, 2L, 3L, 3L, 3L, 4L))
    expect_identical(d1$node, c(NA, NA, "verb", "subject", "aux", NA))
    expect_identical(d1$text, c("book", "was written", "written", "book", "was", "book"))
    expect_identical(d1$start_id, c(2L, 3L, 4L, 2L, 3L, 11L))
    expect_identical(d1$length, c(1L, 2L, 1L, 1L, 1L, 1L))
    d2 <- both[both$doc_id == "doc2", ]
    expect_identical(d2$match_id, c(1L, 2L, 2L, 2L, 3L, 4L, 4L, 4L))
    first <- both[!duplicated(both[, c("doc_id", "match_id")]), ]
    expect_identical(first$start_id, c(2L, 3L, 4L, 11L, 2L, 3L, 9L, 10L))

    # at the same token, sequences come before dependency matches, whatever
    # the order of the labels
    verb <- list(VERB = list(list(RIGHT_ID = "verb", RIGHT_ATTRS = list(TAG = "VBN"))))
    same <- spacy_match(txt["doc1"], c(verb, list(SHORT = list(list(TAG = "VBN")),
                                                  LONG = list(list(TAG = "VBN"), list()))))
    expect_identical(same$label, c("SHORT", "LONG", "VERB"))
    expect_identical(same$match_id, 1:3)
    expect_identical(same$start_id, c(4L, 4L, 4L))

    # overlap has no effect on dependency patterns alone, so it can be given
    # whatever the patterns: the matches are those found without it
    tif <- data.frame(doc_id = names(txt), text = unname(txt))
    for (overlap in c("longest", "all", "first")) {
        expect_identical(spacy_match(txt, list(CLAUSE = clause), overlap = overlap),
                         dep_only, info = overlap)
        expect_identical(spacy_match(tif, list(CLAUSE = clause), overlap = overlap),
                         dep_only, info = overlap)
    }

    # overlap applies to the sequences of a list with both kinds
    child <- list(
        list(RIGHT_ID = "verb", RIGHT_ATTRS = list(POS = "VERB")),
        list(LEFT_ID = "verb", REL_OP = ">", RIGHT_ID = "child", RIGHT_ATTRS = list()))
    pats <- list(ADJ_NOUN = list(list(POS = "ADJ", OP = "+"), list(POS = "NOUN")),
                 VERB_CHILD = child)
    x <- "Jane quickly wrote the long dull book."
    n <- function(overlap) table(unique(spacy_match(x, pats, overlap = overlap)[
        , c("match_id", "label")])$label)
    expect_identical(as.vector(n("all")[c("ADJ_NOUN", "VERB_CHILD")]), c(2L, 4L))
    expect_identical(as.vector(n("longest")[c("ADJ_NOUN", "VERB_CHILD")]), c(1L, 4L))
    expect_identical(as.vector(n("first")[c("ADJ_NOUN", "VERB_CHILD")]), c(1L, 4L))
    # overlap passes through the TIF data.frame method
    tif_x <- data.frame(doc_id = "text1", text = x)
    for (overlap in c("all", "longest", "first")) {
        expect_identical(spacy_match(tif_x, pats, overlap = overlap),
                         spacy_match(x, pats, overlap = overlap), info = overlap)
    }

    # the same from a TIF data.frame and with two processes
    expect_identical(spacy_match(tif, c(passive, list(CLAUSE = clause), book)), both)
    expect_identical(spacy_match(txt, c(passive, list(CLAUSE = clause), book),
                                 n_process = 2), both)
})

test_that("a quanteda corpus is matched as its texts are", {
    skip_on_cran()
    skip_on_os("solaris")
    skip_if_not_installed("quanteda")
    try_spacy_initialize()

    corp <- quanteda::corpus(txt, docvars = data.frame(year = 1:2))
    pattern <- c(passive, list(CLAUSE = clause))
    m <- spacy_match(corp, pattern)
    expect_identical(m, spacy_match(txt, pattern))
    expect_identical(unique(m$doc_id), quanteda::docnames(corp))
    # with a dictionary as the pattern
    d <- quanteda::dictionary(list(writing = c("writ*", "wrote"), error = "mistake*"))
    expect_identical(spacy_match(corp, d)$text, c("written", "wrote", "Mistakes"))
})

test_that("start_id counts whitespace tokens, as spacy_parse does", {
    skip_on_cran()
    skip_on_os("solaris")
    try_spacy_initialize()

    x <- "A  New York office was opened."
    m <- spacy_match(x, c(as.list(passive),
                          list(NY = list(list(LOWER = "new"), list(LOWER = "york")),
                               CLAUSE = clause)))
    parsed <- spacy_parse(x)
    # the two spaces make a token of the second
    expect_identical(parsed$token[2], " ")
    expect_identical(m$start_id[m$label == "NY"], 3L)
    expect_identical(parsed$token[m$start_id], sub(" .*", "", m$text))
})

test_that("overlap = 'longest' gives the matches of tokens_lookup for each key", {
    skip_on_cran()
    skip_on_os("solaris")
    skip_if_not_installed("quanteda")
    try_spacy_initialize()

    nyt <- "The New York Times is a New York paper."
    # the text, the dictionary, and the matches expected as label from:to
    cases <- list(
        list(nyt, list(paper = "New York Times", city = "New York"),
             c("city 2:3", "paper 2:4", "city 7:8")),
        list(nyt, list(place = c("New York Times", "New York")),
             c("place 2:4", "place 7:8")),
        list("a b c", list(k = c("a b", "b c")), "k 1:2"),
        list("a b c", list(A = "a b", B = "b c"), c("A 1:2", "B 2:3")),
        list("a b c", list(A = "a b", B = "b c", C = "c"), c("A 1:2", "B 2:3", "C 3:3")),
        list("a b c d", list(k = c("b c", "a b", "c d")), c("k 1:2", "k 3:4")),
        list("new york city", list(k = c("york", "new york city")), "k 1:3"),
        list("new york", list(A = "new york", B = "new york"), c("A 1:2", "B 1:2")))
    for (case in cases) {
        x <- case[[1]]
        d <- quanteda::dictionary(case[[2]])
        info <- paste(x, deparse(case[[2]]))
        m <- spacy_match(x, d)
        expect_identical(m, spacy_match(x, d, overlap = "longest"), info = info)
        expect_identical(paste0(m$label, " ", m$start_id, ":", m$start_id + m$length - 1L),
                         case[[3]], info = info)
        # the keys that quanteda finds on the same tokens, of any order
        toks <- quanteda::as.tokens(spacy_parse(x))
        lookup <- quanteda::tokens_lookup(toks, d, nested_scope = "key")
        expect_identical(sort(m$label), sort(as.character(lookup)), info = info)
    }
    # a match is a distinct doc_id and match_id, which for sequences is a row
    m <- spacy_match(nyt, quanteda::dictionary(cases[[1]][[2]]))
    expect_identical(nrow(unique(m[, c("doc_id", "match_id")])), nrow(m))
    # every match, which is more in the cases with nested or overlapping values
    all <- vapply(cases, function(case)
        nrow(spacy_match(case[[1]], quanteda::dictionary(case[[2]]), overlap = "all")), 1L)
    expect_identical(all, c(3L, 3L, 2L, 2L, 3L, 3L, 2L, 2L))
})

test_that("spaCy's errors for patterns are shown", {
    skip_on_cran()
    skip_on_os("solaris")
    try_spacy_initialize()

    expect_error(spacy_match(txt, list(X = list(list(LOWR = "a")))),
                 "spaCy could not match the patterns:.*rule 'X'.*LOWR")
})

test_that("documents without sentence boundaries have no sentence positions", {
    skip_on_cran()
    skip_on_os("solaris")
    try(spacy_finalize(), silent = TRUE)
    try_spacy_initialize()
    on.exit(spacy_finalize())
    spacyr:::spacyr_env$nlp$disable_pipe("parser")

    m <- spacy_match(txt["doc1"], list(BOOK = list(list(LOWER = "book"))))
    expect_identical(m$text, c("book", "book"))
    expect_identical(m$sentence_id, c(NA_integer_, NA_integer_))
    expect_identical(m$token_id, c(NA_integer_, NA_integer_))
    expect_identical(m$start_id, c(2L, 11L))
    # spaCy names the component that a pattern needs
    expect_error(spacy_match(txt, passive),
                 "spaCy could not match the patterns:.*E155.*parser")
})

test_that("patterns that need entities warn when nothing sets them", {
    skip_on_cran()
    skip_on_os("solaris")
    person <- list(PERSON = list(list(ENT_TYPE = "PERSON", OP = "+")))
    try(spacy_finalize(), silent = TRUE)
    suppressMessages(spacy_initialize(entity = FALSE))
    on.exit(spacy_finalize())
    expect_warning(m <- spacy_match(txt, person),
                   "need entities \\(ENT_TYPE or ENT_IOB\\)")
    expect_identical(nrow(m), 0L)
    expect_silent(spacy_match(txt, passive))

    spacy_finalize()
    suppressMessages(spacy_initialize())
    expect_silent(m <- spacy_match(txt, person, overlap = "longest"))
    expect_identical(m$text, c("Jane", "Jane"))
})

test_that("documents left out by the pipeline are reported", {
    skip_on_cran()
    skip_on_os("solaris")
    try(spacy_finalize(), silent = TRUE)
    try_spacy_initialize()
    components <- reticulate::import_from_path("spacyr_test_components",
                                               path = test_path("python"))
    nlp <- spacyr:::spacyr_env$nlp
    nlp$add_pipe("spacyr_test_fail_on_bad", last = TRUE)
    components$skip_errors(nlp)
    on.exit(spacy_finalize())

    x <- c(bad = "Bad book.", good = "A good book.")
    expect_warning(m <- spacy_match(x, list(BOOK = list(list(LOWER = "book")))),
                   "did not return 1 document, which is left out of the output: bad")
    expect_identical(m$doc_id, "good")
    expect_identical(m$start_id, 3L)
})

test_that("dictionary matches differ from tokens_lookup where the candidates differ", {
    skip_on_cran()
    skip_on_os("solaris")
    skip_if_not_installed("quanteda")
    try_spacy_initialize()

    # a value without a wildcard is a phrase that spaCy tokenizes, where
    # quanteda splits it at its spaces and looks for the token "Acme,"
    x <- "She joined Acme, Inc. last year."
    d <- quanteda::dictionary(list(ORG = "Acme, Inc."), tolower = FALSE)
    m <- spacy_match(x, d)
    expect_identical(m$text, "Acme, Inc.")
    expect_identical(m$start_id, 3L)
    expect_identical(m$length, 3L)
    toks <- quanteda::as.tokens(spacy_parse(x))
    expect_identical(as.character(toks)[3:5], c("Acme", ",", "Inc."))
    expect_identical(quanteda::ntoken(quanteda::tokens_lookup(toks, d, nested_scope = "key")),
                     c(text1 = 0L))

    # the values of nested keys are labelled by their top-level key, as with
    # levels = 1, which is not the default of tokens_lookup()
    y <- "New York is larger than York."
    nested <- quanteda::dictionary(list(place = list(us = "new york", uk = "york")))
    m <- spacy_match(y, nested)
    expect_identical(m$label, c("place", "place"))
    expect_identical(m$text, c("New York", "York"))
    toks <- quanteda::as.tokens(spacy_parse(y))
    expect_identical(as.character(quanteda::tokens_lookup(toks, nested, levels = 1)),
                     m$label)
    expect_identical(as.character(quanteda::tokens_lookup(toks, nested)),
                     c("place.us", "place.uk", "place.uk"))
})

# lexical patterns, with spaCy

lex <- c(d1 = "Taxes and taxation in New York. New Yorkers pay tax; new york has a Tax.",
         d2 = "The New York Times is not the York Times.")

test_that("a character vector matches one token for each element", {
    skip_on_cran()
    try_spacy_initialize()
    m <- spacy_match(lex, "tax*")
    expect_identical(vapply(m, class, ""), match_columns)
    expect_identical(m$text, c("Taxes", "taxation", "tax", "Tax"))
    expect_identical(m$label, rep("tax*", 4))
    expect_identical(m$start_id, c(1L, 3L, 11L, 17L))
    expect_true(all(m$length == 1L) && all(is.na(m$node)))
    # names are labels, and elements with the same name are alternatives
    m <- spacy_match(lex, c(TAX = "tax*", TAX = "pay", PLACE = "york"))
    expect_identical(m$label[m$doc_id == "d1"], c("TAX", "TAX", "PLACE", "TAX", "TAX", "PLACE", "TAX"))
    expect_identical(m$text[m$doc_id == "d1"],
                     c("Taxes", "taxation", "York", "pay", "tax", "york", "Tax"))
    # case, and the other value types
    expect_identical(spacy_match(lex, "tax*", case_insensitive = FALSE)$text,
                     c("taxation", "tax"))
    expect_identical(spacy_match(lex, "Tax", case_insensitive = FALSE)$text, "Tax")
    expect_identical(spacy_match(lex, "TAX")$text, c("tax", "Tax"))
    expect_identical(spacy_match(lex, "^tax(es|ation)$", valuetype = "regex")$text,
                     c("Taxes", "taxation"))
    # a regular expression can match a part of a token
    expect_identical(spacy_match(lex, "T.x", valuetype = "regex",
                                 case_insensitive = FALSE)$text, c("Taxes", "Tax"))
    expect_identical(nrow(spacy_match(lex, "tax*", valuetype = "fixed")), 0L)
    expect_identical(spacy_match(lex, "tax", valuetype = "fixed")$text, c("tax", "Tax"))
    # from a TIF data.frame and a corpus
    tif <- data.frame(doc_id = names(lex), text = lex, stringsAsFactors = FALSE)
    expect_identical(spacy_match(tif, "tax*", case_insensitive = FALSE),
                     spacy_match(lex, "tax*", case_insensitive = FALSE))
    skip_if_not_installed("quanteda")
    expect_identical(spacy_match(quanteda::corpus(lex), "tax*"), spacy_match(lex, "tax*"))
})

test_that("a character element with a space is one token, without a message", {
    skip_on_cran()
    try_spacy_initialize()
    expect_silent(m <- spacy_match(lex, "new york"))
    expect_identical(nrow(m), 0L)
    expect_identical(vapply(m, class, ""), match_columns)
    # spaCy makes a token of a space after a space, which a pattern can match
    m <- spacy_match("A  New York office", c(SPACE = " "))
    expect_identical(m$start_id, 2L)
    expect_identical(m$text, " ")
})

test_that("phrase() patterns match as quanteda's index() on spaCy's tokens", {
    skip_on_cran()
    skip_if_not_installed("quanteda")
    try_spacy_initialize()
    toks <- quanteda::as.tokens(spacy_parse(lex))
    same_as_index <- function(pattern, ...) {
        m <- spacy_match(lex, pattern, overlap = "all", ...)
        idx <- as.data.frame(quanteda::index(toks, pattern, ...))
        idx <- idx[order(match(idx$docname, names(lex)), idx$from, idx$to), ]
        expect_identical(m$doc_id, idx$docname)
        expect_identical(m$start_id, idx$from)
        expect_identical(m$start_id + m$length - 1L, idx$to)
        expect_identical(m$label, as.character(idx$pattern))
        m
    }
    m <- same_as_index(quanteda::phrase("new york*"))
    expect_identical(m$text, c("New York", "New Yorkers", "new york", "New York"))
    expect_identical(m$label, rep("new york*", 4))
    m <- same_as_index(quanteda::phrase("new york*"), case_insensitive = FALSE)
    expect_identical(m$text, "new york")
    same_as_index(quanteda::phrase(c("new york", "york times", "tax*")))
    same_as_index(quanteda::phrase("New York"), valuetype = "fixed",
                  case_insensitive = FALSE)
    same_as_index(quanteda::phrase("^new$ ^york"), valuetype = "regex")
    same_as_index(c("tax*", "york", "new york"))
    # a list of character vectors is the same, with its names as labels
    l <- spacy_match(lex, list(NY = c("new", "york*")))
    expect_identical(l[-3], spacy_match(lex, quanteda::phrase("new york*"))[-3])
    expect_identical(unique(l$label), "NY")
})

test_that("the strings of a phrase are the tokens, not tokenized again", {
    skip_on_cran()
    skip_if_not_installed("quanteda")
    try_spacy_initialize()
    acme <- "She joined Acme, Inc. last year."
    # spaCy's tokens are Acme , Inc.
    expect_identical(nrow(spacy_match(acme, quanteda::phrase("Acme, Inc."))), 0L)
    m <- spacy_match(acme, quanteda::phrase("Acme , Inc."))
    expect_identical(m$text, "Acme, Inc.")
    expect_identical(m$label, "Acme , Inc.")
    expect_identical(c(m$start_id, m$length), c(3L, 3L))
    # as in quanteda on the same tokens
    idx <- quanteda::index(quanteda::as.tokens(spacy_parse(acme)),
                           quanteda::phrase("Acme , Inc."))
    expect_identical(c(idx$from, idx$to), c(3L, 5L))
    # case is compared token by token, whatever case does to tokenization
    expect_identical(spacy_match(acme, list(c("acme", ",", "inc.")))$text, "Acme, Inc.")
    # no warning for a component that changes the tokens: the words are the
    # caller's
    expect_silent(spacy_match(acme, list(c("acme", ",", "inc."))))
})

test_that("collocations match their words literally", {
    skip_on_cran()
    try_spacy_initialize()
    star <- c(d1 = "New York and new yorkers.", d2 = "a * b and a c b")
    col <- collocations(c("new york", "a * b", "new york*"))
    m <- spacy_match(star, col)
    expect_identical(m$text, c("New York", "a * b"))
    expect_identical(m$label, c("new york", "a * b"))
    expect_identical(spacy_match(star, col, case_insensitive = FALSE)$text, "a * b")
    expect_identical(spacy_match(star, col, valuetype = "fixed"), m)
    # phrase() on the collocations reads the wildcards
    skip_if_not_installed("quanteda")
    g <- spacy_match(star, quanteda::phrase(col), overlap = "all")
    expect_identical(g$text, c("New York", "New York", "new yorkers", "a * b", "a c b"))
    # as quanteda matches both on the same tokens
    toks <- quanteda::as.tokens(spacy_parse(star))
    idx <- as.data.frame(quanteda::index(toks, col))
    expect_identical(paste(m$doc_id, m$start_id, m$start_id + m$length - 1L),
                     paste(idx$docname, idx$from, idx$to))
})

test_that("valuetype and case_insensitive apply to a dictionary", {
    skip_on_cran()
    skip_if_not_installed("quanteda")
    try_spacy_initialize()
    dict <- quanteda::dictionary(list(tax = c("tax*", "new york")))
    expect_identical(spacy_match(lex["d1"], dict)$text,
                     c("Taxes", "taxation", "New York", "tax", "new york", "Tax"))
    expect_identical(spacy_match(lex["d1"], dict, case_insensitive = FALSE)$text,
                     c("taxation", "tax", "new york"))
    expect_identical(spacy_match(lex["d1"], dict, valuetype = "fixed")$text,
                     c("New York", "new york"))
    rx <- quanteda::dictionary(list(tax = "^tax.+"))
    expect_identical(spacy_match(lex["d1"], rx, valuetype = "regex")$text,
                     c("Taxes", "taxation"))
    expect_identical(spacy_match(lex["d1"], dict),
                     spacy_match(lex["d1"], as_entity_patterns(dict)))
})

test_that("overlap applies to the matches of lexical patterns", {
    skip_on_cran()
    try_spacy_initialize()
    # words and tokens patterns of one label, and another label
    pats <- list(P = c("new", "york", "times"), P = c("new", "york"), P = "york",
                 P = c("york", "t*"), Q = "york")
    all <- spacy_match(lex["d2"], pats, overlap = "all")
    expect_identical(paste(all$label, all$start_id, all$length),
                     c("P 2 2", "P 2 3", "P 3 1", "Q 3 1", "P 3 2", "P 8 1", "Q 8 1", "P 8 2"))
    longest <- spacy_match(lex["d2"], pats, overlap = "longest")
    expect_identical(longest, spacy_match(lex["d2"], pats))
    expect_identical(paste(longest$label, longest$start_id, longest$length),
                     c("P 2 3", "Q 3 1", "Q 8 1", "P 8 2"))
    first <- spacy_match(lex["d2"], pats, overlap = "first")
    expect_identical(paste(first$label, first$start_id, first$length),
                     c("P 2 3", "Q 3 1", "Q 8 1", "P 8 2"))
    expect_identical(longest$match_id, 1:4)
    # with a dependency pattern in the list, to which it does not apply
    mixed <- spacy_match("The New York book was written.",
                         list(c("new", "york"), "york", CLAUSE = clause))
    expect_identical(mixed$label, c("new york", "york", rep("CLAUSE", 3)))
})

test_that("phrases as words give the same matches as token patterns", {
    skip_on_cran()
    try_spacy_initialize()
    set.seed(42)
    words <- unique(replicate(600, paste(sample(letters, 4, TRUE), collapse = "")))
    seqs <- c(lapply(seq(1, 499, 2), function(i) words[i:(i + 1)]),
              list(c("new", "york"), c("york", "times"), "tax", c("New", "York", "Times"),
                   c("the", "york", "times", ".")))
    labels <- vapply(seqs, paste, "", collapse = " ")
    for (ci in c(TRUE, FALSE)) {
        fast <- match_patterns(seqs, case_insensitive = ci)
        expect_identical(fast$patterns, rep(list(list()), length(seqs)))
        expect_length(fast$phrases, length(seqs))
        attr <- if (ci) "LOWER" else "ORTH"
        slow <- stats::setNames(lapply(seqs, function(p) lapply(p, function(w)
            stats::setNames(list(if (ci) tolower(w) else w), attr))), labels)
        for (overlap in c("all", "longest")) {
            m <- spacy_match(lex, seqs, case_insensitive = ci, overlap = overlap)
            expect_identical(m, spacy_match(lex, slow, overlap = overlap))
            expect_gt(nrow(m), 2)
        }
    }
    # and with two processes
    expect_identical(spacy_match(lex, seqs, n_process = 2L), spacy_match(lex, seqs))
})

test_that("lexical patterns can be mixed with spaCy's patterns", {
    skip_on_cran()
    try_spacy_initialize()
    m <- spacy_match("The New York book was written.",
                     list(NY = c("new", "york*"), DET = list(list(POS = "DET")),
                          CLAUSE = clause), case_insensitive = FALSE)
    # case_insensitive applies to the character vector only
    expect_identical(m$label, c("DET", rep("CLAUSE", 3)))
    m <- spacy_match("The New York book was written.",
                     list(NY = c("new", "york*"), DET = list(list(POS = "DET")),
                          NY = list(list(LOWER = "book"))))
    expect_identical(m$label, c("DET", "NY", "NY"))
    expect_identical(m$text, c("The", "New York", "book"))
})

test_that("a regular expression that Python does not accept is an error", {
    skip_on_cran()
    try_spacy_initialize()
    expect_error(spacy_match(lex, "^\\p{L}+$", valuetype = "regex"),
                 "spaCy could not match the patterns")
})

test_that("a glob matches tokens of newlines, as quanteda's does", {
    skip_on_cran()
    skip_if_not_installed("quanteda")
    try_spacy_initialize()
    txt <- c(d1 = "A\n\nB", d2 = "A\nB")
    m <- spacy_match(txt, "*")
    idx <- quanteda::index(quanteda::as.tokens(spacy_parse(txt)), "*")
    expect_identical(m$start_id, idx$from)
    expect_identical(m$doc_id, idx$docname)
    expect_identical(m$start_id, c(1:3, 1:3))
    # and so do its other wildcards
    expect_identical(spacy_match(txt, "?*")$start_id, c(1:3, 1:3))
    expect_identical(spacy_match(txt, "?")$text, c("A", "B", "A", "\n", "B"))
    # the whole of a token: "$" would match before a last newline
    expect_identical(spacy_match(txt, c("a*", "?"), case_insensitive = TRUE,
                                 overlap = "all")$text,
                     c("A", "A", "B", "A", "A", "\n", "B"))
    expect_identical(spacy_match(txt, list(c("a", "*", "b")))$doc_id, c("d1", "d2"))
})

test_that("a phrase with a wildcard ignores case as one without does", {
    skip_on_cran()
    skip_if_not(l10n_info()[["UTF-8"]], "not a UTF-8 locale")
    try_spacy_initialize()
    # R's tolower() and spaCy's LOWER differ for a dotted capital I
    txt <- "\u0130stanbul office and \u00c9COLE Normale"
    whole <- spacy_match(txt, list(c("\u0130stanbul", "office"),
                                   c("\u00e9cole", "normale")))
    glob <- spacy_match(txt, list(c("\u0130stanbul", "off*"),
                                  c("\u00e9cole", "norm*")))
    expect_identical(whole$text, c("\u0130stanbul office", "\u00c9COLE Normale"))
    expect_identical(glob$text, whole$text)
    expect_identical(spacy_match(txt, "\u0130stanb*")$text, "\u0130stanbul")
    expect_identical(spacy_lower(c("New", "\u0130stanbul", "\u00c9COLE", "a b")),
                     c("new", "i\u0307stanbul", "\u00e9cole", "a b"))
    skip_if_not_installed("quanteda")
    dict <- quanteda::dictionary(list(CITY = c("\u0130stanbul office",
                                               "\u0130stanbul off*")),
                                 tolower = FALSE)
    expect_identical(spacy_match(txt, dict, overlap = "all")$text,
                     "\u0130stanbul office")
})

test_that("labels of matches give the counts of tokens_lookup()", {
    skip_on_cran()
    skip_if_not_installed("quanteda")
    try_spacy_initialize()
    txt <- c(d1 = "New York is a large city. York is small.",
             d2 = "Nothing here.",
             d3 = "A big book in new york was written by Jane.")
    dict <- quanteda::dictionary(list(place = c("new york", "york"),
                                      size = c("larg*", "small*", "big*"),
                                      colour = "red"))
    m <- spacy_match(txt, dict)
    m1 <- m[!duplicated(m[c("doc_id", "match_id")]), ]
    labels <- quanteda::as.tokens(split(m1$label,
                                        factor(m1$doc_id, levels = names(txt))))
    expect_identical(quanteda::docnames(labels), names(txt))
    counts <- quanteda::dfm_match(quanteda::dfm(labels, tolower = FALSE),
                                  names(dict))
    lookup <- quanteda::dfm(quanteda::tokens_lookup(
        quanteda::as.tokens(spacy_parse(txt)), dict), tolower = FALSE)
    expect_identical(as.matrix(counts), as.matrix(lookup))

    # the identifiers of the documents for the other kinds of input
    count_place <- function(x, ids) {
        m <- spacy_match(x, dict)
        m1 <- m[!duplicated(m[c("doc_id", "match_id")]), ]
        labels <- quanteda::as.tokens(split(m1$label,
                                            factor(m1$doc_id, levels = ids)))
        expect_identical(quanteda::docnames(labels), ids)
        as.vector(as.matrix(quanteda::dfm(labels, tolower = FALSE))[, "place"])
    }
    unnamed <- unname(txt)
    expect_identical(count_place(unnamed, sprintf("text%d", seq_along(unnamed))),
                     c(2, 0, 1))
    tif <- data.frame(doc_id = c("a", "b", "c"), text = unnamed,
                      stringsAsFactors = FALSE)
    expect_identical(count_place(tif, as.character(tif$doc_id)), c(2, 0, 1))
    crp <- quanteda::corpus(txt)
    expect_identical(count_place(crp, quanteda::docnames(crp)), c(2, 0, 1))

    # a dependency match counts once, not once for each node
    dep <- list(
        list(RIGHT_ID = "verb", RIGHT_ATTRS = list(TAG = "VBN")),
        list(LEFT_ID = "verb", REL_OP = ">", RIGHT_ID = "aux",
             RIGHT_ATTRS = list(DEP = "auxpass"))
    )
    md <- spacy_match(txt, list(PASSIVE = dep))
    expect_identical(nrow(md), 2L)
    md1 <- md[!duplicated(md[c("doc_id", "match_id")]), ]
    labels <- quanteda::as.tokens(split(md1$label,
                                        factor(md1$doc_id, levels = names(txt))))
    counts <- quanteda::dfm(labels, tolower = FALSE)
    expect_identical(as.vector(as.matrix(counts)[, "PASSIVE"]), c(0, 0, 1))
})
