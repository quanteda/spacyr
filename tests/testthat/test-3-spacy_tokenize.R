context("test spacy_parse")
source("utils.R")

test_that("spacy_tokenize docnames work as expected", {
    skip_on_cran()
    skip_on_os("solaris")
    skip_if_no_python_or_no_spacy()

    txt <- "This is a test for document names."
    expect_identical(
        names(spacy_tokenize(txt)), "text1"
    )
    expect_identical(
        names(spacy_tokenize(c(onlydoc = txt))),
        "onlydoc"
    )
    expect_identical(
        names(spacy_tokenize(c(doc1 = txt, doc2 = txt))),
        c("doc1", "doc2")
    )
})

test_that("spacy_tokenize remove_punct argument work as expected", {
    skip_on_cran()
    skip_on_os("solaris")
    skip_if_no_python_or_no_spacy()

    txt <- "This: £ = GBP! 15% not! > 20 percent?"
    expect_equivalent(
        spacy_tokenize(txt, remove_punct = FALSE),
        list(c("This", ":", "£", "=", "GBP", "!", "15", "%", "not", "!", ">", "20", "percent", "?"))
    )
    expect_equivalent(
        spacy_tokenize(txt, remove_punct = TRUE, padding = FALSE),
        list(c("This", "£", "=", "GBP", "15", "not", ">", "20", "percent"))
    )
})

test_that("spacy_tokenize remove_symbols argument work as expected", {
    skip_on_cran()
    skip_on_os("solaris")
    skip_if_no_python_or_no_spacy()

    txt <- "This: £ = GBP! 15% not! > 20 percent?"
    expect_equivalent(
        spacy_tokenize(txt, remove_symbols = FALSE),
        list(c("This", ":", "£", "=", "GBP", "!", "15", "%", "not", "!", ">", "20", "percent", "?"))
    )
    expect_equivalent(
        spacy_tokenize(txt, remove_symbols = TRUE, padding = FALSE),
        list(c("This", ":", "GBP", "!", "15", "%", "not", "!",
               ">", "20", "percent", "?"))
    )
})


test_that("spacy_tokenize padding argument work as expected", {
    skip_on_cran()
    skip_on_os("solaris")
    skip_if_no_python_or_no_spacy()

    txt <- "This: a test."
    expect_equivalent(
        spacy_tokenize(txt, remove_punct = FALSE, padding = TRUE),
        list(c("This", ":", "a", "test", "."))
    )
    expect_equivalent(
        spacy_tokenize(txt, remove_punct = TRUE, padding = FALSE),
        list(c("This", "a", "test"))
    )
    expect_equivalent(
        spacy_tokenize(txt, remove_punct = TRUE, padding = TRUE),
        list(c("This", "", "a", "test", ""))
    )
})

test_that("spacy_tokenize remove_punct works as expected", {
    skip_on_cran()
    skip_on_os("solaris")
    skip_if_no_python_or_no_spacy()

    txt <- "My favorite: the very! nice? ±2 for €5 beers."
    expect_equivalent(
        spacy_tokenize(txt, remove_punct = TRUE, padding = FALSE),
        list(c("My", "favorite", "the", "very", "nice", "±2", "for", "€", "5", "beers"))
    )
})

test_that("spacy_tokenize remove_url works as expected", {
    skip_on_cran()
    skip_on_os("solaris")
    skip_if_no_python_or_no_spacy()

    txt <- c(doc1 = "test@unicode.org can be seen at https://bit.ly/2RDxcxs?not=FALSE.")
    expect_equivalent(
        spacy_tokenize(txt, remove_url = FALSE, padding = FALSE, remove_punct = FALSE),
        list(c("test@unicode.org", "can", "be", "seen", "at", "https://bit.ly/2RDxcxs?not=FALSE", "."))
    )
    expect_equivalent(
        spacy_tokenize(txt, remove_url = FALSE, padding = FALSE, remove_punct = TRUE),
        list(c("test@unicode.org", "can", "be", "seen", "at", "https://bit.ly/2RDxcxs?not=FALSE"))
    )
    expect_equivalent(
        spacy_tokenize(txt, remove_url = TRUE, padding = FALSE, remove_punct = FALSE),
        list(c("can", "be", "seen", "at", "."))
    )
})

