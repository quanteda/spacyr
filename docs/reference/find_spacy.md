# Find spaCy

Locate the user's version of Python for which spaCy installed.

## Usage

``` r
find_spacy(model = "en_core_web_sm", ask)
```

## Arguments

- model:

  name of the language model

- ask:

  logical; if `FALSE`, use the first spaCy installation found; if
  `TRUE`, list available spaCy installations and prompt the user for
  which to use. If another (e.g. `python_executable`) is set, then this
  value will always be treated as `FALSE`.

## Value

spacy_python
