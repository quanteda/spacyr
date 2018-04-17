# v0.9.9

* Added `spacy_install()`, `spacy_install_virtualenv()`, and `spacy_upgrade()` to make installing or upgrading spaCy (and Python itself) easy and automatic.
* Added support for multithreading in `spacy_parse()` via the `multithreading` argument.  This uses the "pipes" functionality in spaCy for improved performance.

# v0.9.6

* Create an option to permanently set the default Python through `.Rprofile`
* Performance enhancement through `spacy_initialize(entity = FALSE)` (#91)
* Now looks for Python settings from `.bash_profile`.

# v0.9.3

* Updated for the newer spaCy 2.0 release and new language models.
* Add `ask = FALSE` to `spacy_initialize()`, to find spaCy installations automatically.

# v0.9.2

*  Fixed a bug caused by zero-token "sentences" in `spacy_parse()`, by changing `1:length()` to `seq_along()`.

# v0.9.1

*  Fixed a bug causing non-ASCII characters to be dropped when using Python 2.7.x (#58).
*  Fixed issue with automatic detection of python3 when both python and python3 exist, but only python3 has spaCy installed (#62).

# v0.9.0

*  Initial CRAN release.

