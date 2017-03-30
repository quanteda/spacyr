require(testthat)

test_that("spacy_parse handles newlines and tabs ok", {
    skip_on_cran()
    skip_on_appveyor()
    expect_silent(spacy_initialize())

    txt1 <- c(doc1 = "Sentence one.\nSentence two.", 
              doc2 = "Sentence\tthree.")
    expect_equal(
        dim(spacy_parse(txt1, dependency = TRUE)),
        c(11, 7)
    )
    txt2 <- c(doc1 = "Sentence one.\\nSentence two.", 
              doc2 = "Sentence\\tthree.")
    expect_equal(
        dim(spacy_parse(txt2, dependency = TRUE)),
        c(11, 7)
    )
    
    ## multiple tagsets
    expect_equal(
        names(tag1 <- spacy_parse(txt2, tagset = "google")),
        c("docname", "id", "tokens", "google") 
    )
    expect_equal(
        names(tag2 <- spacy_parse(txt2, tagset = "penn")),
        c("docname", "id", "tokens", "penn") 
    )
    expect_false(any(tag1$google == tag2$penn))

    expect_silent(spacy_finalize())
})

test_that("spacy_parse handles quotes ok", {
    skip_on_cran()
    skip_on_appveyor()
    expect_silent(spacy_initialize())
    
    txt1 <- c(doc1 = "Sentence \"quoted\" one.", 
              doc2 = "Sentence \'quoted\' two.")
    expect_true("dep_rel" %in% names(spacy_parse(txt1, dependency = TRUE)))
    
    txt2 <- c(doc1 = "Sentence \\\"quoted\\\" one.")
    expect_equal(
        dim(spacy_parse(txt2, dependency = TRUE)),
        c(6, 7)
    )
    
    txt3 <- c(doc1 = "Second sentence \\\'quoted\\\' example.")
    expect_equal(
        dim(spacy_parse(txt3, dependency = TRUE)),
        c(7, 7)
    )

    txt4 <- c(doc1 = "Sentence \\\"quoted\\\" one.", 
              doc2 = "Sentence \\\'quoted\\\' two.")
    expect_equal(
        dim(spacy_parse(txt4, dependency = TRUE)), 
        c(12, 7)
    )
    expect_silent(spacy_finalize())
})

test_that("getting named entities works", {
    skip_on_cran()
    skip_on_appveyor()
    expect_silent(spacy_initialize())
    
    txt1 <- c(doc1 = "The United States elected President Donald Trump, from New York.", 
              doc2 = "New buildings on the New York skyline.")
    parsed <- spacy_parse(txt1, named_entity = TRUE)
    
    named_entities <- get_all_named_entities(parsed)
    
    expect_equal(
        named_entities$entity,
        c("New York", "New York")
        #c("The United States", "Donald Trump", "New York", "New York")
    )
    expect_equal(
        named_entities$entity_type,
        c("GPE", "GPE")
        #c("GPE", "PERSON", "GPE", "GPE")
    )

    expect_silent(spacy_finalize())
})
