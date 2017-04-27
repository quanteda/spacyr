require(testthat)

test_that("spacy_parse handles newlines and tabs ok", {
    skip_on_cran()
    skip_on_appveyor()
    expect_message(spacy_initialize(), "successfully")
    
    txt1 <- c(doc1 = "Sentence one.\nSentence two.", 
              doc2 = "Sentence\tthree.")
    expect_equal(
        dim(spacy_parse(txt1, dependency = TRUE)),
        c(11, 8)
    )
    txt2 <- c(doc1 = "Sentence one.\\nSentence two.", 
              doc2 = "Sentence\\tthree.")
    expect_equal(
        dim(spacy_parse(txt2, dependency = TRUE)),
        c(11, 8)
    )
    
    ## multiple tagsets
    expect_equal(
        names(tag1 <- spacy_parse(txt2, tagset_google = TRUE, tagset_detailed = FALSE)),
        c("docname", "sentence_id" ,"token_id", "tokens", "tag_google") 
    )
    expect_equal(
        names(tag2 <- spacy_parse(txt2, tagset_google = FALSE, tagset_detailed = TRUE)),
        c("docname", "sentence_id" ,"token_id", "tokens", "tag_detailed") 
    )
    expect_false(any(tag1$tag_google == tag2$tag_detailed))

    expect_silent(spacy_finalize())
})

test_that("spacy_parse handles quotes ok", {
    skip_on_cran()
    skip_on_appveyor()
    expect_message(spacy_initialize(), "successfully")
    
    txt1 <- c(doc1 = "Sentence \"quoted\" one.", 
              doc2 = "Sentence \'quoted\' two.")
    expect_true("dep_rel" %in% names(spacy_parse(txt1, dependency = TRUE)))
    
    txt2 <- c(doc1 = "Sentence \\\"quoted\\\" one.")
    expect_equal(
        dim(spacy_parse(txt2, dependency = TRUE)),
        c(6, 8)
    )
    
    txt3 <- c(doc1 = "Second sentence \\\'quoted\\\' example.")
    expect_equal(
        dim(spacy_parse(txt3, dependency = TRUE)),
        c(7, 8)
    )

    txt4 <- c(doc1 = "Sentence \\\"quoted\\\" one.", 
              doc2 = "Sentence \\\'quoted\\\' two.")
    expect_equal(
        dim(spacy_parse(txt4, dependency = TRUE)), 
        c(12, 8)
    )
    expect_silent(spacy_finalize())
})

test_that("getting named entities works", {
    skip_on_cran()
    skip_on_appveyor()
    expect_message(spacy_initialize(), "successfully")
    
    txt1 <- c(doc1 = "The United States elected President Donald Trump, from New York.", 
              doc2 = "New buildings on the New York skyline.")
    parsed <- spacy_parse(txt1, named_entity = TRUE)
    
    named_entities <- get_all_named_entities(parsed)
    
    expect_equal(
        named_entities$entity,
        c("The United States", "Donald Trump", "New York", "the New York")
    )
    expect_equal(
        named_entities$entity_type,
        c("GPE", "PERSON", "GPE", "ORG")
    )

    expect_silent(spacy_finalize())
})
