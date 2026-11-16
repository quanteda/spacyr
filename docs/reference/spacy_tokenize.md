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
  currency symbols. Since this needs the part of speech, it runs the
  components of the pipeline that set it, which makes tokenization much
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

  the number of processes for spaCy's `nlp.pipe()` to use, as in
  [`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md):
  `1` (the default) uses the current R session's Python process, a
  larger number starts that many Python processes, and `-1` uses all
  CPUs. It is used only when components of the pipeline run, which is
  for `what = "sentence"` and for `remove_symbols = TRUE`. Splitting
  texts into words runs no components, so more processes would only add
  the time to start them: the words are always tokenized in one process,
  whatever `n_process` is.

- batch_size:

  the number of documents that spaCy's `nlp.pipe()` processes together;
  `NULL` (the default) uses the pipeline's default (`nlp.batch_size`).
  Larger batches can be faster, but use more memory.

- ...:

  not used directly

## Value

either `list` or `data.frame` of tokens

## Details

Splitting texts into words runs no component of spaCy's pipeline. Two
options need some of them, and leave out the others: `what = "sentence"`
needs the components that set the sentences, which is the parser in
spaCy's models, and `remove_symbols = TRUE` those that set the part of
speech, which in spaCy's English models are the tagger, the parser and
the attribute ruler. The output is the same as when every component
runs, by the rules described in the details of
[`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md):
a component stays whenever a later one that stays may read what it sets,
and nothing is left out when the pipeline has a component that is not
one of spaCy's standard ones, or a tokenizer that is not spaCy's own,
which can give the documents a function of its own to find the
sentences.

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
