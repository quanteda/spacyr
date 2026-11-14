source("utils.R")

rules <- c(ORG = "Acme Corp", PERSON = "Jane Smith", gadget = "Widget")
txt <- c(d1 = "Jane Smith spoke at Acme Corp about the Widget.",
         d2 = "Acme Corp is hiring.")

# a pipeline whose only entities are those of the rules
with_rules <- function(code) {
    try(spacy_finalize(), silent = TRUE)
    if (methods::is(try(suppressMessages(
        spacy_initialize(entity = FALSE, entity_patterns = rules))), "try-error"))
        testthat::skip("Can't initialize")
    on.exit(spacy_finalize(), add = TRUE)
    force(code)
}

# the entities that are marked, in order, named by their labels
marked <- function(html) {
    m <- regmatches(html, gregexpr(
        "(?s)<mark class=\"entity\"[^>]*>\\s*(.*?)\\s*<span[^>]*>(.*?)</span>",
        html, perl = TRUE))[[1]]
    stats::setNames(sub("(?s)^<mark[^>]*>\\s*(.*?)\\s*<span.*$", "\\1", m, perl = TRUE),
                    sub("(?s)^.*<span[^>]*>(.*?)</span>$", "\\1", m, perl = TRUE))
}

# the text of each document, with tags and the labels of entities removed,
# and without whitespace, which the markup adds around entities
squash <- function(x) gsub("\\s+", "", x)
plain <- function(html) {
    docs <- regmatches(html, gregexpr("(?s)<div class=\"entities\".*?</div>", html,
                                      perl = TRUE))[[1]]
    docs <- gsub("(?s)<span[^>]*>.*?</span>", "", docs, perl = TRUE)
    squash(gsub("<[^>]+>", "", docs))
}

# the entities of texts, parsed with the positions of their tokens
viz <- function(x, ...) entity_visualize(spacy_parse(x, offsets = TRUE), ...)

# a parse made by hand, which needs no spaCy
by_hand <- structure(
    data.frame(doc_id = "d1", sentence_id = 1L, token_id = 1:2,
               token = c("Acme", "Corp"), entity = c("ORG_B", "ORG_I"),
               stringsAsFactors = FALSE),
    class = c("spacyr_parsed", "data.frame"))

test_that("entity_visualize checks its arguments before starting spaCy", {
    try(spacy_finalize(), silent = TRUE)
    expect_error(entity_visualize(by_hand, labels = 1),
                 "labels must be NULL or a character")
    expect_error(entity_visualize(by_hand, labels = NA_character_), "labels must be")
    for (bad in list(1, c("red", "blue"), c(ORG = NA_character_),
                     stats::setNames(c("red", "blue"), c("ORG", ""))))
        expect_error(entity_visualize(by_hand, colors = bad), "colors must be NULL or")
    expect_error(entity_visualize(by_hand, colors = c(ORG = "red", org = "blue")),
                 "more than one colour for a label")
    for (bad in list(NA, "yes", c(TRUE, FALSE), 1))
        expect_error(entity_visualize(by_hand, view = bad),
                     "view must be TRUE or FALSE")

    expect_error(entity_visualize(by_hand[, c("doc_id", "token")]),
                 "x has no column entity: rerun spacy_parse\\(\\) with entity = TRUE")
    expect_error(entity_visualize(by_hand[, c("doc_id", "entity")]),
                 "x has no column token")
    expect_null(getOption("spacy_initialized"))
})

test_that("entity_visualize takes only parsed documents", {
    try(spacy_finalize(), silent = TRUE)
    for (x in list("Acme Corp is hiring.",
                   data.frame(doc_id = "d1", text = "Acme Corp is hiring."),
                   list("a"), NULL))
        expect_error(entity_visualize(x),
                     "x must be the output of spacy_parse\\(\\): for texts, use entity_visualize\\(spacy_parse\\(x, offsets = TRUE\\)\\)")
    expect_error(entity_visualize(by_hand, n_process = 2), "unused argument")
    expect_null(getOption("spacy_initialized"))
})

