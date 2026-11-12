source("utils.R")

test_that("as.dictionary() converts entity patterns of phrases", {
    skip_if_not_installed("quanteda")
    pat <- as_entity_patterns(c(ORG = "Acme Widgets", GPE = "New York",
                                ORG = "Globex", ORG = "Acme Widgets"))
    d <- quanteda::as.dictionary(pat)
    expect_true(quanteda::is.dictionary(d))
    # keys in the order of the labels, each phrase once, in its own case
    expect_identical(quanteda::as.list(d), list(ORG = c("Acme Widgets", "Globex"),
                                      GPE = "New York"))
})

test_that("as.dictionary() drops ids and case settings", {
    skip_if_not_installed("quanteda")
    pat <- c(as_entity_patterns(c(ORG = "Acme"), id = "acme",
                                case_insensitive = TRUE),
             as_entity_patterns(c(ORG = "Globex")))
    expect_identical(quanteda::as.list(quanteda::as.dictionary(pat)),
                     list(ORG = c("Acme", "Globex")))
})

test_that("as.dictionary() round trip keeps the label and phrase pairs", {
    skip_if_not_installed("quanteda")
    pat <- as_entity_patterns(c(ORG = "Acme Widgets", GPE = "New York",
                                ORG = "Globex"))
    back <- as_entity_patterns(quanteda::as.dictionary(pat),
                               valuetype = "fixed", case_insensitive = FALSE)
    pairs <- function(p) {
        p <- as.data.frame(p)
        sort(paste(p$label, unlist(p$pattern), sep = "\r"))
    }
    expect_true(all(vapply(as.data.frame(back)$pattern, is.character,
                           logical(1))))
    expect_identical(pairs(back), pairs(pat))
    expect_identical(as.data.frame(back)$case_insensitive, rep(FALSE, 3))
    # quanteda trims the whitespace around a value
    padded <- as_entity_patterns(c(ORG = " Globex "))
    expect_identical(quanteda::as.list(quanteda::as.dictionary(padded)),
                     list(ORG = "Globex"))
})

test_that("as.dictionary() stops for token patterns and names their labels", {
    skip_if_not_installed("quanteda")
    tok <- as_entity_patterns(list(
        list(label = "TITLE", pattern = list(list(LOWER = "dr"))),
        list(label = "ROLE", pattern = list(list(LOWER = "ceo")))
    ))
    pat <- c(as_entity_patterns(c(ORG = "Acme")), tok)
    expect_error(quanteda::as.dictionary(pat),
                 "token patterns with the labels TITLE, ROLE")
    expect_error(quanteda::as.dictionary(pat[1:2, ]),
                 "token patterns with the label TITLE$")
})

test_that("as.dictionary() warns for phrases with * or ?", {
    skip_if_not_installed("quanteda")
    pat <- as_entity_patterns(c(Q = "Who?", ORG = "Acme", S = "M*A*S*H"))
    expect_warning(d <- quanteda::as.dictionary(pat),
                   "2 phrases have one, with the labels Q, S")
    expect_identical(quanteda::as.list(d)$Q, "Who?")
    expect_warning(quanteda::as.dictionary(pat[1, ]),
                   "1 phrase has one, with the label Q")
    expect_no_warning(quanteda::as.dictionary(pat[2, ]))
})

test_that("as.dictionary() handles no patterns and rejects other arguments", {
    skip_if_not_installed("quanteda")
    d <- quanteda::as.dictionary(as_entity_patterns(NULL))
    expect_true(quanteda::is.dictionary(d))
    expect_length(d, 0)
    expect_error(quanteda::as.dictionary(as_entity_patterns(c(ORG = "Acme")),
                                         tolower = TRUE),
                 "does not use the argument tolower")
})

test_that("as.dictionary() checks an object that was edited", {
    skip_if_not_installed("quanteda")
    pat <- as_entity_patterns(c(ORG = "Acme", GPE = "New York"))
    expect_s3_class(pat[, c("label", "id")], "spacyr_entity_patterns")
    expect_error(quanteda::as.dictionary(pat[, c("label", "id")]), "pattern")
    expect_error(quanteda::as.dictionary(pat[, c("pattern", "id")]), "label")
    # rows taken out leave a valid object
    expect_identical(quanteda::as.list(quanteda::as.dictionary(pat[2, ])),
                     list(GPE = "New York"))
})

test_that("no entities give an empty dictionary that converts back", {
    skip_if_not_installed("quanteda")
    # spacy_extract_entity() returns NULL when it finds nothing
    d <- quanteda::as.dictionary(as_entity_patterns(NULL))
    expect_length(d, 0)
    back <- as_entity_patterns(d, valuetype = "fixed", case_insensitive = FALSE)
    expect_identical(nrow(back), 0L)
    toks <- quanteda::tokens("a b c")
    expect_identical(nrow(quanteda::kwic(toks, d)), 0L)
    expect_identical(quanteda::nfeat(quanteda::dfm_lookup(quanteda::dfm(toks), d)),
                     0L)
})

test_that("results give a dictionary of their texts", {
    skip_on_cran()
    skip_if_not_installed("quanteda")
    try_spacy_initialize()
    on.exit(try(spacy_finalize(), silent = TRUE))
    txt <- c(d1 = "The book was written in New York. York is small.",
             d2 = "I like new York.")
    dep <- list(
        list(RIGHT_ID = "verb", RIGHT_ATTRS = list(TAG = "VBN")),
        list(LEFT_ID = "verb", REL_OP = ">", RIGHT_ID = "aux",
             RIGHT_ATTRS = list(DEP = "auxpass"))
    )
    m <- spacy_match(txt, list(place = c("new", "york"), place = "york",
                               PASSIVE = dep), overlap = "all")
    seqs <- m[is.na(m$node), ]
    expect_true(all(seqs$label == "place"))
    expect_true(any(m$label == "PASSIVE"))
    d <- quanteda::dictionary(lapply(split(seqs$text, seqs$label), unique),
                              tolower = FALSE)
    expect_identical(names(d), "place")
    expect_setequal(quanteda::as.list(d)$place, c("New York", "York", "new York"))
})
