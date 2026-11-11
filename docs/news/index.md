# Changelog

## spacyr (development version)

### New features

- New function
  [`as_entity_patterns()`](https://spacyr.quanteda.io/reference/as_entity_patterns.md)
  creates patterns for rule-based named entities, as used by spaCy’s
  `entity_ruler`, from phrases, lists of patterns in spaCy’s own
  structure, or a data.frame
  ([\#234](https://github.com/quanteda/spacyr/issues/234)). Patterns are
  checked for their structure, and converted so that they reach spaCy in
  the form it expects: the values of spaCy’s set operators (`IN`,
  `NOT_IN`, `IS_SUBSET`, `IS_SUPERSET` and `INTERSECTS`) stay lists even
  when they hold a single value or none, other empty lists become empty
  dictionaries, and whole numbers become integers. Phrases can match
  regardless of case with `case_insensitive = TRUE`. The new functions
  [`entity_patterns_read()`](https://spacyr.quanteda.io/reference/entity_patterns_read.md)
  and
  [`entity_patterns_write()`](https://spacyr.quanteda.io/reference/entity_patterns_read.md)
  read patterns from, and write them to, spaCy’s JSONL format, JSON
  arrays, or (for reading) a text file of phrases; reading and writing
  JSON needs the **jsonlite** package, now suggested. Pass the patterns
  to
  [`spacy_initialize()`](https://spacyr.quanteda.io/reference/spacy_initialize.md)
  with its new argument `entity_patterns`.
- [`as_entity_patterns()`](https://spacyr.quanteda.io/reference/as_entity_patterns.md)
  also converts the entities found by
  [`spacy_extract_entity()`](https://spacyr.quanteda.io/reference/spacy_extract_entity.md),
  so that entities found in one set of texts can be rules for others,
  and those found by
  [`entity_extract()`](https://spacyr.quanteda.io/reference/entity_extract.md),
  given the `concatenator` that joined their tokens. It converts
  **quanteda** dictionaries too, labelling patterns by their top-level
  keys and matching regardless of case by default. Dictionary values
  with wildcards (`valuetype = "glob"`, the default) become token
  patterns with a regular expression for each part that has a wildcard,
  and `valuetype = "regex"` and `"fixed"` are also supported.
- A new article on the package website, “Adding Rule-Based Named
  Entities”, shows how to add entities by rules: phrases, token patterns
  such as academic titles, rules and the model’s own entities,
  **quanteda** dictionaries, reusing the entities found, and saving
  rules to files.
- A new article on the package website, “Rule-Based Matching”, shows how
  to find sequences of tokens, phrases and dictionary values with
  [`spacy_extract_matches()`](https://spacyr.quanteda.io/reference/spacy_extract_matches.md),
  and tokens connected in the dependency parse with
  [`spacy_extract_dependency_matches()`](https://spacyr.quanteda.io/reference/spacy_extract_dependency_matches.md),
  with passive verbs as the example, and what to keep in mind about
  language models and their parses
  ([\#204](https://github.com/quanteda/spacyr/issues/204)).
- A new article on the package website, “Improving Performance”, shows
  what makes parsing faster or slower: choosing between
  [`spacy_tokenize()`](https://spacyr.quanteda.io/reference/spacy_tokenize.md)
  and
  [`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md),
  leaving out the named entity recognizer, the language model,
  `batch_size` and `n_process`, and long documents
  ([\#226](https://github.com/quanteda/spacyr/issues/226)).
- New function
  [`spacy_extract_matches()`](https://spacyr.quanteda.io/reference/spacy_extract_matches.md)
  finds sequences of tokens that match patterns, using spaCy’s
  rule-based `Matcher`
  ([\#204](https://github.com/quanteda/spacyr/issues/204)). Patterns are
  a named list of token patterns in spaCy’s own structure, with
  alternatives for a label given as a list of patterns, or an
  [`as_entity_patterns()`](https://spacyr.quanteda.io/reference/as_entity_patterns.md)
  object, whose phrases are matched too, exactly or in any case, or a
  **quanteda** dictionary, with its wildcards; they can use any token
  attribute, including those the model assigns, such as `POS`, `TAG`,
  `DEP` and `LEMMA`. It returns a data.frame with one row per match: the
  document, the sentence and token position of its first token as in
  [`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md),
  the label, the matched text, and its position in the document and
  length as in
  [`spacy_extract_entity()`](https://spacyr.quanteda.io/reference/spacy_extract_entity.md);
  nothing matching gives a data.frame with no rows. All matches are
  returned by default, and `overlap = "longest"` or `"first"` keeps one
  of the overlapping matches of a label. Unlike `entity_patterns`, the
  patterns do not change the pipeline or a document’s entities.
- New function
  [`spacy_extract_dependency_matches()`](https://spacyr.quanteda.io/reference/spacy_extract_dependency_matches.md)
  finds tokens that are connected in the dependency parse as a pattern
  describes, using spaCy’s `DependencyMatcher`
  ([\#204](https://github.com/quanteda/spacyr/issues/204)): a passive
  verb with its subject and agent, for instance, wherever they are in
  the sentence. Patterns are a named list of dependency patterns in
  spaCy’s own structure, one for each label, whose nodes are named by
  `RIGHT_ID`. It returns a data.frame with one row for each node of the
  pattern in each match: the document, the number of the match within
  it, the label, the name of the node, and the token it matched with its
  position, as in
  [`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md).
  The pipeline needs a dependency parser, or another component that sets
  dependencies; a document without a dependency parse is an error, not a
  document without matches.
- [`spacy_initialize()`](https://spacyr.quanteda.io/reference/spacy_initialize.md)
  has new arguments `entity_patterns` and `overwrite_entities`, to add
  rule-based named entities to the pipeline
  ([\#234](https://github.com/quanteda/spacyr/issues/234)).
  `entity_patterns` takes anything
  [`as_entity_patterns()`](https://spacyr.quanteda.io/reference/as_entity_patterns.md)
  accepts, and adds spaCy’s entity ruler as `spacyr_entity_ruler`, after
  every component that sets entities, so that an `entity_ruler` saved
  with the model stays in place (if the model already has a
  `spacyr_entity_ruler`, the new one is `spacyr_entity_ruler_2`). Where
  a rule’s entity overlaps one the model found, the rule’s is kept,
  unless `overwrite_entities = FALSE`. Phrases marked `case_insensitive`
  are tokenized with the pipeline’s own tokenizer. The rules’ entities
  are returned by
  [`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md)
  and
  [`spacy_extract_entity()`](https://spacyr.quanteda.io/reference/spacy_extract_entity.md)
  also when `entity = FALSE`, and patterns that need entities found by
  an earlier component (with `ENT_TYPE` or `ENT_IOB`) give a warning
  when no component before the ruler sets entities. Phrase patterns give
  a warning when an earlier component, such as `merge_entities`, changes
  the tokens. spaCy’s message is shown for a pattern it does not accept.
- [`spacy_initialize()`](https://spacyr.quanteda.io/reference/spacy_initialize.md)
  has a new argument `split_hyphens`
  ([\#250](https://github.com/quanteda/spacyr/issues/250)). With
  `split_hyphens = FALSE`, spaCy’s tokenizer no longer splits words at a
  single hyphen between letters, or between a letter and a digit, so
  that “eye-opening” stays one token for the whole pipeline, including
  the tagger and lemmatizer, instead of becoming “eye”, “-” and
  “opening”. The tokenizer still splits wherever else it did, as between
  numbers (“3-4”, which **quanteda**’s `tokens(split_hyphens = FALSE)`
  keeps whole), at two or more hyphens and at the start or end of a
  word. Only the language’s default infix rules are changed; a model
  saved with rules of its own, or with a tokenizer that is not spaCy’s
  rule-based one, gives a warning if it still splits some hyphenated
  words, and so does a ruler saved with the model whose phrase patterns
  were tokenized before the change. The default, `TRUE`, keeps the
  model’s tokenization, unlike the default of
  [`quanteda::tokens()`](https://quanteda.io/reference/tokens.html).
- [`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md),
  [`spacy_tokenize()`](https://spacyr.quanteda.io/reference/spacy_tokenize.md),
  [`spacy_extract_entity()`](https://spacyr.quanteda.io/reference/spacy_extract_entity.md)
  and
  [`spacy_extract_nounphrases()`](https://spacyr.quanteda.io/reference/spacy_extract_nounphrases.md)
  have new arguments `n_process` and `batch_size`, passed to spaCy’s
  `nlp.pipe()` ([\#185](https://github.com/quanteda/spacyr/issues/185)).
  `n_process` sets the number of processes (`-1` for all CPUs) and
  `batch_size` the number of documents processed together; the defaults,
  `n_process = 1` and `batch_size = NULL` (the pipeline’s default batch
  size), process documents as before. The output does not depend on
  either.

### Deprecated

- The `multithread` argument of
  [`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md),
  [`spacy_tokenize()`](https://spacyr.quanteda.io/reference/spacy_tokenize.md),
  [`spacy_extract_entity()`](https://spacyr.quanteda.io/reference/spacy_extract_entity.md)
  and
  [`spacy_extract_nounphrases()`](https://spacyr.quanteda.io/reference/spacy_extract_nounphrases.md)
  is deprecated, and gives a warning when supplied. It has no effect
  (see below); use `n_process` and `batch_size` instead.
- [`process_document()`](https://spacyr.quanteda.io/reference/process_document.md)
  and the functions that read its result,
  [`get_tokens()`](https://spacyr.quanteda.io/reference/get-functions.md),
  [`get_tags()`](https://spacyr.quanteda.io/reference/get-functions.md),
  [`get_attrs()`](https://spacyr.quanteda.io/reference/get-functions.md),
  [`get_named_entities()`](https://spacyr.quanteda.io/reference/get-functions.md),
  [`get_dependency()`](https://spacyr.quanteda.io/reference/get-functions.md),
  [`get_noun_phrases()`](https://spacyr.quanteda.io/reference/get-functions.md),
  [`get_ntokens()`](https://spacyr.quanteda.io/reference/get-functions.md)
  and
  [`get_ntokens_by_sent()`](https://spacyr.quanteda.io/reference/get-functions.md),
  are deprecated, and give a warning on every call. They will be removed
  in a future version.
  [`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md)
  returns all of their results; each warning names the replacement. The
  help for
  [`get_dependency()`](https://spacyr.quanteda.io/reference/get-functions.md)
  shows how to convert
  [`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md)’s
  `head_token_id`, which numbers tokens within each sentence, to its
  `head_id`, which numbers them within each document.
- The result of
  [`process_document()`](https://spacyr.quanteda.io/reference/process_document.md)
  now holds its own parsed documents. Previously, the `get_*()`
  functions read the documents of the most recent call to any spacyr
  function, so they failed with a Python `KeyError` once another
  function, such as
  [`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md),
  had been called.
  [`process_document()`](https://spacyr.quanteda.io/reference/process_document.md)
  now also checks `n_process` and `batch_size`, and warns about
  `multithread`, as the other functions do. It does not keep the
  language model, which
  [`spacy_finalize()`](https://spacyr.quanteda.io/reference/spacy_finalize.md)
  frees as before.

### Changes

- [`spacy_initialize()`](https://spacyr.quanteda.io/reference/spacy_initialize.md)
  now sets the environment variable `TOKENIZERS_PARALLELISM` to
  `"false"`, unless it is already set
  ([\#233](https://github.com/quanteda/spacyr/issues/233)). With
  versions of Hugging Face’s **tokenizers** library before 0.22.2,
  pipelines that use it, such as some built with **spacy-transformers**,
  printed “The current process just got forked, after parallelism has
  already been used. Disabling parallelism to avoid deadlocks…” again
  and again, until R was restarted, once the R process had been forked
  after the library was used, for instance by
  [`parallel::mcparallel()`](https://rdrr.io/r/parallel/mcparallel.html);
  saving a file in RStudio was also reported to trigger it. The setting
  controls the library’s tokenizer threads; its effect on total runtime
  depends on the pipeline and the workload. It applies to the whole R
  process and stays after
  [`spacy_finalize()`](https://spacyr.quanteda.io/reference/spacy_finalize.md);
  if initialization fails, the previous value is restored. A value set
  beforehand, even an empty one, is kept. Setting it to `"true"` turns
  off the library’s safeguard against deadlocks, so a forked worker,
  from
  [`parallel::mclapply()`](https://rdrr.io/r/parallel/mclapply.html) or
  from `n_process` greater than 1 when the workers are started by fork,
  that uses **tokenizers** after the parent has used it can hang; leave
  it at `"false"` whenever that can happen.

- [`spacy_download_langmodel()`](https://spacyr.quanteda.io/reference/spacy_download_langmodel.md),
  also used by
  [`spacy_install()`](https://spacyr.quanteda.io/reference/spacy_install.md),
  now tries a failed model download twice more, after 10 and 30 seconds,
  and warns if all three attempts fail. Models come from GitHub, which
  sometimes answers with a temporary server error that pip does not
  retry. Previously a failed download gave no warning from **spacyr**.

- spacyr now requires spaCy 3.0.0 or later, and Python 3.
  [`spacy_initialize()`](https://spacyr.quanteda.io/reference/spacy_initialize.md)
  stops with an error if an earlier version of spaCy is installed, and
  [`spacy_install()`](https://spacyr.quanteda.io/reference/spacy_install.md)
  refuses a `version` that allows only earlier versions, whether a bare
  version (`"2.3.9"`), a pip-style pin (`"==2.3.9"`,
  `"[cuda102]==2.3.9"`) or a range (`"<3"`). A range without a lower
  bound of 3 or above gets `>=3.0.0` added. A `version` that is not a
  valid pip requirement, such as `"1.10.1a"`, is passed to pip
  unchanged, so that pip’s error shows what was given. The code for
  Python 2 and spaCy 2 has been removed. The `deal_utf8` argument of
  [`get_attrs()`](https://spacyr.quanteda.io/reference/get-functions.md)
  is no longer used.

- [`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md)
  now builds all its columns in one pass over the documents as spaCy
  parses them, instead of storing the parsed documents in Python and
  fetching each column with a separate call. The output is unchanged;
  the parsed documents are no longer kept in memory after the call, and
  parsing with several options is somewhat faster.

- [`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md),
  [`spacy_tokenize()`](https://spacyr.quanteda.io/reference/spacy_tokenize.md),
  [`spacy_extract_entity()`](https://spacyr.quanteda.io/reference/spacy_extract_entity.md)
  and
  [`spacy_extract_nounphrases()`](https://spacyr.quanteda.io/reference/spacy_extract_nounphrases.md)
  now always process documents in batches with spaCy’s `nlp.pipe()`, and
  the `multithread` argument no longer has any effect. Previously,
  `multithread = FALSE`, and a single document in all but
  [`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md),
  processed each document with `nlp()`. With the standard spaCy models
  the results are the same, but a custom pipeline component whose
  [`pipe()`](https://rdrr.io/r/base/connections.html) method behaves
  differently from its `__call__()` method now always has its
  [`pipe()`](https://rdrr.io/r/base/connections.html) method used.

- When a pipeline component fails on a document and the pipeline’s error
  handler suppresses the error, spaCy’s `nlp.pipe()` leaves that
  document out. **spacyr** now keeps the names of the other documents,
  leaves the failed document out of the output and warns about it.
  Previously, the results of later documents could be assigned to the
  wrong document names, and
  [`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md)
  failed.

- [`spacy_tokenize()`](https://spacyr.quanteda.io/reference/spacy_tokenize.md)
  with `remove_punct`, `remove_numbers` or `remove_url`, and without
  `remove_symbols`, no longer runs the components of the pipeline, which
  these options do not need, so they are now about as fast as tokenizing
  without them ([\#226](https://github.com/quanteda/spacyr/issues/226)).
  With the standard spaCy models, the tokens are the same as before.
  With a pipeline whose components change the tokens or their
  attributes, such as spaCy’s `merge_entities`, or that fail on some
  documents and leave them out, these options now give the tokens that
  plain tokenization gives, from all the documents, since those
  components no longer run. `remove_symbols` still runs all the
  components, since it needs the part-of-speech tags, whatever the other
  options.

- [`spacy_tokenize()`](https://spacyr.quanteda.io/reference/spacy_tokenize.md)
  now stops with an error when `remove_punct`, `remove_url`,
  `remove_numbers`, `remove_separators`, `remove_symbols` or `padding`
  is not `TRUE` or `FALSE`. Previously a missing value (`NA`) either
  gave an unclear error or was taken as `TRUE` or `FALSE` without
  warning.

- spacyr now loads its Python code as a module with
  [`reticulate::import_from_path()`](https://rstudio.github.io/reticulate/reference/import.html)
  and calls its functions with arguments, instead of running Python code
  in the `__main__` namespace and passing data through global variables
  there. As a result, spacyr no longer creates the Python variables
  `nlp`, `spobj`, `texts` and others in `__main__`, so code that read
  `reticulate::py$nlp` after
  [`spacy_initialize()`](https://spacyr.quanteda.io/reference/spacy_initialize.md)
  no longer works.

- [`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md),
  [`spacy_tokenize()`](https://spacyr.quanteda.io/reference/spacy_tokenize.md),
  [`spacy_extract_entity()`](https://spacyr.quanteda.io/reference/spacy_extract_entity.md)
  and
  [`spacy_extract_nounphrases()`](https://spacyr.quanteda.io/reference/spacy_extract_nounphrases.md)
  now share one function for checking and preparing their input, which
  fixes three edge cases:

  - A TIF data.frame whose `text` column is a factor, as
    [`data.frame()`](https://rdrr.io/r/base/data.frame.html) made it by
    default before R 4.0, is now accepted. Previously it failed with “no
    applicable method”. (A factor `doc_id` column already worked.)
  - A document name that is `NA` now gives the error “Some docnames are
    missing.” Previously it failed with “missing value where TRUE/FALSE
    needed”.
  - An empty character vector no longer gives a warning that two
    documents (`text1` and `text0`) were left out.

### Bug fixes

- [`entity_extract()`](https://spacyr.quanteda.io/reference/entity_extract.md)
  and
  [`entity_consolidate()`](https://spacyr.quanteda.io/reference/entity_extract.md)
  now keep entity labels that contain underscores, such as a custom
  `PUBLIC_AGENCY` label. Previously they cut the label at its first
  underscore, giving `PUBLIC`. The labels of spaCy’s standard models
  have no underscores, so their results are unchanged.

### Documentation

- The vignette and help pages are updated for spaCy 3: language models
  are named in full (for example `de_core_news_sm` rather than `de`),
  links to spaCy’s documentation point to its current pages, and the
  [`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md)
  description no longer mentions options that do not exist. The help for
  [`entity_extract()`](https://spacyr.quanteda.io/reference/entity_extract.md)
  and
  [`spacy_extract_entity()`](https://spacyr.quanteda.io/reference/spacy_extract_entity.md)
  now lists which entity types count as extended.
- The vignette is now precomputed: its source is
  `vignettes/using_spacyr.Rmd.orig`, which `make vignette` knits, with
  spaCy, into `vignettes/using_spacyr.Rmd`, so that R and pkgdown build
  it without running its code. It replaces the static HTML vignette
  built with **R.rsp**, which had not been updated with the vignette’s
  source, and **R.rsp** is no longer a suggested package. The pkgdown
  site is rebuilt with pkgdown 2.2.1, and now uses Bootstrap 5 with the
  same theme and styling as the **quanteda** site. The site’s search
  box, which pkgdown provides without an outside service, is restored.

### Tests

- The `saved-output` CI job now tries installing the pinned spaCy and
  model versions up to three times, for the same reason.
- Added saved-output tests that compare the results of
  [`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md),
  [`spacy_tokenize()`](https://spacyr.quanteda.io/reference/spacy_tokenize.md),
  [`spacy_extract_entity()`](https://spacyr.quanteda.io/reference/spacy_extract_entity.md),
  [`spacy_extract_nounphrases()`](https://spacyr.quanteda.io/reference/spacy_extract_nounphrases.md)
  and the `entity_*()` and `nounphrase_*()` functions with those of
  version 1.4.0, on a fixed set of texts that includes edge cases. The
  `entity_*()` and `nounphrase_*()` tests do not need Python, so they
  also run on CRAN.
- The saved-output tests compare output only with the spaCy and language
  model versions it was recorded with. A new `saved-output` CI job
  installs exactly those versions and fails if any saved-output test is
  skipped. The 1.4.0 output is kept as a fixed baseline, and the
  accepted output is updated from a named, accepted revision (see
  `tests/testthat/fixtures/README.md`).
- Added tests that record which functions process documents with spaCy’s
  `nlp.pipe()` and which call `nlp()` on each document, using a custom
  pipeline component that behaves differently in the two. Output with
  the standard models is the same either way, so the saved-output tests
  alone would not catch a change of path.

## spacyr v1.4.0

CRAN release: 2026-11-04

### Changes that can affect results

- [`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md),
  [`spacy_tokenize()`](https://spacyr.quanteda.io/reference/spacy_tokenize.md),
  [`spacy_extract_entity()`](https://spacyr.quanteda.io/reference/spacy_extract_entity.md)
  and
  [`spacy_extract_nounphrases()`](https://spacyr.quanteda.io/reference/spacy_extract_nounphrases.md)
  no longer alter the input text. Previously they deleted all
  backslashes and converted the literal sequences `\n` and `\t` into
  newlines and tabs, so that for instance `C:\Users` was tokenized as
  `C`, `:`, `Users`. Code that relied on literal `\n` being converted
  should now convert it in R before calling **spacyr**.
- `NA` documents are now treated as empty documents, rather than as the
  text `"NA"`.
- `spacy_tokenize(what = "sentence", remove_separators = FALSE)` now
  keeps trailing whitespace regardless of the value of `multithread`,
  including a single space after a sentence, so that the sentences join
  back into the original text.
- `spacy_parse(nounphrase = TRUE)` now returns rows in the order of the
  input documents, as it does without noun phrases, instead of sorted by
  document name. This fixes a bug where the `whitespace` column and any
  `additional_attributes` were assigned to the wrong tokens when the
  document names were not in alphabetical order.

### New features

- Added
  [`spacy_installed()`](https://spacyr.quanteda.io/reference/spacy_installed.md),
  which checks without starting Python whether spaCy and, optionally,
  given language models are installed
  ([\#197](https://github.com/quanteda/spacyr/issues/197)).
- Added a `max_length` argument to
  [`spacy_initialize()`](https://spacyr.quanteda.io/reference/spacy_initialize.md)
  to allow documents longer than spaCy’s default limit of 1,000,000
  characters ([\#218](https://github.com/quanteda/spacyr/issues/218)).

### Installation

- [`spacy_install()`](https://spacyr.quanteda.io/reference/spacy_install.md)
  now creates its environment with a version of Python supported by the
  spaCy release being installed, as declared on PyPI, rather than
  whichever Python is found first; if none is found, it offers to
  install a compatible one. For an existing environment whose Python is
  not supported, it stops with an error explaining how to recreate the
  environment, instead of failing during installation.
- [`spacy_initialize()`](https://spacyr.quanteda.io/reference/spacy_initialize.md)
  now explains how to install a language model that cannot be found.
- Fixed
  [`spacy_download_langmodel()`](https://spacyr.quanteda.io/reference/spacy_download_langmodel.md)
  and
  [`spacy_install()`](https://spacyr.quanteda.io/reference/spacy_install.md)
  not detecting already-installed language models with recent versions
  of pip ([\#258](https://github.com/quanteda/spacyr/issues/258)).
- Fixed a bug in
  [`spacy_download_langmodel()`](https://spacyr.quanteda.io/reference/spacy_download_langmodel.md)
  that prevented installing multiple models in one function call
  ([\#249](https://github.com/quanteda/spacyr/issues/249)).
- [`spacy_install()`](https://spacyr.quanteda.io/reference/spacy_install.md)
  and
  [`spacy_upgrade()`](https://spacyr.quanteda.io/reference/spacy_upgrade.md)
  no longer fail on Windows when installing into a different environment
  after Python has been initialised in the session
  ([\#258](https://github.com/quanteda/spacyr/issues/258)).
- Updated the installation instructions: language models are installed
  with
  [`spacy_download_langmodel()`](https://spacyr.quanteda.io/reference/spacy_download_langmodel.md)
  rather than with `pip`
  ([\#253](https://github.com/quanteda/spacyr/issues/253)), and new
  sections cover changing the Python version, using an existing Python
  or conda environment
  ([\#246](https://github.com/quanteda/spacyr/issues/246)), using local
  models ([\#180](https://github.com/quanteda/spacyr/issues/180)) and
  the need for git on Windows
  ([\#245](https://github.com/quanteda/spacyr/issues/245)). The vignette
  no longer describes arguments that were removed from
  [`spacy_initialize()`](https://spacyr.quanteda.io/reference/spacy_initialize.md).
- Requires **reticulate** \>= 1.31.

### Bug fixes

- Fixed a bug where an error during
  [`spacy_tokenize()`](https://spacyr.quanteda.io/reference/spacy_tokenize.md),
  such as a text exceeding spaCy’s maximum length, left the spaCy
  pipeline disabled, so that later calls in the same session failed or
  silently returned no entities.
- Fixed a `SyntaxWarning` about an invalid escape sequence on Python
  3.12+ when initialising spacyr
  ([\#257](https://github.com/quanteda/spacyr/issues/257), thanks to
  [@thjbdvlt](https://github.com/thjbdvlt)).
- [`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md)
  no longer warns that lemmatization “may not work properly” for models
  whose name does not start with “en”.
- [`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md)
  now returns a zero-row result with the usual columns and types when no
  document contains any tokens (for instance when all documents are `NA`
  or empty), instead of failing with `dependency = TRUE` or returning
  malformed columns.

## spacyr v1.3

- Overhauled the
  [`spacy_install()`](https://spacyr.quanteda.io/reference/spacy_install.md)
  and
  [`spacy_uninstall()`](https://spacyr.quanteda.io/reference/spacy_uninstall.md)
  functions to provide a more modern and robust installation procedure.

## spacyr v1.2

CRAN release: 2019-07-04

- Added an option for using conda package manager instead of `pip` in
  [`spacy_install()`](https://spacyr.quanteda.io/reference/spacy_install.md)
  and
  [`spacy_upgrade()`](https://spacyr.quanteda.io/reference/spacy_upgrade.md).
- (1.21) All character inputs to
  [`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md)
  and
  [`spacy_tokenize()`](https://spacyr.quanteda.io/reference/spacy_tokenize.md)
  are now coerced to `character`, which allows them to work directly
  with **quanteda** v2 corpus objects (which are based on the
  `character` class but with special attributed), without special
  methods.

## spacyr v1.1

- Fixed a bug in `spacy_parse(x, nounphrase = TRUE)` that occurred when
  no noun phrases were found in the text.
  ([\#153](https://github.com/quanteda/spacyr/issues/153))
- Fixed a bug in
  [`spacy_initialize()`](https://spacyr.quanteda.io/reference/spacy_initialize.md)
  ([\#157](https://github.com/quanteda/spacyr/issues/157)).
  [`spacy_initialize()`](https://spacyr.quanteda.io/reference/spacy_initialize.md)
  ignored Python options supplied by users when a conda environment
  created through
  [`spacy_install()`](https://spacyr.quanteda.io/reference/spacy_install.md)
  exists.
- General stability enhancements to ensure compatibility with spaCy \>=
  2.1

## spacyr v1.0

CRAN release: 2018-12-15

- Added new commands
  [`spacy_tokenize()`](https://spacyr.quanteda.io/reference/spacy_tokenize.md),
  [`spacy_extract_entity()`](https://spacyr.quanteda.io/reference/spacy_extract_entity.md),
  [`spacy_extract_nounphrases()`](https://spacyr.quanteda.io/reference/spacy_extract_nounphrases.md),
  [`nounphrase_extract()`](https://spacyr.quanteda.io/reference/nounphrase_extract.md),
  and
  [`nounphrase_consolidate()`](https://spacyr.quanteda.io/reference/nounphrase_extract.md)
  for direct extraction of entities, noun phrases, and tokens, and
  extraction of noun phrases from spacyr parsed tests.
- Added a new argument `additional_attributes` to
  [`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md)
  allowing the return of any tokens-level attribute available from
  <https://spacy.io/api/token#attributes>.
- Added a vignette and significantly improved the documentation site
  <https://spacyr.quanteda.io>.

## spacyr v0.9.9

CRAN release: 2018-04-17

- Added
  [`spacy_install()`](https://spacyr.quanteda.io/reference/spacy_install.md),
  [`spacy_install_virtualenv()`](https://spacyr.quanteda.io/reference/spacy_install_virtualenv.md),
  and
  [`spacy_upgrade()`](https://spacyr.quanteda.io/reference/spacy_upgrade.md)
  to make installing or upgrading spaCy (and Python itself) easy and
  automatic.
- Added support for multithreading in
  [`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md)
  via the `multithreading` argument. This uses the “pipes” functionality
  in spaCy for improved performance.

## spacyr v0.9.6

CRAN release: 2018-02-18

- Create an option to permanently set the default Python through
  `.Rprofile`
- Performance enhancement through `spacy_initialize(entity = FALSE)`
  ([\#91](https://github.com/quanteda/spacyr/issues/91))
- Now looks for Python settings from `.bash_profile`.

## spacyr v0.9.3

CRAN release: 2017-11-10

- Updated for the newer spaCy 2.0 release and new language models.
- Add `ask = FALSE` to
  [`spacy_initialize()`](https://spacyr.quanteda.io/reference/spacy_initialize.md),
  to find spaCy installations automatically.

## spacyr v0.9.2

- Fixed a bug caused by zero-token “sentences” in
  [`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md),
  by changing `1:length()` to
  [`seq_along()`](https://rdrr.io/r/base/seq.html).

## spacyr v0.9.1

- Fixed a bug causing non-ASCII characters to be dropped when using
  Python 2.7.x ([\#58](https://github.com/quanteda/spacyr/issues/58)).
- Fixed issue with automatic detection of python3 when both python and
  python3 exist, but only python3 has spaCy installed
  ([\#62](https://github.com/quanteda/spacyr/issues/62)).

## spacyr v0.9.0

CRAN release: 2017-05-20

- Initial CRAN release.
