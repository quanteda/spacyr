context("testing nounphrase functions")
source("utils.R")

test_that("spacy_extract_nounphrases data.frame works", {
    skip_on_cran()
    # skip_on_appveyor()
    skip_on_os("solaris")
    skip_if_no_python_or_no_spacy()

    expect_message(spacy_initialize(), "successfully|already")

    txt1 <- c(doc1 = "The history of natural language processing generally started in the 1950s, although work can be found from earlier periods.",
              doc2 = "In 1950, Alan Turing published an article titled Intelligence which proposed what is now called the Turing test as a criterion of intelligence.")
    noun_phrases <- spacy_extract_nounphrases(txt1, output = "data.frame")
    expect_equal(
        noun_phrases$text,
        c("The history", "natural language processing", "the 1950s",
          "work", "earlier periods", "Alan Turing", "an article", "what",
          "a criterion", "intelligence"))
    expect_equal(
        noun_phrases$root_text,
        c("history", "processing", "1950s", "work", "periods", "Turing",
          "article", "what", "criterion", "intelligence"))

    expect_error(
        spacy_extract_nounphrases(c(doc1 = "Hello", doc1 = "world"), output = "data.frame"),
        "duplicated"
    )

    expect_error(
        spacy_extract_nounphrases(c(doc1 = "Hello", "world"), output = "data.frame"),
        "missing"
    )

    expect_silent(spacy_finalize())
})


test_that("spacy_extract_nounphrases works with a TIF formatted data.frame", {
    skip_on_cran()
    # skip_on_appveyor()
    skip_on_os("solaris")
    skip_if_no_python_or_no_spacy()

    # comment out following line to increase a coverage
    #expect_message(spacy_initialize(), "successfully|already")

    txt1 <- c(doc1 = "The history of natural language processing generally started in the 1950s, although work can be found from earlier periods.",
              doc2 = "In 1950, Alan Turing published an article titled Intelligence which proposed what is now called the Turing test as a criterion of intelligence.")
    txt1_df <- data.frame(doc_id = names(txt1), text = txt1, stringsAsFactors = FALSE)

    expect_equal(
        spacy_extract_nounphrases(txt1_df, output = "data.frame"),
        spacy_extract_nounphrases(txt1, output = "data.frame")
    )

    txt1_df_err <- data.frame(doc_name = names(txt1), text = txt1, stringsAsFactors = FALSE)
    expect_error(
        spacy_extract_nounphrases(txt1_df_err, output = "data.frame"),
        "input data.frame does not conform to the TIF standard"
    )

    expect_silent(spacy_finalize())
})


test_that("spacy_extract_nounphrases with atomic text string", {
    skip_on_cran()
    # skip_on_appveyor()
    skip_on_os("solaris")
    skip_if_no_python_or_no_spacy()

    expect_message(spacy_initialize(), "successfully|already")

    txt1 <- "The history of natural language processing generally started in the 1950s, although work can be found from earlier periods."
    noun_phrases <- spacy_extract_nounphrases(txt1, output = "data.frame")

    expect_true(
        all.equal(noun_phrases$doc_id[1], "text1")
    )
    expect_equal(
        noun_phrases$text,
        c("The history", "natural language processing", "the 1950s",
          "work", "earlier periods")
    )
    expect_equal(
        noun_phrases$root_text,
        c("history", "processing", "1950s", "work", "periods")
    )

    expect_silent(spacy_finalize())
})


test_that("spacy_extract_nounphrases list works", {
    skip_on_cran()
    # skip_on_appveyor()
    skip_on_os("solaris")
    skip_if_no_python_or_no_spacy()

    expect_message(spacy_initialize(), "successfully|already")

    txt1 <- c(doc1 = "The history of natural language processing generally started in the 1950s, although work can be found from earlier periods.",
              doc2 = "In 1950, Alan Turing published an article titled Intelligence which proposed what is now called the Turing test as a criterion of intelligence.")
    noun_phrases <- spacy_extract_nounphrases(txt1, output = "list")

    expect_equal(
        noun_phrases,
        list(doc1 = c("The history", "natural language processing", "the 1950s", "work", "earlier periods"),
             doc2 = c("Alan Turing", "an article", "what", "a criterion", "intelligence")))

    expect_silent(spacy_finalize())
})

test_that("spacy_extract_nounphrases data.frame and list returns the same nounphrases", {
    skip_on_cran()
    # skip_on_appveyor()
    skip_on_os("solaris")
    skip_if_no_python_or_no_spacy()

    expect_message(spacy_initialize(), "successfully|already")

    txt1 <- c(doc1 = "The history of natural language processing generally started in the 1950s, although work can be found from earlier periods.",
              doc2 = "In 1950, Alan Turing published an article titled Intelligence which proposed what is now called the Turing test as a criterion of intelligence.")
    noun_phrases_dataframe <- spacy_extract_nounphrases(txt1, output = "data.frame")
    noun_phrases_list <- spacy_extract_nounphrases(txt1, output = "list")

    expect_equal(
        noun_phrases_dataframe$text,
        unname(unlist(noun_phrases_list))
    )

    expect_equal(
        unname(sapply(noun_phrases_list, length)),
        as.vector(unclass(unname(table(noun_phrases_dataframe$doc_id))))
    )

    expect_silent(spacy_finalize())
})

