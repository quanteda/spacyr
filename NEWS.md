# spacyr (development version)

## Changes

* spacyr now loads its Python code as a module with `reticulate::import_from_path()` and calls its functions with arguments, instead of running Python code in the `__main__` namespace and passing data through global variables there. As a result, spacyr no longer creates the Python variables `nlp`, `spobj`, `texts` and others in `__main__`, so code that read `reticulate::py$nlp` after `spacy_initialize()` no longer works.

## Tests

* Added saved-output tests that compare the results of `spacy_parse()`, `spacy_tokenize()`, `spacy_extract_entity()`, `spacy_extract_nounphrases()` and the `entity_*()` and `nounphrase_*()` functions with those of version 1.4.0, on a fixed set of texts that includes edge cases. The `entity_*()` and `nounphrase_*()` tests do not need Python, so they also run on CRAN.

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

