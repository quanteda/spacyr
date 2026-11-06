context("process_document() and get_*()")
source("utils.R")

# spacy_parse() no longer uses process_document() and the get_*() functions,
# which are exported (as internal) and kept until they are deprecated; they
# must still give the same values as spacy_parse().
test_that("get_*() agree with spacy_parse()", {
  skip_on_cran()
  skip_on_os("solaris")
  try_spacy_initialize()

  txt <- c(b = "The Supreme Court is in Washington. It sits in winter.",
           a = "Paris is in France.", c = "")
  parsed <- spacy_parse(txt, tag = TRUE, dependency = TRUE,
                        additional_attributes = "like_num")
  sp <- process_document(txt)
  expect_identical(sp$docnames, names(txt))
  expect_identical(get_tokens(sp), parsed$token)
  expect_identical(get_attrs(sp, "lemma_"), parsed$lemma)
  expect_identical(get_attrs(sp, "like_num"), parsed$like_num)
  expect_identical(get_tags(sp, "google"), parsed$pos)
  expect_identical(get_tags(sp, "detailed"), parsed$tag)
  expect_identical(get_named_entities(sp), parsed$entity)
  expect_identical(get_dependency(sp)$dep_rel, parsed$dep_rel)
  expect_identical(lengths(get_ntokens_by_sent(sp)),
                   c(2L, 1L, 0L))
  expect_identical(sum(unlist(get_ntokens(sp))), nrow(parsed))
  nps <- get_noun_phrases(sp)
  expect_identical(nps$text, spacy_extract_nounphrases(txt)$text)
})
