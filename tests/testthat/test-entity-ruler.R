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

test_that("needs_entities finds patterns that require earlier entities", {
    one <- function(...) as_entity_patterns(list(label = "X", pattern = list(list(...))))
    expect_true(needs_entities(title_rule))
    expect_true(needs_entities(one(ent_iob = "B")))
    expect_true(needs_entities(one(ENT_TYPE = list(IN = "PERSON"))))
    expect_true(needs_entities(one(ENT_TYPE = "ORG", OP = "+")))
    # these also match tokens outside entities
    expect_false(needs_entities(one(ENT_TYPE = list(NOT_IN = "PERSON"))))
    expect_false(needs_entities(one(ENT_TYPE = "")))
    expect_false(needs_entities(one(ENT_IOB = "O")))
    expect_false(needs_entities(one(ENT_TYPE = "PERSON", OP = "*")))
    expect_false(needs_entities(one(ENT_TYPE = "PERSON", OP = "!")))
    expect_false(needs_entities(as_entity_patterns(c(ORG = "ENT_TYPE"))))
    expect_false(needs_entities(one(IS_TITLE = TRUE)))
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
        "no component before spacyr's entity ruler sets entities.*entity = TRUE")
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

# save a pipeline built in Python to a temporary directory, and return its path
save_pipeline <- function(nlp) {
    path <- tempfile("pipeline")
    dir.create(path)
    nlp$to_disk(path)
    path
}

test_that("a span_ruler that annotates entities counts as setting them", {
    skip_on_cran()
    skip_on_os("solaris")
    try(spacy_finalize(), silent = TRUE)
    try_spacy_initialize()
    spacy_finalize()
    spacy <- reticulate::import("spacy")
    nlp <- spacy$load("en_core_web_sm", exclude = list("ner"))
    sr <- nlp$add_pipe("span_ruler", config = list(annotate_ents = TRUE))
    sr$add_patterns(list(list(label = "PERSON", pattern = "Jane Smith")))
    path <- save_pipeline(nlp)
    on.exit(unlink(path, recursive = TRUE))
    rm(nlp, sr)

    expect_silent(suppressMessages(spacy_initialize(path, entity_patterns = title_rule)))
    expect_identical(ents_of("Prof. Jane Smith spoke.")[["Prof. Jane Smith"]], "PERSON")
    spacy_finalize()

    # a pipeline that has no ner: the warning does not suggest entity = TRUE
    blank <- save_pipeline(spacy$blank("en"))
    on.exit(unlink(blank, recursive = TRUE), add = TRUE)
    w <- tryCatch(suppressMessages(spacy_initialize(blank, entity_patterns = title_rule)),
                  warning = identity)
    expect_match(conditionMessage(w), "will not match")
    expect_no_match(conditionMessage(w), "entity = TRUE", fixed = TRUE)
    try(spacy_finalize(), silent = TRUE)
})

test_that("phrases warn when an earlier component changes the tokens", {
    skip_on_cran()
    skip_on_os("solaris")
    try(spacy_finalize(), silent = TRUE)
    try_spacy_initialize()
    spacy_finalize()
    spacy <- reticulate::import("spacy")
    nlp <- spacy$load("en_core_web_sm")
    ruler <- nlp$add_pipe("entity_ruler", config = list(overwrite_ents = TRUE))
    ruler$add_patterns(list(list(label = "ORG", pattern = "Acme Widgets")))
    nlp$add_pipe("merge_entities")
    path <- save_pipeline(nlp)
    on.exit(unlink(path, recursive = TRUE))
    rm(nlp, ruler)

    expect_warning(
        suppressMessages(spacy_initialize(path, entity_patterns = c(PRODUCT = "Acme Widgets"))),
        "'merge_entities' changes the tokens")
    # the phrase reaches the ruler as a single token, so the rule misses
    expect_identical(ents_of("We met Acme Widgets.")[["Acme Widgets"]], "ORG")
    spacy_finalize()

    # token patterns alone give no warning
    expect_silent(suppressMessages(spacy_initialize(path, entity_patterns = list(
        label = "PRODUCT", pattern = list(list(LOWER = "acme widgets"))))))
    expect_identical(ents_of("We met Acme Widgets.")[["Acme Widgets"]], "PRODUCT")
    spacy_finalize()
})

test_that("a pipeline saved with spacyr's ruler gets a second one", {
    skip_on_cran()
    skip_on_os("solaris")
    try(spacy_finalize(), silent = TRUE)
    suppressMessages(spacy_initialize(entity_patterns = c(ORG = "Acme Widgets")))
    path <- save_pipeline(spacyr:::spacyr_env$nlp)
    on.exit(unlink(path, recursive = TRUE))
    spacy_finalize()

    expect_message(spacy_initialize(path, entity_patterns = c(GPE = "Ruritania")),
                   "successfully")
    expect_identical(spacyr:::spacyr_env$entity_ruler, "spacyr_entity_ruler_2")
    pipes <- pipe_names()
    expect_identical(pipes[length(pipes) - 1:0],
                     c("spacyr_entity_ruler", "spacyr_entity_ruler_2"))
    ents <- ents_of("Acme Widgets moved to Ruritania.")
    expect_identical(ents[["Acme Widgets"]], "ORG")
    expect_identical(ents[["Ruritania"]], "GPE")
    spacy_finalize()
    expect_null(spacyr:::spacyr_env$entity_ruler)
})

test_that("dictionaries and extracted entities work as rules", {
    skip_on_cran()
    skip_on_os("solaris")
    skip_if_not_installed("quanteda")
    try(spacy_finalize(), silent = TRUE)
    values <- list(ORG = c("acme widgets", "globex*", "Initech, Inc."),
                   PERSON = "dr * who")
    txt <- "ACME WIDGETS and Globexcorp met Dr Hal Who at INITECH, Inc."
    # without the model's recognizer, so that only the rules find entities;
    # tolower = FALSE keeps "Inc.", which spaCy's tokenizer keeps whole
    spacy_initialize(entity = FALSE,
                     entity_patterns = quanteda::dictionary(values, tolower = FALSE))
    ents <- ents_of(txt)
    expect_identical(ents[["ACME WIDGETS"]], "ORG")
    expect_identical(ents[["Globexcorp"]], "ORG")
    expect_identical(ents[["Dr Hal Who"]], "PERSON")
    expect_identical(ents[["INITECH, Inc."]], "ORG")
    spacy_finalize()

    # quanteda's default lowercases "Inc." to "inc.", which spaCy splits into
    # "inc" and ".", so that phrase no longer matches
    spacy_initialize(entity = FALSE, entity_patterns = quanteda::dictionary(values))
    ents <- ents_of(txt)
    expect_identical(ents[["ACME WIDGETS"]], "ORG")
    expect_false("INITECH, Inc." %in% names(ents))
    spacy_finalize()

    spacy_initialize()
    # entities found in one text, reused as rules for another pipeline
    found <- spacy_extract_entity("Acme Widgets hired Jane Smith in Ruritania.")
    found_parsed <- entity_extract(spacy_parse("Acme Widgets hired Jane Smith."),
                                   type = "all")
    spacy_finalize()
    spacy_initialize(entity = FALSE, entity_patterns = found)
    ents <- ents_of("Later, Jane Smith left Acme Widgets.")
    expect_identical(ents[["Jane Smith"]], found$ent_type[found$text == "Jane Smith"])
    expect_identical(ents[["Acme Widgets"]], found$ent_type[found$text == "Acme Widgets"])
    spacy_finalize()

    spacy_initialize(entity = FALSE,
                     entity_patterns = as_entity_patterns(found_parsed, concatenator = "_"))
    expect_true("Jane Smith" %in% names(ents_of("Later, Jane Smith left.")))
    spacy_finalize()
})

test_that("single-token regular expressions are merged per label and id", {
    skip_on_cran()
    skip_on_os("solaris")
    try(spacy_finalize(), silent = TRUE)
    try_spacy_initialize()
    on.exit(spacy_finalize())
    rx <- function(label, r, attr = "LOWER", id = NULL) {
        p <- list(label = label, pattern = list(stats::setNames(list(list(REGEX = r)), attr)))
        if (!is.null(id)) p$id <- id
        p
    }
    pats <- as_entity_patterns(list(
        rx("A", "^ab.*$"), rx("A", "^cd.*$"), rx("A", "^ef$", attr = "ORTH"),
        rx("A", "^gh.*$", id = "g"), rx("B", "^ij.*$"),
        rx("A", "(?i)^kl"), rx("A", "^(unclosed"),
        list(label = "A", pattern = list(list(LOWER = list(REGEX = "^mn")),
                                         list(LOWER = "op")))))
    out <- spacyr:::spacyr_env$module$ruler_patterns(spacyr:::spacyr_env$nlp,
                                                     as.list(pats))
    regex_of <- function(p) p$pattern[[1]][[1]]$REGEX
    labels <- vapply(out, function(p) p$label, "")
    ids <- vapply(out, function(p) if (is.null(p$id)) NA_character_ else p$id, "")
    regexes <- vapply(out, function(p) {
        r <- regex_of(p); if (is.null(r)) NA_character_ else r
    }, "")
    expect_length(out, 7)
    expect_true("(?:^ab.*$)|(?:^cd.*$)" %in% regexes)
    expect_true("^ef$" %in% regexes)
    expect_identical(ids[regexes %in% "^gh.*$"], "g")
    expect_identical(labels[regexes %in% "^ij.*$"], "B")
    # left as they were: inline flags, a regular expression that does not
    # compile, and a pattern of more than one token
    expect_true(all(c("(?i)^kl", "^(unclosed", "^mn") %in% regexes))
})

test_that("values of a custom attribute called REGEX are not merged", {
    skip_on_cran()
    skip_on_os("solaris")
    try(spacy_finalize(), silent = TRUE)
    try_spacy_initialize()
    on.exit(spacy_finalize())
    # inside "_", REGEX is the name of an extension, compared for equality
    pats <- as_entity_patterns(list(
        list(label = "A", pattern = list(list(`_` = list(REGEX = "x")))),
        list(label = "A", pattern = list(list(`_` = list(REGEX = "y"))))))
    out <- spacyr:::spacyr_env$module$ruler_patterns(spacyr:::spacyr_env$nlp,
                                                     as.list(pats))
    expect_length(out, 2)
    expect_identical(vapply(out, function(p) p$pattern[[1]][["_"]]$REGEX, ""),
                     c("x", "y"))
})

test_that("regular expressions with backreferences are not merged", {
    skip_on_cran()
    skip_on_os("solaris")
    try(spacy_finalize(), silent = TRUE)
    pats <- as_entity_patterns(list(
        list(label = "PAIR", pattern = list(list(TEXT = list(REGEX = "^(a)\\1$")))),
        list(label = "PAIR", pattern = list(list(TEXT = list(REGEX = "^(b)\\1$")))),
        list(label = "PAIR", pattern = list(list(TEXT = list(REGEX = "^c+$")))),
        list(label = "PAIR", pattern = list(list(TEXT = list(REGEX = "^d+$"))))))
    spacy_initialize(entity = FALSE, entity_patterns = pats)
    on.exit(spacy_finalize())
    ents <- ents_of("aa then bb then ab then cc then dd")
    expect_identical(sort(names(ents)), c("aa", "bb", "cc", "dd"))
    out <- spacyr:::spacyr_env$module$ruler_patterns(spacyr:::spacyr_env$nlp,
                                                     as.list(pats))
    expect_length(out, 3)
})

test_that("case-insensitive phrases match on LOWER when all phrases are", {
    skip_on_cran()
    skip_on_os("solaris")
    try(spacy_finalize(), silent = TRUE)
    ruler_attr <- function() {
        f <- reticulate::py_eval("lambda nlp, n: str(nlp.get_pipe(n).phrase_matcher_attr)")
        f(spacyr:::spacyr_env$nlp, spacyr:::spacyr_env$entity_ruler)
    }
    pats <- as_entity_patterns(c("Acme Widgets", "Globex, Inc."), label = "ORG",
                               case_insensitive = TRUE)
    spacy_initialize(entity_patterns = pats)
    expect_identical(ruler_attr(), "LOWER")
    ents <- ents_of("ACME WIDGETS and globex, Inc. merged.")
    expect_identical(ents[["ACME WIDGETS"]], "ORG")
    expect_identical(ents[["globex, Inc."]], "ORG")
    spacy_finalize()

    # with an exact phrase as well, the exact one stays exact
    spacy_initialize(entity_patterns = c(pats, as_entity_patterns(c(GPE = "Ruritania"))))
    expect_false(identical(ruler_attr(), "LOWER"))
    ents <- ents_of("ACME WIDGETS left RURITANIA for Ruritania.")
    expect_identical(ents[["ACME WIDGETS"]], "ORG")
    expect_identical(ents[["Ruritania"]], "GPE")
    expect_false(isTRUE(ents["RURITANIA"] == "GPE"))
    spacy_finalize()
})

test_that("an extraction that found no entities gives no patterns", {
    skip_on_cran()
    skip_on_os("solaris")
    try(spacy_finalize(), silent = TRUE)
    try_spacy_initialize()
    on.exit(spacy_finalize())
    found <- spacy_extract_entity("nothing to see here")
    expect_null(found)
    expect_identical(as_entity_patterns(found), as_entity_patterns(character()))
})

test_that("phrases with wildcards and dictionary levels become entities", {
    skip_on_cran()
    skip_if_not_installed("quanteda")
    try(spacy_finalize(), silent = TRUE)
    on.exit(try(spacy_finalize(), silent = TRUE))
    txt <- "Acme Widgets and Globex Corporation have offices in Boston and London."
    spacy_initialize(entity = FALSE, entity_patterns = as_entity_patterns(
        c(ORG = "acme wid*", ORG = "globex corp*"), valuetype = "glob",
        case_insensitive = TRUE))
    e <- spacy_extract_entity(txt)
    expect_identical(e$text, c("Acme Widgets", "Globex Corporation"))
    expect_identical(e$ent_type, c("ORG", "ORG"))
    spacy_finalize()
    d <- quanteda::dictionary(list(place = list(us = "boston", uk = "lond*")))
    spacy_initialize(entity = FALSE,
                     entity_patterns = as_entity_patterns(d, levels = 1:2))
    e <- spacy_extract_entity(txt)
    expect_identical(e$text, c("Boston", "London"))
    expect_identical(e$ent_type, c("place.us", "place.uk"))
})
