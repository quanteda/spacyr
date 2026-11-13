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

    # names of the vector are ignored: the columns are named after the attributes
    expect_identical(
        spacy_parse(txt1, additional_attributes = c(title = "is_title", num = "like_num")),
        spacy_parse(txt1, additional_attributes = c("is_title", "like_num")))
    expect_identical(
        spacy_parse("Hello world.", additional_attributes = c(punct = "is_punct")),
        spacy_parse("Hello world.", additional_attributes = "is_punct"))

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

test_that("spacy_parse nounphrase = TRUE keeps attributes aligned with tokens", {
  skip_on_cran()
  skip_on_os("solaris")
  try_spacy_initialize()

  txt <- c(z = "The big dog runs.", a = "Hi!")
  plain <- spacy_parse(txt, entity = FALSE, additional_attributes = c("idx", "whitespace_"))
  np <- spacy_parse(txt, entity = FALSE, nounphrase = TRUE,
                    additional_attributes = c("idx", "whitespace_"))
  expect_identical(np$doc_id, plain$doc_id)
  expect_identical(np$token, plain$token)
  expect_identical(np$idx, plain$idx)
  expect_identical(np$whitespace, nchar(plain$whitespace_) > 0)
  expect_identical(np$idx[np$doc_id == "a" & np$token == "!"], 2L)
})

test_that("spacy_parse returns a typed empty result when all documents are missing", {
  skip_on_cran()
  skip_on_os("solaris")
  try_spacy_initialize()

  empty <- spacy_parse(rep(NA_character_, 2), tag = TRUE, dependency = TRUE)
  expect_s3_class(empty, "spacyr_parsed")
  expect_identical(nrow(empty), 0L)
  full <- spacy_parse("The dog runs.", tag = TRUE, dependency = TRUE)
  expect_identical(names(empty), names(full))
  expect_identical(vapply(empty, typeof, ""), vapply(full, typeof, ""))

  expect_identical(names(spacy_parse(c(a = NA_character_, b = ""))),
                   names(spacy_parse("The dog runs.")))
})

test_that("spacy_parse offsets = TRUE gives the character positions of tokens", {
  skip_on_cran()
  skip_on_os("solaris")
  try_spacy_initialize()

  # two spaces, a newline, a character outside the Basic Multilingual Plane,
  # a combining accent, a document without tokens, and one not in UTF-8
  txt <- c(d1 = "This is a dummy text.  Two spaces.\nA new line.",
           d2 = "An emoji \U0001F600 here, and café too.",
           d3 = "",
           d4 = iconv("Le café crème est prêt.", "UTF-8", "latin1"),
           d5 = "Mr. Smith moved to San Francisco.")
  parsed <- spacy_parse(txt, offsets = TRUE)

  expect_identical(names(parsed),
                   c("doc_id", "sentence_id", "token_id", "token", "start", "end",
                     "lemma", "pos", "entity"))
  expect_type(parsed$start, "integer")
  expect_type(parsed$end, "integer")
  # substring() with the offsets gives each token, whitespace tokens included
  expect_identical(unname(substring(enc2utf8(txt)[parsed$doc_id], parsed$start, parsed$end)),
                   parsed$token)
  # of one text, too, as in the example of the help page
  d5 <- parsed[parsed$doc_id == "d5", ]
  expect_identical(substring(txt[["d5"]], d5$start, d5$end), d5$token)
  expect_true(any(grepl("^\\s+$", parsed$token)))
  # the example of the request: counted from 1, with whitespace counted
  expect_identical(parsed$start[1:6], c(1L, 6L, 9L, 11L, 17L, 21L))
  expect_identical(parsed$end[1:6], c(4L, 7L, 9L, 15L, 20L, 21L))
  # positions start again in each document
  expect_identical(parsed$start[parsed$doc_id == "d5"][1], 1L)

  # the other columns are those of a parse without offsets
  plain <- spacy_parse(txt)
  expect_false(any(c("start", "end") %in% names(plain)))
  expect_identical(unclass(parsed)[names(plain)], unclass(plain)[names(plain)])

  # with every other option, and from a TIF data.frame
  full <- spacy_parse(txt, offsets = TRUE, tag = TRUE, dependency = TRUE,
                      nounphrase = TRUE, additional_attributes = "idx")
  expect_identical(names(full)[5:6], c("start", "end"))
  expect_identical(full$start, full$idx + 1L)
  expect_identical(full$end, full$idx + nchar(full$token))
  tif <- spacy_parse(data.frame(doc_id = names(txt), text = enc2utf8(txt),
                                stringsAsFactors = FALSE), offsets = TRUE)
  expect_identical(tif$start, parsed$start)

  # no tokens: the same columns, of the same types
  empty <- spacy_parse(c(a = NA_character_, b = ""), offsets = TRUE)
  expect_identical(nrow(empty), 0L)
  expect_identical(vapply(empty, typeof, ""), vapply(parsed, typeof, ""))

  expect_error(spacy_parse(txt, offsets = NA), "offsets must be TRUE or FALSE")
  expect_error(spacy_parse(txt, offsets = "yes"), "offsets must be TRUE or FALSE")

  # a consolidated token runs from its first token to its last
  ents <- entity_consolidate(parsed)
  sf <- ents[ents$token == "San_Francisco", ]
  expect_identical(substr(txt[["d5"]], sf$start, sf$end), "San Francisco")
  nps <- nounphrase_consolidate(spacy_parse(txt, offsets = TRUE, nounphrase = TRUE))
  sf <- nps[nps$token == "San_Francisco", ]
  expect_identical(substr(txt[["d5"]], sf$start, sf$end), "San Francisco")
})

