# Visualize the named entities of parsed documents

Shows documents parsed by
[`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md)
with their named entities highlighted and labelled, as HTML made by
displaCy, spaCy's visualizer (see
<https://spacy.io/usage/visualizers#ent>).

## Usage

``` r
entity_visualize(x, entities = NULL, colors = NULL, view = FALSE)
```

## Arguments

- x:

  the output of
  [`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md),
  best with `offsets = TRUE` (see Details), or of
  [`entity_consolidate()`](https://spacyr.quanteda.io/reference/entity_extract.md)

- entities:

  the entity labels to highlight, as a character vector such as
  `c("PERSON", "ORG")`. The default, `NULL`, highlights the entities of
  every label, and `character(0)` highlights none. The labels are those
  of the language model (see its "Label scheme" on
  <https://spacy.io/models>) and of any entity rules, and are matched
  regardless of case.

- colors:

  a named character vector of colours for labels, such as
  `c(ORG = "#7aecec", PERSON = "lightblue")`, whose names are labels and
  whose values are colours in any form that CSS has. displaCy has
  colours of its own for the labels of spaCy's models, and shows other
  labels in grey.

- view:

  logical; if `TRUE`, also open the result in the browser, or in the
  viewer that the `browser` option is set to (see
  [`utils::browseURL()`](https://rdrr.io/r/utils/browseURL.html)).

## Value

a character vector of length one, with the HTML for all the documents.
It is a fragment and not a whole page, so that it can be put into a
page, an R Markdown document or a Shiny app. It is returned invisibly
when `view = TRUE`, and is `""` when there are no documents.

## Details

The entities are those of the `entity` column of the parse, so it needs
`entity = TRUE`, the default of
[`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md).
They include any from rules given to
[`spacy_initialize()`](https://spacyr.quanteda.io/reference/spacy_initialize.md)
as `entity_patterns`. The documents are not processed again.

A parse does not keep the texts, so the text shown is made from the
tokens. With `spacy_parse(x, offsets = TRUE)` the tokens are spaced as
they were in the text. Otherwise there is a space between every two
tokens, also before punctuation and within words that spaCy splits, such
as `did n't`; the entities are the same, and a message, given once in a
session, says how to get the spacing of the text. In the output of
[`entity_consolidate()`](https://spacyr.quanteda.io/reference/entity_extract.md)
each entity is one token, shown with the `concatenator` that joined its
parts.

The documents are shown in the order of the parse, each in a block of
its own. A document without entities, or without any of the labels in
`entities`, is shown as plain text. The HTML is made by spaCy, which is
initialized if it has not been.

## See also

[`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md);
[`entity_extract()`](https://spacyr.quanteda.io/reference/entity_extract.md)
and
[`spacy_extract_entity()`](https://spacyr.quanteda.io/reference/spacy_extract_entity.md)
for the entities as data.

## Examples

``` r
if (FALSE) { # \dontrun{
spacy_initialize()

txt <- head(data_char_sentences, 8)
parsed <- spacy_parse(txt, offsets = TRUE)

# save as HTML
html <- entity_visualize(parsed)

# open in the browser
entity_visualize(parsed, view = TRUE)

# only some labels, and a colour of one's own
entity_visualize(parsed, entities = c("ORG", "GPE"), colors = c(GPE = "gold"),
                 view = TRUE)
} # }
```
