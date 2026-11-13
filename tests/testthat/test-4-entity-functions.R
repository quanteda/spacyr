context("testing entity functions")
source("utils.R")

test_that("spacy_extract_entity data.frame works", {
  skip_on_cran()
  # skip_on_appveyor()
  skip_on_os("solaris")
  try_spacy_initialize()
  
  expect_message(spacy_initialize(), "successfully|already")
  
  txt1 <- c(doc1 = "I would have accepted without question the information that Gatsby sprang from the swamps of Louisiana or from the lower East Side of New York.",
            doc2 = "I graduated from New Haven in 1915, a quarter of a century after my father, and a little later I participated in that delayed Teutonic migration known as the Great War.")
  entities <- spacy_extract_entity(txt1, output = "data.frame")
  
  expect_equal(
    entities$text,
    c("Gatsby", "Louisiana", "East Side", "New York", "New Haven",
      "1915", "a quarter of a century", "Teutonic", "the Great War"))
  expect_equal(
    entities$ent_type,
    c("PERSON", "GPE", "LOC", "GPE", "GPE", "DATE", "DATE", "NORP", "EVENT"))
  expect_silent(spacy_finalize())
})

test_that("spacy_extract_entity data.frame works properly when there is no noun-phrase", {
  skip_on_cran()
  # skip_on_appveyor()
  skip_on_os("solaris")
  try_spacy_initialize()
  
  expect_message(spacy_initialize(), "successfully|already")
  
  txt1 <- c(doc1 = "He told me all this very much later, but I've put it down here with the idea of exploding those wild rumors about his antecedents, which weren t even faintly true.")
  expect_message(
    spacy_extract_entity(txt1, output = "data.frame"),
    "No entity")
  expect_equivalent(
    spacy_extract_entity(txt1, output = "data.frame"),
    NULL)
})


test_that("spacy_extract_entity list works", {
  skip_on_cran()
  # skip_on_appveyor()
  skip_on_os("solaris")
  try_spacy_initialize()
  
  expect_message(spacy_initialize(), "successfully|already")
  
  txt1 <- c(doc1 = "I would have accepted without question the information that Gatsby sprang from the swamps of Louisiana or from the lower East Side of New York.",
            doc2 = "I graduated from New Haven in 1915, a quarter of a century after my father, and a little later I participated in that delayed Teutonic migration known as the Great War.")
  entities <- spacy_extract_entity(txt1, output = "list")
  
  expect_equal(
    entities,
    list(doc1 = c("Gatsby", "Louisiana", "East Side", "New York"),
         doc2 = c("New Haven", "1915", "a quarter of a century",
                  "Teutonic", "the Great War"))
  )
  
})

test_that("spacy_extract_entity data.frame and list returns the same entity", {
  skip_on_cran()
  # skip_on_appveyor()
  skip_on_os("solaris")
  try_spacy_initialize()
  
  expect_message(spacy_initialize(), "successfully|already")
  
  txt1 <- c(doc1 = "I would have accepted without question the information that Gatsby sprang from the swamps of Louisiana or from the lower East Side of New York.",
            doc2 = "It was a matter of chance that I should have rented a house in one of the strangest communities in North America.")
  entities_dataframe <- spacy_extract_entity(txt1, output = "data.frame")
  entities_list <- spacy_extract_entity(txt1, output = "list")
  
  expect_equal(
    entities_dataframe$text,
    unname(unlist(entities_list))
  )
  
  expect_identical(
    lengths(entities_list, use.names = FALSE),
    as.integer(table(entities_dataframe$doc_id))
  )
})

test_that("spacy_extract_entity.data.frame() works", {
  skip_on_cran()
  # skip_on_appveyor()
  skip_on_os("solaris")
  try_spacy_initialize()
  expect_message(spacy_initialize(), "successfully|already")
  
  txt <- c(doc1 = "I would have accepted without question the information that Gatsby sprang from the swamps of Louisiana or from the lower East Side of New York.",
           doc2 = "It was a matter of chance that I should have rented a house in one of the strangest communities in North America.")
  txt_df <- data.frame(doc_id = paste0("doc", 1:2),
                       text = txt, stringsAsFactors = FALSE)
  
  expect_equal(
    spacy_extract_entity(txt),
    spacy_extract_entity(txt_df)
  )
})