test_that("spacy_tokenize remove_numbers works as expected", {
    skip_on_cran()
    skip_on_os("solaris")
    skip_if_no_python_or_no_spacy()

    txt <- c(doc1 = "99 red ballons 4ever £5 gr8!!")
    expect_equivalent(
        spacy_tokenize(txt, remove_numbers = FALSE, padding = FALSE),
        list(c("99", "red", "ballons", "4ever", "£", "5", "gr8", "!", "!"))
    )
    expect_equivalent(
        spacy_tokenize(txt, remove_numbers = TRUE, padding = FALSE),
        list(c("red", "ballons", "4ever", "£", "gr8", "!", "!"))
    )
    expect_equivalent(
        spacy_tokenize(txt, remove_numbers = TRUE, padding = FALSE),
        quanteda::tokens(txt, remove_numbers = TRUE) %>% quanteda::as.list()
    )
})

test_that("spacy_tokenize remove_separators works as expected", {
    skip_on_cran()
    skip_on_os("solaris")
    skip_if_no_python_or_no_spacy()

    txt <- c(doc1 = "Sentence  one\ttwo\nNew paragraph\u2029Last paragraph")
    expect_equivalent(
        spacy_tokenize(txt, remove_separators = FALSE),
        list(c("Sentence", " ", " ", "one", "\t", "two", "\n", "New", " ", "paragraph", "\u2029", "Last", " ", "paragraph"))
    )
    expect_equivalent(
        spacy_tokenize(txt, remove_separators = TRUE),
        list(c("Sentence", "one", "two", "New", "paragraph", "Last", "paragraph"))
    )
    expect_equivalent(
        spacy_tokenize(txt, remove_separators = TRUE),
        quanteda::tokens(txt, remove_separators = TRUE) %>% quanteda::as.list()
    )
})

test_that("spacy_tokenize multithread = TRUE does not change value", {
    skip_on_cran()
    skip_on_os("solaris")
    skip_if_no_python_or_no_spacy()

    expect_identical(
        spacy_tokenize(data_char_paragraph, multithread = TRUE),
        spacy_tokenize(data_char_paragraph, multithread = FALSE)
    )
})

test_that("spacy_tokenize multithread = TRUE is faster than when FALSE", {
    skip_on_cran()
    skip_on_os("solaris")
    skip_if_no_python_or_no_spacy()

    skip("multithread = TRUE performance test skipped because takes so long")
    txt <- rep(data_char_paragraph, 5000)
    expect_lt(
        system.time(spacy_tokenize(txt, multithread = TRUE))["elapsed"],
        system.time(spacy_tokenize(txt, multithread = FALSE))["elapsed"]
    )
})

test_that("spacy_tokenize what = 'sentence' works as expected", {
    skip_on_cran()
    skip_on_os("solaris")
    skip_if_no_python_or_no_spacy()

    txt <- "Sentence one!  This: is a test.\n\nYeah, right.  What, Mr. Jones?"
    expect_equivalent(
        spacy_tokenize(txt, what = "sentence", remove_punct = TRUE,
                       remove_separators = TRUE),
        list(c(
            "Sentence one!",
            "This: is a test.",
            "Yeah, right.",
            "What, Mr. Jones?"
        ))
    )
    expect_equivalent(
        spacy_tokenize(txt, what = "sentence", remove_punct = TRUE,
                       remove_separators = FALSE),
        list(c(
            "Sentence one!  ",
            "This: is a test.\n\n",
            "Yeah, right.  ",
            "What, Mr. Jones?"
        ))
    )
    expect_equivalent(
        spacy_tokenize(txt, what = "sentence", remove_separators = TRUE),
        quanteda::tokens(txt, what = "sentence", remove_separators = TRUE) %>% as.list()
    )
})
