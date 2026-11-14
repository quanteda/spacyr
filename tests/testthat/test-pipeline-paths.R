context("pipeline paths")
source("utils.R")

# Which spaCy path each function uses: nlp.pipe(), which calls each
# component's pipe() method on batches of documents, or nlp(), which calls the
# component on each document. A custom component can behave differently in the
# two. In spacyr 1.4.0, the path depended on multithread and on the number of
# documents; now every function uses nlp.pipe(), whatever the batch size.
# (n_process > 1 is tested in test-pipe-args.R, with the standard pipeline and
# with custom components made importable in the other processes.) A change of
# path must be intended and described in NEWS.md. spacy_tokenize() is not covered: its
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
    for (bs in list(NULL, 1)) {
      for (x in list(two, one)) {
        expect_identical(marks(spacy_parse(x, batch_size = bs)$entity),
                         c("VIA_PIPE_B", "VIA_PIPE_I"))
        expect_identical(marks(spacy_parse(x, batch_size = bs, nounphrase = TRUE)$entity),
                         c("VIA_PIPE_B", "VIA_PIPE_I"))
      }
      expect_identical(
        spacy_parse(two, batch_size = bs, additional_attributes = "norm_")$norm_[c(1, 5)],
        c("VIA_PIPE", "VIA_PIPE"))
    }
  })
})

test_that("spacy_extract_entity() always uses nlp.pipe()", {
  skip_on_cran()
  skip_on_os("solaris")
  with_path_marker({
    for (bs in list(NULL, 1)) {
      expect_identical(spacy_extract_entity(two, batch_size = bs)$ent_type,
                       c("VIA_PIPE", "VIA_PIPE"))
      expect_identical(spacy_extract_entity(one, batch_size = bs)$ent_type, "VIA_PIPE")
      expect_identical(spacy_extract_entity(two, output = "list", batch_size = bs),
                       list(b = "First document", a = "Second one"))
      expect_identical(spacy_extract_entity(one, output = "list", batch_size = bs),
                       list(only = "Just one"))
    }
  })
})

# nlp.pipe() leaves out a document when a component fails on it and the
# pipeline's error handler suppresses the error; the other documents must keep
# their names, and the documents left out are reported in a warning.
with_failing_component <- function(code) {
  try(spacy_finalize(), silent = TRUE)
  try_spacy_initialize()
  components <- reticulate::import_from_path("spacyr_test_components",
                                             path = test_path("python"))
  nlp <- spacyr:::spacyr_env$nlp
  nlp$add_pipe("spacyr_test_fail_on_bad", last = TRUE)
  components$skip_errors(nlp)
  on.exit(spacy_finalize(), add = TRUE)
  force(code)
}

skipped <- c(bad = "Bad input.", good = "London is in England.")
skipped_warning <- "did not return 1 document, which is left out of the output: bad"

test_that("documents left out by the pipeline do not shift the others' names", {
  skip_on_cran()
  skip_on_os("solaris")
  with_failing_component({
    expect_warning(ents <- spacy_extract_entity(skipped), skipped_warning)
    expect_identical(ents$doc_id, c("good", "good"))
    expect_identical(ents$text, c("London", "England"))
    expect_warning(ents <- spacy_extract_entity(skipped, output = "list"), skipped_warning)
    expect_identical(ents, list(good = c("London", "England")))

    expect_warning(html <- entity_visualize(skipped), skipped_warning)
    expect_true(grepl("London", html))
    expect_false(grepl("Bad input", html))
    expect_warning(html <- entity_visualize(skipped["bad"]), skipped_warning)
    expect_identical(html, "")

    expect_warning(nps <- spacy_extract_nounphrases(skipped), skipped_warning)
    expect_identical(unique(nps$doc_id), "good")
    expect_warning(nps <- spacy_extract_nounphrases(skipped, output = "list"), skipped_warning)
    expect_identical(names(nps), "good")

    expect_warning(sents <- spacy_tokenize(skipped, what = "sentence"), skipped_warning)
    expect_identical(sents, list(good = "London is in England."))
    # word tokenization disables the pipeline components, so nothing is left out,
    # also when removing punctuation, numbers or URLs, which need no component
    expect_silent(toks <- spacy_tokenize(skipped))
    expect_identical(names(toks), c("bad", "good"))
    expect_silent(toks <- spacy_tokenize(skipped, remove_punct = TRUE,
                                         remove_numbers = TRUE, remove_url = TRUE))
    expect_identical(toks, list(bad = c("Bad", "input"), good = c("London", "is", "in", "England")))
    # remove_symbols needs the tagger, so the pipeline runs
    expect_warning(toks <- spacy_tokenize(skipped, remove_symbols = TRUE), skipped_warning)
    expect_identical(names(toks), "good")

    for (np in c(FALSE, TRUE)) {
      expect_warning(parsed <- spacy_parse(skipped, nounphrase = np), skipped_warning)
      expect_identical(unique(parsed$doc_id), "good")
      expect_identical(parsed$token, c("London", "is", "in", "England", "."))
      expect_identical(parsed$entity[c(1, 4)], c("GPE_B", "GPE_B"))
    }
  })
})
