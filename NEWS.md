
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

