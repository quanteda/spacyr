# Definitions for the saved-output tests (test-9-saved-output.R).
#
# The texts and calls below are run by fixtures/record-saved-output.R, and the
# accepted results saved in fixtures/saved-output.rds. The tests rerun each
# call and compare the result with the saved one, so that a refactor that
# changes any output is caught. fixtures/saved-output-1.4.0.rds keeps the
# output of spacyr 1.4.0 as a fixed reference. See fixtures/README.md.

saved_output_file <- function(which = c("accepted", "baseline")) {
  file <- switch(match.arg(which),
                 accepted = "saved-output.rds",
                 baseline = "saved-output-1.4.0.rds")
  testthat::test_path("fixtures", file)
}

saved_output_texts <- function() {
  list(
    # several documents, names not in alphabetical order, with edge cases
    en = c(
      zeta = paste("The European Central Bank raised rates by 0.25% on 14 March 2024.",
                   "Christine Lagarde said that inflation remained too high."),
      alpha = "Path C:\\Users\\ken, LaTeX \\alpha, regex \\d+ and a literal \\n here.",
      mu = "One.  Two three.   ",
      beta = NA,
      kappa = "",
      delta = "Email info@example.com or visit https://spacy.io/usage for $5 or \u20ac10 :) #nlp @user",
      gamma = paste0("First line.\nSecond line\tafter a tab.\n\n",
                     "Third paragraph, with \"double quotes\" and 'single quotes'."),
      epsilon = paste("Caf\u00e9 na\u00efve r\u00e9sum\u00e9 \u2014 \u201ccurly quotes\u201d",
                      "and an emoji \U0001f642 in New York City.")
    ),
    # no document names
    en_unnamed = c(
      "Apple is looking at buying a U.K. startup for $1 billion.",
      "Autonomous cars shift insurance liability toward manufacturers."
    ),
    # a single document, with trailing whitespace
    en_single = c(only = "Mr. Smith moved to San Francisco in December. He likes it there.  "),
    # no document contains any tokens, apart from whitespace
    en_empty = c(e1 = NA, e2 = "", e3 = "   "),
    # German
    de = c(
      de_b = paste("Angela Merkel war von 2005 bis 2021 Bundeskanzlerin der",
                   "Bundesrepublik Deutschland. Sie lebt in Berlin."),
      de_a = "Die Stra\u00dfe f\u00fchrt \u00fcber die Br\u00fccke nach M\u00fcnchen.  Gr\u00f6\u00dfere H\u00e4user stehen dort. "
    )
  )
}

saved_output_models <- function() {
  c(en = "en_core_web_sm", en_unnamed = "en_core_web_sm", en_single = "en_core_web_sm",
    en_empty = "en_core_web_sm", de = "de_core_news_sm")
}

# the input passed to the function: a character vector, a TIF data.frame or a
# quanteda corpus made from one of the texts above
saved_output_input <- function(text, input_type = "character") {
  x <- saved_output_texts()[[text]]
  switch(input_type,
         character = x,
         data.frame = data.frame(doc_id = names(x), text = unname(x),
                                 stringsAsFactors = FALSE),
         corpus = quanteda::corpus(ifelse(is.na(x), "", x)))
}

