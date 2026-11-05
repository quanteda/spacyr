context("test spacy_tokenize")
source("utils.R")

test_that("spacy_tokenize returns either data.frame and list", {
  skip_on_cran()
  skip_on_os("solaris")
  try_spacy_initialize()
  
  txt <- "This is a test for document names."
  tokens_list <- spacy_tokenize(txt, output = "list")
  expect_identical(
    length(tokens_list[[1]]),
    8L
  )
  expect_true(
    is.list(tokens_list)
  )
  
  tokens_df <- spacy_tokenize(txt, output = "data.frame")
  expect_identical(
    nrow(tokens_df),
    8L
  )
  expect_true(
    is.data.frame(tokens_df)
  )
  
})

test_that("spacy_tokenize works with a TIF formatted data.frame", {
  skip_on_cran()
  skip_on_os("solaris")
  try_spacy_initialize()
  
  txt1 <- c(doc1 = "The history of natural language processing generally started in the 1950s, although work can be found from earlier periods.",
            doc2 = "In 1950, Alan Turing published an article titled Intelligence which proposed what is now called the Turing test as a criterion of intelligence.")
  txt1_df <- data.frame(doc_id = names(txt1), text = txt1, stringsAsFactors = FALSE)
  
  expect_equal(
    spacy_tokenize(txt1_df, output = "list"),
    spacy_tokenize(txt1, output = "list")
  )
  
  txt1_df_err <- data.frame(doc_name = names(txt1), text = txt1, stringsAsFactors = FALSE)
  expect_error(
    spacy_tokenize(txt1_df_err, output = "data.frame"),
    "input data.frame does not conform to the TIF standard"
  )
  
})


test_that("spacy_tokenize docnames work as expected", {
  skip_on_cran()
  skip_on_os("solaris")
  try_spacy_initialize()
  
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
  try_spacy_initialize()
  
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
  try_spacy_initialize()
  
  txt <- "This: £ = GBP! 15% not! > 20 percent?"
  expect_equivalent(
    spacy_tokenize(txt, remove_symbols = FALSE),
    list(c("This", ":", "£", "=", "GBP", "!", "15", "%", "not", "!", ">", "20", "percent", "?"))
  )
  skip("behaviour of remove_symbols has changed")
  expect_equivalent(
    spacy_tokenize(txt, remove_symbols = TRUE, padding = FALSE),
    list(c("This", ":",  "GBP", "!", "15", "%", "not", "!",
           ">", "20", "percent", "?"))
  )
})


test_that("spacy_tokenize padding argument work as expected", {
  skip_on_cran()
  skip_on_os("solaris")
  try_spacy_initialize()
  
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
  try_spacy_initialize()
  
  txt <- "My favorite: the very! nice? ±2 for €5 beers."
  expect_equivalent(
    spacy_tokenize(txt, remove_punct = TRUE, padding = FALSE),
    list(c("My", "favorite", "the", "very", "nice", "±2", "for", "€", "5", "beers"))
  )
})

test_that("spacy_tokenize remove_url works as expected", {
  skip_on_cran()
  skip_on_os("solaris")
  try_spacy_initialize()
  
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
  try_spacy_initialize()
  
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
  try_spacy_initialize()
  
  txt <- c(doc1 = "Sentence  one\ttwo\nNew paragraph\u2029Last paragraph")
  expect_equivalent(
    spacy_tokenize(txt, remove_separators = FALSE),
    list(c("Sentence", " ", " ", "one", "\t", "two", "\n",
           "New", " ", "paragraph", "\u2029",
           "Last", " ", "paragraph"))
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
  try_spacy_initialize()
  
  expect_identical(
    spacy_tokenize(data_char_paragraph, multithread = TRUE),
    spacy_tokenize(data_char_paragraph, multithread = FALSE)
  )
})

test_that("spacy_tokenize what = 'sentence' works as expected", {
  skip_on_cran()
  skip_on_os("solaris")
  try_spacy_initialize()
  
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

test_that("spacy_tokenize does not alter backslashes in the input text", {
  skip_on_cran()
  skip_on_os("solaris")
  try_spacy_initialize()

  txt <- c(d1 = "See C:\\Users\\ken and \\alpha with \\d+ and a literal \\n here.")
  toks <- spacy_tokenize(txt)[[1]]
  expect_true(all(c("\\alpha", "\\d+") %in% toks))
  expect_true(any(grepl("\\Users", toks, fixed = TRUE)))
  expect_false("alpha" %in% toks)
  expect_false("\n" %in% toks)
})

test_that("spacy_tokenize treats NA documents as empty", {
  skip_on_cran()
  skip_on_os("solaris")
  try_spacy_initialize()

  toks <- spacy_tokenize(c(a = NA, b = "Hi there."))
  expect_identical(names(toks), c("a", "b"))
  expect_length(toks$a, 0)
  expect_identical(toks$b, c("Hi", "there", "."))
})

test_that("spacy_tokenize restores the pipeline after an error", {
  skip_on_cran()
  skip_on_os("solaris")
  try_spacy_initialize()

  # longer than spaCy's default max_length of 1,000,000 characters
  expect_error(spacy_tokenize(strrep("word ", 210000)), "E088")
  expect_equivalent(
    spacy_tokenize("One sentence. Another one.", what = "sentence"),
    list(c("One sentence.", "Another one."))
  )
  expect_identical(
    spacy_extract_entity("Ken lives in London.", output = "list")[[1]],
    c("Ken", "London")
  )
})

test_that("spacy_tokenize what = 'sentence' does not depend on multithread", {
  skip_on_cran()
  skip_on_os("solaris")
  try_spacy_initialize()

  txt <- c(a = "One.  Two.  ", b = "Three.")
  for (rs in c(TRUE, FALSE)) {
    expect_identical(
      spacy_tokenize(txt, what = "sentence", remove_separators = rs, multithread = TRUE),
      spacy_tokenize(txt, what = "sentence", remove_separators = rs, multithread = FALSE)
    )
  }
  expect_identical(
    spacy_tokenize(txt, what = "sentence", remove_separators = FALSE)$a,
    c("One.  ", "Two.  ")
  )
})

test_that("spacy_tokenize what = 'sentence' keeps single trailing spaces", {
  skip_on_cran()
  skip_on_os("solaris")
  try_spacy_initialize()

  txt <- c(a = "One. Two. ", b = "Three.")
  for (mt in c(TRUE, FALSE)) {
    toks <- spacy_tokenize(txt, what = "sentence", remove_separators = FALSE, multithread = mt)
    expect_identical(toks$a, c("One. ", "Two. "))
    expect_identical(paste(toks$a, collapse = ""), unname(txt["a"]))
    expect_identical(
      spacy_tokenize(txt, what = "sentence", remove_separators = TRUE, multithread = mt)$a,
      c("One.", "Two.")
    )
  }
})
