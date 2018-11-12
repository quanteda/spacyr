context("testing entity functions")
source("utils.R")

test_that("getting named entities works", {
    skip_on_cran()
    # skip_on_appveyor()
    skip_on_os("solaris")
    skip_if_no_python_or_no_spacy()
    
    expect_message(spacy_initialize(), "successfully")
    
    txt1 <- c(doc1 = "The United States elected President Donald Trump, from New York.", 
              doc2 = "New buildings on the New York skyline.")
    parsed <- spacy_parse(txt1, entity = TRUE)
    
    entities <- entity_extract(parsed)
    
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

    parsed <- spacy_parse(txt1, entity = TRUE, pos = TRUE, tag = TRUE)
    expect_equal(
        entity_consolidate(parsed)$pos[c(1, 4, 17)],
        rep("ENTITY", 3)
    )
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

