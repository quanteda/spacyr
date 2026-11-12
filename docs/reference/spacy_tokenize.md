# Tokenize text with spaCy

Efficient tokenization (without POS tagging, dependency parsing,
lemmatization, or named entity recognition) of texts using spaCy.

## Usage

``` r
spacy_tokenize(
  x,
  what = c("word", "sentence"),
  remove_punct = FALSE,
  remove_url = FALSE,
  remove_numbers = FALSE,
  remove_separators = TRUE,
  remove_symbols = FALSE,
  padding = FALSE,
  multithread,
  output = c("list", "data.frame"),
  n_process = 1L,
  batch_size = NULL,
  ...
)
```

## Arguments

- x:

  a character object, a quanteda corpus, or a TIF-compliant corpus
  data.frame (see <https://github.com/ropenscilabs/tif>)

- what:

  the unit for splitting the text, available alternatives are:

  `"word"`

  : word segmenter

  `"sentence"`

  : sentence segmenter

- remove_punct:

  remove punctuation tokens.

- remove_url:

  remove tokens that look like a url or email address.

- remove_numbers:

  remove tokens that look like a number (e.g. "334", "3.1415", "fifty").

- remove_separators:

  remove spaces as separators when all other remove functionalities
  (e.g. `remove_punct`) have to be set to `FALSE`. When
  `what = "sentence"`, this option will remove trailing spaces if
  `TRUE`.

- remove_symbols:

  remove symbols. The symbols are either `SYM` in `pos` field, or
  currency symbols. Since this needs the part-of-speech tags, it runs
  all the components of the pipeline, which makes tokenization much
  slower; the other `remove_*` options do not.

- padding:

  if `TRUE`, leave an empty string where the removed tokens previously
  existed. This is useful if a positional match is needed between the
  pre- and post-selected tokens, for instance if a window of adjacency
  needs to be computed.

- multithread:

  deprecated; it no longer has any effect, and gives a warning if
  supplied. Documents are always processed in batches with spaCy's
  `nlp.pipe()`; use `n_process` and `batch_size` instead.

- output:

  type of returning object. Either `list` or `data.frame`.

- n_process:

  the number of processes for spaCy's `nlp.pipe()` to use: `1` (the
  default) processes the documents in the current R session's Python
  process, a larger number starts that many Python processes, and `-1`
  uses all CPUs. Starting the processes and loading the model in each
  takes time, so more than one process helps only for large numbers of
  documents. A custom pipeline component must be defined in an
  importable Python module to be used in other processes.

- batch_size:

  the number of documents that spaCy's `nlp.pipe()` processes together;
  `NULL` (the default) uses the pipeline's default (`nlp.batch_size`).
  Larger batches can be faster, but use more memory.

- ...:

  not used directly

## Value

either `list` or `data.frame` of tokens

## Examples

``` r
if (FALSE) { # \dontrun{
spacy_initialize()
txt <- "And now for something completely different."
spacy_tokenize(txt)

txt2 <- c(doc1 = "The fast cat catches mice.\\nThe quick brown dog jumped.", 
          doc2 = "This is the second document.",
          doc3 = "This is a \\\"quoted\\\" text." )
spacy_tokenize(txt2)
} # }
```
