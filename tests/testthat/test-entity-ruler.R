source("utils.R")

titles <- c("dr", "dr.", "prof", "prof.", "professor")
title_rule <- as_entity_patterns(list(
    label = "PERSON",
    pattern = list(list(LOWER = list(IN = titles)),
                   list(ENT_TYPE = "PERSON", ENT_IOB = "B"),
                   list(ENT_TYPE = "PERSON", ENT_IOB = "I", OP = "*"))))

ents_of <- function(x) {
    ents <- spacy_extract_entity(x)
    stats::setNames(ents$ent_type, ents$text)
}

pipe_names <- function() {
    f <- reticulate::py_eval("lambda nlp: list(nlp.pipe_names)")
    f(spacyr:::spacyr_env$nlp)
}

# the entities of a text as spaCy's spans give them, with their IDs
span_ents <- function(text) {
    f <- reticulate::py_eval(
        "lambda nlp, t: [[e.text, e.label_, e.ent_id_] for e in nlp(t).ents]")
    do.call(rbind, lapply(f(spacyr:::spacyr_env$nlp, text), unlist))
}

test_that("spacy_initialize checks overwrite_entities before starting", {
    try(spacy_finalize(), silent = TRUE)
    for (bad in list(NA, "yes", c(TRUE, FALSE), 1))
        expect_error(spacy_initialize(entity_patterns = c(ORG = "Acme"),
                                      overwrite_entities = bad),
                     "overwrite_entities must be TRUE or FALSE")
    expect_error(spacy_initialize(entity_patterns = 1:3),
                 "as_entity_patterns")
    expect_null(getOption("spacy_initialized"))
})

test_that("uses_entity_attrs finds ENT_TYPE and ENT_IOB in token patterns", {
    expect_true(uses_entity_attrs(title_rule))
    expect_true(uses_entity_attrs(as_entity_patterns(
        list(label = "X", pattern = list(list(ent_iob = "B"))))))
    expect_false(uses_entity_attrs(as_entity_patterns(c(ORG = "ENT_TYPE"))))
    expect_false(uses_entity_attrs(as_entity_patterns(
        list(label = "X", pattern = list(list(IS_TITLE = TRUE))))))
})

test_that("a title rule extends the model's PERSON entities", {
    skip_on_cran()
    skip_on_os("solaris")
    try(spacy_finalize(), silent = TRUE)
    expect_message(spacy_initialize(entity_patterns = title_rule), "successfully")
    on.exit(spacy_finalize())

    pipes <- pipe_names()
    expect_identical(pipes[length(pipes)], "spacyr_entity_ruler")
    expect_identical(spacyr:::spacyr_env$entity_patterns, title_rule)

    ents <- ents_of("Prof. Jane Smith Bob Jones spoke, and so did Dr. Kim Park.")
    expect_identical(ents[["Prof. Jane Smith"]], "PERSON")
    expect_identical(ents[["Bob Jones"]], "PERSON")
    expect_identical(ents[["Dr. Kim Park"]], "PERSON")

    parsed <- spacy_parse("Prof. Jane Smith spoke.", entity = TRUE)
    expect_identical(parsed$entity[1:3], c("PERSON_B", "PERSON_I", "PERSON_I"))
    expect_identical(entity_extract(parsed, concatenator = " ")$entity,
                     "Prof. Jane Smith")
})

test_that("overwrite_entities decides between a rule and the model", {
    skip_on_cran()
    skip_on_os("solaris")
    try(spacy_finalize(), silent = TRUE)
    txt <- "Jane Smith flew to Paris."
    spacy_initialize()
    expect_identical(ents_of(txt)[["Paris"]], "GPE")
    spacy_finalize()

    spacy_initialize(entity_patterns = c(LOC = "Paris", ORG = "flew"))
    expect_identical(ents_of(txt)[["Paris"]], "LOC")
    expect_identical(ents_of(txt)[["flew"]], "ORG")
    spacy_finalize()

    spacy_initialize(entity_patterns = c(LOC = "Paris", ORG = "flew"),
                     overwrite_entities = FALSE)
    # the model wins where they overlap; the rule adds where it found nothing
    expect_identical(ents_of(txt)[["Paris"]], "GPE")
    expect_identical(ents_of(txt)[["flew"]], "ORG")
    spacy_finalize()
})

