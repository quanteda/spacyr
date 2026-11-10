# as_entity_patterns(), entity_patterns_read() and entity_patterns_write()
# need no Python, so these tests also run on CRAN.

titles <- c("dr", "dr.", "prof", "prof.")
title_rule <- list(label = "PERSON",
                   pattern = list(list(LOWER = list(IN = titles)),
                                  list(ENT_TYPE = "PERSON", OP = "+")))
# the same, as stored: IN values become a list
title_stored <- list(list(LOWER = list(IN = as.list(titles))),
                     list(ENT_TYPE = "PERSON", OP = "+"))

test_that("phrases take their labels from names or from label", {
  x <- as_entity_patterns(c(ORG = "Acme Widgets", GPE = "San Francisco"))
  expect_s3_class(x, c("spacyr_entity_patterns", "data.frame"), exact = TRUE)
  expect_named(x, c("label", "pattern", "id", "case_insensitive"))
  expect_identical(x$label, c("ORG", "GPE"))
  expect_identical(x$pattern, list("Acme Widgets", "San Francisco"))
  expect_identical(x$id, c(NA_character_, NA_character_))
  expect_identical(x$case_insensitive, c(FALSE, FALSE))
  expect_identical(row.names(x), c("1", "2"))

  y <- as_entity_patterns(c("Acme Widgets", "Globex"), label = "ORG", id = c("a", "g"),
                          case_insensitive = TRUE)
  expect_identical(y$label, c("ORG", "ORG"))
  expect_identical(y$id, c("a", "g"))
  expect_identical(y$case_insensitive, c(TRUE, TRUE))
  # label wins over names
  expect_identical(as_entity_patterns(c(GPE = "Globex"), label = "ORG")$label, "ORG")
})

test_that("phrases without labels, and bad phrases, are errors", {
  expect_error(as_entity_patterns("Acme"), "Every phrase needs a label")
  expect_error(as_entity_patterns(c(ORG = "Acme", "Globex")), "Every phrase needs a label")
  expect_error(as_entity_patterns(c("a", "b", "c"), label = c("X", "Y")),
               "label must be a character vector of length 1 or 3")
  expect_error(as_entity_patterns(c(ORG = NA_character_)), "Pattern 1 is not a single, non-empty phrase")
  expect_error(as_entity_patterns(c(ORG = "a", ORG = " ")),
               "Pattern 2 is not a single, non-empty phrase")
  expect_error(as_entity_patterns("a", label = NA_character_), "Pattern 1 has a missing or empty label")
  expect_error(as_entity_patterns("a", label = "ORG", case_insensitive = NA),
               "case_insensitive must be TRUE or FALSE")
})

test_that("empty input gives an empty object", {
  for (x in list(character(0), list())) {
    p <- as_entity_patterns(x)
    expect_s3_class(p, "spacyr_entity_patterns")
    expect_identical(nrow(p), 0L)
  }
  expect_output(print(as_entity_patterns(character(0))), "^Entity patterns: 0 patterns$")
})

test_that("a list of patterns, or a single pattern, is converted", {
  x <- as_entity_patterns(list(title_rule, list(label = "ORG", pattern = "Acme", id = "acme")))
  expect_identical(x$label, c("PERSON", "ORG"))
  expect_identical(x$pattern[[1]], title_stored)
  expect_identical(x$pattern[[2]], "Acme")
  expect_identical(x$id, c(NA, "acme"))
  expect_identical(x$case_insensitive, c(NA, FALSE))
  expect_identical(as_entity_patterns(title_rule), as_entity_patterns(list(title_rule)))
})

test_that("case_insensitive applies to phrases, and a pattern's own setting wins", {
  x <- as_entity_patterns(list(title_rule,
                               list(label = "ORG", pattern = "acme"),
                               list(label = "ORG", pattern = "globex", case_insensitive = FALSE)),
                          case_insensitive = TRUE)
  expect_identical(x$case_insensitive, c(NA, TRUE, FALSE))
})

