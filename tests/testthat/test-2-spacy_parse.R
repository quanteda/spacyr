context("test spacy_parse")
source("utils.R")

test_that("spacy_parse handles newlines and tabs ok", {
    skip_on_cran()
    # skip_on_appveyor()
    skip_on_os("solaris")
    try_spacy_initialize()

    txt1 <- c(doc1 = "Sentence one.\nSentence two.",
              doc2 = "Sentence\tthree.")
    expect_equal(
        dim(spacy_parse(txt1, dependency = TRUE)),
        c(11, 9)
    )
    # escaped sequences are text, not whitespace: they are passed to spaCy unchanged
    txt2 <- c(doc1 = "Sentence one.\\nSentence two.",
              doc2 = "Sentence\\tthree.")
    parsed2 <- spacy_parse(txt2, dependency = TRUE)
    expect_false(any(grepl("^\\s+$", parsed2$token)))
    expect_true(any(grepl("\\", parsed2$token, fixed = TRUE)))

    ## multiple tagsets
    expect_equal(
        names(tag1 <- spacy_parse(txt2, pos = TRUE, tag = FALSE, entity = FALSE)),
        c("doc_id", "sentence_id", "token_id", "token", "lemma", "pos")
    )
    expect_equal(
        names(tag2 <- spacy_parse(txt2, pos = FALSE, tag = TRUE, entity = FALSE)),
        c("doc_id", "sentence_id", "token_id", "token", "lemma", "tag")
    )
    expect_false(any(tag1$pos == tag2$tag))

    expect_silent(spacy_finalize())
})

test_that("spacy_parse handles quotes ok", {
    skip_on_cran()
    # skip_on_appveyor()
    skip_on_os("solaris")
    try_spacy_initialize()

    txt1 <- c(doc1 = "Sentence \"quoted\" one.",
              doc2 = "Sentence \'quoted\' two.")
    expect_true("dep_rel" %in% names(spacy_parse(txt1, dependency = TRUE)))

    # backslash-escaped quotes keep their backslashes
    txt4 <- c(doc1 = "Sentence \\\"quoted\\\" one.",
              doc2 = "Sentence \\\'quoted\\\' two.")
    parsed4 <- spacy_parse(txt4, dependency = TRUE)
    expect_identical(unique(parsed4$doc_id), c("doc1", "doc2"))
    expect_true(all(c("doc1", "doc2") %in%
                      parsed4$doc_id[grepl("\\", parsed4$token, fixed = TRUE)]))
    expect_silent(spacy_finalize())
})

test_that("spacy_parse returns the same regardless of the value of 'entity' option at the initialization", {
    skip_on_cran()
    # skip_on_appveyor()
    skip_on_os("solaris")
    try_spacy_initialize()

    txt1 <- c(doc1 = "Sentence one.\nSentence two.",
              doc2 = "Sentence\tthree.")
    
    data_not_omit_entity <- spacy_parse(txt1, entity = FALSE)
    expect_silent(spacy_finalize())

    expect_message(spacy_initialize(entity = FALSE), "successfully")
    data_omit_entity <- spacy_parse(txt1, entity = FALSE)

    expect_equal(
        data_omit_entity,
        data_not_omit_entity
    )

    expect_silent(spacy_finalize())
})

test_that("spacy_parse returns the message if 'entity' option is not consistent with the initialization options", {
    skip_on_cran()
    # skip_on_appveyor()
    skip_on_os("solaris")
    try_spacy_initialize()

    txt1 <- c(doc1 = "Sentence one.\nSentence two.",
              doc2 = "Sentence\tthree.")
    
    expect_silent(spacy_finalize())
    expect_message(spacy_initialize(entity = FALSE), "successfully|already")
    expect_message(spacy_parse(txt1, entity = TRUE), "entity == TRUE is ignored")

    expect_silent(spacy_finalize())
    expect_message(spacy_initialize(entity = TRUE), "successfully")
    expect_silent(tmp <- spacy_parse(txt1, entity = TRUE))

    expect_silent(spacy_finalize())
})

