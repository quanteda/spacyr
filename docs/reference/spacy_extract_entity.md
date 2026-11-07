# Extract named entities from texts using spaCy

This function extracts named entities from texts, based on the entity
tag `ent` attributes of documents objects parsed by spaCy (see
<https://spacy.io/usage/linguistic-features#named-entities>).

## Usage

``` r
spacy_extract_entity(
  x,
  output = c("data.frame", "list"),
  type = c("all", "named", "extended"),
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

  type of returned object, either `"list"` or `"data.frame"`.

- type:

  type of named entities, either `named`, `extended`, or `all`. Extended
  entities are those of types `DATE`, `TIME`, `PERCENT`, `MONEY`,
  `QUANTITY`, `ORDINAL` and `CARDINAL`, and named entities are those of
  all other types. The entity types are those of the language model; see
  its "Label scheme" on <https://spacy.io/models>.

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

- `entity_type`:

  type of entity (e.g. `ORG` for organizations)

- `start_id`:

  serial number ID of starting token. This number corresponds with the
  number of `data.frame` returned from `spacy_tokenize(x)` with default
  options.

- `length`:

  number of words (tokens) included in a named entity (e.g. for an
  entity, "New York Stock Exchange"", `length = 4`)

## Examples

``` r
if (FALSE) { # \dontrun{
spacy_initialize()

txt <- c(doc1 = "The Supreme Court is located in Washington D.C.",
         doc2 = "Paul earned a postgraduate degree from MIT.")
spacy_extract_entity(txt)
spacy_extract_entity(txt, output = "list")
} # }
```