test_that("badly formed list patterns are errors", {
  expect_error(as_entity_patterns(list(list(label = "ORG"))),
               "Pattern 1 is not a list with the elements label and pattern")
  expect_error(as_entity_patterns(list("Acme")),
               "Pattern 1 is not a list with the elements label and pattern")
  expect_error(as_entity_patterns(list(list(label = "ORG", pattern = "a", foo = 1))),
               "Pattern 1 has unknown elements: foo")
  expect_error(as_entity_patterns(list(list(label = c("A", "B"), pattern = "a"))),
               "The label of pattern 1 is not a single string")
  expect_error(as_entity_patterns(list(list(label = "A", pattern = "a", id = 1))),
               "The id of pattern 1 is not a single string")
  expect_error(as_entity_patterns(list(list(label = "A", pattern = "a", case_insensitive = "yes"))),
               "The case_insensitive element of pattern 1 is not TRUE or FALSE")
  expect_error(as_entity_patterns(list(list(label = "A", pattern = list()))),
               "Pattern 1 is neither a phrase nor a list of token patterns")
  expect_error(as_entity_patterns(list(list(label = "A", pattern = 3))),
               "Pattern 1 is neither a phrase nor a list of token patterns")
  # a single token pattern, not wrapped in a list of tokens
  expect_error(as_entity_patterns(list(list(label = "A", pattern = list(LOWER = "dr")))),
               "Pattern 1 is a single token pattern; wrap it in list\\(\\)")
  expect_error(as_entity_patterns(list(list(label = "A", pattern = list("dr")))),
               "Token 1 of pattern 1 is not a named list of attributes")
  expect_error(as_entity_patterns(list(list(label = "A", pattern = list(list(LOWER = "a"), list("b"))))),
               "Token 2 of pattern 1 is not a named list of attributes")
})

test_that("IN and NOT_IN values become lists, and whole numbers integers", {
  x <- as_entity_patterns(list(label = "X", pattern = list(
    list(LOWER = list(IN = "dr")),
    list(LOWER = list(NOT_IN = c("a", "b"))),
    list(LENGTH = 3, IS_TITLE = TRUE),
    list(LENGTH = list(IN = c(3, 4))),
    list(LENGTH = list(`>=` = 2)),
    list(LIKE_NUM = TRUE, OP = "?"),
    list(OP = "*")
  )))
  p <- x$pattern[[1]]
  expect_identical(p[[1]], list(LOWER = list(IN = list("dr"))))
  expect_identical(p[[2]], list(LOWER = list(NOT_IN = list("a", "b"))))
  expect_identical(p[[3]], list(LENGTH = 3L, IS_TITLE = TRUE))
  expect_identical(p[[4]], list(LENGTH = list(IN = list(3L, 4L))))
  expect_identical(p[[5]], list(LENGTH = list(`>=` = 2L)))
  expect_identical(p[[6]], list(LIKE_NUM = TRUE, OP = "?"))
  expect_identical(p[[7]], list(OP = "*"))
  # other numbers are kept
  y <- as_entity_patterns(list(label = "X", pattern = list(list(LENGTH = 2.5))))
  expect_identical(y$pattern[[1]][[1]]$LENGTH, 2.5)
})

test_that("an empty token pattern, which matches any token, is kept", {
  x <- as_entity_patterns(list(label = "X", pattern = list(list(LOWER = "dr"), list())))
  expect_identical(x$pattern[[1]][[2]], structure(list(), names = character(0)))
})

