source("utils.R")

# spacy_parse() leaves out, for the call, the pipeline components whose
# results its options do not ask for (#308). Its output must not depend on
# that: every combination of options gives the columns of a parse with all
# of them.

pipe_names <- function() reticulate::py_str(spacyr:::spacyr_env$nlp$pipe_names)
# the components that a call with these options leaves out
left_out <- function(...) {
  as.character(unlist(spacyr:::spacyr_module()$unneeded_pipes(spacyr:::spacyr_env$nlp, ...)))
}
columns <- function(x, cols = names(x)) unclass(x)[cols]

txt <- c(d1 = "The Supreme Court is located in Washington D.C.  It sits in a large building.",
         d2 = "",
         d3 = "Paul earned a postgraduate degree from MIT. He did not like it; the students were running.",
         d4 = "Yes.",
         d5 = "Mistakes were made, and the report is being rewritten by Jane Smith of Acme Corp. in May.",
         # documents of whitespace only, and with whitespace tokens: the
         # attribute ruler of spaCy's English models sets their dependency
         w1 = "\n\n",
         w2 = "  ",
         w3 = "A  b.\n\nC d.\n",
         w4 = " Leading and trailing \t ")

test_that("spacy_parse() gives the same output whichever components it leaves out", {
  skip_on_cran()
  skip_on_os("solaris")
  try(spacy_finalize(), silent = TRUE)
  try_spacy_initialize()
  on.exit(spacy_finalize(), add = TRUE)
  before <- pipe_names()

  full <- spacy_parse(txt, pos = TRUE, tag = TRUE, lemma = TRUE, entity = TRUE,
                      dependency = TRUE, nounphrase = TRUE, offsets = TRUE)
  grid <- expand.grid(pos = c(TRUE, FALSE), tag = c(TRUE, FALSE), lemma = c(TRUE, FALSE),
                      entity = c(TRUE, FALSE), dependency = c(TRUE, FALSE),
                      nounphrase = c(TRUE, FALSE))
  same <- vapply(seq_len(nrow(grid)), function(i) {
    parsed <- suppressMessages(do.call(spacy_parse, c(list(txt), as.list(grid[i, ]))))
    identical(columns(parsed), columns(full, names(parsed)))
  }, logical(1))
  expect_true(all(same))
  expect_identical(pipe_names(), before)

  # with offsets, in batches of one, and with two processes
  few <- spacy_parse(txt, pos = FALSE, lemma = FALSE, entity = FALSE,
                     dependency = TRUE, offsets = TRUE, batch_size = 1)
  expect_identical(columns(few), columns(full, names(few)))
  two <- spacy_parse(txt, pos = FALSE, lemma = FALSE, entity = FALSE,
                     dependency = TRUE, n_process = 2)
  expect_identical(columns(two), columns(full, names(two)))
  expect_identical(pipe_names(), before)
})

