# Extract noun phrases from texts using spaCy

This function extracts noun phrases from documents, based on the
`noun_chunks` attributes of documents objects parsed by spaCy (see
<https://spacy.io/usage/linguistic-features#noun-chunks>).

## Usage

``` r
spacy_extract_nounphrases(
  x,
  output = c("data.frame", "list"),
  multithread,
  n_process = 1L,
  batch_size = NULL,
  ...
)
```

## Arguments

- x:

  a character object or a TIF-compliant corpus data.frame (see
  <https://github.com/ropensci/tif>)

- output:

  type of returned object, either `"data.frame"` or `"list"`

- multithread:

  deprecated; it no longer has any effect, and gives a warning if
  supplied. Documents are always processed in batches with spaCy's
  `nlp.pipe()`; use `n_process` and `batch_size` instead.

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

  unused

## Value

either a `list` or `data.frame` of tokens

## Details

When the option `output = "data.frame"` is selected, the function
returns a `data.frame` with the following fields.

- `root_text`:

  contents of root token

- `start_id`:

  serial number ID of starting token: its position in the document,
  starting at 1 and counting every token of spaCy's, as the rows of
  `spacy_parse(x)` do. Whitespace tokens are counted, so where a
  document has them this is not the position among the tokens of
  `spacy_tokenize(x)` with default options, which leaves them out.

- `root_id`:

  serial number ID of root token

- `length`:

  number of words (tokens) included in a noun-phrase (e.g. for a
  noun-phrase, "individual car owners", `length = 3`)

## Examples

``` r
if (FALSE) { # \dontrun{
spacy_initialize()

txt <- c(doc1 = "Natural language processing is a branch of computer science.",
         doc2 = "Paul earned a postgraduate degree from MIT.")
spacy_extract_nounphrases(txt)
spacy_extract_nounphrases(txt, output = "list")
} # }
```
