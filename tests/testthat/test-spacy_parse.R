context("test spacy_parse")

test_that("spacy_parse handles newlines and tabs ok", {
    skip_on_cran()
    skip_on_appveyor()
    expect_message(spacy_initialize(), "successfully")
    
    txt1 <- c(doc1 = "Sentence one.\nSentence two.", 
              doc2 = "Sentence\tthree.")
    expect_equal(
        dim(spacy_parse(txt1, dependency = TRUE)),
        c(11, 9)
    )
    txt2 <- c(doc1 = "Sentence one.\\nSentence two.", 
              doc2 = "Sentence\\tthree.")
    expect_equal(
        dim(spacy_parse(txt2, dependency = TRUE)),
        c(11, 9)
    )
    
    ## multiple tagsets
    expect_equal(
        names(tag1 <- spacy_parse(txt2, pos = TRUE, tag = FALSE, entity = FALSE)),
        c("doc_id", "sentence_id" ,"token_id", "token", "lemma", "pos") 
    )
    expect_equal(
        names(tag2 <- spacy_parse(txt2, pos = FALSE, tag = TRUE, entity = FALSE)),
        c("doc_id", "sentence_id" ,"token_id", "token", "lemma", "tag") 
    )
    expect_false(any(tag1$pos == tag2$tag))

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
        c(6, 9)
    )
    
    txt3 <- c(doc1 = "Second sentence \\\'quoted\\\' example.")
    expect_equal(
        dim(spacy_parse(txt3, dependency = TRUE)),
        c(7, 9)
    )

    txt4 <- c(doc1 = "Sentence \\\"quoted\\\" one.", 
              doc2 = "Sentence \\\'quoted\\\' two.")
    expect_equal(
        dim(spacy_parse(txt4, dependency = TRUE)), 
        c(12, 9)
    )
    expect_silent(spacy_finalize())
})