test_that("spacy_parse() leaves out the components its options do not need", {
  skip_on_cran()
  skip_on_os("solaris")
  try(spacy_finalize(), silent = TRUE)
  try_spacy_initialize()
  on.exit(spacy_finalize(), add = TRUE)
  before <- pipe_names()
  tags <- c("tagger", "attribute_ruler", "lemmatizer")

  # the defaults need every component
  expect_identical(left_out(), character())
  expect_identical(left_out(entity = FALSE), "ner")
  expect_identical(left_out(lemma = FALSE), "lemmatizer")
  # the lemmatizer needs the tags, and noun phrases the part of speech
  expect_identical(left_out(pos = FALSE), character())
  expect_identical(left_out(pos = FALSE, lemma = FALSE), tags)
  expect_identical(left_out(pos = FALSE, lemma = FALSE, tag = TRUE), "lemmatizer")
  expect_identical(left_out(pos = FALSE, lemma = FALSE, nounphrase = TRUE), "lemmatizer")
  expect_identical(left_out(pos = FALSE, lemma = FALSE, entity = FALSE), c(tags, "ner"))
  # the attribute ruler of this model also sets the dependency of whitespace
  # tokens, so with dependency it stays, and the tagger, which it reads
  expect_identical(left_out(pos = FALSE, lemma = FALSE, dependency = TRUE), "lemmatizer")
  expect_identical(left_out(pos = FALSE, lemma = FALSE, entity = FALSE, dependency = TRUE),
                   c("lemmatizer", "ner"))
  whitespace <- spacy_parse(c(a = "\n\n"), pos = FALSE, lemma = FALSE, dependency = TRUE)
  expect_identical(whitespace$dep_rel,
                   spacy_parse(c(a = "\n\n"), dependency = TRUE)$dep_rel)
  # the parser, which sets the sentences, always runs
  expect_false("parser" %in% left_out(pos = FALSE, lemma = FALSE, entity = FALSE))
  # an additional attribute can come from any component
  expect_identical(left_out(pos = FALSE, lemma = FALSE, entity = FALSE,
                            attributes = list("is_stop")), character())

  # what spacy_parse() itself passes on, and its result without them
  spobj <- spacyr:::new_spobj()
  res <- spobj$parse_table(as.list(unname(txt)), as.list(names(txt)),
                           lemma = FALSE, pos = FALSE, entity = FALSE)
  expect_identical(as.character(unlist(res$disabled)), c(tags, "ner"))
  res <- spobj$parse_table(as.list(unname(txt)), as.list(names(txt)),
                           lemma = FALSE, pos = FALSE, entity = FALSE,
                           attributes = list("is_stop"))
  expect_identical(length(res$disabled), 0L)
  none <- spacy_parse(txt, pos = FALSE, lemma = FALSE, entity = FALSE,
                      additional_attributes = "pos_")
  expect_true(any(nzchar(none$pos_)))

  # the pipeline is as it was after a call, also after one that fails
  expect_identical(pipe_names(), before)
  expect_error(spacy_parse(c(a = "Short text.", b = strrep("a ", 600000)),
                           lemma = FALSE, entity = FALSE))
  expect_identical(pipe_names(), before)
})

test_that("spacy_parse() keeps an attribute ruler whose rules set what it returns", {
  skip_on_cran()
  skip_on_os("solaris")
  on.exit(spacy_finalize(), add = TRUE)
  sents <- c(a = "We met and they left early. Paul saw the big building.")
  tags <- c("tagger", "attribute_ruler", "lemmatizer")
  # a pipeline whose attribute ruler has one more rule
  with_rule <- function(pattern, attrs) {
    try(spacy_finalize(), silent = TRUE)
    try_spacy_initialize()
    spacyr:::spacyr_env$nlp$get_pipe("attribute_ruler")$add(
      patterns = list(list(pattern)), attrs = attrs)
  }
  expect_same <- function(...) {
    full <- spacy_parse(sents, tag = TRUE, dependency = TRUE)
    parsed <- spacy_parse(sents, ...)
    expect_identical(columns(parsed), columns(full, names(parsed)))
    full
  }

  # a rule that sets a sentence boundary: the ruler always stays, with the
  # tagger that its other rules read
  with_rule(list(LOWER = "and"), list(SENT_START = TRUE))
  expect_identical(left_out(pos = FALSE, lemma = FALSE, entity = FALSE),
                   c("lemmatizer", "ner"))
  full <- expect_same(pos = FALSE, lemma = FALSE, entity = FALSE)
  expect_identical(full$sentence_id[full$token == "and"], 2L)

  # a rule that sets an entity: the ruler stays when entities are returned
  with_rule(list(LOWER = "building"), list(ENT_TYPE = "THING", ENT_IOB = 3L))
  expect_identical(left_out(pos = FALSE, lemma = FALSE), "lemmatizer")
  expect_identical(left_out(pos = FALSE, lemma = FALSE, entity = FALSE), c(tags, "ner"))
  full <- expect_same(pos = FALSE, lemma = FALSE)
  expect_identical(full$entity[full$token == "building"], "THING_B")
  expect_same(pos = FALSE, lemma = FALSE, entity = FALSE)

  # a rule that sets another attribute, which a later component may read
  with_rule(list(LOWER = "paul"), list(NORM = "saul"))
  expect_identical(left_out(pos = FALSE, lemma = FALSE, entity = FALSE),
                   c("lemmatizer", "ner"))
  expect_same(pos = FALSE, lemma = FALSE, entity = FALSE)
})