test_that("entity_visualize marks the entities of documents in order", {
    skip_on_cran()
    skip_on_os("solaris")
    with_rules({
        expect_silent(html <- viz(txt))
        expect_type(html, "character")
        expect_length(html, 1)
        expect_identical(
            marked(html),
            c(PERSON = "Jane Smith", ORG = "Acme Corp", gadget = "Widget",
              ORG = "Acme Corp"))
        expect_identical(plain(html), squash(unname(txt)))
        # a fragment, not a page
        expect_false(grepl("<html|<body", html))

        # one document, and a corpus that was parsed
        expect_identical(marked(viz(txt[2])), c(ORG = "Acme Corp"))
        expect_identical(viz(unname(txt)), html)
        expect_identical(
            viz(data.frame(doc_id = names(txt), text = txt)), html)
    })
})

test_that("labels chooses the labels to mark and keeps the rest of the text", {
    skip_on_cran()
    skip_on_os("solaris")
    with_rules({
        html <- viz(txt, labels = c("PERSON", "ORG"))
        expect_identical(marked(html), c(PERSON = "Jane Smith", ORG = "Acme Corp",
                                         ORG = "Acme Corp"))
        expect_identical(plain(html), plain(viz(txt)))
        # one label, in another case, and a label that only a rule has
        expect_identical(marked(viz(txt, labels = "org")),
                         c(ORG = "Acme Corp", ORG = "Acme Corp"))
        expect_identical(marked(viz(txt, labels = "gadget")),
                         c(gadget = "Widget"))
        # a document with none of the labels is still there, as is every
        # document when no label is chosen
        html <- viz(txt, labels = "PERSON")
        expect_identical(plain(html), plain(viz(txt)))
        for (none in list(character(0), "NOSUCHLABEL")) {
            expect_silent(html <- viz(txt, labels = none))
            expect_length(marked(html), 0)
            expect_identical(plain(html), squash(unname(txt)))
        }
    })
})

test_that("colors sets the colors of labels", {
    skip_on_cran()
    skip_on_os("solaris")
    with_rules({
        background <- function(html)
            regmatches(html, gregexpr("background: [^;]+", html))[[1]]
        expect_identical(
            background(viz(txt[1], colors = c(org = "#123456",
                                                           gadget = "gold"))),
            c(background(viz(txt[1]))[1],
              "background: #123456", "background: gold"))
        expect_identical(viz(txt, colors = character(0)),
                         viz(txt))
    })
})

test_that("entity_visualize handles special characters and empty documents", {
    skip_on_cran()
    skip_on_os("solaris")
    with_rules({
        x <- c(a = "Acme Corp <b>café</b> & 東京.",
               b = "No entities here.", c = NA, d = "")
        expect_silent(html <- viz(x))
        expect_identical(Encoding(html), "UTF-8")
        expect_identical(marked(html), c(ORG = "Acme Corp"))
        expect_true(grepl("&lt;b&gt;café&lt;/b&gt; &amp; 東京.", html,
                          fixed = TRUE))
        expect_false(grepl("<b>", html, fixed = TRUE))
        expect_identical(plain(html)[2:4], c("Noentitieshere.", "", ""))

        expect_identical(viz(character(0)), "")
        expect_identical(viz(character(0), view = FALSE, labels = "ORG"), "")
    })
})

