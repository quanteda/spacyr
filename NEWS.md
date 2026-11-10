# spacyr (development version)

## New features

* New function `as_entity_patterns()` creates patterns for rule-based named entities, as used by spaCy's `entity_ruler`, from phrases, lists of patterns in spaCy's own structure, or a data.frame (#234). Patterns are checked for their structure, and converted so that they reach spaCy in the form it expects: the values of `IN` and `NOT_IN` stay lists even when they hold a single value, and whole numbers become integers. Phrases can match regardless of case with `case_insensitive = TRUE`. The new functions `entity_patterns_read()` and `entity_patterns_write()` read patterns from, and write them to, spaCy's JSONL format, JSON arrays, or (for reading) a text file of phrases; reading and writing JSON needs the **jsonlite** package, now suggested. Pass the patterns to `spacy_initialize()` with its new argument `entity_patterns`.
* `spacy_initialize()` has new arguments `entity_patterns` and `overwrite_entities`, to add rule-based named entities to the pipeline (#234). `entity_patterns` takes anything `as_entity_patterns()` accepts, and adds spaCy's entity ruler as `spacyr_entity_ruler`, after every component that sets entities, so that an `entity_ruler` saved with the model stays in place. Where a rule's entity overlaps one the model found, the rule's is kept, unless `overwrite_entities = FALSE`. Phrases marked `case_insensitive` are tokenized with the pipeline's own tokenizer. The rules' entities are returned by `spacy_parse()` and `spacy_extract_entity()` also when `entity = FALSE`, and patterns that use `ENT_TYPE` or `ENT_IOB` give a warning when no component of the pipeline sets entities. spaCy's message is shown for a pattern it does not accept.
* `spacy_parse()`, `spacy_tokenize()`, `spacy_extract_entity()` and `spacy_extract_nounphrases()` have new arguments `n_process` and `batch_size`, passed to spaCy's `nlp.pipe()` (#185). `n_process` sets the number of processes (`-1` for all CPUs) and `batch_size` the number of documents processed together; the defaults, `n_process = 1` and `batch_size = NULL` (the pipeline's default batch size), process documents as before. The output does not depend on either.

## Deprecated

* The `multithread` argument of `spacy_parse()`, `spacy_tokenize()`, `spacy_extract_entity()` and `spacy_extract_nounphrases()` is deprecated, and gives a warning when supplied. It has no effect (see below); use `n_process` and `batch_size` instead.
* `process_document()` and the functions that read its result, `get_tokens()`, `get_tags()`, `get_attrs()`, `get_named_entities()`, `get_dependency()`, `get_noun_phrases()`, `get_ntokens()` and `get_ntokens_by_sent()`, are deprecated, and give a warning on every call. They will be removed in a future version. `spacy_parse()` returns all of their results; each warning names the replacement. The help for `get_dependency()` shows how to convert `spacy_parse()`'s `head_token_id`, which numbers tokens within each sentence, to its `head_id`, which numbers them within each document.
* The result of `process_document()` now holds its own parsed documents. Previously, the `get_*()` functions read the documents of the most recent call to any spacyr function, so they failed with a Python `KeyError` once another function, such as `spacy_parse()`, had been called. `process_document()` now also checks `n_process` and `batch_size`, and warns about `multithread`, as the other functions do. It does not keep the language model, which `spacy_finalize()` frees as before.

## Changes

* `spacy_download_langmodel()`, also used by `spacy_install()`, now tries a failed model download twice more, after 10 and 30 seconds, and warns if all three attempts fail. Models come from GitHub, which sometimes answers with a temporary server error that pip does not retry. Previously a failed download gave no warning from **spacyr**.
* spacyr now requires spaCy 3.0.0 or later, and Python 3. `spacy_initialize()` stops with an error if an earlier version of spaCy is installed, and `spacy_install()` refuses a `version` that allows only earlier versions, whether a bare version (`"2.3.9"`), a pip-style pin (`"==2.3.9"`, `"[cuda102]==2.3.9"`) or a range (`"<3"`). A range without a lower bound of 3 or above gets `>=3.0.0` added. A `version` that is not a valid pip requirement, such as `"1.10.1a"`, is passed to pip unchanged, so that pip's error shows what was given. The code for Python 2 and spaCy 2 has been removed. The `deal_utf8` argument of `get_attrs()` is no longer used.
* `spacy_parse()` now builds all its columns in one pass over the documents as spaCy parses them, instead of storing the parsed documents in Python and fetching each column with a separate call. The output is unchanged; the parsed documents are no longer kept in memory after the call, and parsing with several options is somewhat faster.
* `spacy_parse()`, `spacy_tokenize()`, `spacy_extract_entity()` and `spacy_extract_nounphrases()` now always process documents in batches with spaCy's `nlp.pipe()`, and the `multithread` argument no longer has any effect. Previously, `multithread = FALSE`, and a single document in all but `spacy_parse()`, processed each document with `nlp()`. With the standard spaCy models the results are the same, but a custom pipeline component whose `pipe()` method behaves differently from its `__call__()` method now always has its `pipe()` method used.
* When a pipeline component fails on a document and the pipeline's error handler suppresses the error, spaCy's `nlp.pipe()` leaves that document out. **spacyr** now keeps the names of the other documents, leaves the failed document out of the output and warns about it. Previously, the results of later documents could be assigned to the wrong document names, and `spacy_parse()` failed.
* spacyr now loads its Python code as a module with `reticulate::import_from_path()` and calls its functions with arguments, instead of running Python code in the `__main__` namespace and passing data through global variables there. As a result, spacyr no longer creates the Python variables `nlp`, `spobj`, `texts` and others in `__main__`, so code that read `reticulate::py$nlp` after `spacy_initialize()` no longer works.

* `spacy_parse()`, `spacy_tokenize()`, `spacy_extract_entity()` and `spacy_extract_nounphrases()` now share one function for checking and preparing their input, which fixes three edge cases:
    * A TIF data.frame whose `text` column is a factor, as `data.frame()` made it by default before R 4.0, is now accepted. Previously it failed with "no applicable method". (A factor `doc_id` column already worked.)
    * A document name that is `NA` now gives the error "Some docnames are missing." Previously it failed with "missing value where TRUE/FALSE needed".
    * An empty character vector no longer gives a warning that two documents (`text1` and `text0`) were left out.

## Bug fixes

* `entity_extract()` and `entity_consolidate()` now keep entity labels that contain underscores, such as a custom `PUBLIC_AGENCY` label. Previously they cut the label at its first underscore, giving `PUBLIC`. The labels of spaCy's standard models have no underscores, so their results are unchanged.

## Documentation

* The vignette and help pages are updated for spaCy 3: language models are named in full (for example `de_core_news_sm` rather than `de`), links to spaCy's documentation point to its current pages, and the `spacy_parse()` description no longer mentions options that do not exist. The help for `entity_extract()` and `spacy_extract_entity()` now lists which entity types count as extended.
* The vignette is now precomputed: its source is `vignettes/using_spacyr.Rmd.orig`, which `make vignette` knits, with spaCy, into `vignettes/using_spacyr.Rmd`, so that R and pkgdown build it without running its code. It replaces the static HTML vignette built with **R.rsp**, which had not been updated with the vignette's source, and **R.rsp** is no longer a suggested package. The pkgdown site is rebuilt with pkgdown 2.2.1, and now uses Bootstrap 5 with the same theme and styling as the **quanteda** site. The site's search box, which pkgdown provides without an outside service, is restored.

## Tests

* The `saved-output` CI job now tries installing the pinned spaCy and model versions up to three times, for the same reason.
* Added saved-output tests that compare the results of `spacy_parse()`, `spacy_tokenize()`, `spacy_extract_entity()`, `spacy_extract_nounphrases()` and the `entity_*()` and `nounphrase_*()` functions with those of version 1.4.0, on a fixed set of texts that includes edge cases. The `entity_*()` and `nounphrase_*()` tests do not need Python, so they also run on CRAN.
* The saved-output tests compare output only with the spaCy and language model versions it was recorded with. A new `saved-output` CI job installs exactly those versions and fails if any saved-output test is skipped. The 1.4.0 output is kept as a fixed baseline, and the accepted output is updated from a named, accepted revision (see `tests/testthat/fixtures/README.md`).
* Added tests that record which functions process documents with spaCy's `nlp.pipe()` and which call `nlp()` on each document, using a custom pipeline component that behaves differently in the two. Output with the standard models is the same either way, so the saved-output tests alone would not catch a change of path.

# spacyr v1.4.0

## Changes that can affect results

* `spacy_parse()`, `spacy_tokenize()`, `spacy_extract_entity()` and `spacy_extract_nounphrases()` no longer alter the input text. Previously they deleted all backslashes and converted the literal sequences `\n` and `\t` into newlines and tabs, so that for instance `C:\Users` was tokenized as `C`, `:`, `Users`. Code that relied on literal `\n` being converted should now convert it in R before calling **spacyr**.
* `NA` documents are now treated as empty documents, rather than as the text `"NA"`.
* `spacy_tokenize(what = "sentence", remove_separators = FALSE)` now keeps trailing whitespace regardless of the value of `multithread`, including a single space after a sentence, so that the sentences join back into the original text.
* `spacy_parse(nounphrase = TRUE)` now returns rows in the order of the input documents, as it does without noun phrases, instead of sorted by document name. This fixes a bug where the `whitespace` column and any `additional_attributes` were assigned to the wrong tokens when the document names were not in alphabetical order.

## New features

* Added `spacy_installed()`, which checks without starting Python whether spaCy and, optionally, given language models are installed (#197).
* Added a `max_length` argument to `spacy_initialize()` to allow documents longer than spaCy's default limit of 1,000,000 characters (#218).

## Installation

* `spacy_install()` now creates its environment with a version of Python supported by the spaCy release being installed, as declared on PyPI, rather than whichever Python is found first; if none is found, it offers to install a compatible one. For an existing environment whose Python is not supported, it stops with an error explaining how to recreate the environment, instead of failing during installation.
* `spacy_initialize()` now explains how to install a language model that cannot be found.
* Fixed `spacy_download_langmodel()` and `spacy_install()` not detecting already-installed language models with recent versions of pip (#258).
* Fixed a bug in `spacy_download_langmodel()` that prevented installing multiple models in one function call (#249).
* `spacy_install()` and `spacy_upgrade()` no longer fail on Windows when installing into a different environment after Python has been initialised in the session (#258).
* Updated the installation instructions: language models are installed with `spacy_download_langmodel()` rather than with `pip` (#253), and new sections cover changing the Python version, using an existing Python or conda environment (#246), using local models (#180) and the need for git on Windows (#245). The vignette no longer describes arguments that were removed from `spacy_initialize()`.
* Requires **reticulate** >= 1.31.

## Bug fixes

* Fixed a bug where an error during `spacy_tokenize()`, such as a text exceeding spaCy's maximum length, left the spaCy pipeline disabled, so that later calls in the same session failed or silently returned no entities.
* Fixed a `SyntaxWarning` about an invalid escape sequence on Python 3.12+ when initialising spacyr (#257, thanks to @thjbdvlt).
* `spacy_parse()` no longer warns that lemmatization "may not work properly" for models whose name does not start with "en".
* `spacy_parse()` now returns a zero-row result with the usual columns and types when no document contains any tokens (for instance when all documents are `NA` or empty), instead of failing with `dependency = TRUE` or returning malformed columns.

# spacyr v1.3

* Overhauled the `spacy_install()` and `spacy_uninstall()` functions to provide a more modern and robust installation procedure.


# spacyr v1.2

* Added an option for using conda package manager instead of `pip` in `spacy_install()` and `spacy_upgrade()`.
* (1.21) All character inputs to `spacy_parse()` and `spacy_tokenize()` are now coerced to `character`, which allows them to work directly with **quanteda** v2 corpus objects (which are based on the `character` class but with special attributed), without special methods.

# spacyr v1.1

* Fixed a bug in `spacy_parse(x, nounphrase = TRUE)` that occurred when no noun phrases were found in the text.  (#153)
* Fixed a bug in `spacy_initialize()` (#157). `spacy_initialize()` ignored Python options supplied by users when a conda environment created through `spacy_install()` exists.
* General stability enhancements to ensure compatibility with spaCy >= 2.1

# spacyr v1.0

* Added new commands `spacy_tokenize()`, `spacy_extract_entity()`, `spacy_extract_nounphrases()`, `nounphrase_extract()`, and `nounphrase_consolidate()` for direct extraction of entities, noun phrases, and tokens, and extraction of noun phrases from spacyr parsed tests.
* Added a new argument `additional_attributes` to `spacy_parse()` allowing the return of any tokens-level attribute available from https://spacy.io/api/token#attributes.
* Added a vignette and significantly improved the documentation site https://spacyr.quanteda.io.

# spacyr v0.9.9

* Added `spacy_install()`, `spacy_install_virtualenv()`, and `spacy_upgrade()` to make installing or upgrading spaCy (and Python itself) easy and automatic.
* Added support for multithreading in `spacy_parse()` via the `multithreading` argument.  This uses the "pipes" functionality in spaCy for improved performance.

# spacyr v0.9.6

* Create an option to permanently set the default Python through `.Rprofile`
* Performance enhancement through `spacy_initialize(entity = FALSE)` (#91)
* Now looks for Python settings from `.bash_profile`.

# spacyr v0.9.3

* Updated for the newer spaCy 2.0 release and new language models.
* Add `ask = FALSE` to `spacy_initialize()`, to find spaCy installations automatically.

# spacyr v0.9.2

*  Fixed a bug caused by zero-token "sentences" in `spacy_parse()`, by changing `1:length()` to `seq_along()`.

# spacyr v0.9.1

*  Fixed a bug causing non-ASCII characters to be dropped when using Python 2.7.x (#58).
*  Fixed issue with automatic detection of python3 when both python and python3 exist, but only python3 has spaCy installed (#62).

# spacyr v0.9.0

*  Initial CRAN release.

