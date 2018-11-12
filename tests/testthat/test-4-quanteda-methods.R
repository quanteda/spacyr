context("test quanteda functions")
source("utils.R")

test_that("quanteda functions work", {
    skip_on_cran()
    # skip_on_appveyor()
    skip_on_os("solaris")
    skip_if_not_installed("quanteda")
    skip_if_no_python_or_no_spacy()
    
    library("quanteda")
    spacy_initialize()
    
    txt <- c(doc1 = "And now, now, now for something completely different.",
             doc2 = "Jack and Jill are children.")
    parsed <- spacy_parse(txt)
    
    expect_equal(
        quanteda::ntype(parsed),
        c(doc1 = 8, doc2 = 6)
    )
    
    expect_equal(
        quanteda::ntoken(parsed),
        c(doc1 = 11, doc2 = 6)
    )
    
    expect_equal(
        quanteda::ntype(parsed),
        c(doc1 = 8, doc2 = 6)
    )
    
    expect_equal(
        quanteda::ndoc(parsed),
        2
    )
    
    expect_equal(
        quanteda::docnames(parsed),
        c("doc1", "doc2")
    )

    spacy_finalize()
})
