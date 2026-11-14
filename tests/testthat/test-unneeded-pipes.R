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

test_that("spacy_parse() keeps what the model of a later component reads", {
  skip_on_cran()
  skip_on_os("solaris")
  try(spacy_finalize(), silent = TRUE)
  try_spacy_initialize()
  on.exit(spacy_finalize(), add = TRUE)
  comp <- reticulate::import_from_path("spacyr_test_components",
                                       path = test_path("python"))
  # only components of spaCy's: a sentencizer, an attribute ruler that sets
  # the part of speech of "alpha", and an entity recognizer whose model
  # embeds the part of speech
  dir <- tempfile("spacyr_pos_ner")
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  comp$save_pos_ner_pipeline(dir)
  spacy_finalize()
  spacy_initialize(model = dir)
  nlp <- spacyr:::spacyr_env$nlp
  alpha <- c(a = "We saw alpha today.", b = "Nothing new here.")

  # the recognizer finds the entity by the part of speech, and not without
  # the ruler that sets it
  full <- spacy_parse(alpha, lemma = FALSE)
  expect_identical(full$entity[full$token == "alpha"], "PERSON_B")
  with(nlp$select_pipes(disable = list("attribute_ruler")),
       expect_identical(length(nlp("We saw alpha today.")$ents), 0L))

  # so the ruler stays as long as the recognizer does
  expect_identical(left_out(lemma = FALSE), character())
  expect_identical(left_out(pos = FALSE, lemma = FALSE), character())
  expect_identical(left_out(pos = FALSE, lemma = FALSE, entity = FALSE),
                   c("attribute_ruler", "ner"))
  for (args in list(list(pos = FALSE, lemma = FALSE),
                    list(pos = FALSE, lemma = FALSE, n_process = 2),
                    list(pos = FALSE, lemma = FALSE, entity = FALSE))) {
    parsed <- do.call(spacy_parse, c(list(alpha), args))
    expect_identical(columns(parsed), columns(full, names(parsed)))
  }
})

