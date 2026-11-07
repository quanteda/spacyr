# Finalize spaCy

Removes the spaCy language model and any parsed documents from the
Python session, so that their memory can be released, and allows
[`spacy_initialize()`](https://spacyr.quanteda.io/reference/spacy_initialize.md)
to be called again, for instance with a different language model or
options.

## Usage

``` r
spacy_finalize()
```

## Details

Python itself remains loaded in the R session: once started, it cannot
be shut down or switched to a different Python installation or
environment without restarting R.

## Author

Akitaka Matsuo
