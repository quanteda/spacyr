context("pipeline paths")
source("utils.R")

# Which spaCy path each function uses: nlp.pipe(), which calls each
# component's pipe() method on batches of documents, or nlp(), which calls the
# component on each document. A custom component can behave differently in the
# two, so these tests record the paths of spacyr 1.4.0; a change of path must
# be intended and described in NEWS.md. spacy_tokenize() is not covered: its
# tokens do not depend on pipeline components other than the parser.

with_path_marker <- function(code) {
  try(spacy_finalize(), silent = TRUE)
  try_spacy_initialize()
  reticulate::import_from_path("spacyr_test_components",
                               path = test_path("python"))
  nlp <- spacyr:::spacyr_env$nlp
  nlp$add_pipe("spacyr_test_path_marker", last = TRUE)
  on.exit(spacy_finalize(), add = TRUE)
  force(code)
}

two <- c(b = "First document here.", a = "Second one.")
one <- c(only = "Just one document.")
marks <- function(x) unique(x[nzchar(x)])

test_that("spacy_parse() uses nlp.pipe() only with multithread = TRUE", {
  skip_on_cran()
  skip_on_os("solaris")
  with_path_marker({
    expect_identical(marks(spacy_parse(two)$entity), c("VIA_PIPE_B", "VIA_PIPE_I"))
    expect_identical(marks(spacy_parse(one)$entity), c("VIA_PIPE_B", "VIA_PIPE_I"))
    expect_identical(marks(spacy_parse(two, multithread = FALSE)$entity), "VIA_CALL_B")
    expect_identical(marks(spacy_parse(one, multithread = FALSE)$entity), "VIA_CALL_B")
    expect_identical(
      spacy_parse(two, additional_attributes = "norm_")$norm_[c(1, 5)],
      c("VIA_PIPE", "VIA_PIPE"))
    expect_identical(
      spacy_parse(two, multithread = FALSE, additional_attributes = "norm_")$norm_[c(1, 5)],
      c("VIA_CALL", "VIA_CALL"))
    expect_identical(marks(spacy_parse(two, nounphrase = TRUE)$entity),
                     c("VIA_PIPE_B", "VIA_PIPE_I"))
    expect_identical(marks(spacy_parse(two, nounphrase = TRUE, multithread = FALSE)$entity),
                     "VIA_CALL_B")
  })
})

test_that("spacy_extract_entity() uses nlp.pipe() only for several documents with multithread = TRUE", {
  skip_on_cran()
  skip_on_os("solaris")
  with_path_marker({
    expect_identical(spacy_extract_entity(two)$ent_type, c("VIA_PIPE", "VIA_PIPE"))
    expect_identical(spacy_extract_entity(two, multithread = FALSE)$ent_type,
                     c("VIA_CALL", "VIA_CALL"))
    expect_identical(spacy_extract_entity(one)$ent_type, "VIA_CALL")
    expect_identical(spacy_extract_entity(two, output = "list"),
                     list(b = "First document", a = "Second one"))
    expect_identical(spacy_extract_entity(two, output = "list", multithread = FALSE),
                     list(b = "First", a = "Second"))
    expect_identical(spacy_extract_entity(one, output = "list"), list(only = "Just"))
  })
})
