# v0.9.3

* Updated for the newer spaCy 2.0 release and new language models.
* Add`ask = FAlSE` to `spacy_initialize()`.

# v0.9.2

*  Fixed a bug caused by zero-token "sentences" in `spacy_parse()`, by changing `1:length()` to `seq_along()`.

# v0.9.1

*  Fixed a bug causing non-ASCII characters to be dropped when using Python 2.7.x (#58).
*  Fixed issue with automatic detection of python3 when both python and python3 exist, but only python3 has spaCy installed (#62).

# v0.9.0

*  Initial CRAN release.

