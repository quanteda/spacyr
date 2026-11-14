source("utils.R")

# spacy_vectors_types(): the word vectors of types, from the model's table.
# The tests use a small pipeline with known vectors, made when they run, so
# that they need no model with vectors to be installed.

with_vectors_pipeline <- function(code) {
  try(spacy_finalize(), silent = TRUE)
  try_spacy_initialize()
  comp <- reticulate::import_from_path("spacyr_test_components",
                                       path = test_path("python"))
  dir <- tempfile("spacyr_vectors")
  on.exit({
    try(spacy_finalize(), silent = TRUE)
    unlink(dir, recursive = TRUE)
  }, add = TRUE)
  comp$save_vectors_pipeline(dir)
  spacy_finalize()
  spacy_initialize(model = dir)
  force(code)
}

test_that("spacy_vectors_types() stops on what it cannot look up, without Python", {
  expect_error(spacy_vectors_types(1:3), "not an object of class 'integer'")
  expect_error(spacy_vectors_types(data.frame(token = "a")),
               "not an object of class 'data.frame'")
  expect_error(spacy_vectors_types(list("a", 1)), "character vectors only")
  parsed <- structure(data.frame(doc_id = "d", token = "a", stringsAsFactors = FALSE),
                      class = c("spacyr_parsed", "data.frame"))
  expect_error(spacy_vectors_types(parsed, what = "lemma"),
               "x has no column lemma: rerun spacy_parse\\(\\) with lemma = TRUE")
  expect_error(spacy_vectors_types(parsed, what = "pos"), "should be one of")
  # what comes after ..., so that it is given by its full name
  expect_identical(names(formals(spacyr:::spacy_vectors_types.spacyr_parsed)),
                   c("x", "...", "what"))
  expect_error(spacy_vectors_types("a", nonsense = 1),
               "spacy_vectors_types\\(\\) does not use the argument nonsense")
})

test_that("spacy_vectors_types() returns the vectors of the model's table", {
  skip_on_cran()
  skip_on_os("solaris")
  with_vectors_pipeline({
    vec <- spacy_vectors_types(c("dog", "cat", "Cat", "zebra", "dog", NA, ""))

    # one row for each type, in the order of their first occurrence
    expect_true(is.matrix(vec))
    expect_type(vec, "double")
    expect_identical(dim(vec), c(5L, 3L))
    expect_identical(rownames(vec), c("dog", "cat", "Cat", "zebra", ""))
    expect_null(colnames(vec))
    expect_identical(unname(vec["dog", ]), c(0, 1, 0))
    expect_identical(unname(vec["cat", ]), c(1, 0, 0))
    expect_identical(vec["Cat", ], vec["cat", ])
    # types without a vector: rows of zeros, and named in oov
    expect_identical(unname(vec["zebra", ]), c(0, 0, 0))
    expect_identical(attr(vec, "oov"),
                     c(dog = FALSE, cat = FALSE, Cat = FALSE, zebra = TRUE, TRUE))
    expect_identical(names(attr(vec, "oov"))[5], "")
    expect_identical(attr(vec, "model"),
                     list(name = "en_spacyr_test_vectors", version = "0.0.1",
                          vectors = attr(vec, "model")$vectors))
    # a vector that is not a whole number, as stored in single precision
    expect_equal(unname(spacy_vectors_types(".")[1, ]), c(0, 0, 0.25))

    # no types: a matrix with no rows and the model's width
    none <- spacy_vectors_types(character())
    expect_identical(dim(none), c(0L, 3L))
    expect_identical(attr(none, "oov"), structure(logical(), names = character()))
    expect_identical(dim(spacy_vectors_types(NA_character_)), c(0L, 3L))
    # one type
    expect_identical(dim(spacy_vectors_types("cat")), c(1L, 3L))
  })
})

test_that("spacy_vectors_types() takes parsed texts, lists and quanteda objects", {
  skip_on_cran()
  skip_on_os("solaris")
  skip_if_not_installed("quanteda")
  with_vectors_pipeline({
    txt <- c(d1 = "The cat sat.", d2 = "", d3 = "the dog sat. The Cat sat.")
    # a blank pipeline has no lemmatizer or tagger
    parsed <- suppressWarnings(spacy_parse(txt, pos = FALSE, lemma = FALSE, entity = FALSE))
    types <- c("The", "cat", "sat", ".", "the", "dog", "Cat")
    reference <- spacy_vectors_types(types)

    expect_identical(spacy_vectors_types(parsed), reference)
    expect_identical(spacy_vectors_types(parsed, what = "token"), reference)
    expect_identical(spacy_vectors_types(spacy_tokenize(txt)), reference)
    expect_identical(spacy_vectors_types(list(c("The", "cat"), character(),
                                              c("sat", ".", "the", "dog", "Cat"))),
                     reference)

    # one row for each token of a parse
    by_token <- reference[parsed$token, ]
    expect_identical(nrow(by_token), nrow(parsed))
    expect_identical(unname(by_token[2, ]), c(1, 0, 0))

    # lemmas, where the parse has them
    with_lemma <- parsed
    with_lemma$lemma <- tolower(with_lemma$token)
    expect_identical(rownames(spacy_vectors_types(with_lemma, what = "lemma")),
                     c("the", "cat", "sat", ".", "dog"))

    # the types of a tokens object and the features of a dfm, without the
    # padding of removed tokens
    toks <- quanteda::as.tokens(parsed)
    expect_identical(spacy_vectors_types(toks)[types, ], reference[types, ])
    expect_setequal(rownames(spacy_vectors_types(toks)), types)
    padded <- quanteda::tokens_remove(toks, ".", padding = TRUE)
    expect_false("" %in% rownames(spacy_vectors_types(padded)))
    dfmat <- quanteda::dfm(toks, tolower = FALSE)
    fem <- spacy_vectors_types(dfmat)
    expect_identical(rownames(fem), quanteda::featnames(dfmat))
    # the document-feature matrix times the vectors of its features: a
    # vector for each document
    dem <- as.matrix(dfmat) %*% fem
    expect_identical(dim(dem), c(3L, 3L))
    expect_identical(unname(dem["d1", ]), c(1, 0, 1.25))
  })
})

test_that("spacy_vectors_types() stops for a model without word vectors", {
  skip_on_cran()
  skip_on_os("solaris")
  try(spacy_finalize(), silent = TRUE)
  try_spacy_initialize()
  on.exit(spacy_finalize(), add = TRUE)
  expect_error(spacy_vectors_types(c("cat", "dog")),
               "The language model 'en_core_web_sm' has no word vectors")
  expect_error(spacy_vectors_types(spacy_parse("A cat.")),
               "has no word vectors")
})