test_that("spacy_extract_entity type option works", {
  skip_on_cran()
  # skip_on_appveyor()
  skip_on_os("solaris")
  try_spacy_initialize()
  
  expect_message(spacy_initialize(), "successfully|already")
  
  txt1 <- c(doc1 = "I would have accepted without question the information that Gatsby sprang from the swamps of Louisiana or from the lower East Side of New York.",
            doc2 = "I graduated from New Haven in 1915, a quarter of a century after my father, and a little later I participated in that delayed Teutonic migration known as the Great War.")
  
  expect_equal(
    nrow(spacy_extract_entity(txt1, output = "data.frame", type = "named")),
    7
  )
  
  expect_equal(
    nrow(spacy_extract_entity(txt1, output = "data.frame", type = "extended")),
    2
  )
  
  expect_equal(
    nrow(spacy_extract_entity(txt1, output = "data.frame", type = "all")),
    9
  )
  
  expect_equal(
    unname(unlist(spacy_extract_entity(txt1, output = "list", type = "named"))),
    c("Gatsby", "Louisiana", "East Side", "New York", "New Haven",
      "Teutonic", "the Great War")
  )
  
  expect_equal(
    unname(unlist(spacy_extract_entity(txt1, output = "list", type = "extended"))),
    c("1915", "a quarter of a century")
  )
  
  expect_equal(
    spacy_extract_entity(txt1, output = "data.frame", type = "named")$text,
    unname(unlist(spacy_extract_entity(txt1, output = "list", type = "named")))
  )
})


test_that("getting named entities from spacy_parsed object works", {
  skip_on_cran()
  # skip_on_appveyor()
  skip_on_os("solaris")
  try_spacy_initialize()
  
  expect_message(spacy_initialize(), "successfully|already")
  
  txt1 <- c(doc1 = "The United States elected President Donald Trump, from New York.",
            doc2 = "New buildings on the New York skyline.")
  parsed <- spacy_parse(txt1, entity = TRUE)
  
  entities <- entity_extract(parsed, concatenator = " ")
  
  expect_equal(
    entities$entity,
    c("The United States", "Donald Trump", "New York", "New York")
  )
  expect_equal(
    entities$entity_type,
    c("GPE", "PERSON", "GPE", "GPE")
  )
  
  txt1 <- c(doc1 = "The United States elected President Donald Trump, from New York.",
            doc2 = "New buildings on the New York skyline appeared in January.")
  parsed <- spacy_parse(txt1, entity = TRUE)
  expect_equal(
    entity_extract(parsed, type = "extended")$entity_type,
    "DATE"
  )
  expect_equal(
    entity_extract(parsed, type = "named")$entity_type,
    c("GPE", "PERSON", "GPE", "GPE")
  )
  
  parsed <- spacy_parse(txt1, entity = FALSE)
  expect_error(
    entity_extract(parsed),
    "no entities in parsed object"
  )
  
  expect_silent(spacy_finalize())
})


test_that("compare entity_extract(spacy_parse()) and spacy_extract_entity()", {
  skip_on_cran()
  # skip_on_appveyor()
  skip_on_os("solaris")
  try_spacy_initialize()
  
  expect_message(spacy_initialize(), "successfully|already")
  
  txt1 <- c(doc1 = "The history of natural language processing generally started in the 1950s, although work can be found from earlier periods.",
            doc2 = "In 1950, Alan Turing published an article titled Intelligence which proposed what is now called the Turing test as a criterion of intelligence.")
  parsed <- spacy_parse(txt1, entity = TRUE)
  
  entities_1 <- entity_extract(parsed, concatenator = " ", type = "all")
  entities_2 <- spacy_extract_entity(txt1, output = "data.frame")
  expect_equal(
    entities_1$entity,
    entities_2$text
  )
  
  expect_silent(spacy_finalize())
})




