try_spacy_initialize <- function() {
  if (methods::is(try(spacy_initialize()), "try-error")) 
    testthat::skip("Can't initialize")
}

# whether R can set an environment variable to an empty value: on Windows,
# for instance, Sys.setenv(x = "") removes the variable instead
empty_env_supported <- function() {
  name <- "SPACYR_EMPTY_ENV_PROBE"
  on.exit(Sys.unsetenv(name))
  Sys.setenv(SPACYR_EMPTY_ENV_PROBE = "")
  identical(Sys.getenv(name, unset = NA_character_), "")
}