test_that("phrases match as written, or in any case", {
    skip_on_cran()
    skip_on_os("solaris")
    try(spacy_finalize(), silent = TRUE)
    pats <- c(as_entity_patterns("Acme Widgets", label = "ORG"),
              as_entity_patterns(c("Globex, Inc.", "zorg flim"), label = "PRODUCT",
                                 case_insensitive = TRUE))
    spacy_initialize(entity_patterns = pats)
    on.exit(spacy_finalize())

    expect_identical(ents_of("We met Acme Widgets.")[["Acme Widgets"]], "ORG")
    expect_false("ACME WIDGETS" %in% names(ents_of("We met ACME WIDGETS.")))
    # tokenized with the pipeline's tokenizer: "Globex", ",", "Inc."
    expect_identical(ents_of("GLOBEX, Inc. called.")[["GLOBEX, Inc."]], "PRODUCT")
    expect_identical(ents_of("Try the Zorg Flim today.")[["Zorg Flim"]], "PRODUCT")
})

test_that("a pattern's id reaches the entity's span", {
    skip_on_cran()
    skip_on_os("solaris")
    try(spacy_finalize(), silent = TRUE)
    pats <- c(as_entity_patterns("Acme Widgets", label = "ORG", id = "acme"),
              as_entity_patterns("acme widgets", label = "ORG", id = "acme",
                                 case_insensitive = TRUE),
              as_entity_patterns(c(GPE = "Ruritania")))
    spacy_initialize(entity_patterns = pats)
    on.exit(spacy_finalize())

    ents <- span_ents("Acme Widgets and ACME WIDGETS left Ruritania.")
    expect_identical(ents[, 1], c("Acme Widgets", "ACME WIDGETS", "Ruritania"))
    expect_identical(ents[, 3], c("acme", "acme", ""))
})

test_that("rules set entities without the model's recognizer", {
    skip_on_cran()
    skip_on_os("solaris")
    try(spacy_finalize(), silent = TRUE)
    pats <- as_entity_patterns(list(label = "NAME",
                                    pattern = list(list(IS_TITLE = TRUE),
                                                   list(IS_TITLE = TRUE))))
    expect_silent(suppressMessages(spacy_initialize(entity = FALSE,
                                                    entity_patterns = pats)))
    on.exit(spacy_finalize())
    expect_true(getOption("spacy_entity"))
    parsed <- spacy_parse("We saw Jane Smith there.", entity = TRUE)
    expect_identical(parsed$entity[1:4], c("", "", "NAME_B", "NAME_I"))
})

test_that("ENT_TYPE patterns warn only when nothing sets entities", {
    skip_on_cran()
    skip_on_os("solaris")
    try(spacy_finalize(), silent = TRUE)
    expect_warning(
        suppressMessages(spacy_initialize(entity = FALSE, entity_patterns = title_rule)),
        "no component of the pipeline sets entities")
    spacy_finalize()

    # a model saved with its own entity_ruler, which sets entities
    spacy <- reticulate::import("spacy")
    nlp <- spacy$load("en_core_web_sm")
    ruler <- nlp$add_pipe("entity_ruler")
    ruler$add_patterns(list(list(label = "PERSON", pattern = "Jane Smith"),
                            list(label = "ORG", pattern = "Acme Widgets")))
    path <- tempfile("with_ruler")
    dir.create(path)
    on.exit(unlink(path, recursive = TRUE), add = TRUE)
    nlp$to_disk(path)
    rm(nlp, ruler)

    expect_silent(suppressMessages(spacy_initialize(
        path, entity = FALSE,
        entity_patterns = c(title_rule, as_entity_patterns(c(GPE = "Ruritania"))))))
    pipes <- pipe_names()
    expect_identical(pipes[length(pipes) - 0:1], c("spacyr_entity_ruler", "entity_ruler"))
    ents <- ents_of("Prof. Jane Smith of Acme Widgets visited Ruritania.")
    expect_identical(ents[["Prof. Jane Smith"]], "PERSON")
    expect_identical(ents[["Acme Widgets"]], "ORG")
    expect_identical(ents[["Ruritania"]], "GPE")
    spacy_finalize()
})

test_that("spaCy's message is given for a pattern it does not accept", {
    skip_on_cran()
    skip_on_os("solaris")
    try(spacy_finalize(), silent = TRUE)
    bad <- as_entity_patterns(list(label = "X",
                                   pattern = list(list(LOWER = list(FOO = "a")))))
    err <- tryCatch(spacy_initialize(entity_patterns = bad), error = identity)
    expect_match(conditionMessage(err), "spaCy did not accept the entity patterns")
    expect_match(conditionMessage(err), "Invalid token patterns for matcher rule 'X'",
                 fixed = TRUE)
    expect_no_match(conditionMessage(err), "py_last_error", fixed = TRUE)
    expect_null(getOption("spacy_initialized"))
    expect_message(spacy_initialize(), "successfully")
    pipes <- pipe_names()
    expect_false("spacyr_entity_ruler" %in% pipes)
    spacy_finalize()
    expect_null(spacyr:::spacyr_env$entity_patterns)
})
