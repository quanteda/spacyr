source("utils.R")

index_cols <- function(x) as.list(unclass(x))[c("docname", "from", "to", "pattern")]

test_that("as_index() makes an index of matches, entities and noun phrases", {
    m <- data.frame(doc_id = c("d1", "d1", "d2"), match_id = c(1L, 2L, 1L),
                    label = c("paper", "city", "paper"), node = NA_character_,
                    text = c("New York Times", "New York", "New York Times"),
                    start_id = c(2L, 7L, 1L), length = c(3L, 2L, 3L))
    idx <- as_index(m)
    expect_identical(class(idx), c("index", "data.frame"))
    expect_identical(names(idx), c("docname", "from", "to", "pattern"))
    expect_identical(idx$docname, c("d1", "d1", "d2"))
    expect_identical(idx$from, c(2L, 7L, 1L))
    expect_identical(idx$to, c(4L, 8L, 3L))
    expect_identical(idx$pattern, factor(c("paper", "city", "paper"),
                                         levels = c("paper", "city")))
    # positions stored as doubles, and a data.table
    m2 <- m
    m2$start_id <- as.numeric(m2$start_id)
    m2$length <- as.numeric(m2$length)
    expect_identical(as_index(m2), idx)
    expect_identical(as_index(data.table::as.data.table(m)), idx)

    ents <- data.frame(doc_id = c("a", "b"), text = c("Jane Smith", "Paris"),
                       ent_type = c("PERSON", "GPE"), start_id = c(1, 6),
                       length = c(2, 1))
    e <- as_index(ents)
    expect_identical(e$to, c(2L, 6L))
    expect_identical(e$pattern, factor(c("PERSON", "GPE"), levels = c("PERSON", "GPE")))

    nps <- data.frame(doc_id = "a", text = "the book", root_text = "book",
                      start_id = 4, root_id = 5, length = 2)
    n <- as_index(nps)
    expect_identical(n$pattern, factor("nounphrase"))
    expect_identical(c(n$from, n$to), c(4L, 5L))
})

test_that("as_index() keeps a row for each node of a dependency match", {
    dep <- data.frame(doc_id = "d1", match_id = c(1L, 1L, 1L, 2L),
                      label = "CLAUSE", node = c("verb", "subj", "agent", "verb"),
                      text = c("written", "book", "written", "edited"),
                      start_id = c(4L, 2L, 4L, 6L), length = 1L)
    idx <- as_index(dep)
    expect_identical(nrow(idx), 4L)
    expect_identical(idx$from, dep$start_id)
    expect_identical(idx$to, dep$start_id)
})

test_that("as_index() of nothing is an index with no rows", {
    for (x in list(NULL, data.frame(doc_id = character(), label = character(),
                                    start_id = integer(), length = integer()))) {
        idx <- as_index(x)
        expect_identical(class(idx), c("index", "data.frame"))
        expect_identical(nrow(idx), 0L)
        expect_identical(names(idx), c("docname", "from", "to", "pattern"))
        expect_type(idx$from, "integer")
        expect_s3_class(idx$pattern, "factor")
    }
})

test_that("as_index() gives errors for other input", {
    expect_error(as_index("a"), "x must be the output of")
    expect_error(as_index(list(doc_id = "a")), "x must be the output of")
    expect_error(as_index(data.frame(doc_id = "a", label = "A", start_id = 1)),
                 "missing: length")
    # entity_extract() has no positions
    expect_error(as_index(data.frame(doc_id = "a", sentence_id = 1, entity = "x",
                                     entity_type = "ORG")),
                 "missing: start_id, length")
    expect_error(as_index(data.frame(doc_id = "a", start_id = 1, length = 1)),
                 "none of the columns that say what each row is")
    ok <- data.frame(doc_id = "a", label = "A", start_id = 1, length = 1)
    for (bad in list(0, -1, 1.5, NA, Inf, "1")) {
        x <- ok; x$start_id <- bad
        expect_error(as_index(x), "must be whole numbers from 1")
        x <- ok; x$length <- bad
        expect_error(as_index(x), "must be whole numbers from 1")
    }
    x <- ok; x$label <- NA
    expect_error(as_index(x), "must not be missing")
    x <- ok; x$doc_id <- NA
    expect_error(as_index(x), "must not be missing")
})

