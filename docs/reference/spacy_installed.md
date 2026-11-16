# Check whether spaCy is installed (deprecated)

This function is deprecated, and will be removed in a future version of
spacyr. It gives a warning on every call. Use
[`spacy_is_installed()`](https://spacyr.quanteda.io/reference/spacy_is_installed.md)
instead, which is the same function under a new name.

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

as
[`spacy_is_installed()`](https://spacyr.quanteda.io/reference/spacy_is_installed.md)

## Examples

``` r
# instead of spacy_installed():
spacy_is_installed()
#> [1] TRUE
```