test_that("view = TRUE opens a UTF-8 page and returns the HTML invisibly", {
    skip_on_cran()
    skip_on_os("solaris")
    with_rules({
        # the page as it is when the browser is given it
        opened <- page <- NULL
        old <- options(browser = function(url) {
            opened <<- url
            page <<- paste(readLines(url, encoding = "UTF-8", warn = FALSE),
                           collapse = "\n")
        })
        on.exit(options(old), add = TRUE)
        x <- c(a = "Acme Corp in 東京.")
        html <- viz(x)
        expect_invisible(viewed <- viz(x, view = TRUE))
        expect_identical(viewed, html)
        expect_true(file.exists(opened))
        on.exit(unlink(opened), add = TRUE)
        expect_true(grepl("<meta charset=\"utf-8\">", page, fixed = TRUE))
        expect_true(grepl(html, page, fixed = TRUE))
        expect_true(grepl("東京", page, fixed = TRUE))

        # nothing is opened without it
        opened <- NULL
        expect_visible(viz(x))
        expect_null(opened)
    })
})

test_that("labels and colours cannot add elements or attributes to the HTML", {
    skip_on_cran()
    skip_on_os("solaris")
    try(spacy_finalize(), silent = TRUE)
    label <- "<img src=x onerror=alert(1)>"
    if (methods::is(try(suppressMessages(spacy_initialize(
        entity = FALSE,
        entity_patterns = c(stats::setNames("Acme Corp", label), ORG = "Widget",
                            "R&D" = "Lab")))), "try-error"))
        testthat::skip("Can't initialize")
    on.exit(spacy_finalize(), add = TRUE)
    x <- "Acme Corp makes the Widget in the Lab."
    color <- "red\" onmouseover=\"alert(2)"

    # the elements of the HTML and the names of their attributes
    tags <- function(html)
        regmatches(html, gregexpr("<[^>]*>", html))[[1]]
    elements <- function(html)
        sort(unique(sub("^</?([A-Za-z0-9]*).*$", "\\1", tags(html))))
    attribute_names <- function(html) {
        inside <- gsub("\"[^\"]*\"", "\"\"", tags(html))
        sort(unique(unlist(regmatches(
            inside, gregexpr("[A-Za-z-]+(?==)", inside, perl = TRUE)))))
    }

    html <- viz(x, colors = stats::setNames(
        c(color, "gold", "pink"), c("ORG", tolower(label), "r&d")))
    expect_identical(elements(html), c("div", "mark", "span"))
    expect_identical(attribute_names(html), c("class", "style"))
    expect_false(grepl("<img", html, fixed = TRUE))
    # the label and the colour are there as text
    expect_true(grepl("&lt;img src=x onerror=alert(1)&gt;", html, fixed = TRUE))
    expect_true(grepl("background: red&quot; onmouseover=&quot;alert(2);", html,
                      fixed = TRUE))
    expect_true(grepl("R&amp;D</span>", html, fixed = TRUE))
    # colours and labels still match such labels, in any case
    expect_true(grepl("background: gold;", html, fixed = TRUE))
    expect_true(grepl("background: pink;", html, fixed = TRUE))
    expect_identical(marked(viz(x, labels = c(tolower(label), "r&d"))),
                     stats::setNames(c("Acme Corp", "Lab"),
                                     c("&lt;img src=x onerror=alert(1)&gt;",
                                       "R&amp;D")))
})