saved_output_cases <- function() {
  cases <- list()
  add <- function(fun, text, label, args = list(), input_type = "character",
                  multithread = NULL) {
    if (!is.null(multithread)) args$multithread <- multithread
    id <- paste(c(fun, text, label,
                  if (input_type != "character") input_type,
                  if (!is.null(multithread)) paste0("multithread=", multithread)),
                collapse = "/")
    cases[[id]] <<- list(id = id, fun = fun, text = text, args = args,
                         input_type = input_type, model = saved_output_models()[[text]])
  }
  attrs <- c("is_punct", "like_num", "like_url", "like_email", "is_stop",
             "shape_", "idx", "ent_iob_", "whitespace_")

  ## spacy_parse()
  parse_options <- list(
    default = list(),
    minimal = list(pos = FALSE, lemma = FALSE, entity = FALSE),
    tag = list(tag = TRUE),
    dependency = list(dependency = TRUE),
    nounphrase = list(nounphrase = TRUE),
    attributes = list(additional_attributes = attrs),
    full = list(tag = TRUE, dependency = TRUE, nounphrase = TRUE,
                additional_attributes = attrs)
  )
  for (mt in c(TRUE, FALSE))
    for (label in names(parse_options))
      add("spacy_parse", "en", label, parse_options[[label]], multithread = mt)
  for (text in c("en_unnamed", "en_single", "en_empty", "de")) {
    add("spacy_parse", text, "default")
    add("spacy_parse", text, "full", parse_options$full)
  }

  ## spacy_tokenize()
  tokenize_options <- list(
    default = list(),
    remove_punct = list(remove_punct = TRUE),
    remove_url = list(remove_url = TRUE),
    remove_numbers = list(remove_numbers = TRUE),
    remove_symbols = list(remove_symbols = TRUE),
    keep_separators = list(remove_separators = FALSE),
    remove_symbols_keep_separators = list(remove_symbols = TRUE, remove_separators = FALSE),
    remove_punct_padding = list(remove_punct = TRUE, padding = TRUE),
    remove_all = list(remove_punct = TRUE, remove_url = TRUE, remove_numbers = TRUE,
                      remove_symbols = TRUE),
    remove_all_padding = list(remove_punct = TRUE, remove_url = TRUE, remove_numbers = TRUE,
                              remove_symbols = TRUE, padding = TRUE),
    remove_punct_keep_separators = list(remove_punct = TRUE, remove_separators = FALSE),
    dataframe = list(output = "data.frame"),
    sentence = list(what = "sentence"),
    sentence_keep_separators = list(what = "sentence", remove_separators = FALSE),
    sentence_dataframe = list(what = "sentence", output = "data.frame")
  )
  for (mt in c(TRUE, FALSE))
    for (label in names(tokenize_options))
      add("spacy_tokenize", "en", label, tokenize_options[[label]], multithread = mt)
  for (text in c("en_unnamed", "en_single", "en_empty", "de"))
    for (label in c("default", "keep_separators", "sentence", "sentence_keep_separators"))
      add("spacy_tokenize", text, label, tokenize_options[[label]])

  ## spacy_extract_entity()
  for (mt in c(TRUE, FALSE))
    for (output in c("data.frame", "list"))
      for (type in c("all", "named", "extended"))
        add("spacy_extract_entity", "en", paste(output, type, sep = "_"),
            list(output = output, type = type), multithread = mt)
  for (text in c("en_unnamed", "en_single", "en_empty", "de"))
    for (output in c("data.frame", "list"))
      add("spacy_extract_entity", text, output, list(output = output))

  ## spacy_extract_nounphrases()
  for (mt in c(TRUE, FALSE))
    for (output in c("data.frame", "list"))
      add("spacy_extract_nounphrases", "en", output, list(output = output), multithread = mt)
  for (text in c("en_unnamed", "en_single", "en_empty", "de"))
    for (output in c("data.frame", "list"))
      add("spacy_extract_nounphrases", text, output, list(output = output))

  ## other input types give the same results as character input
  for (input_type in c("data.frame", "corpus")) {
    add("spacy_parse", "en", "full", parse_options$full, input_type = input_type)
    add("spacy_tokenize", "en", "default", input_type = input_type)
    add("spacy_tokenize", "en", "sentence", tokenize_options$sentence, input_type = input_type)
    add("spacy_extract_entity", "en", "data.frame", list(output = "data.frame"),
        input_type = input_type)
    add("spacy_extract_nounphrases", "en", "data.frame", list(output = "data.frame"),
        input_type = input_type)
  }

  cases
}

# Cases for entity_*() and nounphrase_*(), which take a saved spacy_parse()
# result as input and so need no Python
saved_output_helper_cases <- function() {
  cases <- list()
  add <- function(fun, parse_id, label, args = list()) {
    id <- paste(fun, parse_id, label, sep = " <- ")
    cases[[id]] <<- list(id = id, fun = fun, parse_id = parse_id, args = args)
  }
  parses <- c("spacy_parse/en/full/multithread=TRUE", "spacy_parse/en_unnamed/full",
              "spacy_parse/en_single/full", "spacy_parse/en_empty/full",
              "spacy_parse/de/full")
  for (p in parses) {
    for (type in c("named", "extended", "all"))
      add("entity_extract", p, type, list(type = type))
    add("entity_extract", p, "all_space", list(type = "all", concatenator = " "))
    add("entity_consolidate", p, "default")
    add("entity_consolidate", p, "plus", list(concatenator = "+"))
    add("nounphrase_extract", p, "default")
    add("nounphrase_extract", p, "space", list(concatenator = " "))
    add("nounphrase_consolidate", p, "default")
    add("nounphrase_consolidate", p, "plus", list(concatenator = "+"))
  }
  # parses without the entity or nounphrase columns
  for (fun in c("entity_extract", "entity_consolidate", "nounphrase_extract",
                "nounphrase_consolidate"))
    add(fun, "spacy_parse/en/minimal/multithread=TRUE", "default")
  cases
}

# Run a call, capturing its value, messages, warnings and error message
capture_saved_output <- function(f, args) {
  messages <- character()
  warnings <- character()
  error <- NULL
  value <- withCallingHandlers(
    tryCatch(do.call(f, args), error = function(e) {
      error <<- conditionMessage(e)
      NULL
    }),
    message = function(m) {
      messages <<- c(messages, conditionMessage(m))
      invokeRestart("muffleMessage")
    },
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  list(value = value, messages = messages, warnings = warnings, error = error)
}

run_saved_output_case <- function(case) {
  f <- getExportedValue("spacyr", case$fun)
  capture_saved_output(f, c(list(saved_output_input(case$text, case$input_type)),
                            case$args))
}

run_saved_output_helper_case <- function(case, parses) {
  f <- getExportedValue("spacyr", case$fun)
  capture_saved_output(f, c(list(parses[[case$parse_id]]$value), case$args))
}

# installed version of a Python package, e.g. a language model
python_package_version <- function(package) {
  tryCatch(reticulate::import("importlib.metadata")$version(package),
           error = function(e) NA_character_)
}