test_that("a data.frame of patterns is converted", {
  df <- data.frame(label = c("ORG", "GPE"), pattern = c("Acme", "Paris"),
                   stringsAsFactors = TRUE)
  x <- as_entity_patterns(df)
  expect_identical(x$label, c("ORG", "GPE"))
  expect_identical(x$pattern, list("Acme", "Paris"))
  expect_identical(x$case_insensitive, c(FALSE, FALSE))
  expect_identical(as_entity_patterns(df, case_insensitive = TRUE)$case_insensitive,
                   c(TRUE, TRUE))

  df2 <- data.frame(label = c("PERSON", "ORG"), id = c(NA, "a"),
                    case_insensitive = c(NA, TRUE))
  df2$pattern <- list(title_rule$pattern, "acme")
  y <- as_entity_patterns(df2)
  expect_identical(y$pattern[[1]], title_stored)
  expect_identical(y$id, c(NA, "a"))
  expect_identical(y$case_insensitive, c(NA, TRUE))

  expect_error(as_entity_patterns(data.frame(label = "ORG")),
               "x needs the columns label and pattern; missing: pattern")
  expect_error(as_entity_patterns(data.frame(label = "ORG", pattern = 1)),
               "The pattern column must be a character or list column")
  expect_error(as_entity_patterns(data.frame(label = "ORG", pattern = "a",
                                             case_insensitive = "yes")),
               "The case_insensitive column must be logical")
})

test_that("other objects are errors", {
  expect_error(as_entity_patterns(1:3),
               "as_entity_patterns\\(\\) cannot convert an object of class integer")
})

test_that("duplicates are removed, and an object is returned as it is", {
  x <- as_entity_patterns(c(ORG = "Acme", ORG = "Acme", GPE = "Acme"))
  expect_identical(x$label, c("ORG", "GPE"))
  expect_identical(row.names(x), c("1", "2"))
  # differing case_insensitive or id are different patterns
  expect_identical(nrow(c(as_entity_patterns(c(ORG = "Acme")),
                          as_entity_patterns(c(ORG = "Acme"), case_insensitive = TRUE),
                          as_entity_patterns(c(ORG = "Acme"), id = "a"))), 3L)
  expect_identical(as_entity_patterns(x), x)
})

test_that("c() combines patterns, converting other inputs", {
  x <- c(as_entity_patterns(title_rule), as_entity_patterns(c(ORG = "Acme")),
         c(GPE = "Paris"), as_entity_patterns(title_rule))
  expect_s3_class(x, "spacyr_entity_patterns")
  expect_identical(x$label, c("PERSON", "ORG", "GPE"))
  expect_identical(x$case_insensitive, c(NA, FALSE, FALSE))
})

test_that("as.list() gives spaCy's structure, and as.data.frame() drops the class", {
  x <- as_entity_patterns(list(title_rule,
                               list(label = "ORG", pattern = "acme", id = "a",
                                    case_insensitive = TRUE),
                               list(label = "ORG", pattern = "Globex")))
  expect_identical(as.list(x), list(
    list(label = "PERSON", pattern = title_stored),
    list(label = "ORG", pattern = "acme", id = "a", case_insensitive = TRUE),
    list(label = "ORG", pattern = "Globex")
  ))
  expect_identical(class(as.data.frame(x)), "data.frame")
})

test_that("subsetting keeps the class", {
  x <- as_entity_patterns(c(ORG = "Acme", GPE = "Paris"))
  expect_s3_class(x[x$label == "ORG", ], "spacyr_entity_patterns")
})

test_that("print() shows counts and readable patterns", {
  x <- c(as_entity_patterns(title_rule),
         as_entity_patterns(c(ORG = "acme"), id = "a", case_insensitive = TRUE),
         as_entity_patterns(list(label = "X", pattern = list(
           list(LOWER = list(REGEX = "^dr.*$")), list(LENGTH = list(`>=` = 2)),
           list(IS_TITLE = TRUE), list(OP = "*")))))
  out <- capture.output(print(x))
  expect_identical(out, c(
    "Entity patterns: 3 patterns (PERSON: 1, ORG: 1, X: 1)",
    "  PERSON  [LOWER in (dr, dr., prof, prof.)] [ENT_TYPE = PERSON]+",
    "  ORG     \"acme\" (any case) [id: a]",
    "  X       [LOWER ~ /^dr.*$/] [LENGTH >= 2] [IS_TITLE = true] []*"
  ))
  out <- capture.output(print(as_entity_patterns(c("a", "b", "c"), label = "ORG"), n = 2))
  expect_identical(out[c(1, 4)], c("Entity patterns: 3 patterns (ORG: 3)", "  ... and 1 more"))
  expect_identical(capture.output(print(as_entity_patterns(c(ORG = "a"))))[1],
                   "Entity patterns: 1 pattern (ORG: 1)")
})

