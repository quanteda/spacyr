source("utils.R")

passive <- list(
    PASSIVE = list(list(DEP = "auxpass"),
                   list(DEP = list(IN = c("advmod", "neg", "aux", "auxpass")), OP = "*"),
                   list(TAG = "VBN")))
txt <- c(doc1 = "The book was written by Jane. Jane wrote the book.",
         doc2 = "Mistakes were made, and the report is being rewritten.")
match_columns <- c("doc_id", "sentence_id", "token_id", "label", "text",
                   "start_id", "length")

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

test_that("match_patterns rejects patterns it cannot use", {
    tok <- list(list(LOWER = "a"))
    expect_error(match_patterns(list(tok)), "must be a named list")
    expect_error(match_patterns(list(A = tok, tok)), "must be a named list")
    expect_error(match_patterns(list(A = tok, A = tok)), "must be unique.*: A$")
    expect_error(match_patterns(list()), "holds no patterns")
    expect_error(match_patterns("a b"), "must be a named list")
    expect_error(match_patterns(data.frame(label = "A")), "must be a named list")
    expect_error(match_patterns(list(A = "new york")),
                 "'A' is a phrase.*as_entity_patterns")
    expect_error(match_patterns(list(A = list())), "'A' is not a list of token patterns")
    expect_error(match_patterns(list(A = list(LOWER = "a"))),
                 "Pattern 'A' is a single token pattern")
    expect_error(match_patterns(list(A = list(tok, "b"))),
                 "Pattern 'A' \\(alternative 2\\) is a phrase")
    expect_error(match_patterns(list(A = list(tok, list(1)))),
                 "Token 1 of pattern 'A' \\(alternative 2\\)")
    dep <- list(list(RIGHT_ID = "verb", RIGHT_ATTRS = list(TAG = "VBN")),
                list(LEFT_ID = "verb", REL_OP = ">", RIGHT_ID = "subject",
                     RIGHT_ATTRS = list(DEP = "nsubjpass")))
    expect_error(match_patterns(list(A = tok, P = dep)),
                 "Pattern 'P' is a dependency pattern.*spacy_extract_dependency_matches")
})

test_that("spacy_extract_matches checks its arguments before starting spaCy", {
    try(spacy_finalize(), silent = TRUE)
    expect_error(spacy_extract_matches("a", passive, overlap = "none"), "should be one of")
    expect_error(spacy_extract_matches("a", passive, n_process = 0), "n_process")
    expect_error(spacy_extract_matches("a"), "patterns must be supplied")
    expect_error(spacy_extract_matches("a", list(passive$PASSIVE)), "must be a named list")
    expect_null(getOption("spacy_initialized"))
})

test_that("spacy_extract_matches finds passives by dependency and tag", {
    skip_on_cran()
    skip_on_os("solaris")
    try_spacy_initialize()

    m <- spacy_extract_matches(txt, passive)
    expect_s3_class(m, "data.frame", exact = TRUE)
    expect_named(m, match_columns)
    expect_identical(m$doc_id, c("doc1", "doc2", "doc2"))
    expect_identical(m$text, c("was written", "were made", "being rewritten"))
    expect_identical(m$label, rep("PASSIVE", 3))
    expect_identical(m$start_id, c(3L, 2L, 9L))
    expect_identical(m$length, c(2L, 2L, 2L))

    # the same from a TIF data.frame and with two processes
    tif <- data.frame(doc_id = names(txt), text = unname(txt))
    expect_identical(spacy_extract_matches(tif, passive), m)
    expect_identical(spacy_extract_matches(txt, passive, n_process = 2), m)
})

test_that("positions agree with spacy_parse, also across sentences", {
    skip_on_cran()
    skip_on_os("solaris")
    try_spacy_initialize()

    pats <- list(BOOK = list(list(LOWER = "book")),
                 # crosses the sentence boundary
                 CROSS = list(list(IS_PUNCT = TRUE), list(POS = "PROPN")))
    m <- spacy_extract_matches(txt["doc1"], pats)
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
    all <- spacy_extract_matches(big, pats)
    # by start, then length, then the order of the labels
    expect_identical(all$text, c("big red shiny ball", "red shiny", "red shiny ball",
                                 "shiny ball"))
    expect_identical(all$label, c("A", "B", "A", "A"))
    expect_identical(spacy_extract_matches(big, pats, overlap = "all"), all)
    for (overlap in c("longest", "first")) {
        m <- spacy_extract_matches(big, pats, overlap = overlap)
        # matches of different labels still overlap
        expect_identical(m$text, c("big red shiny ball", "red shiny"), info = overlap)
        expect_identical(m$label, c("A", "B"), info = overlap)
    }
    # where the match that starts first is the shorter one, "first" and
    # "longest" differ
    alt <- list(X = list(list(list(LOWER = "a"), list(LOWER = "b")),
                         list(list(LOWER = "b"), list(LOWER = "c"),
                              list(LOWER = "d"), list(LOWER = "e"))))
    expect_identical(spacy_extract_matches("a b c d e", alt)$text, c("a b", "b c d e"))
    expect_identical(spacy_extract_matches("a b c d e", alt, overlap = "first")$text, "a b")
    expect_identical(spacy_extract_matches("a b c d e", alt, overlap = "longest")$text,
                     "b c d e")
    # the shortest of the matches with the same start comes first
    starts <- spacy_extract_matches("a b c", list(
        LONG = list(list(LOWER = "a"), list(LOWER = "b"), list(LOWER = "c")),
        SHORT = list(list(LOWER = "a"))))
    expect_identical(starts$label, c("SHORT", "LONG"))
    # equal spans are ordered by label
    same <- spacy_extract_matches("red", list(Z = list(list(LOWER = "red")),
                                              A = list(list(IS_ALPHA = TRUE))))
    expect_identical(same$label, c("Z", "A"))
})

