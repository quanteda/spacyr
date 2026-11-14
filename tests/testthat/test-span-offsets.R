source("utils.R")

# offsets = TRUE in spacy_extract_entity(), spacy_extract_nounphrases() and
# spacy_match(): the positions in the text of the first and the last
# character of each entity, noun phrase or match, as spacy_parse() gives them
# for tokens.

test_that("offsets comes after ... in the extractors and in spacy_match()", {
  # so that it is given by its full name, and the arguments before ... are
  # matched as they were, also by the start of their names
  last_two <- function(f) utils::tail(names(formals(f)), 2)
  for (f in list(spacy_extract_entity, spacyr:::spacy_extract_entity.character,
                 spacy_extract_nounphrases, spacyr:::spacy_extract_nounphrases.character,
                 spacy_match, spacyr:::spacy_match.character)) {
    expect_identical(last_two(f), c("...", "offsets"))
  }
  # o is still output or overlap, and off is not offsets
  bound <- function(f, ...) {
    names(as.list(match.call(f, as.call(c(list(quote(f), "a"), list(...)))))[-1])
  }
  expect_true("output" %in% bound(spacy_extract_entity, o = "list"))
  expect_true("output" %in% bound(spacy_extract_nounphrases, o = "list"))
  expect_true("overlap" %in% bound(spacy_match, "a", o = "all"))
  expect_false("offsets" %in% bound(spacy_match, "a", off = TRUE))
})

test_that("offsets = TRUE gives the character positions of entities, noun phrases and matches", {
  skip_on_cran()
  skip_on_os("solaris")
  try(spacy_finalize(), silent = TRUE)
  try_spacy_initialize()
  on.exit(spacy_finalize(), add = TRUE)

  # two spaces, a character outside the Basic Multilingual Plane, a document
  # without tokens and one without spans
  txt <- c(d1 = "The Supreme Court is located in Washington D.C.  It sits in a \U0001F600 building.",
           d2 = "",
           d3 = "Paul earned a postgraduate degree from MIT.",
           d4 = "Yes.")
  parsed <- spacy_parse(txt, offsets = TRUE)
  # of the span that starts at token start_id of a document and has length
  # tokens: the start of its first token and the end of its last
  from_parse <- function(x) {
    rows <- lapply(seq_len(nrow(x)), function(i) {
      doc <- parsed[parsed$doc_id == x$doc_id[i], ]
      c(doc$start[x$start_id[i]], doc$end[x$start_id[i] + x$length[i] - 1])
    })
    list(start = vapply(rows, `[`, 1L, 1), end = vapply(rows, `[`, 1L, 2))
  }
  expect_positions <- function(x) {
    expect_identical(utils::tail(names(x), 2), c("start", "end"))
    expect_type(x$start, "integer")
    expect_type(x$end, "integer")
    expect_identical(unname(substring(txt[x$doc_id], x$start, x$end)), x$text)
    expect_identical(x[c("start", "end")], as.data.frame(from_parse(x)))
  }

  ents <- spacy_extract_entity(txt, offsets = TRUE)
  expect_true(nrow(ents) > 0)
  expect_positions(ents)
  plain <- spacy_extract_entity(txt)
  expect_identical(names(plain), c("doc_id", "text", "ent_type", "start_id", "length"))
  expect_identical(ents[names(plain)], plain)
  expect_positions(spacy_extract_entity(txt, type = "named", offsets = TRUE, batch_size = 1))

  nps <- spacy_extract_nounphrases(txt, offsets = TRUE)
  expect_true(any(grepl("\U0001F600", nps$text)))
  expect_positions(nps)
  plain <- spacy_extract_nounphrases(txt)
  expect_identical(names(plain),
                   c("doc_id", "text", "root_text", "start_id", "root_id", "length"))
  expect_identical(nps[names(plain)], plain)

  # sequences, which can hold a space, and the nodes of a dependency pattern
  pattern <- list(
    np = list(list(POS = "DET"), list(OP = "+"), list(POS = "NOUN")),
    clause = list(list(RIGHT_ID = "verb", RIGHT_ATTRS = list(POS = "VERB")),
                  list(LEFT_ID = "verb", REL_OP = ">", RIGHT_ID = "subject",
                       RIGHT_ATTRS = list(DEP = "nsubj"))))
  found <- spacy_match(txt, pattern, offsets = TRUE)
  expect_true(all(c("np", "clause") %in% found$label))
  expect_true(any(found$length > 1))
  expect_positions(found)
  plain <- spacy_match(txt, pattern)
  expect_false(any(c("start", "end") %in% names(plain)))
  expect_identical(found[names(plain)], plain)

  # from a TIF data.frame
  tif <- data.frame(doc_id = names(txt), text = unname(txt), stringsAsFactors = FALSE)
  expect_identical(spacy_extract_entity(tif, offsets = TRUE), ents)
  expect_identical(spacy_extract_nounphrases(tif, offsets = TRUE), nps)
  expect_identical(spacy_match(tif, pattern, offsets = TRUE), found)

  # nothing found: the columns are there for matches; the extractors
  # return NULL as without offsets
  none <- spacy_match(txt, "zzzzzz", offsets = TRUE)
  expect_identical(nrow(none), 0L)
  expect_identical(vapply(none, typeof, ""), vapply(found, typeof, ""))
  expect_null(suppressMessages(spacy_extract_entity(c(a = "Yes."), offsets = TRUE)))
  expect_null(suppressMessages(spacy_extract_nounphrases(c(a = "Yes."), offsets = TRUE)))

  # the other functions take the output as before
  expect_identical(as_index(ents), as_index(ents[1:5]))
  expect_identical(as_index(found), as_index(found[1:9]))
  expect_identical(as_entity_patterns(ents), as_entity_patterns(ents[1:5]))

  # the arguments before offsets can still be given by the start of their names
  expect_identical(spacy_extract_entity(txt, o = "list"),
                   spacy_extract_entity(txt, output = "list"))
  expect_identical(spacy_extract_nounphrases(txt, o = "list"),
                   spacy_extract_nounphrases(txt, output = "list"))
  expect_identical(spacy_match(txt, pattern, o = "all"),
                   spacy_match(txt, pattern, overlap = "all"))
  expect_identical(spacy_match(txt, pattern, o = "all", offsets = TRUE)[names(plain)],
                   spacy_match(txt, pattern, overlap = "all"))

  expect_error(spacy_extract_entity(txt, offsets = NA), "offsets must be TRUE or FALSE")
  expect_error(spacy_extract_nounphrases(txt, offsets = "yes"), "offsets must be TRUE or FALSE")
  expect_error(spacy_match(txt, "court", offsets = 1), "offsets must be TRUE or FALSE")
  expect_error(spacy_extract_entity(txt, output = "list", offsets = TRUE),
               "offsets = TRUE needs output = \"data.frame\"")
  expect_error(spacy_extract_nounphrases(txt, output = "list", offsets = TRUE),
               "offsets = TRUE needs output = \"data.frame\"")
})

