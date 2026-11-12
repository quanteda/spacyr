source("utils.R")

# a parse written by hand: d2 had no tokens, d3 has two sentences
hand_parsed <- function(docvars = NULL) {
    x <- data.frame(
        doc_id = c("d1", "d1", "d1", "d3", "d3", "d3", "d4"),
        sentence_id = c(1L, 1L, 1L, 1L, 2L, 2L, 1L),
        token_id = c(1L, 2L, 3L, 1L, 1L, 2L, 1L),
        token = c("a", "b", "a", "c", "c", ".", "e"),
        lemma = c("A", "B", "A", "C", "C", ".", "E"),
        pos = c("X", "Y", "X", "Z", "Z", "PUNCT", "X"),
        stringsAsFactors = FALSE
    )
    class(x) <- c("spacyr_parsed", "data.frame")
    spacyr:::set_parsed_documents(x, c("d1", "d2", "d3", "d4"), docvars)
}

test_that("the methods are found through quanteda's generics", {
    skip_if_not_installed("quanteda")
    x <- hand_parsed()
    expect_identical(quanteda::docnames(x), c("d1", "d2", "d3", "d4"))
    expect_identical(quanteda::ndoc(x), 4L)
    expect_identical(quanteda::ntoken(x), c(d1 = 3L, d2 = 0L, d3 = 3L, d4 = 1L))
    expect_identical(quanteda::ntype(x), c(d1 = 2L, d2 = 0L, d3 = 2L, d4 = 1L))
    expect_identical(quanteda::nsentence(x),
                     c(d1 = 1L, d2 = 0L, d3 = 2L, d4 = 1L))
})

test_that("as.tokens() keeps documents without tokens and agrees with the counts", {
    skip_if_not_installed("quanteda")
    x <- hand_parsed()
    toks <- quanteda::as.tokens(x)
    expect_identical(quanteda::docnames(toks), quanteda::docnames(x))
    expect_identical(quanteda::ntoken(toks), quanteda::ntoken(x))
    expect_identical(quanteda::as.list(toks),
                     list(d1 = c("a", "b", "a"), d2 = character(),
                          d3 = c("c", "c", "."), d4 = "e"))
    expect_identical(
        quanteda::as.list(quanteda::as.tokens(x, include_pos = "pos"))$d3,
        c("c/Z", "c/Z", "./PUNCT")
    )
    expect_identical(
        quanteda::as.list(quanteda::as.tokens(x, include_pos = "pos",
                                              concatenator = "_",
                                              use_lemma = TRUE))$d1,
        c("A_X", "B_Y", "A_X")
    )
    expect_error(quanteda::as.tokens(x, include_pos = "tag"),
                 "x has no column tag: rerun spacy_parse\\(\\) with tag = TRUE")
    expect_error(quanteda::as.tokens(x[, names(x) != "lemma"], use_lemma = TRUE),
                 "x has no column lemma")
})

test_that("as.tokens() restores the document variables", {
    skip_if_not_installed("quanteda")
    dv <- data.frame(year = 2001:2004, party = c("a", "b", "c", "d"),
                     stringsAsFactors = FALSE)
    toks <- quanteda::as.tokens(hand_parsed(dv))
    expect_identical(quanteda::docvars(toks), dv)
    # none without a record of them
    expect_identical(ncol(quanteda::docvars(quanteda::as.tokens(hand_parsed()))),
                     0L)
})

test_that("removing tokens keeps every document", {
    skip_if_not_installed("quanteda")
    dv <- data.frame(year = 2001:2004)
    x <- hand_parsed(dv)
    nopunct <- x[x$pos != "PUNCT", ]
    expect_identical(quanteda::docnames(nopunct), c("d1", "d2", "d3", "d4"))
    expect_identical(quanteda::ntoken(nopunct),
                     c(d1 = 3L, d2 = 0L, d3 = 2L, d4 = 1L))
    toks <- quanteda::as.tokens(nopunct)
    expect_identical(quanteda::ntoken(toks), quanteda::ntoken(nopunct))
    expect_identical(quanteda::docvars(toks, "year"), 2001:2004)
})