test_that("alternatives, entity patterns and set operators match", {
    skip_on_cran()
    skip_on_os("solaris")
    try_spacy_initialize()

    alt <- list(WRITE = list(list(list(LEMMA = "write")), list(list(LEMMA = "rewrite"))))
    m <- spacy_extract_matches(txt, alt)
    expect_identical(m$text, c("written", "wrote", "rewritten"))
    ep <- as_entity_patterns(list(
        list(label = "WRITE", pattern = list(list(LEMMA = "write"))),
        list(label = "WRITE", pattern = list(list(LEMMA = "rewrite")))))
    expect_identical(spacy_extract_matches(txt, ep), m)

    # a set operator with one value, which spaCy accepts as an array only
    past <- spacy_extract_matches("Jane wrote books.", list(
        PAST = list(list(MORPH = list(IS_SUPERSET = "Tense=Past")))))
    expect_identical(past$text, "wrote")
    # an empty token matches any token
    any <- spacy_extract_matches("Jane wrote books.", list(ANY = list(list())))
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
        sep = "\n"))
    on.exit(reticulate::py_run_string(paste(
        "Token.remove_extension('is_subset')",
        "Token.remove_extension('spacyr_tags')", sep = "\n")))

    run <- function(...) spacy_extract_matches("red ball", list(X = list(list(`_` = list(...)))))
    expect_identical(run(is_subset = "x")$text, c("red", "ball"))
    expect_identical(nrow(run(is_subset = "y")), 0L)
    # operators still apply within the value of a custom attribute
    expect_identical(run(is_subset = list(IN = "x"))$text, c("red", "ball"))
    expect_identical(run(spacyr_tags = list(IS_SUPERSET = "a"))$text, c("red", "ball"))
    expect_identical(nrow(run(spacyr_tags = list(IS_SUPERSET = "z"))), 0L)
})

test_that("phrases of entity patterns match exactly or in any case", {
    skip_on_cran()
    skip_on_os("solaris")
    try_spacy_initialize()

    x <- c(d1 = "Acme Widgets sued ACME WIDGETS in New York.",
           d2 = "Trade between new york and Paris.")
    ep <- c(as_entity_patterns(c(ORG = "Acme Widgets", GPE = "New York")),
            as_entity_patterns(list(label = "GPE", pattern = list(list(LOWER = "paris")))))
    m <- spacy_extract_matches(x, ep)
    expect_named(m, match_columns)
    expect_identical(m$text, c("Acme Widgets", "New York", "Paris"))
    expect_identical(m$label, c("ORG", "GPE", "GPE"))
    expect_identical(m$start_id, c(1L, 7L, 6L))
    expect_identical(m$length, c(2L, 2L, 1L))

    any <- spacy_extract_matches(x, as_entity_patterns(c(ORG = "acme widgets", GPE = "NEW YORK"),
                                                       case_insensitive = TRUE))
    expect_identical(any$text, c("Acme Widgets", "ACME WIDGETS", "New York", "new york"))
    # exact and any-case phrases together, with two processes
    both <- c(as_entity_patterns(c(ORG = "Acme Widgets")),
              as_entity_patterns(c(GPE = "new york"), case_insensitive = TRUE))
    m <- spacy_extract_matches(x, both)
    expect_identical(m$text, c("Acme Widgets", "New York", "new york"))
    expect_identical(spacy_extract_matches(x, both, n_process = 2), m)

    # phrases are split into spaCy's tokens, not at spaces
    comma <- spacy_extract_matches("We met Smith, Jones and Brown.",
                                   as_entity_patterns(c(NAMES = "Smith, Jones")))
    expect_identical(comma$text, "Smith, Jones")
    expect_identical(comma$length, 3L)

    # the same span found by a phrase and a token pattern is one match
    twice <- c(as_entity_patterns(c(GPE = "New York")),
               as_entity_patterns(list(label = "GPE", pattern = list(
                   list(LOWER = "new"), list(LOWER = "york")))))
    m <- spacy_extract_matches(x, twice)
    expect_identical(m$text, c("New York", "new york"))
    expect_identical(nrow(spacy_extract_matches("Nothing here.", twice)), 0L)
})

