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

    # the types of a tokens object, in the order in which they first occur
    toks <- quanteda::as.tokens(parsed)
    expect_identical(spacy_vectors_types(toks), reference)

    # the features of a dfm, in their order: the dfm times the vectors of
    # its features is a vector for each document
    dfmat <- quanteda::dfm(toks, tolower = FALSE)
    fem <- spacy_vectors_types(dfmat)
    expect_identical(rownames(fem), quanteda::featnames(dfmat))
    dem <- as.matrix(dfmat %*% fem)
    expect_identical(dim(dem), c(3L, 3L))
    expect_identical(unname(dem["d1", ]), c(1, 0, 1.25))
  })
})

test_that("spacy_vectors_types() follows the documents and features of quanteda objects", {
  skip_on_cran()
  skip_on_os("solaris")
  skip_if_not_installed("quanteda")
  with_vectors_pipeline({
    toks <- quanteda::tokens(c(a = "cat dog", b = "sat the", c = "dog zebra"))

    # the types of the documents that are there, and no others: types() of a
    # subset still has those of the documents that were removed
    expect_identical(rownames(spacy_vectors_types(toks)),
                     c("cat", "dog", "sat", "the", "zebra"))
    expect_identical(rownames(spacy_vectors_types(toks[2])), c("sat", "the"))
    expect_identical(rownames(spacy_vectors_types(toks[c(3, 1)])),
                     c("dog", "zebra", "cat"))
    expect_identical(dim(spacy_vectors_types(toks[0])), c(0L, 3L))
    expect_identical(dim(spacy_vectors_types(toks[integer()])), c(0L, 3L))

    # the padding of removed tokens is a type, without a vector
    padded <- quanteda::tokens_remove(toks, "dog", padding = TRUE)
    vec <- spacy_vectors_types(padded)
    expect_identical(rownames(vec), c("cat", "", "sat", "the", "zebra"))
    expect_identical(unname(attr(vec, "oov")), c(FALSE, TRUE, FALSE, FALSE, TRUE))
    expect_identical(unname(vec[2, ]), c(0, 0, 0))

    # a dfm of padded tokens keeps the padding as a feature: there is a row
    # for it, so that the dfm and the vectors can be multiplied
    dfmat <- quanteda::dfm(padded)
    expect_true("" %in% quanteda::featnames(dfmat))
    fem <- spacy_vectors_types(dfmat)
    expect_identical(rownames(fem), quanteda::featnames(dfmat))
    dem <- as.matrix(dfmat %*% fem)
    expect_identical(dim(dem), c(3L, 3L))
    expect_identical(unname(dem["a", ]), c(1, 0, 0))
    expect_identical(unname(dem["b", ]), c(0.5, 0.5, 1))
    expect_identical(unname(dem["c", ]), c(0, 0, 0))
    # also after the features are subsetted or reordered
    some <- dfmat[, c("the", "cat")]
    expect_identical(rownames(spacy_vectors_types(some)), c("the", "cat"))
    expect_identical(dim(spacy_vectors_types(dfmat[, 0])), c(0L, 3L))
  })
})

test_that("vectors that are on a GPU are copied to the host", {
  skip_on_cran()
  skip_on_os("solaris")
  with_vectors_pipeline({
    comp <- reticulate::import_from_path("spacyr_test_components",
                                         path = test_path("python"))
    module <- spacyr:::spacyr_module()
    nlp <- spacyr:::spacyr_env$nlp
    # a stand-in for a table on a GPU: its vectors are arrays that NumPy
    # does not convert by itself, as CuPy's
    device <- comp$use_device_vectors(nlp)
    np <- reticulate::import("numpy", convert = FALSE)
    expect_error(np$asarray(device$vocab$get_vector("cat")), "Implicit conversion")
    res <- module$type_vectors(device, list("dog", "zebra", "cat"))
    expect_identical(res[[1]], module$type_vectors(nlp, list("dog", "zebra", "cat"))[[1]])
    expect_identical(unname(res[[1]][1, ]), c(0, 1, 0))
    expect_identical(unlist(res[[2]]), c(FALSE, TRUE, FALSE))
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
