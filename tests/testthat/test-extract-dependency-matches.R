source("utils.R")

passive <- list(
    list(RIGHT_ID = "verb", RIGHT_ATTRS = list(TAG = "VBN")),
    list(LEFT_ID = "verb", REL_OP = ">", RIGHT_ID = "subject",
         RIGHT_ATTRS = list(DEP = "nsubjpass")),
    list(LEFT_ID = "verb", REL_OP = ">", RIGHT_ID = "aux",
         RIGHT_ATTRS = list(DEP = "auxpass")))
agent <- c(passive, list(
    list(LEFT_ID = "verb", REL_OP = ">", RIGHT_ID = "by",
         RIGHT_ATTRS = list(DEP = "agent")),
    list(LEFT_ID = "by", REL_OP = ">", RIGHT_ID = "agent",
         RIGHT_ATTRS = list(DEP = "pobj"))))
txt <- c(doc1 = "The book was written by Jane. Jane wrote the book.",
         doc2 = "Mistakes were made, and the report is being rewritten.")
dependency_columns <- c("doc_id", "match_id", "label", "node", "sentence_id",
                        "token_id", "start_id", "token")

# dependency_patterns() needs no Python, so these tests also run on CRAN

test_that("dependency_patterns takes one pattern for each label", {
    d <- dependency_patterns(list(PASSIVE = passive, PASSIVE_AGENT = agent))
    expect_identical(d$labels, c("PASSIVE", "PASSIVE_AGENT"))
    expect_identical(d$patterns, list(passive, agent))
})

test_that("dependency_patterns normalizes the attributes of nodes", {
    empty <- structure(list(), names = character(0))
    d <- dependency_patterns(list(P = list(
        list(RIGHT_ID = "verb", RIGHT_ATTRS = list(TAG = list(IN = "VBN"), LENGTH = 7)),
        list(LEFT_ID = "verb", REL_OP = ">", RIGHT_ID = "any", RIGHT_ATTRS = list()),
        list(LEFT_ID = "verb", REL_OP = ">", RIGHT_ID = "morph",
             RIGHT_ATTRS = list(MORPH = list(IS_SUPERSET = "Number=Sing"))))))
    p <- d$patterns[[1]]
    expect_identical(p[[1]]$RIGHT_ATTRS, list(TAG = list(IN = list("VBN")), LENGTH = 7L))
    # an empty RIGHT_ATTRS, which matches any token, is a dict for Python
    expect_identical(p[[2]]$RIGHT_ATTRS, empty)
    expect_identical(p[[3]]$RIGHT_ATTRS, list(MORPH = list(IS_SUPERSET = list("Number=Sing"))))
})

test_that("dependency_patterns rejects patterns it cannot use", {
    expect_error(dependency_patterns(list(passive)), "must be a named list")
    expect_error(dependency_patterns(list(A = passive, A = agent)),
                 "must be unique.*labels of their own: A$")
    expect_error(dependency_patterns(list()), "holds no patterns")
    expect_error(dependency_patterns("a"), "must be a named list of dependency patterns")
    expect_error(dependency_patterns(data.frame(a = 1)), "must be a named list")
    expect_error(dependency_patterns(as_entity_patterns(list(
        label = "X", pattern = list(list(LOWER = "a"))))),
        "entity patterns.*spacy_extract_matches")
    expect_error(dependency_patterns(list(A = "verb")), "'A' is not a list of nodes")
    expect_error(dependency_patterns(list(A = list())), "'A' is not a list of nodes")
    expect_error(dependency_patterns(list(A = passive[[1]])), "'A' is a single node")
    # alternatives under one label
    expect_error(dependency_patterns(list(A = list(passive, agent))),
                 "'A' holds more than one pattern")
    expect_error(dependency_patterns(list(A = c(passive, list("x")))),
                 "Node 4 of pattern 'A' is not a named list")
    # a token pattern
    expect_error(dependency_patterns(list(A = list(list(LOWER = "new"), list(LOWER = "york")))),
                 "'A' is a token pattern.*spacy_extract_matches")
    bad <- passive; bad[[2]]$RIGHT_ID <- NULL
    expect_error(dependency_patterns(list(A = bad)), "Node 2 of pattern 'A' has no RIGHT_ID")
    bad <- passive; bad[[3]]$RIGHT_ATTRS <- NULL
    expect_error(dependency_patterns(list(A = bad)),
                 "Node 3 of pattern 'A' \\('aux'\\) has no RIGHT_ATTRS")
    bad <- passive; bad[[3]]$RIGHT_ATTRS <- "auxpass"
    expect_error(dependency_patterns(list(A = bad)), "has no RIGHT_ATTRS")
    bad <- passive; bad[[3]]$RIGHT_ID <- "subject"
    expect_error(dependency_patterns(list(A = bad)),
                 "'A' names more than one node 'subject'")
})