test_that("patterns written and read back are identical", {
  skip_if_not_installed("jsonlite")
  x <- c(as_entity_patterns(title_rule),
         as_entity_patterns(c(ORG = "Acme Widgets"), id = "acme"),
         as_entity_patterns(c(ORG = "globex"), case_insensitive = TRUE),
         as_entity_patterns(c(GPE = "Zürich")),
         as_entity_patterns(list(label = "X", pattern = list(
           list(LOWER = list(IN = "dr")), list(LENGTH = 3L), list(),
           list(LENGTH = 2.5)))))
  file <- tempfile(fileext = ".jsonl")
  on.exit(unlink(file), add = TRUE)
  expect_identical(entity_patterns_write(x, file), file)
  lines <- readLines(file, encoding = "UTF-8")
  expect_length(lines, 5)
  expect_identical(lines[1], paste0('{"label":"PERSON","pattern":[{"LOWER":{"IN":',
                                    '["dr","dr.","prof","prof."]}},',
                                    '{"ENT_TYPE":"PERSON","OP":"+"}]}'))
  expect_identical(lines[3], '{"label":"ORG","pattern":"globex","case_insensitive":true}')
  expect_identical(lines[5], paste0('{"label":"X","pattern":[{"LOWER":{"IN":["dr"]}},',
                                    '{"LENGTH":3},{},{"LENGTH":2.5}]}'))
  expect_identical(entity_patterns_read(file), x)
  # other inputs are converted first
  entity_patterns_write(c(ORG = "Acme"), file)
  expect_identical(readLines(file), '{"label":"ORG","pattern":"Acme"}')
})

test_that("JSON arrays and spaCy's JSONL files are read", {
  skip_if_not_installed("jsonlite")
  jsonl <- tempfile(fileext = ".jsonl")
  on.exit(unlink(jsonl), add = TRUE)
  writeLines(c('{"label": "ORG", "pattern": "Apple", "id": "apple"}', "",
               '{"label": "PERSON", "pattern": [{"LOWER": "dr"}, {"ENT_TYPE": "PERSON", "OP": "+"}]}'),
             jsonl)
  x <- entity_patterns_read(jsonl)
  expect_identical(x$label, c("ORG", "PERSON"))
  expect_identical(x$id, c("apple", NA))
  expect_identical(x$pattern[[2]], list(list(LOWER = "dr"), list(ENT_TYPE = "PERSON", OP = "+")))
  expect_identical(entity_patterns_read(jsonl, case_insensitive = TRUE)$case_insensitive,
                   c(TRUE, NA))

  json <- tempfile(fileext = ".json")
  on.exit(unlink(json), add = TRUE)
  writeLines(c("[", '  {"label": "ORG", "pattern": "Apple", "id": "apple"},',
               '  {"label": "PERSON", "pattern": [{"LOWER": "dr"}, {"ENT_TYPE": "PERSON", "OP": "+"}]}',
               "]"), json)
  expect_identical(entity_patterns_read(json), x)
  writeLines('{"label": "ORG", "pattern": "Apple"}', json)
  expect_identical(entity_patterns_read(json)$label, "ORG")
  writeLines('{"a": 1}', json)
  expect_error(entity_patterns_read(json), "does not hold a JSON array of patterns")
  writeLines("[{]", json)
  expect_error(entity_patterns_read(json), "is not valid JSON")
  writeLines(c('{"label": "ORG", "pattern": "Apple"}', "{oops"), jsonl)
  expect_error(entity_patterns_read(jsonl), "Line 2 of .* is not valid JSON")
  writeLines('{"label": "ORG", "pattern": "Apple"}', jsonl)
  expect_warning(entity_patterns_read(jsonl, label = "ORG"),
                 "label is used only for .txt files")
})

