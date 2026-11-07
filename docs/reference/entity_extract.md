# Extract or consolidate entities from parsed documents

From an object parsed by
[`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md),
extract the entities as a separate object, or convert the multi-word
entities into single "token" consisting of the concatenated elements of
the multi-word entities.

## Usage

``` r
entity_extract(x, type = c("named", "extended", "all"), concatenator = "_")

entity_consolidate(x, concatenator = "_")
```

## Arguments

- x:

  output from
  [`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md).

- type:

  type of named entities, either `named`, `extended`, or `all`. Extended
  entities are those of types `DATE`, `TIME`, `PERCENT`, `MONEY`,
  `QUANTITY`, `ORDINAL` and `CARDINAL`, and named entities are those of
  all other types. The entity types are those of the language model; see
  its "Label scheme" on <https://spacy.io/models>.

- concatenator:

  the character(s) used to join the elements of multi-word named
  entities

## Value

`entity_extract()` returns a data.frame of all named entities,
containing the following fields:

- `doc_id` name of the document containing the entity

- `sentence_id` the sentence ID containing the entity, within the
  document

- `entity` the named entity

- `entity_type` the type of named entities (e.g. PERSON, ORG, PERCENT,
  etc.)

`entity_consolidate` returns a modified `data.frame` of parsed results,
where the named entities have been combined into a single "token".
Currently, dependency parsing is removed when this consolidation occurs.

## Examples

``` r
if (FALSE) { # \dontrun{
spacy_initialize()

# entity extraction
txt <- "Mr. Smith of moved to San Francisco in December."
parsed <- spacy_parse(txt, entity = TRUE)
entity_extract(parsed)
entity_extract(parsed, type = "all")
} # }
if (FALSE) { # \dontrun{
# consolidating multi-word entities 
txt <- "The House of Representatives voted to suspend aid to South Dakota."
parsed <- spacy_parse(txt, entity = TRUE)
entity_consolidate(parsed)
} # }
```