test_that("overlap applies to the phrases and token patterns of a label together", {
    skip_on_cran()
    skip_on_os("solaris")
    try_spacy_initialize()

    ep <- c(as_entity_patterns(c(X = "a b", Y = "b c")),
            as_entity_patterns(list(label = "X", pattern = list(
                list(LOWER = "b"), list(LOWER = "c"), list(LOWER = "d"), list(LOWER = "e")))))
    all <- spacy_extract_matches("a b c d e", ep)
    expect_identical(all$text, c("a b", "b c", "b c d e"))
    expect_identical(all$label, c("X", "Y", "X"))
    first <- spacy_extract_matches("a b c d e", ep, overlap = "first")
    expect_identical(first$text, c("a b", "b c"))
    longest <- spacy_extract_matches("a b c d e", ep, overlap = "longest")
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
        ours <- spacy_extract_matches(x, pats, overlap = overlap)
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
    m <- spacy_extract_matches(x, d)
    expect_identical(m$text, c("Taxes", "New York", "taxation", "Acme Widgets"))
    expect_identical(m$label, c("tax", "tax", "tax", "org"))
    # many wildcard values of a label are matched as one regular expression
    many <- quanteda::dictionary(list(t = c("tax*", "ros?", "wid*")))
    expect_identical(spacy_extract_matches(x, many)$text,
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

    expect_warning(spacy_extract_matches("He lives in New York.",
                                         as_entity_patterns(c(GPE = "New York"))),
                   "Phrases may not match, since 'merge_entities' changes the tokens")
    expect_silent(spacy_extract_matches("He lives in New York.",
                                        list(GPE = list(list(LOWER = "new york")))))
})

test_that("no matches give a data.frame with no rows", {
    skip_on_cran()
    skip_on_os("solaris")
    try_spacy_initialize()

    for (x in list(character(0), "Nothing here.", c(a = "", b = NA))) {
        m <- spacy_extract_matches(x, passive)
        expect_s3_class(m, "data.frame", exact = TRUE)
        expect_named(m, match_columns)
        expect_identical(nrow(m), 0L)
        expect_identical(vapply(m, typeof, ""),
                         c(doc_id = "character", sentence_id = "integer",
                           token_id = "integer", label = "character",
                           text = "character", start_id = "integer", length = "integer"))
    }
})

test_that("spaCy's errors for patterns are shown", {
    skip_on_cran()
    skip_on_os("solaris")
    try_spacy_initialize()

    expect_error(spacy_extract_matches(txt, list(X = list(list(LOWR = "a")))),
                 "spaCy could not match the patterns:.*rule 'X'.*LOWR")
})

test_that("documents without sentence boundaries have no sentence positions", {
    skip_on_cran()
    skip_on_os("solaris")
    try(spacy_finalize(), silent = TRUE)
    try_spacy_initialize()
    on.exit(spacy_finalize())
    spacyr:::spacyr_env$nlp$disable_pipe("parser")

    m <- spacy_extract_matches(txt["doc1"], list(BOOK = list(list(LOWER = "book"))))
    expect_identical(m$text, c("book", "book"))
    expect_identical(m$sentence_id, c(NA_integer_, NA_integer_))
    expect_identical(m$token_id, c(NA_integer_, NA_integer_))
    expect_identical(m$start_id, c(2L, 11L))
    # spaCy names the component that a pattern needs
    expect_error(spacy_extract_matches(txt, passive),
                 "spaCy could not match the patterns:.*E155.*parser")
})

test_that("patterns that need entities warn when nothing sets them", {
    skip_on_cran()
    skip_on_os("solaris")
    person <- list(PERSON = list(list(ENT_TYPE = "PERSON", OP = "+")))
    try(spacy_finalize(), silent = TRUE)
    suppressMessages(spacy_initialize(entity = FALSE))
    on.exit(spacy_finalize())
    expect_warning(m <- spacy_extract_matches(txt, person),
                   "need entities \\(ENT_TYPE or ENT_IOB\\)")
    expect_identical(nrow(m), 0L)
    expect_silent(spacy_extract_matches(txt, passive))

    spacy_finalize()
    suppressMessages(spacy_initialize())
    expect_silent(m <- spacy_extract_matches(txt, person, overlap = "longest"))
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
    expect_warning(m <- spacy_extract_matches(x, list(BOOK = list(list(LOWER = "book")))),
                   "did not return 1 document, which is left out of the output: bad")
    expect_identical(m$doc_id, "good")
    expect_identical(m$start_id, 3L)
})