test_that("spacy_parse additional_attributes option works as intended", {
    skip_on_cran()
    # skip_on_appveyor()
    skip_on_os("solaris")
    try_spacy_initialize()

    expect_message(spacy_initialize(), "successfully|already")

    txt1 <- c(doc1 = "I would have accepted without question the information that Gatsby sprang from the swamps of Louisiana or from the lower East Side of New York.",
              doc2 = "I graduated from New Haven in 1915, just a quarter of a century after my father, and a little later I participated in that delayed Teutonic migration known as the Great War.")

    spacy_parsed <- spacy_parse(txt1, additional_attributes = "is_title")

    expect_true("is_title" %in% names(spacy_parsed))
    expect_equal(sum(spacy_parsed$is_title), 14)

    spacy_parsed <- spacy_parse(txt1, additional_attributes = c("is_title", "like_num"))

    expect_true("like_num" %in% names(spacy_parsed))
    expect_equal(spacy_parsed[spacy_parsed$token == "1915", "like_num"],
                 TRUE)

    expect_error(spacy_parse(txt1, additional_attributes = c("random_attribute_name")),
                 "object has no attribute")

    expect_silent(spacy_finalize())
})

test_that("spacy_parse can handle data.frame properly", {
    skip_on_cran()
    # skip_on_appveyor()
    skip_on_os("solaris")
    try_spacy_initialize()

    expect_message(spacy_initialize(), "successfully|already")

    df <- data.frame(doc_id = paste0("doc", seq(2)),
                     text = c("Sentence one.\nSentence two.",
                              "Sentence\tthree."),
                     stringsAsFactors = FALSE)
    expect_equal(dim(spacy_parse(df)), c(11, 7))

    df_impropoer <- data.frame(id = paste0("doc", seq(2)),
                               text = c("Sentence one.\nSentence two.",
                                        "Sentence\tthree."),
                               stringsAsFactors = FALSE)
    expect_error(spacy_parse(df_impropoer),
                 "input data.frame does not conform to the TIF standard")

    expect_silent(spacy_finalize())
})

# see https://stackoverflow.com/questions/55518184/how-to-feed-a-tibble-to-spacyr
test_that("spacy_parse handles numbers/tibbles correctly", {
    skip_on_cran()
    skip_on_os("solaris")
    try_spacy_initialize()
    skip_if_not_installed("tibble")
    bogustib <- tibble::tibble(doc_id = c(1, 2, 3),
                               text = c("bug", "one love", "838383838"))
    expect_equivalent(
        spacy_parse(bogustib)[, c("doc_id", "sentence_id", "token_id", "token", "pos")],
        data.frame(
            doc_id = as.character(c(1, 2, 2, 3)),
            sentence_id = rep(1, 4),
            token_id = c(1, 1, 2, 1),
            token = c("bug", "one", "love", "838383838"),
            pos = c("NOUN", "NUM", "NOUN", "NUM"),
            stringsAsFactors = FALSE)
    )
})

test_that("spacy_parse and extractors do not alter backslashes in the input text", {
  skip_on_cran()
  skip_on_os("solaris")
  try_spacy_initialize()

  txt <- c(d1 = "Ken wrote \\alpha in C:\\Users and a literal \\n here.")
  parsed <- spacy_parse(txt, entity = FALSE)
  expect_true("\\alpha" %in% parsed$token)
  expect_false(any(grepl("^\\s+$", parsed$token)))
  expect_identical(
    paste(spacy_tokenize(txt, remove_separators = FALSE)[[1]], collapse = ""),
    unname(txt)
  )
})

test_that("spacy_parse treats NA documents as empty", {
  skip_on_cran()
  skip_on_os("solaris")
  try_spacy_initialize()

  parsed <- spacy_parse(c(a = NA, b = "Hi there."), entity = FALSE)
  expect_false("NA" %in% parsed$token)
  expect_identical(unique(parsed$doc_id), "b")
})

test_that("spacy_parse does not warn about lemmatization for non-English models", {
  skip_on_cran()
  skip_on_os("solaris")
  skip_if_not(spacyr:::py_check_installed("de_core_news_sm"), "de_core_news_sm not installed")
  try(spacy_finalize(), silent = TRUE)
  expect_message(spacy_initialize(model = "de_core_news_sm"), "successfully")
  expect_no_warning(spacy_parse("Ich bin hier."))
  spacy_finalize()
  expect_message(spacy_initialize(), "successfully")
})
