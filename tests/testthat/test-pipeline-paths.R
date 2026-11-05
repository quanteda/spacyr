context("pipeline paths")
source("utils.R")

# Which spaCy path each function uses: nlp.pipe(), which calls each
# component's pipe() method on batches of documents, or nlp(), which calls the
# component on each document. A custom component can behave differently in the
# two. In spacyr 1.4.0, the path depended on multithread and on the number of
# documents; now every function uses nlp.pipe(). A change of path must be
# intended and described in NEWS.md. spacy_tokenize() is not covered: its
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

test_that("spacy_parse() always uses nlp.pipe()", {
  skip_on_cran()
  skip_on_os("solaris")
  with_path_marker({
    for (mt in c(TRUE, FALSE)) {
      for (x in list(two, one)) {
        expect_identical(marks(spacy_parse(x, multithread = mt)$entity),
                         c("VIA_PIPE_B", "VIA_PIPE_I"))
        expect_identical(marks(spacy_parse(x, multithread = mt, nounphrase = TRUE)$entity),
                         c("VIA_PIPE_B", "VIA_PIPE_I"))
      }
      expect_identical(
        spacy_parse(two, multithread = mt, additional_attributes = "norm_")$norm_[c(1, 5)],
        c("VIA_PIPE", "VIA_PIPE"))
    }
  })
})

test_that("spacy_extract_entity() always uses nlp.pipe()", {
  skip_on_cran()
  skip_on_os("solaris")
  with_path_marker({
    for (mt in c(TRUE, FALSE)) {
      expect_identical(spacy_extract_entity(two, multithread = mt)$ent_type,
                       c("VIA_PIPE", "VIA_PIPE"))
      expect_identical(spacy_extract_entity(one, multithread = mt)$ent_type, "VIA_PIPE")
      expect_identical(spacy_extract_entity(two, output = "list", multithread = mt),
                       list(b = "First document", a = "Second one"))
      expect_identical(spacy_extract_entity(one, output = "list", multithread = mt),
                       list(only = "Just one"))
    }
  })
})