test_that("kwic() shows matches, entities, noun phrases and nodes from as_index()", {
    skip_on_cran()
    skip_if_not_installed("quanteda")
    try_spacy_initialize()
    # with whitespace tokens, which the positions count
    txt <- c(d1 = "The New York Times is a paper in New York.\n\nIt was written by Jane Smith.",
             d2 = "Nothing here",
             d3 = "Jane Smith wrote  the book in Boston.")
    toks <- quanteda::as.tokens(spacy_parse(txt))
    keyword <- function(x) quanteda::kwic(toks, index = as_index(x))$keyword

    m <- spacy_match(txt, quanteda::phrase(c("new york", "the book", "it")))
    expect_identical(keyword(m), m$text)
    expect_identical(m$text, c("New York", "New York", "It", "the book"))
    # as quanteda's own index of the same tokens
    idx <- quanteda::index(toks, quanteda::phrase(c("new york", "the book", "it")))
    expect_identical(index_cols(as_index(m))[1:3], index_cols(idx)[1:3])
    expect_identical(as.character(as_index(m)$pattern), as.character(idx$pattern))

    ents <- spacy_extract_entity(txt)
    expect_identical(keyword(ents), ents$text)
    expect_true("Jane Smith" %in% ents$text)

    nps <- spacy_extract_nounphrases(txt)
    expect_identical(keyword(nps), nps$text)
    expect_true(all(c("d1", "d2", "d3") %in% as_index(nps)$docname))

    dep <- spacy_match(txt, list(CLAUSE = list(
        list(RIGHT_ID = "verb", RIGHT_ATTRS = list(POS = "VERB")),
        list(LEFT_ID = "verb", REL_OP = ">", RIGHT_ID = "subj",
             RIGHT_ATTRS = list(DEP = list(IN = c("nsubj", "nsubjpass")))))))
    expect_identical(keyword(dep), dep$text)
    expect_identical(dep$node, rep(c("verb", "subj"), 2))

    # nothing found
    expect_message(none <- spacy_extract_entity("nothing here"), "No entity found")
    expect_null(none)
    expect_identical(nrow(quanteda::kwic(toks, index = as_index(none))), 0L)
    expect_identical(nrow(quanteda::kwic(toks, index = as_index(spacy_match(txt, "zzz")))), 0L)
})

test_that("a concordance from as_index() follows overlap, not kwic()'s own rule", {
    skip_on_cran()
    skip_if_not_installed("quanteda")
    try_spacy_initialize()
    txt <- "The New York Times is a New York paper."
    toks <- quanteda::as.tokens(spacy_parse(txt))
    pats <- list(paper = c("new", "york", "times"), city = c("new", "york"))
    m <- spacy_match(txt, pats)
    kw <- quanteda::kwic(toks, index = as_index(m))
    expect_identical(paste(kw$pattern, kw$from, kw$to),
                     c("city 2 3", "paper 2 4", "city 7 8"))
    own <- quanteda::kwic(toks, quanteda::phrase(c("new york times", "new york")))
    expect_identical(paste(own$from, own$to), c("2 4", "7 8"))
})

test_that("as_index() checks the end position before converting it", {
    big <- .Machine$integer.max
    m <- data.frame(doc_id = "d1", label = "a", start_id = big, length = 1)
    expect_identical(as_index(m)$to, big)
    expect_identical(as_index(m)$from, big)
    m$length <- 2
    expect_error(as_index(m), "beyond the largest integer")
    m <- data.frame(doc_id = "d1", label = "a", start_id = 1e10, length = 1)
    expect_error(as_index(m), "beyond the largest integer")
})

test_that("as_index() gives document names in composed form", {
    skip_if_not_installed("stringi")
    skip_if_not(l10n_info()[["UTF-8"]])
    m <- data.frame(doc_id = c("de\u0301comp", "plain"), label = "a",
                    start_id = 1:2, length = 1)
    expect_identical(as_index(m)$docname, c("d\u00e9comp", "plain"))
})

test_that("kwic() keeps matches of documents with decomposed names", {
    skip_if_not_installed("quanteda")
    skip_if_not_installed("stringi")
    skip_if_not(l10n_info()[["UTF-8"]])
    skip_on_cran()
    try_spacy_initialize()
    on.exit(try(spacy_finalize(), silent = TRUE))
    txt <- c("New York is big.", "I like New York.")
    names(txt) <- c("de\u0301comp", "plain")
    m <- spacy_match(txt, quanteda::phrase("new york"))
    toks <- quanteda::as.tokens(spacy_parse(txt))
    kw <- quanteda::kwic(toks, index = as_index(m))
    expect_identical(nrow(kw), 2L)
    expect_identical(kw$keyword, m$text)
    # the same names when a corpus is the input of both
    crp <- quanteda::corpus(txt)
    m2 <- spacy_match(crp, quanteda::phrase("new york"))
    expect_identical(as_index(m2)$docname, quanteda::docnames(crp)[c(1, 2)])
    kw2 <- quanteda::kwic(quanteda::as.tokens(spacy_parse(crp)),
                          index = as_index(m2))
    expect_identical(nrow(kw2), 2L)
})