test_that("spacy_extract_dependency_matches checks its arguments before starting spaCy", {
    try(spacy_finalize(), silent = TRUE)
    expect_error(spacy_extract_dependency_matches("a", list(P = passive), n_process = 0),
                 "n_process")
    expect_error(spacy_extract_dependency_matches("a"), "patterns must be supplied")
    expect_error(spacy_extract_dependency_matches("a", list(passive)), "must be a named list")
    expect_null(getOption("spacy_initialized"))
})

test_that("spacy_extract_dependency_matches finds passives and their parts", {
    skip_on_cran()
    skip_on_os("solaris")
    try_spacy_initialize()

    m <- spacy_extract_dependency_matches(txt, list(PASSIVE = passive))
    expect_s3_class(m, "data.frame", exact = TRUE)
    expect_named(m, dependency_columns)
    expect_identical(m$doc_id, rep(c("doc1", "doc2"), c(3, 6)))
    expect_identical(m$match_id, rep(c(1L, 1L, 2L), each = 3))
    expect_identical(m$label, rep("PASSIVE", 9))
    expect_identical(m$node, rep(c("verb", "subject", "aux"), 3))
    expect_identical(m$token, c("written", "book", "was", "made", "Mistakes", "were",
                                "rewritten", "report", "being"))
    expect_identical(m$start_id, c(4L, 2L, 3L, 3L, 1L, 2L, 10L, 7L, 9L))

    # the same from a TIF data.frame and with two processes
    tif <- data.frame(doc_id = names(txt), text = unname(txt))
    expect_identical(spacy_extract_dependency_matches(tif, list(PASSIVE = passive)), m)
    expect_identical(spacy_extract_dependency_matches(txt, list(PASSIVE = passive),
                                                      n_process = 2), m)

    # positions agree with spacy_parse(), also in a second sentence
    one <- spacy_extract_dependency_matches(
        "Jane wrote the book. The book was written by Jane.", list(PASSIVE = passive))
    expect_identical(one$sentence_id, c(2L, 2L, 2L))
    expect_identical(one$token_id, c(4L, 2L, 3L))
    expect_identical(one$start_id, c(9L, 7L, 8L))
    parsed <- spacy_parse("Jane wrote the book. The book was written by Jane.")
    expect_identical(parsed$token[one$start_id], one$token)
    joined <- merge(one, parsed, by = c("sentence_id", "token_id"), sort = FALSE)
    expect_identical(joined$token.x, joined$token.y)
})

test_that("matches are ordered by position, then label, and numbered", {
    skip_on_cran()
    skip_on_os("solaris")
    try_spacy_initialize()

    # the label given first has the longer pattern, which sorts second
    m <- spacy_extract_dependency_matches(txt["doc1"], list(PASSIVE_AGENT = agent,
                                                            PASSIVE = passive))
    expect_identical(m$match_id, rep(1:2, c(3, 5)))
    # match_id starts again in each document
    two <- spacy_extract_dependency_matches(txt, list(PASSIVE = passive))
    expect_identical(unique(two[, c("doc_id", "match_id")])$match_id, c(1L, 1L, 2L))
    expect_identical(m$label, rep(c("PASSIVE", "PASSIVE_AGENT"), c(3, 5)))
    expect_identical(m$node, c("verb", "subject", "aux",
                               "verb", "subject", "aux", "by", "agent"))
    expect_identical(m$token[4:8], c("written", "book", "was", "by", "Jane"))

    # equal tokens are ordered by label
    same <- spacy_extract_dependency_matches(txt["doc1"], list(Z = passive, A = passive))
    expect_identical(same$label, rep(c("Z", "A"), each = 3))
    expect_identical(same$match_id, rep(1:2, each = 3))

    # a pattern matches once for each combination of tokens
    child <- list(VERB_CHILD = list(
        list(RIGHT_ID = "verb", RIGHT_ATTRS = list(POS = "VERB")),
        list(LEFT_ID = "verb", REL_OP = ">", RIGHT_ID = "child", RIGHT_ATTRS = list())))
    m <- spacy_extract_dependency_matches("Jane quickly wrote the long book.", child)
    expect_identical(m$match_id, rep(1:4, each = 2))
    expect_identical(m$token[m$node == "verb"], rep("wrote", 4))
    expect_identical(m$token[m$node == "child"], c("Jane", "quickly", "book", "."))
})

