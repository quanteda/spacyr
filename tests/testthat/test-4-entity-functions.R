context("testing entity functions")
source("utils.R")

test_that("spacy_extract_entity data.frame works", {
    skip_on_cran()
    # skip_on_appveyor()
    skip_on_os("solaris")
    skip_if_no_python_or_no_spacy()

    expect_message(spacy_initialize(), "successfully|already")

    txt1 <- c(doc1 = "I would have accepted without question the information that Gatsby sprang from the swamps of Louisiana or from the lower East Side of New York.",
              doc2 = "I graduated from New Haven in 1915, just a quarter of a century after my father, and a little later I participated in that delayed Teutonic migration known as the Great War.")
    entities <- spacy_extract_entity(txt1, output = "data.frame")

    expect_equal(
        entities$text,
        c("Gatsby", "Louisiana", "East Side", "New York", "New Haven",
          "1915", "just a quarter of a century", "Teutonic", "the Great War"))
    expect_equal(
        entities$ent_type,
        c("GPE", "GPE", "LOC", "GPE", "GPE", "DATE", "DATE", "NORP", "EVENT"))
    expect_silent(spacy_finalize())
})

test_that("spacy_extract_entity list works", {
    skip_on_cran()
    # skip_on_appveyor()
    skip_on_os("solaris")
    skip_if_no_python_or_no_spacy()

    expect_message(spacy_initialize(), "successfully|already")

    txt1 <- c(doc1 = "I would have accepted without question the information that Gatsby sprang from the swamps of Louisiana or from the lower East Side of New York.",
              doc2 = "I graduated from New Haven in 1915, just a quarter of a century after my father, and a little later I participated in that delayed Teutonic migration known as the Great War.")
    entities <- spacy_extract_entity(txt1, output = "list")

    expect_equal(
        entities,
        list(doc1 = c("Gatsby", "Louisiana", "East Side", "New York"),
             doc2 = c("New Haven", "1915", "just a quarter of a century",
                      "Teutonic", "the Great War"))
    )

})

test_that("spacy_extract_entity data.frame and list returns the same entity", {
    skip_on_cran()
    # skip_on_appveyor()
    skip_on_os("solaris")
    skip_if_no_python_or_no_spacy()

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
    skip_if_no_python_or_no_spacy()
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
    skip_if_no_python_or_no_spacy()

    expect_message(spacy_initialize(), "successfully|already")

    txt1 <- c(doc1 = "I would have accepted without question the information that Gatsby sprang from the swamps of Louisiana or from the lower East Side of New York.",
              doc2 = "I graduated from New Haven in 1915, just a quarter of a century after my father, and a little later I participated in that delayed Teutonic migration known as the Great War.")

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
        c("1915", "just a quarter of a century")
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
    skip_if_no_python_or_no_spacy()

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
    skip_if_no_python_or_no_spacy()

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
    skip_if_no_python_or_no_spacy()
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
        entity_consolidate(parsed)$lemma[c(1, 4, 16)],
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