test_that("text files are read as phrases with one label", {
  txt <- tempfile(fileext = ".txt")
  on.exit(unlink(txt), add = TRUE)
  writeLines(c("Acme Widgets", "", "Globex", "  "), txt)
  x <- entity_patterns_read(txt, label = "ORG")
  expect_identical(x$pattern, list("Acme Widgets", "Globex"))
  expect_identical(x$label, c("ORG", "ORG"))
  expect_identical(entity_patterns_read(txt, label = "ORG", case_insensitive = TRUE)$case_insensitive,
                   c(TRUE, TRUE))
  expect_error(entity_patterns_read(txt), "Reading phrases from a .txt file needs a label")
})

test_that("bad file arguments are errors", {
  expect_error(entity_patterns_read("no-such-file.jsonl"), "File not found: no-such-file.jsonl")
  expect_error(entity_patterns_read(c("a", "b")), "file must be a single file path")
  csv <- tempfile(fileext = ".csv")
  on.exit(unlink(csv), add = TRUE)
  writeLines("x", csv)
  expect_error(entity_patterns_read(csv), "file must have the extension .jsonl, .json or .txt")
  expect_error(entity_patterns_write(c(ORG = "a"), NA_character_), "file must be a single file path")
})

test_that("IN and NOT_IN values lose their names, and lowercase operators are lists too", {
  x <- as_entity_patterns(list(label = "X", pattern = list(
    list(LOWER = list(IN = c(first = "apple", second = "pear"))),
    list(LOWER = list(`in` = "apple")),
    list(LOWER = list(not_in = list(a = "b")))
  )))
  p <- x$pattern[[1]]
  expect_identical(p[[1]], list(LOWER = list(IN = list("apple", "pear"))))
  expect_identical(p[[2]], list(LOWER = list(`in` = list("apple"))))
  expect_identical(p[[3]], list(LOWER = list(not_in = list("b"))))
  skip_if_not_installed("jsonlite")
  file <- tempfile(fileext = ".jsonl")
  on.exit(unlink(file), add = TRUE)
  entity_patterns_write(x, file)
  expect_identical(readLines(file), paste0(
    '{"label":"X","pattern":[{"LOWER":{"IN":["apple","pear"]}},',
    '{"LOWER":{"in":["apple"]}},{"LOWER":{"not_in":["b"]}}]}'))
  expect_identical(entity_patterns_read(file), x)
})

test_that("entity_patterns_write() needs a .jsonl file, and leaves other files alone", {
  skip_if_not_installed("jsonlite")
  for (ext in c(".json", ".txt", "")) {
    file <- tempfile(fileext = ext)
    writeLines("keep", file)
    expect_error(entity_patterns_write(c(ORG = "a", GPE = "b"), file),
                 "file must have the extension .jsonl")
    expect_identical(readLines(file), "keep")
    unlink(file)
  }
})

