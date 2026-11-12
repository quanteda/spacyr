# Parse a text using spaCy

The `spacy_parse()` function calls spaCy to both tokenize and tag the
texts, and returns a data.frame of the results, with one row per token.
The function provides options for universal (`pos`) and detailed (`tag`)
part-of-speech tags, lemmatization (`lemma`), named entity recognition
(`entity`), dependency parsing (`dependency`), noun phrases
(`nounphrase`), and any other token attributes from spaCy
(`additional_attributes`).

## Usage

``` r
spacy_parse(
  x,
  pos = TRUE,
  tag = FALSE,
  lemma = TRUE,
  entity = TRUE,
  dependency = FALSE,
  nounphrase = FALSE,
  multithread,
  additional_attributes = NULL,
  n_process = 1L,
  batch_size = NULL,
  ...
)
```

## Arguments

- x:

  a character object, a quanteda corpus, or a TIF-compliant corpus
  data.frame (see <https://github.com/ropensci/tif>)

- pos:

  logical whether to return universal dependency POS tagset
  (<https://universaldependencies.org/u/pos/>)

- tag:

  logical whether to return detailed part-of-speech tags; the English
  language models use the OntoNotes 5 version of the Penn Treebank tag
  set (<https://spacy.io/models/en>). The tag sets of other language
  models are listed under "Label scheme" on <https://spacy.io/models>.

- lemma:

  logical; include lemmatized tokens in the output (the quality of
  lemmatization depends on the language model)

- entity:

  logical; if `TRUE`, report named entities

- dependency:

  logical; if `TRUE`, analyse and tag dependencies

- nounphrase:

  logical; if `TRUE`, analyse and tag noun phrases tags

- multithread:

  deprecated; it no longer has any effect, and gives a warning if
  supplied. Documents are always processed in batches with spaCy's
  `nlp.pipe()`; use `n_process` and `batch_size` instead.

- additional_attributes:

  a character vector; this option is for extracting additional
  attributes of tokens from spaCy. When the names of attributes are
  supplied, the output data.frame will contain additional variables
  corresponding to the names of the attributes. For instance, when
  `additional_attributes = c("is_punct")`, the output will include an
  additional variable named `is_punct`, which is a Boolean (in R,
  logical) variable indicating whether the token is a punctuation. A
  full list of available attributes is available from
  <https://spacy.io/api/token#attributes>.

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

a `data.frame` of tokenized, parsed, and annotated tokens, of class
`spacyr_parsed`. It keeps the names of all the documents of `x`, also of
those in which spaCy found no tokens, and the document variables of a
quanteda corpus, for the [quanteda
methods](https://spacyr.quanteda.io/reference/quanteda-methods.md) such
as
[`quanteda::as.tokens()`](https://quanteda.io/reference/as.tokens.html).

## Examples

``` r
if (FALSE) { # \dontrun{
spacy_initialize()
# See Chap 5.1 of the NLTK book, http://www.nltk.org/book/ch05.html
txt <- "And now for something completely different."
spacy_parse(txt)
spacy_parse(txt, pos = TRUE, tag = TRUE)
spacy_parse(txt, dependency = TRUE)

txt2 <- c(doc1 = "The fast cat catches mice.\\nThe quick brown dog jumped.", 
          doc2 = "This is the second document.",
          doc3 = "This is a \\\"quoted\\\" text." )
spacy_parse(txt2, entity = TRUE, dependency = TRUE)

txt3 <- "We analyzed the Supreme Court with three natural language processing tools." 
spacy_parse(txt3, entity = TRUE, nounphrase = TRUE)
spacy_parse(txt3, additional_attributes = c("like_num", "is_punct"))
} # }
```
