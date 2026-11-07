context("process_document() and get_*()")
source("utils.R")

# process_document() and the get_*() functions are deprecated. Until they are
# removed, they must still give the same values as spacy_parse().
quiet <- function(expr) {
  withCallingHandlers(expr, spacyr_deprecated = function(w) invokeRestart("muffleWarning"))
}

test_that("get_*() agree with spacy_parse()", {
  skip_on_cran()
  skip_on_os("solaris")
  try_spacy_initialize()

  txt <- c(b = "The Supreme Court is in Washington. It sits in winter.",
           a = "Paris is in France.", c = "")
  parsed <- spacy_parse(txt, tag = TRUE, dependency = TRUE,
                        additional_attributes = "like_num")
  sp <- quiet(process_document(txt))
  expect_identical(sp$docnames, names(txt))
  quiet({
    expect_identical(get_tokens(sp), parsed$token)
    expect_identical(get_attrs(sp, "lemma_"), parsed$lemma)
    expect_identical(get_attrs(sp, "like_num"), parsed$like_num)
    expect_identical(get_tags(sp, "google"), parsed$pos)
    expect_identical(get_tags(sp, "detailed"), parsed$tag)
    expect_identical(get_named_entities(sp), parsed$entity)
    expect_identical(get_dependency(sp)$dep_rel, parsed$dep_rel)
    expect_identical(lengths(get_ntokens_by_sent(sp)), c(2L, 1L, 0L))
    expect_identical(sum(unlist(get_ntokens(sp))), nrow(parsed))
    nps <- get_noun_phrases(sp)
  })
  expect_identical(nps$text, spacy_extract_nounphrases(txt)$text)
})

test_that("process_document() and each get_*() give a deprecation warning", {
  skip_on_cran()
  skip_on_os("solaris")
  try_spacy_initialize()

  expect_warning(sp <- process_document(c(a = "Paris is big.")),
                 class = "spacyr_deprecated")
  expect_warning(process_document("x"), "`process_document\\(\\)` is deprecated")
  calls <- list(
    get_tokens = function() get_tokens(sp),
    get_tags = function() get_tags(sp),
    get_attrs = function() get_attrs(sp, "is_punct"),
    get_named_entities = function() get_named_entities(sp),
    get_dependency = function() get_dependency(sp),
    get_noun_phrases = function() get_noun_phrases(sp),
    get_ntokens = function() get_ntokens(sp),
    get_ntokens_by_sent = function() get_ntokens_by_sent(sp))
  for (f in names(calls)) {
    # exactly one warning, naming the function, on every call
    for (i in 1:2) {
      w <- list()
      withCallingHandlers(calls[[f]](), warning = function(cond) {
        w[[length(w) + 1]] <<- cond
        invokeRestart("muffleWarning")
      })
      expect_length(w, 1)
      expect_s3_class(w[[1]], "spacyr_deprecated")
      expect_match(conditionMessage(w[[1]]), paste0("`", f, "()` is deprecated"),
                   fixed = TRUE, info = f)
    }
  }
})

test_that("a process_document() result is not affected by later calls", {
  skip_on_cran()
  skip_on_os("solaris")
  try_spacy_initialize()

  sp1 <- quiet(process_document(c(a = "Hello world.")))
  sp2 <- quiet(process_document(c(b = "Another text here.")))
  spacy_parse("Something else.")
  spacy_tokenize("And more.")
  spacy_extract_entity("Paris is big.")
  spacy_extract_nounphrases("The big dog.")
  quiet({
    expect_identical(get_tokens(sp1), c("Hello", "world", "."))
    expect_identical(get_tokens(sp2), c("Another", "text", "here", "."))
  })
})

test_that("get_*() need a process_document() result", {
  expect_error(quiet(get_tokens(list(timestamps = "x"))),
               "must be the result of process_document")
})

test_that("process_document() checks its arguments before initializing spaCy", {
  local_mocked_bindings(spacy_initialize = function(...) stop("spacy_initialize() was called"),
                        .package = "spacyr")
  op <- options(spacy_initialized = NULL)
  on.exit(options(op), add = TRUE)
  quiet({
    expect_error(process_document("x", n_process = 0), "`n_process` must be")
    expect_error(process_document("x", batch_size = 2.5), "`batch_size` must be")
    expect_warning(expect_error(process_document("x", multithread = TRUE),
                                "spacy_initialize\\(\\) was called"),
                   "`multithread` argument of `process_document\\(\\)`")
  })
})
