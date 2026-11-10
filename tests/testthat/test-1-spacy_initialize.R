context("test spacy_initialize")
source("utils.R")

test_that("spacy_initialize works as expected", {
  skip_on_cran()
  skip_on_os("solaris")
  suppressWarnings(spacy_install()) # is skipped if installed anyway
  
  expect_message(spacy_initialize(),
                 "successfully")

  expect_no_condition(spacy_finalize())
  
  expect_error(spacy_finalize(),
               "Nothing to finalize")
})

test_that("spacy_initialize max_length works", {
  skip_on_cran()
  skip_on_os("solaris")
  try(spacy_finalize(), silent = TRUE)

  for (bad in list(-1, 0, 1.5, Inf, NA_real_, 2^31, "a", c(1e6, 2e6))) {
    expect_error(spacy_initialize(max_length = bad), "max_length")
  }
  expect_null(getOption("spacy_initialized"))

  expect_message(spacy_initialize(max_length = 2e6), "successfully")
  long_txt <- strrep("word ", 210000) # 1,050,000 characters
  expect_length(spacy_tokenize(long_txt)[[1]], 210000)
  spacy_finalize()

  expect_message(spacy_initialize(), "successfully")
  expect_error(spacy_tokenize(long_txt), "E088")
  spacy_finalize()
})

test_that("spacy_initialize split_hyphens works", {
  skip_on_cran()
  skip_on_os("solaris")
  try(spacy_finalize(), silent = TRUE)

  for (bad in list(NA, "no", c(TRUE, FALSE), 0)) {
    expect_error(spacy_initialize(split_hyphens = bad), "split_hyphens")
  }
  expect_null(getOption("spacy_initialized"))

  txt <- "An eye-opening, well-known X-ray: 3-4 days - or e-mail -me, x--y today."
  expect_message(spacy_initialize(), "successfully")
  split <- spacy_tokenize(txt)[[1]]
  expect_true(all(c("eye", "-", "opening", "well", "known") %in% split))
  spacy_finalize()

  expect_message(spacy_initialize(split_hyphens = FALSE), "successfully")
  kept <- spacy_tokenize(txt)[[1]]
  expect_identical(
    kept,
    c("An", "eye-opening", ",", "well-known", "X-ray", ":", "3", "-", "4",
      "days", "-", "or", "e-mail", "-me", ",", "x", "--", "y", "today", ".")
  )
  parsed <- spacy_parse(txt, entity = FALSE)
  expect_identical(parsed$token, kept)
  # phrases of the entity ruler are tokenized in the same way
  spacy_finalize()
  expect_message(
    spacy_initialize(split_hyphens = FALSE,
                     entity_patterns = c(PRODUCT = "X-ray machine")),
    "successfully")
  ents <- spacy_extract_entity("The X-ray machine broke.")
  expect_identical(ents$text, "X-ray machine")
  spacy_finalize()

  # the check of the tokenizer does not depend on nlp.max_length
  expect_message(spacy_initialize(max_length = 4, split_hyphens = FALSE),
                 "successfully")
  spacy_finalize()

  # the default tokenizer is unchanged by a later initialization
  expect_message(spacy_initialize(), "successfully")
  expect_identical(spacy_tokenize(txt)[[1]], split)
  spacy_finalize()
})

# save a pipeline built in Python to a temporary directory, and return its path
save_hyphen_pipeline <- function(nlp) {
  path <- tempfile("pipeline")
  dir.create(path)
  nlp$to_disk(path)
  path
}

test_that("split_hyphens keeps the other boundaries of a rule", {
  skip_on_cran()
  skip_on_os("solaris")
  try(spacy_finalize(), silent = TRUE)
  try_spacy_initialize()
  spacy_finalize()
  # Polish splits at any hyphen with one infix rule
  spacy <- reticulate::import("spacy")
  path <- save_hyphen_pipeline(spacy$blank("pl"))
  on.exit(unlink(path, recursive = TRUE))
  txt <- "biało-czerwony X-1 3-4 a--b słowo- koniec"
  expect_message(spacy_initialize(path), "successfully")
  split <- spacy_tokenize(txt)[[1]]
  expect_true(all(c("biało", "-", "czerwony", "X", "1") %in% split))
  spacy_finalize()
  expect_silent(suppressMessages(spacy_initialize(path, split_hyphens = FALSE)))
  expect_identical(
    spacy_tokenize(txt)[[1]],
    c("biało-czerwony", "X-1", "3", "-", "4", "a", "-", "-", "b",
      "słowo", "-", "koniec")
  )
  spacy_finalize()
})