test_that("no dependency matches give a data.frame with no rows", {
    skip_on_cran()
    skip_on_os("solaris")
    try_spacy_initialize()

    for (x in list(character(0), "Jane wrote the book.", c(a = "", b = NA))) {
        m <- spacy_extract_dependency_matches(x, list(PASSIVE = passive))
        expect_s3_class(m, "data.frame", exact = TRUE)
        expect_named(m, dependency_columns)
        expect_identical(nrow(m), 0L)
        expect_identical(unname(vapply(m, typeof, "")),
                         c("character", "integer", "character", "character",
                           "integer", "integer", "integer", "character"))
    }
})

test_that("spaCy's errors for dependency patterns are shown", {
    skip_on_cran()
    skip_on_os("solaris")
    try_spacy_initialize()

    run <- function(p) spacy_extract_dependency_matches(txt, list(P = p))
    bad <- passive; bad[[2]]$LEFT_ID <- "nothing"
    expect_error(run(bad), "spaCy could not match the patterns:.*E101")
    bad <- passive; bad[[2]]$REL_OP <- "??"
    expect_error(run(bad), "spaCy could not match the patterns:.*E1007")
    bad <- passive; bad[[2]]$REL_OP <- NULL
    expect_error(run(bad), "spaCy could not match the patterns:.*REL_OP")
    bad <- passive; bad[[2]]$RIGHT_ATTRS <- list(LOWR = "x")
    expect_error(run(bad), "spaCy could not match the patterns:.*LOWR")
})

test_that("dependency patterns need the parser, and warn about missing entities", {
    skip_on_cran()
    skip_on_os("solaris")
    try(spacy_finalize(), silent = TRUE)
    suppressMessages(spacy_initialize(entity = FALSE))
    on.exit(spacy_finalize())

    person <- list(WRITER = list(
        list(RIGHT_ID = "verb", RIGHT_ATTRS = list(LEMMA = "write")),
        list(LEFT_ID = "verb", REL_OP = ">", RIGHT_ID = "person",
             RIGHT_ATTRS = list(ENT_TYPE = "PERSON"))))
    expect_warning(m <- spacy_extract_dependency_matches(txt, person),
                   "need entities \\(ENT_TYPE or ENT_IOB\\)")
    expect_identical(nrow(m), 0L)
    expect_silent(spacy_extract_dependency_matches(txt, list(PASSIVE = passive)))

    # nodes that ask for no dependency label: spaCy would find nothing
    # without a parse, instead of giving an error
    verb_noun <- list(VERB_NOUN = list(
        list(RIGHT_ID = "verb", RIGHT_ATTRS = list(POS = "VERB")),
        list(LEFT_ID = "verb", REL_OP = ">", RIGHT_ID = "noun",
             RIGHT_ATTRS = list(POS = "NOUN"))))
    verb <- list(VERB = verb_noun$VERB_NOUN[1])
    x <- c(a = "", b = "Jane wrote the book.")
    expect_identical(spacy_extract_dependency_matches(x, verb_noun)$token,
                     c("wrote", "book"))

    spacyr:::spacyr_env$nlp$disable_pipe("parser")
    no_parse <- "spaCy could not match the patterns:.*Document 'b' has no dependency parse"
    expect_error(spacy_extract_dependency_matches(x, verb_noun), no_parse)
    expect_error(spacy_extract_dependency_matches(x, list(PASSIVE = passive)), no_parse)
    expect_error(spacy_extract_dependency_matches(x, c(verb, verb_noun)), no_parse)
    # an empty document has nothing to parse
    expect_identical(nrow(spacy_extract_dependency_matches(x["a"], verb_noun)), 0L)
    # a single node has no relations, and needs no parse; its sentence is
    # then unknown
    m <- spacy_extract_dependency_matches(x, verb)
    expect_identical(m$token, "wrote")
    expect_identical(m$start_id, 2L)
    expect_identical(m$sentence_id, NA_integer_)
    expect_identical(m$token_id, NA_integer_)

    spacy_finalize()
    suppressMessages(spacy_initialize())
    expect_silent(m <- spacy_extract_dependency_matches(txt, person))
    expect_identical(m$token, c("wrote", "Jane"))
})

test_that("documents left out by the pipeline are reported for dependency matches", {
    skip_on_cran()
    skip_on_os("solaris")
    try(spacy_finalize(), silent = TRUE)
    try_spacy_initialize()
    components <- reticulate::import_from_path("spacyr_test_components",
                                               path = test_path("python"))
    nlp <- spacyr:::spacyr_env$nlp
    nlp$add_pipe("spacyr_test_fail_on_bad", last = TRUE)
    components$skip_errors(nlp)
    on.exit(spacy_finalize())

    x <- c(bad = "Bad books were written.", good = "Good books were written.")
    expect_warning(m <- spacy_extract_dependency_matches(x, list(PASSIVE = passive)),
                   "did not return 1 document, which is left out of the output: bad")
    expect_identical(unique(m$doc_id), "good")
    expect_identical(m$token, c("written", "books", "were"))
})
