# Extract matches of token patterns and phrases from texts using spaCy

Find sequences of tokens that match patterns, using spaCy's rule-based
`Matcher` (see <https://spacy.io/usage/rule-based-matching>). A pattern
describes each token of a sequence by its attributes, which can be those
that the language model assigns, such as the part of speech or the
dependency relation. Phrases, and the values of a **quanteda**
dictionary, can be matched too. Unlike the patterns given to
[`spacy_initialize()`](https://spacyr.quanteda.io/reference/spacy_initialize.md)
as `entity_patterns`, these do not change the pipeline or the entities
of a document.

## Usage

``` r
spacy_extract_matches(
  x,
  patterns,
  overlap = c("all", "longest", "first"),
  n_process = 1L,
  batch_size = NULL,
  ...
)
```

## Arguments

- x:

  a character object or a TIF-compliant corpus data.frame (see
  <https://github.com/ropensci/tif>)

- patterns:

  the patterns to match, either:

  - a named list, in which each name is the label of a pattern, and each
    element is a token pattern in spaCy's structure: a list with one
    named list of attributes for each token, such as
    `list(list(LOWER = "new"), list(LOWER = "york"))`. An element can
    also be a list of such token patterns, which are then alternatives
    for that label. The names must be unique.

  - a `spacyr_entity_patterns` object from
    [`as_entity_patterns()`](https://spacyr.quanteda.io/reference/as_entity_patterns.md),
    whose labels become the labels of the matches. Patterns with the
    same label are alternatives for that label, and the IDs of the
    patterns are ignored. The object can hold phrases as well as token
    patterns; this is the way to match phrases, exactly or, with
    `case_insensitive = TRUE`, in any case.

  - a **quanteda** dictionary, which is converted with
    [`as_entity_patterns()`](https://spacyr.quanteda.io/reference/as_entity_patterns.md)
    and its defaults: the top-level keys are the labels, and values
    match in any case, with wildcards as in **quanteda**. Call
    [`as_entity_patterns()`](https://spacyr.quanteda.io/reference/as_entity_patterns.md)
    yourself to change these.

- overlap:

  which matches to return where matches of the same label overlap:
  `"all"` (the default) returns every match, including those inside or
  overlapping another, as spaCy does; `"longest"` keeps the longest of
  them, and `"first"` the one that starts first. Matches of different
  labels can overlap whatever the value.

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

A `data.frame` with one row for each match, and no rows when nothing
matches:

- `doc_id`:

  the document

- `sentence_id`, `token_id`:

  the sentence of the first token of the match, and the position of that
  token in its sentence, both starting at 1 as in
  [`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md).
  A match that crosses a sentence boundary is given the sentence of its
  first token. Both are `NA` when the document has no sentence
  boundaries, as when the pipeline has neither a parser nor a sentence
  segmenter.

- `label`:

  the label of the pattern that matched. It does not say which of a
  label's alternative patterns matched, which spaCy does not report.

- `text`:

  the matched text

- `start_id`:

  the position of the first token of the match in the document, starting
  at 1, as in
  [`spacy_extract_entity()`](https://spacyr.quanteda.io/reference/spacy_extract_entity.md)

- `length`:

  the number of tokens matched

Rows are in the order of the documents in `x`; within a document, by
`start_id`, then by `length` (the shortest first), then by the order of
the labels in `patterns`. The order does not depend on `overlap`.

## Details

Patterns are matched against spaCy's tokens, and an attribute can only
match when a component of the pipeline sets it: `DEP` needs the parser,
for instance, and spaCy gives an error when the component is missing.
Patterns that ask for an entity type (`ENT_TYPE` or `ENT_IOB`) give a
warning when no component sets entities, as after
`spacy_initialize(entity = FALSE)`, since they then match nothing. The
labels of tags and dependency relations differ between language models;
`spacy_parse(x, tag = TRUE, dependency = TRUE)` shows those of the model
in use. A match is only as good as the model's annotation of the text.

The values of spaCy's set operators (`IN`, `NOT_IN`, `IS_SUBSET`,
`IS_SUPERSET` and `INTERSECTS`) can be vectors of any length, and whole
numbers need not be integers, as for
[`as_entity_patterns()`](https://spacyr.quanteda.io/reference/as_entity_patterns.md).

Phrases are split into tokens by spaCy's tokenizer, and match the same
sequence of tokens in a document, as described for
[`as_entity_patterns()`](https://spacyr.quanteda.io/reference/as_entity_patterns.md).
They are matched with spaCy's `PhraseMatcher`, which stays fast for many
thousands of phrases. A phrase that matches in any case, as dictionary
values do, is tokenized as it is written, and spaCy's tokenizer can
split the same word differently in another case: it keeps `"Inc."` as
one token but splits `"inc."` into two, so the phrase
`"acme widgets, inc."` does not match the text `"Acme Widgets, Inc."`,
while the phrase `"Acme Widgets, Inc."` in any case does. A warning is
given when a component of the pipeline, such as `merge_entities`,
changes the tokens of the documents, since phrases may then not match.

Matching adds little to the time that parsing takes, except for many
token patterns: a few thousand make it much slower, so give phrases as
phrases where you can, not as token patterns. Dictionary values with
wildcards are token patterns, but those of a single word are combined
into one for each label. Patterns that need no entities are faster after
`spacy_initialize(entity = FALSE)`.

## See also

[`spacy_extract_dependency_matches()`](https://spacyr.quanteda.io/reference/spacy_extract_dependency_matches.md)
for tokens connected in the dependency parse;
[`as_entity_patterns()`](https://spacyr.quanteda.io/reference/as_entity_patterns.md)
and
[`spacy_initialize()`](https://spacyr.quanteda.io/reference/spacy_initialize.md)
to make matches named entities.

## Examples

``` r
if (FALSE) { # \dontrun{
spacy_initialize()

txt <- c(doc1 = "The book was written by Jane. Jane wrote the book.",
         doc2 = "Mistakes were made, and the report is being rewritten.")

# passive verbs, by the dependency and tag labels of the English models:
# a passive auxiliary, any adverbs or further auxiliaries, and a past
# participle
passive <- list(
  PASSIVE = list(list(DEP = "auxpass"),
                 list(DEP = list(IN = c("advmod", "neg", "aux", "auxpass")),
                      OP = "*"),
                 list(TAG = "VBN"))
)
spacy_extract_matches(txt, passive)

# two labels, the second with alternative patterns
spacy_extract_matches(txt, list(
  DET_NOUN = list(list(POS = "DET"), list(POS = "NOUN")),
  WRITE = list(list(list(LEMMA = "write")),
               list(list(LEMMA = "rewrite")))
))

# phrases, matched exactly or in any case
spacy_extract_matches(txt, as_entity_patterns(c(TITLE = "the book")))
spacy_extract_matches(txt, as_entity_patterns(c(TITLE = "the book"),
                                              case_insensitive = TRUE))

# a quanteda dictionary, with its wildcards
dict <- quanteda::dictionary(list(writing = c("writ*", "wrote", "the book"),
                                  error = "mistake*"))
spacy_extract_matches(txt, dict)
} # }
```
