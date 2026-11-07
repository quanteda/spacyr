# Extract or consolidate noun phrases from parsed documents

From an object parsed by
[`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md),
extract the multi-word noun phrases as a separate object, or convert the
multi-word noun phrases into single "token" consisting of the
concatenated elements of the multi-word noun phrases.

## Usage

``` r
nounphrase_extract(x, concatenator = "_")

nounphrase_consolidate(x, concatenator = "_")
```

## Arguments

- x:

  output from
  [`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md)

- concatenator:

  the character(s) used to join elements of multi-word noun phrases

## Value

`noun` returns a `data.frame` of all named entities, containing the
following fields:

- `doc_id` name of the document containing the noun phrase

- `sentence_id` the sentence ID containing the noun phrase, within the
  document

- `nounphrase` the noun phrase

- `root` the root token of the noun phrase

`nounphrase_consolidate` returns a modified `data.frame` of parsed
results, where the noun phrases have been combined into a single
"token". Currently, dependency parsing is removed when this
consolidation occurs.

## Examples

``` r
if (FALSE) { # \dontrun{
spacy_initialize()

# entity extraction
txt <- "Mr. Smith of moved to San Francisco in December."
parsed <- spacy_parse(txt, nounphrase = TRUE)
entity_extract(parsed)
} # }
if (FALSE) { # \dontrun{
# consolidating multi-word noun phrases
txt <- "The House of Representatives voted to suspend aid to South Dakota."
parsed <- spacy_parse(txt, nounphrase = TRUE)
nounphrase_consolidate(parsed)
} # }
```