test_that("spacy_parse offsets are positions in the input when the tokenizer changes whitespace", {
  skip_on_cran()
  skip_on_os("solaris")
  try(spacy_finalize(), silent = TRUE)
  try_spacy_initialize()
  on.exit(spacy_finalize(), add = TRUE)
  comp <- reticulate::import_from_path("spacyr_test_components",
                                       path = test_path("python"))
  nlp <- spacyr:::spacyr_env$nlp

  # as spaCy's tokenizer for Korean does, this one makes the document with
  # single spaces, whatever whitespace the text has
  comp$set_single_space_tokenizer(nlp)
  txt <- c(ko = "안녕  세계",
           ws = "  One\ttwo \n three  ",
           same = "Plain text here",
           none = "   ")
  parsed <- spacy_parse(txt, offsets = TRUE, additional_attributes = "idx")
  expect_identical(parsed$token,
                   c("안녕", "세계", "One", "two", "three",
                     "Plain", "text", "here"))
  expect_identical(parsed$start, c(1L, 5L, 3L, 7L, 13L, 1L, 7L, 12L))
  expect_identical(parsed$end, c(2L, 6L, 5L, 9L, 17L, 5L, 10L, 15L))
  expect_identical(unname(substring(txt[parsed$doc_id], parsed$start, parsed$end)),
                   parsed$token)
  # spaCy's own positions are those in its document, not in the text
  expect_identical(parsed$idx[1:5], c(0L, 3L, 0L, 4L, 8L))
  # also without the positional ids of several processes
  expect_identical(spacy_parse(txt, offsets = TRUE, batch_size = 1)$start, parsed$start)

  # a tokenizer that changes the words themselves: their place is unknown
  comp$set_single_space_tokenizer(nlp, lower = TRUE)
  expect_error(spacy_parse(c(a = "all lower  case", b = "Not  so"), offsets = TRUE),
               "tokenizer changed the text of document 'b'")
  expect_identical(spacy_parse(c(a = "all lower  case"), offsets = TRUE)$start,
                   c(1L, 5L, 12L))
  # without offsets, such a tokenizer is no error
  expect_identical(spacy_parse(c(b = "Not  so"))$token, c("not", "so"))
})

test_that("offsets is the last argument of spacy_parse(), after those of earlier versions", {
  before <- c("x", "pos", "tag", "lemma", "entity", "dependency", "nounphrase",
              "multithread", "additional_attributes", "n_process", "batch_size")
  expect_identical(names(formals(spacy_parse)), c(before, "offsets", "..."))
  expect_identical(names(formals(spacyr:::spacy_parse.character)),
                   c(before, "offsets", "..."))
})
