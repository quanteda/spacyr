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

test_that("entity_visualize checks its arguments before starting spaCy", {
    try(spacy_finalize(), silent = TRUE)
    expect_error(entity_visualize("a", ents = 1), "ents must be NULL or a character")
    expect_error(entity_visualize("a", ents = NA_character_), "ents must be")
    for (bad in list(1, c("red", "blue"), c(ORG = NA_character_),
                     stats::setNames(c("red", "blue"), c("ORG", ""))))
        expect_error(entity_visualize("a", colors = bad), "colors must be NULL or")
    expect_error(entity_visualize("a", colors = c(ORG = "red", org = "blue")),
                 "more than one colour for a label")
    for (bad in list(NA, "yes", c(TRUE, FALSE), 1))
        expect_error(entity_visualize("a", view = bad), "view must be TRUE or FALSE")
    expect_error(entity_visualize("a", n_process = 0), "n_process")
    expect_error(entity_visualize("a", batch_size = 0), "batch_size")
    expect_error(entity_visualize(data.frame(a = 1)), "TIF")
    expect_null(getOption("spacy_initialized"))
})

test_that("entity_visualize marks the entities of documents in order", {
    skip_on_cran()
    skip_on_os("solaris")
    with_rules({
        expect_silent(html <- entity_visualize(txt))
        expect_type(html, "character")
        expect_length(html, 1)
        expect_identical(
            marked(html),
            c(PERSON = "Jane Smith", ORG = "Acme Corp", gadget = "Widget",
              ORG = "Acme Corp"))
        expect_identical(plain(html), squash(unname(txt)))
        # a fragment, not a page
        expect_false(grepl("<html|<body", html))

        # one document, and the same from other forms of input
        expect_identical(marked(entity_visualize(txt[2])), c(ORG = "Acme Corp"))
        expect_identical(entity_visualize(unname(txt)), html)
        expect_identical(
            entity_visualize(data.frame(doc_id = names(txt), text = txt)), html)
        expect_identical(entity_visualize(txt, n_process = 2, batch_size = 1), html)
    })
})

test_that("entity_visualize takes a quanteda corpus", {
    skip_on_cran()
    skip_on_os("solaris")
    skip_if_not_installed("quanteda")
    with_rules({
        expect_identical(entity_visualize(quanteda::corpus(txt)),
                         entity_visualize(txt))
    })
})

test_that("ents chooses the labels to mark and keeps the rest of the text", {
    skip_on_cran()
    skip_on_os("solaris")
    with_rules({
        html <- entity_visualize(txt, ents = c("PERSON", "ORG"))
        expect_identical(marked(html), c(PERSON = "Jane Smith", ORG = "Acme Corp",
                                         ORG = "Acme Corp"))
        expect_identical(plain(html), plain(entity_visualize(txt)))
        # one label, in another case, and a label that only a rule has
        expect_identical(marked(entity_visualize(txt, ents = "org")),
                         c(ORG = "Acme Corp", ORG = "Acme Corp"))
        expect_identical(marked(entity_visualize(txt, ents = "gadget")),
                         c(gadget = "Widget"))
        # a document with none of the labels is still there, as is every
        # document when no label is chosen
        html <- entity_visualize(txt, ents = "PERSON")
        expect_identical(plain(html), plain(entity_visualize(txt)))
        for (none in list(character(0), "NOSUCHLABEL")) {
            expect_silent(html <- entity_visualize(txt, ents = none))
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
            background(entity_visualize(txt[1], colors = c(org = "#123456",
                                                           gadget = "gold"))),
            c(background(entity_visualize(txt[1]))[1],
              "background: #123456", "background: gold"))
        expect_identical(entity_visualize(txt, colors = character(0)),
                         entity_visualize(txt))
    })
})

test_that("entity_visualize handles special characters and empty documents", {
    skip_on_cran()
    skip_on_os("solaris")
    with_rules({
        x <- c(a = "Acme Corp <b>café</b> & 東京.",
               b = "No entities here.", c = NA, d = "")
        expect_silent(html <- entity_visualize(x))
        expect_identical(Encoding(html), "UTF-8")
        expect_identical(marked(html), c(ORG = "Acme Corp"))
        expect_true(grepl("&lt;b&gt;café&lt;/b&gt; &amp; 東京.", html,
                          fixed = TRUE))
        expect_false(grepl("<b>", html, fixed = TRUE))
        expect_identical(plain(html)[2:4], c("Noentitieshere.", "", ""))

        expect_identical(entity_visualize(character(0)), "")
        expect_identical(entity_visualize(character(0), view = FALSE,
                                          ents = "ORG"), "")
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
        html <- entity_visualize(x)
        expect_invisible(viewed <- entity_visualize(x, view = TRUE))
        expect_identical(viewed, html)
        expect_true(file.exists(opened))
        on.exit(unlink(opened), add = TRUE)
        expect_true(grepl("<meta charset=\"utf-8\">", page, fixed = TRUE))
        expect_true(grepl(html, page, fixed = TRUE))
        expect_true(grepl("東京", page, fixed = TRUE))

        # nothing is opened without it
        opened <- NULL
        expect_visible(entity_visualize(x))
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

    html <- entity_visualize(x, colors = stats::setNames(
        c(color, "gold", "pink"), c("ORG", tolower(label), "r&d")))
    expect_identical(elements(html), c("div", "mark", "span"))
    expect_identical(attribute_names(html), c("class", "style"))
    expect_false(grepl("<img", html, fixed = TRUE))
    # the label and the colour are there as text
    expect_true(grepl("&lt;img src=x onerror=alert(1)&gt;", html, fixed = TRUE))
    expect_true(grepl("background: red&quot; onmouseover=&quot;alert(2);", html,
                      fixed = TRUE))
    expect_true(grepl("R&amp;D</span>", html, fixed = TRUE))
    # colours and ents still match such labels, in any case
    expect_true(grepl("background: gold;", html, fixed = TRUE))
    expect_true(grepl("background: pink;", html, fixed = TRUE))
    expect_identical(marked(entity_visualize(x, ents = c(tolower(label), "r&d"))),
                     stats::setNames(c("Acme Corp", "Lab"),
                                     c("&lt;img src=x onerror=alert(1)&gt;",
                                       "R&amp;D")))
})