test_that("entity consolidation works", {
  skip_on_cran()
  # skip_on_appveyor()
  skip_on_os("solaris")
  try(spacy_finalize(), silent = TRUE)
  expect_message(spacy_initialize(), "successfully")
  
  txt1 <- c(doc1 = "The United States elected President Donald Trump, from New York.",
            doc2 = "New buildings on the New York skyline appeared in January.")
  
  parsed <- spacy_parse(txt1, entity = TRUE)
  expect_equal(
    entity_consolidate(parsed)$token[c(1, 4)],
    c("The_United_States", "Donald_Trump")
  )
  expect_equal(
    entity_consolidate(parsed, concatenator = " ")$token[c(1, 4)],
    c("The United States", "Donald Trump")
  )
  expect_equal(
    entity_consolidate(parsed)$token_id,
    c(1:8, 1:10)
  )
  
  parsed <- spacy_parse(txt1, entity = TRUE, nounphrase = TRUE)
  expect_equal(
    entity_consolidate(parsed)$token[c(1, 4)],
    c("The_United_States", "Donald_Trump")
  )
  expect_true( !("nounphrase" %in% names(entity_consolidate(parsed))) )
  
  parsed <- spacy_parse(txt1, entity = TRUE, pos = TRUE, tag = TRUE)
  expect_equal(
    entity_consolidate(parsed)$tag[c(1, 4, 17)],
    rep("ENTITY", 3)
  )
  expect_equal(
    tolower(entity_consolidate(parsed)$lemma[c(1, 4, 16)]), # obviously en_model stop lowercasing lemmas. That's cool
    tolower(entity_consolidate(parsed)$token[c(1, 4, 16)])
  )
  
  parsed <- spacy_parse(txt1, entity = TRUE, dependency = TRUE)
  expect_true(
    !"dep_rel" %in% names(entity_consolidate(parsed))
  )
  expect_message(
    entity_consolidate(parsed),
    "Note: removing head_token_id, dep_rel"
  )
  
  parsed <- spacy_parse(txt1, entity = FALSE)
  expect_error(
    entity_consolidate(parsed),
    "no entities in parsed object"
  )
  
  expect_silent(spacy_finalize())
})

test_that("entity labels containing underscores are kept whole", {
  # a parse from a model with custom labels, built without Python
  parsed <- data.frame(
    doc_id = "d1", sentence_id = 1L, token_id = 1:7,
    token = c("The", "Federal", "Reserve", "met", "Jane", "Smith", "."),
    pos = c("DET", "PROPN", "PROPN", "VERB", "PROPN", "PROPN", "PUNCT"),
    entity = c("", "PUBLIC_AGENCY_B", "PUBLIC_AGENCY_I", "", "PERSON_B", "PERSON_I", ""),
    stringsAsFactors = FALSE
  )
  class(parsed) <- c("spacyr_parsed", "data.frame")

  ents <- entity_extract(parsed, type = "all")
  expect_identical(ents$entity, c("Federal_Reserve", "Jane_Smith"))
  expect_identical(ents$entity_type, c("PUBLIC_AGENCY", "PERSON"))
  # custom labels count as named entities
  expect_identical(entity_extract(parsed)$entity_type, c("PUBLIC_AGENCY", "PERSON"))

  cons <- entity_consolidate(parsed)
  expect_identical(cons$token, c("The", "Federal_Reserve", "met", "Jane_Smith", "."))
  expect_identical(cons$entity_type, c("", "PUBLIC_AGENCY", "", "PERSON", ""))
  expect_identical(cons$pos, c("DET", "ENTITY", "VERB", "ENTITY", "PUNCT"))
})

test_that("entity_consolidate() keeps the offsets of the whole entity", {
  # a parse with offsets, built without Python
  parsed <- data.frame(
    doc_id = rep(c("d1", "d2"), c(5, 3)), sentence_id = 1L,
    token_id = c(1:5, 1:3),
    token = c("Go", "to", "San", "Francisco", ".", "New", "York", "wins"),
    start = c(1L, 4L, 7L, 11L, 20L, 1L, 5L, 10L),
    end = c(2L, 5L, 9L, 19L, 20L, 3L, 8L, 13L),
    entity = c("", "", "GPE_B", "GPE_I", "", "GPE_B", "GPE_I", ""),
    stringsAsFactors = FALSE
  )
  class(parsed) <- c("spacyr_parsed", "data.frame")

  cons <- entity_consolidate(parsed)
  expect_identical(names(cons),
                   c("doc_id", "sentence_id", "token_id", "token", "start", "end",
                     "entity_type"))
  expect_identical(cons$token, c("Go", "to", "San_Francisco", ".", "New_York", "wins"))
  expect_identical(cons$start, c(1L, 4L, 7L, 20L, 1L, 10L))
  expect_identical(cons$end, c(2L, 5L, 19L, 20L, 8L, 13L))

  # without offsets there are no such columns
  expect_false(any(c("start", "end") %in%
                     names(entity_consolidate(parsed[, setdiff(names(parsed), c("start", "end"))]))))
})