test_that("split_hyphens warns about phrases of a saved ruler", {
  skip_on_cran()
  skip_on_os("solaris")
  try(spacy_finalize(), silent = TRUE)
  try_spacy_initialize()
  spacy_finalize()
  spacy <- reticulate::import("spacy")
  nlp <- spacy$load("en_core_web_sm", exclude = list("ner"))
  ruler <- nlp$add_pipe("entity_ruler")
  ruler$add_patterns(list(list(label = "PRODUCT", pattern = "X-ray machine")))
  path <- save_hyphen_pipeline(nlp)
  on.exit(unlink(path, recursive = TRUE))
  rm(nlp, ruler)

  expect_silent(suppressMessages(spacy_initialize(path)))
  expect_identical(spacy_extract_entity("The X-ray machine broke.")$text,
                   "X-ray machine")
  spacy_finalize()
  expect_warning(
    suppressMessages(spacy_initialize(path, split_hyphens = FALSE)),
    "Phrase patterns of 'entity_ruler' may not match")
  spacy_finalize()

  # no warning when the tokenizer is not changed, as for German
  path_de <- save_hyphen_pipeline(local({
    nlp <- spacy$blank("de")
    nlp$add_pipe("entity_ruler")$add_patterns(
      list(list(label = "ORG", pattern = "Rot-Kreuz")))
    nlp
  }))
  on.exit(unlink(path_de, recursive = TRUE), add = TRUE)
  expect_silent(suppressMessages(spacy_initialize(path_de, split_hyphens = FALSE)))
  spacy_finalize()
})

test_that("split_hyphens leaves a custom infix callback alone", {
  skip_on_cran()
  skip_on_os("solaris")
  try(spacy_finalize(), silent = TRUE)
  try_spacy_initialize()
  spacy_finalize()
  bridge <- spacyr:::load_spacyr_module()
  spacy <- reticulate::import("spacy")
  main <- reticulate::py_run_string("
class HyphenSplitter:
    def __init__(self, rx = '-'):
        import re
        self.rx = re.compile(rx)
    def finditer(self, text):
        return self.rx.finditer(text)
", local = TRUE)
  nlp <- spacy$blank("en")
  nlp$tokenizer$infix_finditer <- main$HyphenSplitter()$finditer
  res <- bridge$keep_hyphens(nlp)
  expect_false(res$changed)
  expect_true(res$splits)

  # callbacks that split only one direction of a letter and a digit
  for (rx in c("(?<=[0-9])-(?=[a-z])", "(?<=[a-z])-(?=[0-9])")) {
    nlp <- spacy$blank("en")
    nlp$tokenizer$infix_finditer <- main$HyphenSplitter(rx)$finditer
    res <- bridge$keep_hyphens(nlp)
    expect_false(res$changed, label = rx)
    expect_true(res$splits, label = rx)
  }
})

test_that("spacy_installed() reports an installed spaCy and models", {
  skip_on_cran()
  skip_on_os("solaris")
  skip_if_not(spacy_installed(), "spaCy not installed")

  expect_true(spacy_installed("en_core_web_sm"))
  expect_false(spacy_installed("xx_no_such_model_sm"))
})

test_that("spacy_initialize gives a helpful error for a missing model", {
  skip_on_cran()
  skip_on_os("solaris")
  try(spacy_finalize(), silent = TRUE)

  expect_error(spacy_initialize(model = "xx_no_such_model_sm"),
               "spacy_download_langmodel\\(\"xx_no_such_model_sm\"\\)")
  expect_message(spacy_initialize(), "successfully")
  spacy_finalize()
})

test_that("spacyr leaves no variables in Python's __main__", {
  skip_on_cran()
  skip_on_os("solaris")
  try(spacy_finalize(), silent = TRUE)
  try_spacy_initialize()
  main_names <- function() names(reticulate::import_main(convert = FALSE))
  before <- main_names()
  txt <- c(d2 = "The European Central Bank is in Frankfurt.", d1 = "One more.")
  spacy_parse(txt, dependency = TRUE, nounphrase = TRUE)
  spacy_tokenize(txt, remove_punct = TRUE)
  spacy_tokenize(txt, what = "sentence")
  spacy_extract_entity(txt)
  spacy_extract_nounphrases(txt, output = "list")
  expect_identical(setdiff(main_names(), before), character())
  expect_false(any(c("nlp", "spobj", "texts", "spacyr") %in% main_names()))
  spacy_finalize()
})

test_that("spacy_initialize ignores a cached module with the same name", {
  skip_on_cran()
  skip_on_os("solaris")
  try(spacy_finalize(), silent = TRUE)
  try_spacy_initialize()
  spacy_finalize()
  # a module of the same name from elsewhere, e.g. another copy of spacyr
  sys <- reticulate::import("sys", convert = FALSE)
  types <- reticulate::import("types")
  sys$modules$`__setitem__`("spacyr_bridge", types$ModuleType("spacyr_bridge"))
  expect_message(spacy_initialize(), "successfully")
  expect_identical(
    normalizePath(reticulate::py_to_r(spacyr:::spacyr_env$module$`__file__`)),
    normalizePath(system.file("python", "spacyr_bridge.py", package = "spacyr")))
  expect_identical(nrow(spacy_parse("One two.")), 3L)
  spacy_finalize()
})
