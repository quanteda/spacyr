# Initialize spaCy

Initialize spaCy to call from R.

## Usage

``` r
spacy_initialize(
  model = "en_core_web_sm",
  entity = TRUE,
  max_length = NULL,
  split_hyphens = TRUE,
  entity_patterns = NULL,
  overwrite_entities = TRUE,
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

- split_hyphens:

  logical; if `TRUE` (the default), words joined by a hyphen are split
  as the language model's tokenizer splits them, which for English makes
  three tokens of "eye-opening": "eye", "-" and "opening". If `FALSE`,
  the tokenizer no longer splits at a single hyphen between letters, or
  between a letter and a digit, so that "eye-opening" stays one token,
  and the rest of the pipeline, such as the tagger and lemmatizer,
  processes it as one. Note that the default differs from that of
  **quanteda**'s
  [`quanteda::tokens()`](https://quanteda.io/reference/tokens.html),
  whose `split_hyphens = FALSE` keeps hyphenated words together by
  default. See Details.

- entity_patterns:

  rule-based entities to add to the pipeline: a `spacyr_entity_patterns`
  object, or anything that
  [`as_entity_patterns()`](https://spacyr.quanteda.io/reference/as_entity_patterns.md)
  accepts, such as a named character vector of phrases. spacyr adds
  spaCy's entity ruler, as `spacyr_entity_ruler`, at the end of the
  pipeline, after every component that sets entities; an entity ruler
  saved with the model stays as it is. If the model already has a
  component of that name, for instance because it was saved from a
  pipeline with rules added by spacyr, the new ruler is named
  `spacyr_entity_ruler_2` (or the next free number). If `NULL` (the
  default), the pipeline is not changed.

- overwrite_entities:

  logical; where an entity matched by `entity_patterns` overlaps one
  found by an earlier component, such as the model's named entity
  recognizer, the rule's entity is kept if `TRUE` (the default), and the
  earlier one if `FALSE`, so that the rules only add entities where none
  were found.

- ...:

  not used.

## Details

With `entity_patterns`, the entities found by the rules are returned by
[`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md)
and
[`spacy_extract_entity()`](https://spacyr.quanteda.io/reference/spacy_extract_entity.md)
like any others, also when `entity = FALSE`. Patterns that ask for an
entity type (`ENT_TYPE`) or for tokens inside an entity (`ENT_IOB`)
build on the entities of earlier components, such as the model's `ner`
or a ruler saved with the model, so they give a warning when no earlier
component sets entities, for instance with `entity = FALSE`. Phrases are
tokenized with the pipeline's own tokenizer, and those marked
`case_insensitive` match the lower case form of each token. A component
that changes the tokens, such as spaCy's `merge_entities`, can stop
phrases from matching when it comes before the ruler, which gives a
warning.

With `split_hyphens = FALSE`, the tokenizer still splits wherever the
model's tokenizer did other than at a single hyphen within a word:
between numbers, so that "3-4" is still three tokens ("3", "-" and "4"),
where **quanteda**'s `tokens(split_hyphens = FALSE)` keeps it as one; at
two or more hyphens, as in "a–b"; and at the start or end of a word. The
models were trained on text with hyphenated words split, so their tags,
lemmas and dependencies for a hyphenated word kept whole can differ from
those for its parts. Only the language's default infix rules are
changed: a model saved with infix rules of its own, or whose tokenizer
is not spaCy's rule-based one, as for Chinese and Japanese, is left as
it is. A warning is given if the tokenizer still splits some hyphenated
words, between letters or between a letter and a digit, for whatever
reason. Many languages, such as German, do not split them in the first
place. Phrase patterns of a ruler saved with the model, such as an
`entity_ruler`, were tokenized when the model was saved, so those
containing hyphenated words may no longer match; changing the tokenizer
gives a warning when an active component has phrase patterns. Those of
`entity_patterns` are tokenized after the change.

Phrases are matched quickly, even many thousands of them, and so are
patterns of a single token with a regular expression, such as dictionary
values with a wildcard, which spacyr combines into one regular
expression for each label. Other token patterns are checked one by one,
and so are phrases marked `case_insensitive` when the patterns also
include phrases that are not, which makes parsing slower when there are
many of them.

Unless the environment variable `TOKENIZERS_PARALLELISM` is already set,
`spacy_initialize()` sets it to `"false"`. Pipelines that use Hugging
Face's **tokenizers** library, such as some built with
**spacy-transformers**, otherwise print a warning about disabling
parallelism, with versions of **tokenizers** before 0.22.2, again and
again until R is restarted, once the R process is forked after the
library has been used, for instance by
[`parallel::mcparallel()`](https://rdrr.io/r/parallel/mcparallel.html);
saving a file in RStudio has also been reported to trigger it. The
setting controls the library's tokenizer threads; its effect on total
runtime depends on the pipeline and the workload. It applies to the
whole R process, Python included, and stays after
[`spacy_finalize()`](https://spacyr.quanteda.io/reference/spacy_finalize.md);
if initialization fails, the previous value is restored. A value set
before calling `spacy_initialize()` is kept, even an empty one, which
**tokenizers** reads as `"false"`. Setting
`Sys.setenv(TOKENIZERS_PARALLELISM = "true")` turns off the library's
safeguard against deadlocks: a forked process, such as a worker of
[`parallel::mclapply()`](https://rdrr.io/r/parallel/mclapply.html), or
of `n_process` greater than 1 when the workers are started by fork, that
uses **tokenizers** after the parent has used it can then hang. Leave
the setting at `"false"` whenever that can happen.

## See also

[`as_entity_patterns()`](https://spacyr.quanteda.io/reference/as_entity_patterns.md)

## Author

Akitaka Matsuo, Johannes B. Gruber

## Examples

``` r
if (FALSE) { # \dontrun{
# academic titles as part of a person's name
titles <- c("dr", "dr.", "prof", "prof.", "professor")
pats <- as_entity_patterns(list(
    label = "PERSON",
    pattern = list(list(LOWER = list(IN = titles)),
                   list(ENT_TYPE = "PERSON", ENT_IOB = "B"),
                   list(ENT_TYPE = "PERSON", ENT_IOB = "I", OP = "*"))))
spacy_initialize(entity_patterns = pats)
spacy_extract_entity("Prof. Jane Smith met Dr Bob Jones in Paris.")
spacy_finalize()

# phrases, with labels as names
spacy_initialize(entity_patterns = c(ORG = "Acme Widgets", GPE = "Ruritania"))
spacy_finalize()
} # }
```