test_that("removing a document does not bring it or an empty one back", {
    skip_if_not_installed("quanteda")
    dv <- data.frame(year = 2001:2004)
    x <- hand_parsed(dv)
    sub <- x[x$doc_id != "d3", ]
    # row subsetting keeps the record as it was
    expect_identical(attr(sub, "documents")$doc_id, c("d1", "d2", "d3", "d4"))
    expect_identical(quanteda::docnames(sub), c("d1", "d4"))
    expect_identical(quanteda::ndoc(sub), 2L)
    expect_identical(quanteda::ntoken(sub), c(d1 = 3L, d4 = 1L))
    expect_identical(quanteda::ntype(sub), c(d1 = 2L, d4 = 1L))
    expect_identical(quanteda::nsentence(sub), c(d1 = 1L, d4 = 1L))
    toks <- quanteda::as.tokens(sub)
    expect_identical(quanteda::docnames(toks), c("d1", "d4"))
    # the document variables of the documents that are left
    expect_identical(quanteda::docvars(toks, "year"), c(2001L, 2004L))
    # all rows removed
    none <- x[0, ]
    expect_identical(quanteda::ndoc(none), 0L)
    expect_identical(quanteda::ndoc(quanteda::as.tokens(none)), 0L)
    expect_identical(quanteda::ntoken(none), structure(integer(), names = character()))
})

test_that("rows in another order give the documents in that order", {
    skip_if_not_installed("quanteda")
    dv <- data.frame(year = 2001:2004)
    x <- hand_parsed(dv)
    rev_rows <- x[order(x$doc_id, decreasing = TRUE), ]
    expect_identical(quanteda::docnames(rev_rows), c("d4", "d3", "d1", "d2"))
    toks <- quanteda::as.tokens(rev_rows)
    expect_identical(quanteda::docnames(toks), c("d4", "d3", "d1", "d2"))
    expect_identical(quanteda::docvars(toks, "year"),
                     c(2004L, 2003L, 2001L, 2002L))
})

test_that("objects without a usable record fall back to their rows", {
    skip_if_not_installed("quanteda")
    x <- hand_parsed(data.frame(year = 2001:4))
    # as saved by an earlier version of spacyr
    old <- x
    attr(old, "documents") <- NULL
    expect_identical(quanteda::docnames(old), c("d1", "d3", "d4"))
    expect_identical(quanteda::ntoken(old), c(d1 = 3L, d3 = 3L, d4 = 1L))
    toks <- quanteda::as.tokens(old)
    expect_identical(quanteda::docnames(toks), c("d1", "d3", "d4"))
    expect_identical(ncol(quanteda::docvars(toks)), 0L)
    # a document that the record does not know
    other <- as.data.frame(x[1, ])
    other$doc_id <- "z9"
    both <- rbind.data.frame(x, other)
    expect_identical(attr(both, "documents")$doc_id, c("d1", "d2", "d3", "d4"))
    expect_identical(quanteda::docnames(both), c("d1", "d3", "d4", "z9"))
    expect_identical(ncol(quanteda::docvars(quanteda::as.tokens(both))), 0L)
    # a record that is not what spacy_parse() writes
    bad <- x
    attr(bad, "documents") <- list(doc_id = c("d1", "d3", "d4"))
    expect_identical(quanteda::docnames(bad), c("d1", "d3", "d4"))
    attr(bad, "documents") <- "d1"
    expect_identical(quanteda::docnames(bad), c("d1", "d3", "d4"))
})

test_that("spacy_parse() keeps empty documents and corpus docvars", {
    skip_on_cran()
    skip_if_not_installed("quanteda")
    try_spacy_initialize()
    on.exit(try(spacy_finalize(), silent = TRUE))
    txt <- c(d1 = "And now for something  different.", d2 = "",
             d3 = "Jack and Jill are children. They ran.")
    corp <- quanteda::corpus(txt, docvars = data.frame(year = 2001:2003))
    parsed <- spacy_parse(corp)
    expect_identical(unique(parsed$doc_id), c("d1", "d3"))
    expect_identical(quanteda::docnames(parsed), c("d1", "d2", "d3"))
    expect_identical(quanteda::ndoc(parsed), 3L)
    expect_identical(unname(quanteda::ntoken(parsed)),
                     c(sum(parsed$doc_id == "d1"), 0L, sum(parsed$doc_id == "d3")))
    expect_identical(quanteda::nsentence(parsed), c(d1 = 1L, d2 = 0L, d3 = 2L))
    toks <- quanteda::as.tokens(parsed)
    expect_identical(quanteda::docnames(toks), c("d1", "d2", "d3"))
    expect_identical(quanteda::ntoken(toks), quanteda::ntoken(parsed))
    expect_identical(quanteda::docvars(toks, "year"), 2001:2003)
    expect_identical(quanteda::as.list(toks)$d1, parsed$token[parsed$doc_id == "d1"])

    # a character vector: the same documents, no docvars
    parsed_chr <- spacy_parse(txt)
    expect_identical(quanteda::docnames(parsed_chr), c("d1", "d2", "d3"))
    expect_identical(ncol(quanteda::docvars(quanteda::as.tokens(parsed_chr))), 0L)

    # a subset by document
    toks_d3 <- quanteda::as.tokens(parsed[parsed$doc_id == "d3", ])
    expect_identical(quanteda::docnames(toks_d3), "d3")
    expect_identical(quanteda::docvars(toks_d3, "year"), 2003L)

    # only empty documents
    nothing <- spacy_parse(c(a = "", b = ""))
    expect_identical(nrow(nothing), 0L)
    expect_identical(quanteda::docnames(nothing), c("a", "b"))
    expect_identical(quanteda::ntoken(quanteda::as.tokens(nothing)),
                     c(a = 0L, b = 0L))

    # consolidated entities keep the documents
    cons <- entity_consolidate(parsed)
    expect_identical(quanteda::docnames(cons), c("d1", "d2", "d3"))
    expect_identical(quanteda::docvars(quanteda::as.tokens(cons), "year"),
                     2001:2003)
})

