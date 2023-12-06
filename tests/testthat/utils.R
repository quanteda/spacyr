try_spacy_initialize <- function() {
  if (methods::is(try(spacy_initialize()), "try-error")) 
    testthat::skip("Can't initialize")
}