test_that("an edited object is checked again before it is used or written", {
  x <- as_entity_patterns(c(ORG = "Acme", GPE = "Paris"))
  y <- x
  y$pattern <- NULL
  expect_error(as_entity_patterns(y), "x is missing the columns: pattern")
  y <- x
  y$id <- NULL
  expect_error(as_entity_patterns(y), "x is missing the columns: id")
  y <- x
  y$label <- c(1, 2)
  expect_error(as_entity_patterns(y), "x has columns of the wrong type")
  y <- x
  y$pattern[[2]] <- ""
  expect_error(as_entity_patterns(y), "Pattern 2 is not a single, non-empty phrase")
  # edits that leave valid patterns are normalized again
  y <- x
  y$pattern[[1]] <- list(list(LOWER = list(IN = "acme")))
  expect_identical(as_entity_patterns(y)$pattern[[1]],
                   list(list(LOWER = list(IN = list("acme")))))
  expect_identical(as_entity_patterns(y)$case_insensitive, c(NA, FALSE))
  expect_error(c(x, y[, c("label", "id")]), "x is missing the columns")

  skip_if_not_installed("jsonlite")
  file <- tempfile(fileext = ".jsonl")
  on.exit(unlink(file), add = TRUE)
  entity_patterns_write(x, file)
  before <- readLines(file)
  y <- x
  y$pattern <- NULL
  expect_error(entity_patterns_write(y, file), "x is missing the columns: pattern")
  expect_identical(readLines(file), before)
})

test_that("c() ignores its own arguments and the names of its arguments", {
  x <- as_entity_patterns(c(ORG = "Acme"))
  y <- as_entity_patterns(c(GPE = "Paris"))
  expect_identical(c(x, y, use.names = FALSE), c(x, y))
  expect_identical(c(x, y, recursive = TRUE), c(x, y))
  z <- do.call(c, list(companies = x, places = y))
  expect_identical(z, c(x, y))
  expect_null(names(z$pattern))
  skip_if_not_installed("jsonlite")
  file <- tempfile(fileext = ".jsonl")
  on.exit(unlink(file), add = TRUE)
  entity_patterns_write(z, file)
  expect_identical(entity_patterns_read(file), z)
})

test_that("names on the input do not reach the pattern column", {
  df <- data.frame(label = "ORG")
  df$pattern <- list(a = "Acme")
  expect_null(names(as_entity_patterns(df)$pattern))
  expect_null(names(as_entity_patterns(list(a = list(label = "ORG", pattern = "Acme")))$pattern))
})

test_that("a file named after an extension, with no dot, has no extension", {
  dir <- tempfile()
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  for (name in c("jsonl", "json", "txt", "jsonl.")) {
    file <- file.path(dir, name)
    writeLines("keep", file)
    expect_error(entity_patterns_read(file, label = "ORG"),
                 "file must have the extension .jsonl, .json or .txt")
    expect_error(entity_patterns_write(c(ORG = "a"), file),
                 "file must have the extension .jsonl")
    expect_identical(readLines(file), "keep")
  }
  expect_identical(spacyr:::file_extension(c("a.JSONL")), "jsonl")
  expect_identical(spacyr:::file_extension("dir.jsonl/patterns"), "")
  expect_identical(spacyr:::file_extension("a.b.jsonl"), "jsonl")
})

test_that("glob_to_regex anchors globs and escapes other characters", {
    expect_identical(glob_to_regex("dr*"), "^dr.*$")
    expect_identical(glob_to_regex("col?r"), "^col.r$")
    expect_identical(glob_to_regex("u.s.*"), "^u\\.s\\..*$")
    expect_identical(glob_to_regex("a+b(c)[d]{e}|^$"),
                     "^a\\+b\\(c\\)\\[d\\]\\{e\\}\\|\\^\\$$")
    expect_identical(glob_to_regex("x\\y"), "^x\\\\y$")
    for (g in c("dr*", "col?r", "u.s.*", "a+b(c)"))
        expect_true(grepl(glob_to_regex(g), sub("*", "zz", sub("?", "o", g, fixed = TRUE),
                                                 fixed = TRUE)))
})