test_that("the documents of a parse are made from its tokens", {
    parsed <- structure(
        data.frame(doc_id = rep(c("d1", "d2"), c(6, 2)),
                   token = c("Jane", "Smith", ",", "Acme", "Corp", "!",
                             "café", "Acme"),
                   start = c(3L, 8L, 13L, 15L, 21L, 25L, 1L, 6L),
                   end = c(6L, 12L, 13L, 18L, 24L, 25L, 4L, 9L),
                   entity = c("PERSON_B", "PERSON_I", "", "ORG_B", "ORG_I", "",
                              "", "ORG_B"),
                   stringsAsFactors = FALSE),
        class = c("spacyr_parsed", "data.frame"))
    docs <- parsed_entity_docs(parsed)
    # spaced as in the text, without the whitespace before the first token
    expect_identical(docs[[1]]$text, "Jane Smith, Acme  Corp!")
    expect_identical(docs[[1]]$ents,
                     list(list(start = 0L, end = 10L, label = "PERSON"),
                          list(start = 12L, end = 22L, label = "ORG")))
    expect_identical(substring(docs[[1]]$text, c(1, 13), c(10, 22)),
                     c("Jane Smith", "Acme  Corp"))
    # positions count characters, not bytes
    expect_identical(docs[[2]], list(text = "café Acme", ents = list(
        list(start = 5L, end = 9L, label = "ORG"))))

    # without positions, a space between every two tokens
    docs <- parsed_entity_docs(parsed[, c("doc_id", "token", "entity")])
    expect_identical(docs[[1]]$text, "Jane Smith , Acme Corp !")
    expect_identical(docs[[1]]$ents,
                     list(list(start = 0L, end = 10L, label = "PERSON"),
                          list(start = 13L, end = 22L, label = "ORG")))

    # adjacent entities, and one whose first token was taken out
    tags <- parsed[c(2, 4, 5, 8), c("doc_id", "token", "entity")]
    tags$entity <- c("PERSON_I", "ORG_B", "ORG_B", "ORG_B")
    docs <- parsed_entity_docs(tags)
    expect_identical(docs[[1]]$text, "Smith Acme Corp")
    expect_identical(vapply(docs[[1]]$ents, function(e) e$label, ""),
                     c("PERSON", "ORG", "ORG"))
    expect_identical(vapply(docs[[1]]$ents, function(e) e$end, 1L), c(5L, 10L, 15L))
})

test_that("the text of a parse is spaced as its tokens were, given their positions", {
    skip_on_cran()
    skip_on_os("solaris")
    with_rules({
        x <- c(txt, d3 = "", d4 = "Nothing (here), really.  Acme Corp didn't.")
        parsed <- spacy_parse(x, offsets = TRUE)
        expect_silent(html <- entity_visualize(parsed))
        expect_true(grepl(">Nothing (here), really.  \n<mark", html, fixed = TRUE))
        expect_true(grepl("\n didn't.</div>", html, fixed = TRUE))
        expect_true(grepl(" about the \n<mark", html, fixed = TRUE))
        expect_identical(plain(html), squash(unname(x)))

        # without them, a space between every two tokens, with a message
        # once in a session, and the same entities and tokens
        spacyr_env$told_offsets <- NULL
        parsed <- spacy_parse(x, pos = FALSE, lemma = FALSE)
        expect_message(spaced <- entity_visualize(parsed),
                       "spacy_parse\\(x, offsets = TRUE\\)")
        expect_silent(entity_visualize(parsed))
        expect_identical(marked(spaced), marked(html))
        expect_identical(plain(spaced), plain(html))
        expect_true(grepl(">Nothing ( here ) , really .", spaced, fixed = TRUE))
        expect_true(grepl("did n't .</div>", spaced, fixed = TRUE))

        # consolidated entities are single tokens
        expect_identical(
            marked(entity_visualize(entity_consolidate(parsed))),
            c(PERSON = "Jane_Smith", ORG = "Acme_Corp", gadget = "Widget",
              ORG = "Acme_Corp", ORG = "Acme_Corp"))

        # the rows of some documents, and of none, which give no message
        expect_identical(marked(entity_visualize(parsed[parsed$doc_id == "d2", ])),
                         c(ORG = "Acme Corp"))
        spacyr_env$told_offsets <- NULL
        expect_silent(none <- entity_visualize(parsed[0, ]))
        expect_identical(none, "")

        expect_error(entity_visualize(spacy_parse(x, entity = FALSE)),
                     "x has no column entity")
    })
})

test_that("entity_visualize starts spaCy when it is not running", {
    skip_on_cran()
    skip_on_os("solaris")
    with_rules({
        parsed <- spacy_parse(txt, offsets = TRUE)
        html <- entity_visualize(parsed)
        spacy_finalize()
        expect_identical(suppressMessages(entity_visualize(parsed)), html)
    })
})
