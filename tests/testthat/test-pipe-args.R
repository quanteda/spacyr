context("n_process, batch_size and multithread")
source("utils.R")

test_that("n_process and batch_size are checked", {
  expect_identical(spacyr:::pipe_args(1, NULL), list(n_process = 1L, batch_size = NULL))
  expect_identical(spacyr:::pipe_args(-1, 10), list(n_process = -1L, batch_size = 10L))
  expect_identical(spacyr:::pipe_args(4L, 1L), list(n_process = 4L, batch_size = 1L))
  # the largest value that as.integer() can represent
  big <- .Machine$integer.max
  expect_identical(spacyr:::pipe_args(big, big), list(n_process = big, batch_size = big))
  expect_silent(spacyr:::pipe_args(as.numeric(big), as.numeric(big)))
  for (bad in list(0, -2, 1.5, NA, NA_integer_, "2", c(1, 2), Inf, NULL, TRUE,
                   2^31, -2^31, big + 1)) {
    expect_error(spacyr:::pipe_args(bad, NULL), "`n_process` must be")
  }
  for (bad in list(0, -1, 1.5, NA, "2", c(1, 2), Inf, TRUE, 2^31, big + 1)) {
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

test_that("spacy_tokenize() starts processes only when components run", {
  # new_spobj() is replaced by an object that records the n_process it is
  # given, so that this test needs no Python
  seen <- NULL
  fake <- list(tokenize = function(..., n_process) {
                   seen <<- n_process
                   list(d1 = "a")
               },
               tokenize_sentence = function(..., n_process) {
                   seen <<- n_process
                   list(d1 = "a")
               },
               skipped = list())
  local_mocked_bindings(new_spobj = function() fake, .package = "spacyr")
  op <- options(spacy_initialized = TRUE)
  on.exit(options(op), add = TRUE)
  x <- c(d1 = "a")

  # words: no component runs, so one process whatever n_process is
  spacy_tokenize(x, n_process = 4)
  expect_identical(seen, 1L)
  spacy_tokenize(x, n_process = -1, remove_punct = TRUE)
  expect_identical(seen, 1L)
  # n_process is still checked
  expect_error(spacy_tokenize(x, n_process = 0), "`n_process` must be")

  # the tagger runs for remove_symbols, and the whole pipeline for sentences
  spacy_tokenize(x, n_process = 4, remove_symbols = TRUE)
  expect_identical(seen, 4L)
  spacy_tokenize(x, n_process = -1, what = "sentence")
  expect_identical(seen, -1L)
  spacy_tokenize(x, what = "sentence")
  expect_identical(seen, 1L)
})

test_that("invalid arguments stop before spaCy is initialized", {
  # spacy_initialize() is replaced, so that this test needs no Python and
  # fails if any function initializes spaCy before checking its arguments
  local_mocked_bindings(spacy_initialize = function(...) stop("spacy_initialize() was called"),
                        .package = "spacyr")
  op <- options(spacy_initialized = NULL)
  on.exit(options(op), add = TRUE)
  funs <- list(spacy_parse = spacy_parse, spacy_tokenize = spacy_tokenize,
               spacy_extract_entity = spacy_extract_entity,
               spacy_extract_nounphrases = spacy_extract_nounphrases)
  for (fun in funs) {
    expect_error(fun(txt, n_process = 0), "`n_process` must be")
    expect_error(fun(txt, n_process = 2^31), "`n_process` must be")
    expect_error(fun(txt, batch_size = 2^31), "`batch_size` must be")
    expect_error(fun(txt, batch_size = 2.5), "`batch_size` must be")
    # valid arguments reach spacy_initialize()
    expect_error(fun(txt), "spacy_initialize\\(\\) was called")
  }
  expect_null(getOption("spacy_initialized"))
})

test_that("spacy_tokenize() rejects flags that are not TRUE or FALSE", {
  # checked before spaCy is initialized: a missing value used to be passed to
  # Python, where it counted as TRUE or FALSE depending on the flag
  local_mocked_bindings(spacy_initialize = function(...) stop("spacy_initialize() was called"),
                        .package = "spacyr")
  op <- options(spacy_initialized = NULL)
  on.exit(options(op), add = TRUE)
  flags <- c("remove_punct", "remove_url", "remove_numbers",
             "remove_separators", "remove_symbols", "padding")
  for (flag in flags) {
    for (value in list(NA, c(TRUE, FALSE), "TRUE", 1)) {
      args <- stats::setNames(list(txt, value), c("x", flag))
      expect_error(do.call(spacy_tokenize, args),
                   paste0("`", flag, "` must be TRUE or FALSE"), fixed = TRUE)
    }
  }
  expect_null(getOption("spacy_initialized"))
})