test_that("what a model reads is told from its settings", {
  skip_on_cran()
  skip_on_os("solaris")
  try(spacy_finalize(), silent = TRUE)
  try_spacy_initialize()
  on.exit(spacy_finalize(), add = TRUE)
  sorted <- reticulate::import_builtins()$sorted
  reads <- function(model) {
    as.character(unlist(sorted(spacyr:::spacyr_module()$`_model_reads`(model))))
  }
  everything <- c("deps", "ents", "lemma", "other", "sents", "tags")
  embed <- function(...) {
    list(`@architectures` = "spacy.Tok2Vec.v2",
         embed = list(`@architectures` = "spacy.MultiHashEmbed.v2", width = 96L, ...),
         encode = list(`@architectures` = "spacy.MaxoutWindowEncoder.v2", width = 96L))
  }

  # the attributes of the token's text, which spaCy's models embed by default
  expect_identical(reads(embed(attrs = list("NORM", "PREFIX", "SUFFIX", "SHAPE"))),
                   character())
  # annotations of earlier components, by name or by number
  expect_identical(reads(embed(attrs = list("NORM", "POS"))), "tags")
  expect_identical(reads(embed(attrs = list("norm", "dep", "ENT_TYPE", "LEMMA"))),
                   c("deps", "ents", "lemma"))
  pos <- reticulate::import("spacy.attrs")$POS
  expect_identical(reads(embed(attrs = list(pos))), "tags")
  # as the model of a component, behind a listener or inside another model
  expect_identical(reads(list(`@architectures` = "spacy.Tagger.v2",
                              tok2vec = list(`@architectures` = "spacy.Tok2VecListener.v1",
                                             upstream = "tok2vec"))),
                   character())
  expect_identical(reads(list(`@architectures` = "spacy.TransitionBasedParser.v2",
                              tok2vec = embed(attrs = list("TAG")))), "tags")
  # the other settings that name attributes
  expect_identical(reads(list(`@architectures` = "spacy.CharacterEmbed.v2",
                              feature = "LEMMA")), "lemma")
  expect_identical(reads(list(`@architectures` = "spacy.FeatureExtractor.v1",
                              columns = list("ORTH", "DEP"))), "deps")
  # a model that is not built by spaCy's functions, or whose settings are
  # not as expected, may read anything
  expect_identical(reads(list(`@architectures` = "my_package.MyTok2Vec.v1")), everything)
  expect_identical(reads(embed(attrs = "POS")), everything)
  expect_identical(reads(list(`@architectures` = "spacy.Tok2Vec.v2",
                              embed = list(`@layers` = "custom.Embed.v1"))), everything)

  # the models of spaCy's own pipeline read none of the annotations
  nlp <- spacyr:::spacyr_env$nlp
  for (name in c("tok2vec", "tagger", "parser", "ner")) {
    expect_identical(reads(nlp$get_pipe_config(name)$get("model")), character())
  }
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

# spacy_extract_entity() and spacy_extract_nounphrases() leave out the
# components that entities, or noun phrases, do not need.

# what the last call of an extractor left out, called as the R function
# calls it
extractor_left_out <- function(what, output = "dataframe", x = txt) {
  spobj <- spacyr:::new_spobj()
  spobj[[paste0("extract_", what, "_", output)]](texts = as.list(unname(x)),
                                                 docnames = as.list(names(x)))
  as.character(unlist(spobj$disabled))
}
extractors <- function(x, ...) {
  list(entity = suppressMessages(spacy_extract_entity(x, ...)),
       entity_list = spacy_extract_entity(x, output = "list"),
       named = suppressMessages(spacy_extract_entity(x, type = "named", ...)),
       nounphrases = suppressMessages(spacy_extract_nounphrases(x, ...)),
       nounphrases_list = spacy_extract_nounphrases(x, output = "list"))
}

test_that("the extractors give the same output whichever components they leave out", {
  skip_on_cran()
  skip_on_os("solaris")
  try(spacy_finalize(), silent = TRUE)
  try_spacy_initialize()
  on.exit(spacy_finalize(), add = TRUE)
  reticulate::import_from_path("spacyr_test_components", path = test_path("python"))
  nlp <- spacyr:::spacyr_env$nlp
  before <- pipe_names()

  # with a component that is not spaCy's, every component runs
  nlp$add_pipe("spacyr_test_noop", last = TRUE)
  expect_identical(extractor_left_out("entity"), character())
  expect_identical(extractor_left_out("nounphrases"), character())
  whole <- extractors(txt, offsets = TRUE)
  nlp$remove_pipe("spacyr_test_noop")
  expect_identical(pipe_names(), before)

  expect_true(nrow(whole$entity) > 0)
  expect_true(nrow(whole$nounphrases) > 0)
  expect_identical(extractors(txt, offsets = TRUE), whole)
  expect_identical(extractors(txt, offsets = TRUE, batch_size = 1), whole)
  expect_identical(extractors(txt, offsets = TRUE, n_process = 2), whole)
  expect_identical(pipe_names(), before)
})

test_that("the extractors leave out the components that their spans do not need", {
  skip_on_cran()
  skip_on_os("solaris")
  try(spacy_finalize(), silent = TRUE)
  try_spacy_initialize()
  on.exit(spacy_finalize(), add = TRUE)
  before <- pipe_names()
  tags <- c("tagger", "attribute_ruler", "lemmatizer")

  # entities need neither tags nor lemmas; noun phrases need the tags and
  # the dependencies, and not the entities. The parser always runs.
  for (output in c("dataframe", "list")) {
    expect_identical(extractor_left_out("entity", output), tags)
    expect_identical(extractor_left_out("nounphrases", output), c("lemmatizer", "ner"))
  }
  expect_identical(pipe_names(), before)

  # the pipeline is as it was after a call that fails
  long <- c(a = "Short text.", b = strrep("a ", 600000))
  expect_error(spacy_extract_entity(long))
  expect_error(spacy_extract_nounphrases(long, output = "list"))
  expect_identical(pipe_names(), before)

  # documents that were already parsed need no pipeline
  parsed <- suppressWarnings(process_document(txt))
  expect_true(length(suppressWarnings(get_named_entities(parsed))) > 0)
  expect_true(length(suppressWarnings(get_noun_phrases(parsed))) > 0)
})

test_that("the extractors keep what entity rules and attribute rules need", {
  skip_on_cran()
  skip_on_os("solaris")
  on.exit(spacy_finalize(), add = TRUE)
  reticulate::import_from_path("spacyr_test_components", path = test_path("python"))
  whole_and_part <- function(fun, ...) {
    nlp <- spacyr:::spacyr_env$nlp
    nlp$add_pipe("spacyr_test_noop", last = TRUE)
    whole <- fun(txt, ...)
    nlp$remove_pipe("spacyr_test_noop")
    expect_identical(fun(txt, ...), whole)
    whole
  }

  # an entity rule on the lemma and the part of speech: the ruler may read
  # all that comes before it
  try(spacy_finalize(), silent = TRUE)
  rule <- list(list(label = "ACTION",
                    pattern = list(list(LEMMA = "run", POS = "VERB"))))
  if (methods::is(try(spacy_initialize(entity_patterns = rule)), "try-error"))
    skip("Can't initialize")
  expect_identical(extractor_left_out("entity"), character())
  expect_identical(extractor_left_out("nounphrases"),
                   c("lemmatizer", "ner", "spacyr_entity_ruler"))
  ents <- whole_and_part(spacy_extract_entity)
  expect_true("ACTION" %in% ents$ent_type)
  whole_and_part(spacy_extract_nounphrases)

  # an attribute rule that sets an entity: the ruler stays for the
  # entities, with the tagger that its other rules read
  spacy_finalize()
  try_spacy_initialize()
  spacyr:::spacyr_env$nlp$get_pipe("attribute_ruler")$add(
    patterns = list(list(list(LOWER = "building"))),
    attrs = list(ENT_TYPE = "THING", ENT_IOB = 3L))
  expect_identical(extractor_left_out("entity"), "lemmatizer")
  ents <- whole_and_part(spacy_extract_entity)
  expect_true("THING" %in% ents$ent_type)

  # without the entity recognizer in the pipeline
  spacy_finalize()
  if (methods::is(try(spacy_initialize(entity = FALSE)), "try-error"))
    skip("Can't initialize")
  expect_identical(extractor_left_out("nounphrases"), "lemmatizer")
  whole_and_part(spacy_extract_nounphrases)
})

test_that("spacy_extract_entity() keeps what the model of the recognizer reads", {
  skip_on_cran()
  skip_on_os("solaris")
  try(spacy_finalize(), silent = TRUE)
  try_spacy_initialize()
  on.exit(spacy_finalize(), add = TRUE)
  comp <- reticulate::import_from_path("spacyr_test_components",
                                       path = test_path("python"))
  dir <- tempfile("spacyr_pos_ner")
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  comp$save_pos_ner_pipeline(dir)
  spacy_finalize()
  spacy_initialize(model = dir)
  alpha <- c(a = "We saw alpha today.", b = "Nothing new here.")

  # the recognizer embeds the part of speech that the attribute ruler sets
  expect_identical(extractor_left_out("entity", x = alpha), character())
  ents <- spacy_extract_entity(alpha)
  expect_identical(ents$text, "alpha")
  expect_identical(ents$ent_type, "PERSON")
})

test_that("nothing is left out for noun phrases from an iterator that is not spaCy's", {
  skip_on_cran()
  skip_on_os("solaris")
  try(spacy_finalize(), silent = TRUE)
  try_spacy_initialize()
  on.exit(spacy_finalize(), add = TRUE)
  comp <- reticulate::import_from_path("spacyr_test_components",
                                       path = test_path("python"))
  nlp <- spacyr:::spacyr_env$nlp
  animals <- c(a = "The dogs barked. The cats slept.")

  # spaCy's iterator for English reads the dependencies and the tags
  expect_identical(extractor_left_out("nounphrases", x = animals), c("lemmatizer", "ner"))
  expect_identical(spacy_extract_nounphrases(animals)$text, c("The dogs", "The cats"))

  # an iterator of the pipeline's own, which keeps the noun phrases with the
  # lemma "dog": it reads the lemmas, so the lemmatizer has to run
  comp$set_lemma_noun_chunks(nlp)
  for (output in c("dataframe", "list")) {
    expect_identical(extractor_left_out("nounphrases", output, x = animals), character())
  }
  expect_identical(spacy_extract_nounphrases(animals)$text, "The dogs")
  expect_identical(spacy_extract_nounphrases(animals, output = "list"),
                   list(a = "The dogs"))

  # in spacy_parse() too, where the noun phrases are one of the options
  expect_identical(left_out(nounphrase = TRUE, lemma = FALSE, entity = FALSE), character())
  parsed <- spacy_parse(animals, nounphrase = TRUE, lemma = FALSE, entity = FALSE)
  expect_identical(parsed$nounphrase[1:2], c("beg", "end_root"))
  expect_true(all(parsed$nounphrase[-(1:2)] == ""))
  # without them, the options decide as before
  expect_identical(left_out(lemma = FALSE, entity = FALSE), c("lemmatizer", "ner"))
  # entities do not come from the iterator
  expect_identical(extractor_left_out("entity", x = animals),
                   c("tagger", "attribute_ruler", "lemmatizer"))
})

# spacy_tokenize() runs components of the pipeline only for remove_symbols,
# which reads the part of speech, and for what = "sentence": then it leaves
# out those that these do not need.

symbols <- c(txt,
             s1 = "The price is $ 5 + 3 % more © 2020. A < B & C = D.",
             s2 = "Rates rose 5 % ; costs + 2.")
# what a call of the bridge left out
tokenize_left_out <- function(what, ..., x = symbols) {
  spobj <- spacyr:::new_spobj()
  spobj[[what]](as.list(unname(x)), as.list(names(x)), ...)
  as.character(unlist(spobj$disabled))
}
tokenizers <- function(x, ...) {
  list(symbols = spacy_tokenize(x, remove_symbols = TRUE, ...),
       symbols_padding = spacy_tokenize(x, remove_symbols = TRUE, remove_punct = TRUE,
                                        padding = TRUE, output = "data.frame", ...),
       sentence = spacy_tokenize(x, what = "sentence", ...),
       sentence_spaces = spacy_tokenize(x, what = "sentence", remove_separators = FALSE, ...))
}

test_that("spacy_tokenize() gives the same output whichever components it leaves out", {
  skip_on_cran()
  skip_on_os("solaris")
  try(spacy_finalize(), silent = TRUE)
  try_spacy_initialize()
  on.exit(spacy_finalize(), add = TRUE)
  reticulate::import_from_path("spacyr_test_components", path = test_path("python"))
  nlp <- spacyr:::spacyr_env$nlp
  before <- pipe_names()

  # with a component that is not spaCy's, every component runs
  nlp$add_pipe("spacyr_test_noop", last = TRUE)
  expect_identical(tokenize_left_out("tokenize", remove_symbols = TRUE,
                                     turn_off_pipes = FALSE), character())
  expect_identical(tokenize_left_out("tokenize_sentence"), character())
  whole <- tokenizers(symbols)
  nlp$remove_pipe("spacyr_test_noop")

  # symbols are removed, and sentences split
  expect_false("+" %in% whole$symbols$s1)
  expect_true("+" %in% spacy_tokenize(symbols)$s1)
  expect_true(length(whole$sentence$d3) > 1)

  expect_identical(tokenizers(symbols), whole)
  expect_identical(tokenizers(symbols, batch_size = 1), whole)
  expect_identical(tokenizers(symbols, n_process = 2), whole)
  expect_identical(pipe_names(), before)
})

test_that("spacy_tokenize() leaves out the components that its options do not need", {
  skip_on_cran()
  skip_on_os("solaris")
  try(spacy_finalize(), silent = TRUE)
  try_spacy_initialize()
  on.exit(spacy_finalize(), add = TRUE)
  before <- pipe_names()
  all_six <- c("tok2vec", "tagger", "parser", "attribute_ruler", "lemmatizer", "ner")

  # words need no component, as before
  expect_identical(tokenize_left_out("tokenize"), all_six)
  expect_identical(tokenize_left_out("tokenize", remove_punct = TRUE), all_six)
  # symbols need the part of speech, which the attribute ruler sets from
  # the tags and the dependencies
  expect_identical(tokenize_left_out("tokenize", remove_symbols = TRUE,
                                     turn_off_pipes = FALSE),
                   c("lemmatizer", "ner"))
  # sentences need the parser
  expect_identical(tokenize_left_out("tokenize_sentence"),
                   c("tagger", "attribute_ruler", "lemmatizer", "ner"))

  # the pipeline is as it was after a call, also after one that fails
  expect_identical(pipe_names(), before)
  long <- c(a = "Short text.", b = strrep("a ", 600000))
  expect_error(spacy_tokenize(long, remove_symbols = TRUE))
  expect_error(spacy_tokenize(long, what = "sentence"))
  expect_identical(pipe_names(), before)
})

test_that("spacy_tokenize() keeps an attribute ruler that sets sentence boundaries", {
  skip_on_cran()
  skip_on_os("solaris")
  try(spacy_finalize(), silent = TRUE)
  try_spacy_initialize()
  on.exit(spacy_finalize(), add = TRUE)
  reticulate::import_from_path("spacyr_test_components", path = test_path("python"))
  nlp <- spacyr:::spacyr_env$nlp
  nlp$get_pipe("attribute_ruler")$add(patterns = list(list(list(LOWER = "and"))),
                                      attrs = list(SENT_START = TRUE))
  sents <- c(a = "We met and they left early. Paul saw the big building.")

  # the ruler stays, with the tagger that its other rules read
  expect_identical(tokenize_left_out("tokenize_sentence", x = sents),
                   c("lemmatizer", "ner"))
  nlp$add_pipe("spacyr_test_noop", last = TRUE)
  whole <- spacy_tokenize(sents, what = "sentence")
  nlp$remove_pipe("spacyr_test_noop")
  expect_identical(whole$a[2], "and they left early.")
  expect_identical(spacy_tokenize(sents, what = "sentence"), whole)
})
