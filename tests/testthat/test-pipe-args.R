context("n_process, batch_size and multithread")
source("utils.R")

test_that("n_process and batch_size are checked", {
  expect_identical(spacyr:::pipe_args(1, NULL), list(n_process = 1L, batch_size = NULL))
  expect_identical(spacyr:::pipe_args(-1, 10), list(n_process = -1L, batch_size = 10L))
  expect_identical(spacyr:::pipe_args(4L, 1L), list(n_process = 4L, batch_size = 1L))
  for (bad in list(0, -2, 1.5, NA, NA_integer_, "2", c(1, 2), Inf, NULL, TRUE)) {
    expect_error(spacyr:::pipe_args(bad, NULL), "`n_process` must be")
  }
  for (bad in list(0, -1, 1.5, NA, "2", c(1, 2), Inf, TRUE)) {
    expect_error(spacyr:::pipe_args(1, bad), "`batch_size` must be")
  }
})

test_that("multithread gives a deprecation warning only when supplied", {
  f <- function(multithread) spacyr:::check_multithread(multithread, "f")
  expect_silent(f())
  for (mt in c(TRUE, FALSE)) {
    expect_warning(f(mt), "The `multithread` argument of `f\\(\\)` is deprecated",
                   class = "deprecatedWarning")
  }
})

txt <- c(b = "London is in England. It rains.", a = "Paris is in France.",
         c = "", d = "Berlin is big.")

test_that("each function warns about multithread and still works", {
  skip_on_cran()
  skip_on_os("solaris")
  try_spacy_initialize()
  for (mt in c(TRUE, FALSE)) {
    expect_warning(p <- spacy_parse(txt, multithread = mt), "deprecated",
                   class = "deprecatedWarning")
    expect_identical(p, spacy_parse(txt))
    expect_warning(p <- spacy_tokenize(txt, multithread = mt), "deprecated",
                   class = "deprecatedWarning")
    expect_identical(p, spacy_tokenize(txt))
    expect_warning(p <- spacy_extract_entity(txt, multithread = mt), "deprecated",
                   class = "deprecatedWarning")
    expect_identical(p, spacy_extract_entity(txt))
    expect_warning(p <- spacy_extract_nounphrases(txt, multithread = mt), "deprecated",
                   class = "deprecatedWarning")
    expect_identical(p, spacy_extract_nounphrases(txt))
  }
  df <- data.frame(doc_id = names(txt), text = unname(txt), stringsAsFactors = FALSE)
  expect_warning(spacy_parse(df, multithread = TRUE), "deprecated", class = "deprecatedWarning")
  expect_silent(spacy_tokenize(txt))
})

test_that("batch_size and n_process do not change the output", {
  skip_on_cran()
  skip_on_os("solaris")
  try_spacy_initialize()
  x <- rep(txt, 5)
  names(x) <- paste0(names(x), rep(1:5, each = length(txt)))
  ref <- list(parse = spacy_parse(x, dependency = TRUE, nounphrase = TRUE),
              tokens = spacy_tokenize(x),
              sentences = spacy_tokenize(x, what = "sentence"),
              symbols = spacy_tokenize(x, remove_symbols = TRUE),
              entities = spacy_extract_entity(x),
              entity_list = spacy_extract_entity(x, output = "list"),
              nounphrases = spacy_extract_nounphrases(x),
              nounphrase_list = spacy_extract_nounphrases(x, output = "list"))
  run <- function(...) {
    list(parse = spacy_parse(x, dependency = TRUE, nounphrase = TRUE, ...),
         tokens = spacy_tokenize(x, ...),
         sentences = spacy_tokenize(x, what = "sentence", ...),
         symbols = spacy_tokenize(x, remove_symbols = TRUE, ...),
         entities = spacy_extract_entity(x, ...),
         entity_list = spacy_extract_entity(x, output = "list", ...),
         nounphrases = spacy_extract_nounphrases(x, ...),
         nounphrase_list = spacy_extract_nounphrases(x, output = "list", ...))
  }
  expect_identical(run(batch_size = 1), ref)
  expect_identical(run(batch_size = 3), ref)
  # starts two Python processes, each loading the model
  expect_identical(run(n_process = 2, batch_size = 4), ref)
})

test_that("invalid n_process and batch_size stop before spaCy is called", {
  skip_on_cran()
  skip_on_os("solaris")
  try_spacy_initialize()
  expect_error(spacy_parse(txt, n_process = 0), "`n_process` must be")
  expect_error(spacy_tokenize(txt, batch_size = 0), "`batch_size` must be")
  expect_error(spacy_extract_entity(txt, n_process = "2"), "`n_process` must be")
  expect_error(spacy_extract_nounphrases(txt, batch_size = 2.5), "`batch_size` must be")
})
