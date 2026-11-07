# Process documents with spaCy (deprecated)

This function is deprecated, and will be removed in a future version of
spacyr, together with the
[get-functions](https://spacyr.quanteda.io/reference/get-functions.md)
that read its result. It gives a warning on every call. Use
[`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md)
instead, which returns all the results in one data.frame.

`process_document()` parses documents with spaCy and returns a handle on
the parsed documents, which are kept in Python until the handle is
garbage collected. They are not affected by later calls to other spacyr
functions. The handle does not keep the language model:
[`spacy_finalize()`](https://spacyr.quanteda.io/reference/spacy_finalize.md)
frees it as usual.

## Usage

``` r
process_document(x, multithread, n_process = 1L, batch_size = NULL, ...)
```

## Arguments

- x:

  a character object or a quanteda corpus

- multithread:

  deprecated; see
  [`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md)

- n_process, batch_size:

  passed to spaCy's `nlp.pipe()`; see
  [`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md)

- ...:

  not used

## Value

an object of class `spacy_out`, for the
[get-functions](https://spacyr.quanteda.io/reference/get-functions.md)

## Examples

``` r
if (FALSE) { # \dontrun{
spacy_initialize()
txt <- c(text1 = "This is the first sentence.\nHere is the second sentence.",
         text2 = "This is the second document.")
# instead of process_document() and get_tokens():
spacy_parse(txt)$token
} # }
```
