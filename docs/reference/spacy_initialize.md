# Initialize spaCy

Initialize spaCy to call from R.

## Usage

``` r
spacy_initialize(
  model = "en_core_web_sm",
  entity = TRUE,
  max_length = NULL,
  ...
)
```

## Arguments

- model:

  Language package for loading spaCy. Example: `en_core_web_sm`
  (English) and `de_core_news_sm` (German). Default is `en_core_web_sm`.
  This can also be the path to a model directory.

- entity:

  logical; if `FALSE` is selected, named entity recognition is turned
  off in spaCy. This will speed up the parsing as it will exclude `ner`
  from the pipeline. For details of spaCy pipeline, see
  <https://spacy.io/usage/processing-pipelines>.

- max_length:

  integer; the maximum number of characters in a single document that
  spaCy will accept (`nlp.max_length`), a whole number no larger than
  `.Machine$integer.max`. If `NULL` (the default), spaCy's default of
  1,000,000 is used. Larger values require roughly 1GB of temporary
  memory per 100,000 characters for the parser and entity recogniser.

- ...:

  not used.

## Author

Akitaka Matsuo, Johannes B. Gruber
