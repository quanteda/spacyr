source("utils.R")

# Most of these tests need no Python: spacy_initialize() is replaced so that a
# test fails if it is called, and spaCy is marked as initialized or not.
no_spacy <- function(...) stop("spacy_initialize() was called")

test_that("spacy_input() names documents and treats NA documents as empty", {
  local_mocked_bindings(spacy_initialize = no_spacy, .package = "spacyr")
  op <- options(spacy_initialized = TRUE)
  on.exit(options(op), add = TRUE)
  expect_identical(spacyr:::spacy_input(c("a b", NA)),
                   list(x = c("a b", ""), docnames = c("text1", "text2")))
  expect_identical(spacyr:::spacy_input(c(d1 = "a", d2 = "b")),
                   list(x = c("a", "b"), docnames = c("d1", "d2")))
  expect_identical(spacyr:::spacy_input(character(0)),
                   list(x = character(0), docnames = character(0)))
  # names do not travel with the texts
  expect_null(names(spacyr:::spacy_input(c(d1 = "a"))$x))
})

test_that("spacy_input() rejects duplicated or missing document names", {
  local_mocked_bindings(spacy_initialize = no_spacy, .package = "spacyr")
  op <- options(spacy_initialized = TRUE)
  on.exit(options(op), add = TRUE)
  expect_error(spacyr:::spacy_input(c(a = "x", a = "y")), "^Docnames are duplicated\\.$")
  expect_error(spacyr:::spacy_input(structure(c("x", "y"), names = c("a", ""))),
               "^Some docnames are missing\\.$")
  expect_error(spacyr:::spacy_input(structure(c("x", "y"), names = c("a", NA))),
               "^Some docnames are missing\\.$")
})

test_that("spacy_input() checks names before initializing spaCy", {
  local_mocked_bindings(spacy_initialize = no_spacy, .package = "spacyr")
  op <- options(spacy_initialized = NULL)
  on.exit(options(op), add = TRUE)
  expect_error(spacyr:::spacy_input(c(a = "x", a = "y")), "duplicated")
  expect_error(spacyr:::spacy_input(c("x")), "spacy_initialize\\(\\) was called")
})

test_that("tif_texts() takes the texts and names from doc_id and text", {
  df <- data.frame(doc_id = c("a", "b"), text = c("x", "y"), stringsAsFactors = FALSE)
  expect_identical(spacyr:::tif_texts(df), c(a = "x", b = "y"))
  # factors, as data.frame() made them by default before R 4.0, and numbers
  df_factor <- data.frame(doc_id = c("a", "b"), text = c("x", "y"), stringsAsFactors = TRUE)
  expect_identical(spacyr:::tif_texts(df_factor), c(a = "x", b = "y"))
  expect_identical(spacyr:::tif_texts(data.frame(doc_id = 1:2, text = c("x", "y"))),
                   c("1" = "x", "2" = "y"))
  # other columns are ignored
  expect_identical(spacyr:::tif_texts(cbind(df, year = 1:2)), c(a = "x", b = "y"))
  expect_error(spacyr:::tif_texts(data.frame(id = "a", text = "x")),
               "^input data.frame does not conform to the TIF standard$")
})

funs <- list(spacy_parse = spacy_parse, spacy_tokenize = spacy_tokenize,
             spacy_extract_entity = spacy_extract_entity,
             spacy_extract_nounphrases = spacy_extract_nounphrases)

test_that("all functions reject bad input before initializing spaCy", {
  local_mocked_bindings(spacy_initialize = no_spacy, .package = "spacyr")
  op <- options(spacy_initialized = NULL)
  on.exit(options(op), add = TRUE)
  for (f in names(funs)) {
    fun <- funs[[f]]
    expect_error(fun(c(a = "x", a = "y")), "^Docnames are duplicated\\.$", info = f)
    expect_error(fun(structure("x", names = NA_character_)),
                 "^Some docnames are missing\\.$", info = f)
    expect_error(fun(data.frame(id = "a", text = "x")), "TIF standard", info = f)
  }
})

test_that("all functions accept factor TIF data.frames and empty input", {
  skip_on_cran()
  skip_on_os("solaris")
  try_spacy_initialize()

  df_chr <- data.frame(doc_id = c("a", "b"), text = c("New York is big.", "Paris is too."),
                       stringsAsFactors = FALSE)
  df_factor <- data.frame(doc_id = c("a", "b"), text = c("New York is big.", "Paris is too."),
                          stringsAsFactors = TRUE)
  for (f in names(funs)) {
    fun <- funs[[f]]
    expect_identical(fun(df_factor), fun(df_chr), info = f)
    # no documents, and so no warning about documents left out
    expect_no_warning(suppressMessages(fun(character(0))), message = NULL)
  }
  expect_identical(spacy_tokenize(character(0)), structure(list(), names = character(0)))
})