test_that("spacy_parse() leaves nothing out of a pipeline with a custom component", {
  skip_on_cran()
  skip_on_os("solaris")
  try(spacy_finalize(), silent = TRUE)
  try_spacy_initialize()
  on.exit(spacy_finalize(), add = TRUE)
  reticulate::import_from_path("spacyr_test_components", path = test_path("python"))
  spacyr:::spacyr_env$nlp$add_pipe("spacyr_test_path_marker", last = TRUE)

  expect_identical(left_out(pos = FALSE, lemma = FALSE, entity = FALSE), character())
  # the component sets the first token's norm_, and entities of its own
  parsed <- spacy_parse(txt[c("d1", "d3")], pos = FALSE, lemma = FALSE,
                        additional_attributes = "norm_")
  expect_identical(parsed$norm_[parsed$token_id == 1 & parsed$sentence_id == 1],
                   c("VIA_PIPE", "VIA_PIPE"))
})

test_that("spacy_parse() keeps what entity rules may read", {
  skip_on_cran()
  skip_on_os("solaris")
  try(spacy_finalize(), silent = TRUE)
  # a rule on the lemma and the part of speech, which the ruler reads
  rule <- list(list(label = "ACTION",
                    pattern = list(list(LEMMA = "run", POS = "VERB"))))
  if (methods::is(try(spacy_initialize(entity_patterns = rule)), "try-error"))
    skip("Can't initialize")
  on.exit(spacy_finalize(), add = TRUE)
  ruler <- "spacyr_entity_ruler"

  # with entities, the ruler runs, and so does all that it may read
  expect_identical(left_out(lemma = FALSE), character())
  expect_identical(left_out(pos = FALSE, lemma = FALSE), character())
  # without them, neither it nor the recognizer runs
  expect_identical(left_out(entity = FALSE), c("ner", ruler))
  expect_identical(left_out(pos = FALSE, lemma = FALSE, entity = FALSE),
                   c("tagger", "attribute_ruler", "lemmatizer", "ner", ruler))

  full <- spacy_parse(txt, tag = TRUE, dependency = TRUE)
  expect_true("ACTION_B" %in% full$entity)
  for (args in list(list(lemma = FALSE), list(pos = FALSE, lemma = FALSE),
                    list(entity = FALSE), list(pos = FALSE, lemma = FALSE, entity = FALSE))) {
    parsed <- do.call(spacy_parse, c(list(txt), args))
    expect_identical(columns(parsed), columns(full, names(parsed)))
  }
})

test_that("spacy_parse() leaves out components of a pipeline without the entity recognizer", {
  skip_on_cran()
  skip_on_os("solaris")
  try(spacy_finalize(), silent = TRUE)
  if (methods::is(try(spacy_initialize(entity = FALSE)), "try-error"))
    skip("Can't initialize")
  on.exit(spacy_finalize(), add = TRUE)

  expect_identical(left_out(entity = FALSE), character())
  expect_identical(left_out(pos = FALSE, lemma = FALSE, entity = FALSE),
                   c("tagger", "attribute_ruler", "lemmatizer"))
  full <- spacy_parse(txt, tag = TRUE, entity = FALSE, dependency = TRUE)
  few <- spacy_parse(txt, pos = FALSE, lemma = FALSE, entity = FALSE, dependency = TRUE)
  expect_identical(columns(few), columns(full, names(few)))
})
