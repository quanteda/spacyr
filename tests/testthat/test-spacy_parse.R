require(testthat)

spacy_initialize()

test_that("spacy_parse handles newlines and tabs ok", {
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
})

test_that("spacy_parse handles quotes ok", {
    
    txt1 <- c(doc1 = "Sentence \"quoted\" one.", 
              doc2 = "Sentence \'quoted\' two.")
    # expect_error(
    #     spacy_parse(txt1, dependency = TRUE)
    # )
    
    txt2 <- c(doc1 = "Sentence \\\"quoted\\\" one.")
    expect_equal(
        dim(spacy_parse(txt2, dependency = TRUE)),
        c(6, 8)
    )
    
    txt3 <- c(doc1 = "Second sentence \\\'quoted\\\' example.")
    # expect_equal(
    #     dim(spacy_parse(txt3, dependency = TRUE)),
    #     c(6, 8)
    # )
    
    txt4 <- c(doc1 = "Sentence \\\"quoted\\\" one.", 
              doc2 = "Sentence \\\'quoted\\\' two.")
     # expect_message(
     #     spacy_parse(txt4, dependency = TRUE), 
     #     "SyntaxError: invalid syntax"
     # )
    
})
