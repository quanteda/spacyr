# Check whether spaCy is installed

Checks, without starting Python, whether spaCy (and optionally one or
more language models) is installed in the environment that
[`spacy_initialize()`](https://spacyr.quanteda.io/reference/spacy_initialize.md)
will use: the one set by `RETICULATE_PYTHON` if set, or otherwise the
virtual environment named by `SPACY_PYTHON` (by default `"r-spacyr"`).
This is useful, for instance, to skip examples or tests when spaCy is
not available. If a different interpreter is already running in the R
session and prevents use of the named virtual environment, returns
`FALSE`.

## Usage

``` r
spacy_installed(lang_models = NULL)
```

## Arguments

- lang_models:

  character; names of language models that must also be installed, e.g.
  `"en_core_web_sm"`. If `NULL` (the default), only spaCy itself is
  checked.

## Value

`TRUE` if spaCy and all `lang_models` are installed, `FALSE` otherwise.

## See also

[`spacy_install()`](https://spacyr.quanteda.io/reference/spacy_install.md),
[`spacy_download_langmodel()`](https://spacyr.quanteda.io/reference/spacy_download_langmodel.md)

## Examples

``` r
spacy_installed()
#> [1] TRUE
spacy_installed("en_core_web_sm")
#> [1] TRUE
```