test_that("span offsets are positions in the input when the tokenizer changes whitespace", {
  skip_on_cran()
  skip_on_os("solaris")
  try(spacy_finalize(), silent = TRUE)
  if (methods::is(try(spacy_initialize(entity_patterns = c(PLACE = "New York"))),
                  "try-error"))
    skip("Can't initialize")
  on.exit(spacy_finalize(), add = TRUE)
  comp <- reticulate::import_from_path("spacyr_test_components",
                                       path = test_path("python"))
  nlp <- spacyr:::spacyr_env$nlp

  # as spaCy's tokenizer for Korean does, this one makes the document with
  # single spaces, whatever whitespace the text has
  comp$set_single_space_tokenizer(nlp)
  txt <- c(a = "We like New  York \n a lot", b = "  In New\tYork  now")
  single <- function(x) gsub("\\s+", " ", unname(x))

  ents <- spacy_extract_entity(txt, offsets = TRUE)
  place <- ents[ents$ent_type == "PLACE", ]
  expect_identical(place$text, c("New York", "New York"))
  expect_identical(place$start, c(9L, 6L))
  expect_identical(place$end, c(17L, 13L))
  expect_identical(unname(substring(txt[place$doc_id], place$start, place$end)),
                   c("New  York", "New\tYork"))
  expect_identical(single(substring(txt[ents$doc_id], ents$start, ents$end)), ents$text)

  nps <- spacy_extract_nounphrases(txt, offsets = TRUE)
  expect_true(nrow(nps) > 0)
  expect_identical(single(substring(txt[nps$doc_id], nps$start, nps$end)), nps$text)

  found <- spacy_match(txt, quanteda::phrase("new york"), offsets = TRUE)
  expect_identical(found$start, c(9L, 6L))
  expect_identical(found$end, c(17L, 13L))

  # a tokenizer that leaves out the end of the text: an error, as in
  # spacy_parse()
  comp$set_single_space_tokenizer(nlp, drop_last = TRUE)
  changed <- "tokenizer changed the text of document 'a'"
  expect_error(spacy_extract_entity(txt, offsets = TRUE), changed)
  expect_error(spacy_extract_nounphrases(txt, offsets = TRUE), changed)
  expect_error(spacy_match(txt, quanteda::phrase("new york"), offsets = TRUE), changed)
  # without offsets, such a tokenizer is no error
  expect_identical(spacy_match(txt, quanteda::phrase("new york"))$text,
                   c("New York", "New York"))
})
