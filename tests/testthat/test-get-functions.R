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

test_that("the documented conversion gives get_dependency()'s head IDs", {
  skip_on_cran()
  skip_on_os("solaris")
  try_spacy_initialize()

  # head_token_id numbers tokens within each sentence, head_id within each
  # document; the conversion is the one documented in ?get_dependency
  txt <- c(a = "Dogs bark. Cats sleep.", b = "",
           c = "The Supreme Court is in Washington. It sits in winter. Yes.")
  parsed <- spacy_parse(txt, dependency = TRUE)
  head_id <- parsed$head_token_id +
    ave(seq_len(nrow(parsed)), parsed$doc_id, FUN = seq_along) -
    parsed$token_id
  sp <- quiet(process_document(txt))
  expect_identical(as.numeric(quiet(get_dependency(sp))$head_id), head_id)
  # the head of "Cats" is token 5 of document a, and token 2 of its sentence
  expect_identical(head_id[4], 5)
  expect_identical(parsed$head_token_id[4], 2)
})

test_that("spacy_finalize() frees the pipeline while a handle is kept", {
  skip_on_cran()
  skip_on_os("solaris")
  try_spacy_initialize()
  on.exit(spacy_initialize(), add = TRUE)

  ref <- reticulate::import("weakref")$ref(spacyr:::spacyr_env$nlp)
  sp <- quiet(process_document(c(a = "Hello world.")))
  expect_false(is.null(ref()))
  spacy_finalize()
  expect_null(ref())
  # the handle still reads its documents
  expect_identical(quiet(get_tokens(sp)), c("Hello", "world", "."))
})

test_that("get_*() work on a handle with no documents", {
  skip_on_cran()
  skip_on_os("solaris")
  try_spacy_initialize()

  sp <- quiet(process_document(character(0)))
  expect_length(sp$timestamps, 0)
  quiet({
    # previously, an empty handle made Python parse texts with the pipeline
    # that the handle has released
    expect_null(get_noun_phrases(sp))
    expect_identical(get_dependency(sp)$head_id, numeric(0))
    expect_length(get_dependency(sp)$dep_rel, 0)
    expect_length(get_tokens(sp), 0)
    expect_length(get_tags(sp), 0)
    expect_length(get_attrs(sp, "is_punct"), 0)
    expect_length(get_named_entities(sp), 0)
    expect_length(get_ntokens(sp), 0)
    expect_length(get_ntokens_by_sent(sp), 0)
  })
})
