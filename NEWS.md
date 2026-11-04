# spacyr v1.3.1

* Fixed a bug in `spacy_download_langmodel()` that prevented installing multiple models in one function call (#249)
* Fixed a `SyntaxWarning` about an invalid escape sequence on Python 3.12+ when initialising spacyr (#257, thanks to @thjbdvlt).
* Fixed `spacy_download_langmodel()` and `spacy_install()` not detecting already-installed language models with recent versions of pip (#258).
* `spacy_install()` and `spacy_upgrade()` no longer fail on Windows when installing into a different environment after Python has been initialised in the session (#258).
* `spacy_parse()`, `spacy_tokenize()`, `spacy_extract_entity()` and `spacy_extract_nounphrases()` no longer alter the input text. Previously they deleted all backslashes and converted the literal sequences `\n` and `\t` into newlines and tabs, so that for instance `C:\Users` was tokenized as `C`, `:`, `Users`.
* Fixed a bug where an error during `spacy_tokenize()`, such as a text exceeding spaCy's maximum length, left the spaCy pipeline disabled, so that later calls in the same session failed or silently returned no entities.
* `spacy_tokenize(what = "sentence", remove_separators = FALSE)` now keeps trailing whitespace regardless of the value of `multithread`.
* `NA` documents are now treated as empty documents, rather than as the text `"NA"`.
* Added a `max_length` argument to `spacy_initialize()` to allow documents longer than spaCy's default limit of 1,000,000 characters (#218).
* `spacy_parse()` no longer warns that lemmatization "may not work properly" for models whose name does not start with "en".

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