test_that("spacy_extract_nounphrases.data.frame() works", {
    skip_on_cran()
    # skip_on_appveyor()
    skip_on_os("solaris")
    skip_if_no_python_or_no_spacy()
    expect_message(spacy_initialize(), "successfully|already")

    txt <- c(doc1 = "The history of natural language processing generally started in the 1950s, although work can be found from earlier periods.",
             doc2 = "In 1950, Alan Turing published an article titled Intelligence which proposed what is now called the Turing test as a criterion of intelligence.")
    txt_df <- data.frame(doc_id = paste0("doc", 1:2),
                         text = txt, stringsAsFactors = FALSE)

    expect_equal(
        spacy_extract_nounphrases(txt),
        spacy_extract_nounphrases(txt_df)
    )
})


test_that("spacy_parse nounphrase = TRUE works", {
    skip_on_cran()
    # skip_on_appveyor()
    skip_on_os("solaris")
    skip_if_no_python_or_no_spacy()

    expect_message(spacy_initialize(), "successfully|already")

    txt1 <- c(doc1 = "The history of natural language processing generally started in the 1950s, although work can be found from earlier periods.",
              doc2 = "In 1950, Alan Turing published an article titled Intelligence which proposed what is now called the Turing test as a criterion of intelligence.")
    parsed <- spacy_parse(txt1, nounphrase = TRUE)

    expect_true(
        "nounphrase" %in% names(parsed)
    )
    expect_true(
        "whitespace" %in% names(parsed)
    )
    expect_identical(
        sum(grepl("beg", parsed$nounphrase)),
        10L
    )


    expect_silent(spacy_finalize())
})

test_that("nounphrase_extract() on parsed object works", {
    skip_on_cran()
    # skip_on_appveyor()
    skip_on_os("solaris")
    skip_if_no_python_or_no_spacy()

    expect_message(spacy_initialize(), "successfully|already")

    txt1 <- c(doc1 = "The history of natural language processing generally started in the 1950s, although work can be found from earlier periods.",
              doc2 = "In 1950, Alan Turing published an article titled Intelligence which proposed what is now called the Turing test as a criterion of intelligence.")
    parsed <- spacy_parse(txt1, nounphrase = TRUE)

    expect_silent(
        nounphrase_extract(parsed)
    )

    parsed_without_nounphrase <- spacy_parse(txt1, nounphrase = FALSE)
    expect_error(
        nounphrase_extract(parsed_without_nounphrase),
        "no nounphrases in parsed object"
    )
})

test_that("compare nounphrase_extract(spacy_parse()) and spacy_extract_nounphrases()", {
    skip_on_cran()
    # skip_on_appveyor()
    skip_on_os("solaris")
    skip_if_no_python_or_no_spacy()

    expect_message(spacy_initialize(), "successfully|already")

    txt1 <- c(doc1 = "The history of natural language processing generally started in the 1950s, although work can be found from earlier periods.",
              doc2 = "In 1950, Alan Turing published an article titled Intelligence which proposed what is now called the Turing test as a criterion of intelligence.")
    parsed <- spacy_parse(txt1, nounphrase = TRUE)

    noun_phrases_1 <- nounphrase_extract(parsed, concatenator = " ")
    noun_phrases_2 <- spacy_extract_nounphrases(txt1, output = "data.frame")
    expect_equal(
        noun_phrases_1$nounphrase,
        noun_phrases_2$text
    )
    expect_equal(
        parsed$token[grep("root", parsed$nounphrase)],
        noun_phrases_2$root_text
    )

    expect_silent(spacy_finalize())
})


test_that("nounphrase consolidation works", {
    skip_on_cran()
    # skip_on_appveyor()
    skip_on_os("solaris")
    skip_if_no_python_or_no_spacy()
    expect_message(spacy_initialize(), "successfully|already")

    txt1 <- c(doc1 = "The history of natural language processing generally started in the 1950s, although work can be found from earlier periods.",
              doc2 = "In 1950, Alan Turing published an article titled Intelligence which proposed what is now called the Turing test as a criterion of intelligence.")

    parsed <- spacy_parse(txt1, entity = TRUE, nounphrase = TRUE)
    expect_equal(
        nounphrase_consolidate(parsed)$token[c(1, 3, 15)],
        c("The_history", "natural_language_processing", "earlier_periods")
    )
    expect_equal(
        nounphrase_consolidate(parsed, concatenator = " ")$token[c(1, 3, 15)],
        c("The history", "natural language processing", "earlier periods")
    )
    expect_equal(
        nounphrase_consolidate(parsed)$token_id,
        c(1:16, 1:22)
    )

    expect_identical( c("nounphrase", "whitespace", "entity")  %in% names(nounphrase_consolidate(parsed)),
                      rep(FALSE, 3))

    parsed <- spacy_parse(txt1, nounphrase = TRUE, pos = TRUE, tag = TRUE)
    expect_equal(
        nounphrase_consolidate(parsed)$pos[c(1, 3, 7, 10)],
        rep("nounphrase", 4)
    )
    expect_equal(
        nounphrase_consolidate(parsed)$tag[c(1, 3, 7, 10)],
        rep("nounphrase", 4)
    )
    expect_equal(
        nounphrase_consolidate(parsed)$lemma[c(1, 3, 7)],
        c("the_history", "natural_language_processing", "the_1950")
    )

    parsed <- spacy_parse(txt1, nounphrase = TRUE, dependency = TRUE)
    expect_message(
        nounphrase_consolidate(parsed),
        "emoving head_token_id, dep_rel for nounphrases"
    )

    expect_silent(spacy_finalize())
})