test_that("a quanteda dictionary becomes patterns labelled by its top-level keys", {
    skip_if_not_installed("quanteda")
    d <- quanteda::dictionary(list(
        ORG = c("Acme Widgets", "globex*"),
        PERSON = list(titled = "dr * who", plain = "jane smith")))
    p <- as_entity_patterns(d)
    expect_s3_class(p, "spacyr_entity_patterns")
    expect_identical(p$label, c("ORG", "ORG", "PERSON", "PERSON"))
    # quanteda lowercases dictionary values by default
    expect_identical(p$pattern[[1]], "acme widgets")
    expect_identical(p$pattern[[2]], list(list(LOWER = list(REGEX = "^globex.*$"))))
    expect_identical(p$pattern[[3]], list(list(LOWER = "dr"),
                                          list(LOWER = list(REGEX = "^.*$")),
                                          list(LOWER = "who")))
    expect_identical(p$pattern[[4]], "jane smith")
    expect_identical(p$case_insensitive, c(TRUE, NA, NA, TRUE))
})

test_that("dictionary valuetype and case_insensitive are respected", {
    skip_if_not_installed("quanteda")
    d <- quanteda::dictionary(list(ORG = c("Acme*", "Big Co")), tolower = FALSE)
    exact <- as_entity_patterns(d, case_insensitive = FALSE)
    expect_identical(exact$pattern[[1]], list(list(ORTH = list(REGEX = "^Acme.*$"))))
    expect_identical(exact$case_insensitive, c(NA, FALSE))

    fixed <- as_entity_patterns(d, valuetype = "fixed")
    expect_identical(fixed$pattern, list("Acme*", "Big Co"))
    expect_identical(fixed$case_insensitive, c(TRUE, TRUE))

    rx <- as_entity_patterns(quanteda::dictionary(list(ORG = "^ac.+ wid"),
                                                  tolower = FALSE),
                             valuetype = "regex")
    expect_identical(rx$pattern[[1]], list(list(TEXT = list(REGEX = "(?i)^ac.+")),
                                           list(TEXT = list(REGEX = "(?i)wid"))))
    expect_error(as_entity_patterns(d, valuetype = "other"), "should be one of")
})

test_that("the output of spacy_extract_entity() becomes phrases", {
    ents <- data.frame(doc_id = c("d1", "d1", "d2", "d2"),
                       text = c("Jane Smith", "Acme, Inc.", "Jane Smith", "Paris"),
                       ent_type = c("PERSON", "ORG", "PERSON", "GPE"),
                       start_id = c(1, 4, 1, 6), length = c(2, 3, 2, 1))
    p <- as_entity_patterns(ents)
    expect_identical(p$label, c("PERSON", "ORG", "GPE"))
    expect_identical(p$pattern, list("Jane Smith", "Acme, Inc.", "Paris"))
    expect_identical(as_entity_patterns(ents, case_insensitive = TRUE)$case_insensitive,
                     rep(TRUE, 3))
})

test_that("the output of entity_extract() needs its concatenator", {
    ents <- data.frame(doc_id = "d1", sentence_id = 1,
                       entity = c("Jane_Smith", "Acme_,_Inc.", "PUBLIC_AGENCY_X"),
                       entity_type = c("PERSON", "ORG", "PUBLIC_AGENCY"))
    expect_error(as_entity_patterns(ents), "concatenator = \"_\"")
    expect_error(as_entity_patterns(ents, concatenator = ""), "non-empty")
    p <- as_entity_patterns(ents, concatenator = "_")
    expect_identical(p$pattern, list("Jane Smith", "Acme , Inc.", "PUBLIC AGENCY X"))
    expect_identical(p$label, c("PERSON", "ORG", "PUBLIC_AGENCY"))
    p2 <- as_entity_patterns(data.frame(entity = "Jane Smith", entity_type = "PERSON"),
                             concatenator = " ")
    expect_identical(p2$pattern, list("Jane Smith"))
})

test_that("a data.frame with label and pattern ignores the concatenator", {
    df <- data.frame(label = "ORG", pattern = "Acme_Widgets", entity = "x",
                     entity_type = "y")
    expect_identical(as_entity_patterns(df, concatenator = "_")$pattern,
                     list("Acme_Widgets"))
})
