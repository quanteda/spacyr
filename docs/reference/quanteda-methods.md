# quanteda methods for parsed texts

Methods of quanteda's functions for the output of
[`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md):
its tokens as a quanteda tokens object, and its documents and their
sizes. They need the quanteda package, and are available when both
packages are loaded.

## Usage

``` r
# S3 method for class 'spacyr_parsed'
as.tokens(
  x,
  concatenator = "/",
  include_pos = c("none", "pos", "tag"),
  use_lemma = FALSE,
  ...
)

# S3 method for class 'spacyr_parsed'
docnames(x)

# S3 method for class 'spacyr_parsed'
ndoc(x)

# S3 method for class 'spacyr_parsed'
ntoken(x, ...)

# S3 method for class 'spacyr_parsed'
ntype(x, ...)

# S3 method for class 'spacyr_parsed'
nsentence(x)
```

## Arguments

- x:

  the output of
  [`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md),
  or of
  [`entity_consolidate()`](https://spacyr.quanteda.io/reference/entity_extract.md)
  or
  [`nounphrase_consolidate()`](https://spacyr.quanteda.io/reference/nounphrase_extract.md)

- concatenator:

  the character that joins a token and its part of speech, when
  `include_pos` is not `"none"`

- include_pos:

  which part of speech to add to each token, after `concatenator`:
  `"none"`, the default, for none; `"pos"` for the column `pos`; or
  `"tag"` for the column `tag`

- use_lemma:

  if `TRUE`, the tokens are the lemmas and not the tokens as they are in
  the text

- ...:

  not used

## Value

- `as.tokens()` returns a quanteda tokens object with the tokens of each
  document, with the document variables of the corpus that was parsed,
  if it was a corpus.

- `docnames()` returns the names of the documents, and `ndoc()` their
  number.

- `ntoken()`, `ntype()` and `nsentence()` return the number of tokens,
  of different tokens and of sentences in each document, as an integer
  vector named by document, in the order of `docnames()`.

## Details

The tokens are spaCy's, with its tokens of whitespace, so their
positions are those that
[`spacy_match()`](https://spacyr.quanteda.io/reference/spacy_match.md),
[`spacy_extract_entity()`](https://spacyr.quanteda.io/reference/spacy_extract_entity.md)
and
[`spacy_extract_nounphrases()`](https://spacyr.quanteda.io/reference/spacy_extract_nounphrases.md)
report in `start_id`: see
[`as_index()`](https://spacyr.quanteda.io/reference/as_index.md).

## Which documents there are

All six methods agree on the documents of `x`.
[`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md)
keeps with its output the names of all the documents it was given, in
their order, and the document variables of a quanteda corpus. So a
document in which spaCy found no tokens, such as an empty text, is a
document with no tokens here, although it has no row in `x`.

Taking rows out of `x` can leave that record as it was. It is therefore
used only as far as the rows agree with it:

- When every document that had tokens still has rows, the documents are
  all those that were parsed. Removing some of the tokens, such as the
  punctuation, does not remove a document.

- When a document that had tokens has no rows left, documents were taken
  out of `x`, and the documents are those that have rows. One without
  tokens is then not kept either.

- When `x` has rows that were not parsed with the others, or has no
  record, as an object saved by an earlier version of spacyr or one that
  another function made into a new data.frame, the documents are those
  that have rows, without document variables.

[`rbind()`](https://rdrr.io/r/base/cbind.html) of parses combines their
records when no two of them have a document of the same name: the result
has the documents of all of them, and their document variables when all
have the same ones. When two parses have a document of the same name,
the result has no record, since the rows of the two cannot be told
apart: its documents are those that have rows, without document
variables. Other ways of combining parses, such as
[`dplyr::bind_rows()`](https://dplyr.tidyverse.org/reference/bind_rows.html),
can keep the record of the first. It is then not used when a document
has more rows than it had tokens, or a name that the record does not
have; give the documents different names to be sure.

The documents are in the order in which they were parsed, or in the
order of the rows of `x` when that is another, with the documents
without tokens last.

## Earlier versions

Until spacyr 2.0 these methods were part of quanteda. To use them on an
object that was saved to a file, load spacyr as well as quanteda, for
instance with [`library("spacyr")`](https://spacyr.quanteda.io): reading
the object does not load it.

## See also

[`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md),
[`as_index()`](https://spacyr.quanteda.io/reference/as_index.md),
[`quanteda::as.tokens()`](https://quanteda.io/reference/as.tokens.html),
[`quanteda::docnames()`](https://quanteda.io/reference/docnames.html),
[`quanteda::ntoken()`](https://quanteda.io/reference/ntoken.html)

## Examples

``` r
if (FALSE) { # \dontrun{
spacy_initialize()
corp <- quanteda::corpus(c(d1 = "And now for something different.",
                           d2 = "",
                           d3 = "Jack and Jill are children."),
                         docvars = data.frame(year = 2001:2003))
parsed <- spacy_parse(corp)

quanteda::docnames(parsed)
quanteda::ntoken(parsed)
quanteda::nsentence(parsed)

toks <- quanteda::as.tokens(parsed)
toks
quanteda::docvars(toks)
quanteda::as.tokens(parsed, include_pos = "pos")
spacy_finalize()
} # }
```