# a second parse by hand: one document, named as given
hand_parsed2 <- function(doc_id, year, empty = character()) {
    x <- data.frame(doc_id = rep(doc_id, 2), sentence_id = 1L,
                    token_id = 1:2, token = c("p", "q"), lemma = c("P", "Q"),
                    pos = c("X", "Y"), stringsAsFactors = FALSE)
    class(x) <- c("spacyr_parsed", "data.frame")
    spacyr:::set_parsed_documents(x, c(doc_id, empty),
                                  data.frame(year = year))
}

test_that("rbind() of parses with a document of the same name drops the record", {
    skip_if_not_installed("quanteda")
    first <- hand_parsed2("d", c(2000L, 2001L), empty = "nothing")
    second <- hand_parsed2("d", 2010L)
    both <- rbind(first, second)
    expect_s3_class(both, "spacyr_parsed")
    expect_identical(nrow(both), 4L)
    expect_null(attr(both, "documents"))
    expect_identical(quanteda::docnames(both), "d")
    expect_identical(quanteda::ntoken(both), c(d = 4L))
    toks <- quanteda::as.tokens(both)
    expect_identical(quanteda::docnames(toks), "d")
    expect_identical(ncol(quanteda::docvars(toks)), 0L)
})

test_that("a record kept by another way of binding is not used", {
    skip_if_not_installed("quanteda")
    first <- hand_parsed2("d", c(2000L, 2001L), empty = "nothing")
    second <- hand_parsed2("d", 2010L)
    # as functions that keep the attributes of their first argument do
    both <- rbind.data.frame(first, second)
    expect_identical(attr(both, "documents")$doc_id, c("d", "nothing"))
    expect_identical(quanteda::docnames(both), "d")
    expect_identical(quanteda::ndoc(both), 1L)
    toks <- quanteda::as.tokens(both)
    expect_identical(quanteda::docnames(toks), "d")
    expect_identical(ncol(quanteda::docvars(toks)), 0L)
})

test_that("rbind() of parses with different documents combines the records", {
    skip_if_not_installed("quanteda")
    first <- hand_parsed2("a", c(2000L, 2001L), empty = "nothing")
    second <- hand_parsed2("b", 2010L)
    both <- rbind(first, second)
    expect_identical(quanteda::docnames(both), c("a", "nothing", "b"))
    expect_identical(quanteda::ntoken(both), c(a = 2L, nothing = 0L, b = 2L))
    toks <- quanteda::as.tokens(both)
    expect_identical(quanteda::docnames(toks), c("a", "nothing", "b"))
    expect_identical(quanteda::docvars(toks, "year"), c(2000L, 2001L, 2010L))

    # other document variables, or none in one: the documents, no docvars
    third <- second
    names(attr(third, "documents")$docvars) <- "decade"
    mixed <- rbind(first, third)
    expect_identical(quanteda::docnames(mixed), c("a", "nothing", "b"))
    expect_identical(ncol(quanteda::docvars(quanteda::as.tokens(mixed))), 0L)
    attr(third, "documents")$docvars <- NULL
    mixed <- rbind(first, third)
    expect_identical(quanteda::docnames(mixed), c("a", "nothing", "b"))
    expect_identical(ncol(quanteda::docvars(quanteda::as.tokens(mixed))), 0L)

    # a parse without a record: none for the result
    old <- second
    attr(old, "documents") <- NULL
    expect_null(attr(rbind(first, old), "documents"))
    expect_identical(quanteda::docnames(rbind(first, old)), c("a", "b"))
    # one parse alone keeps its record
    expect_identical(attr(rbind(first), "documents"), attr(first, "documents"))
})
