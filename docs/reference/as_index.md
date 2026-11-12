# Convert matches, entities or noun phrases to a quanteda index

Turn the positions that
[`spacy_match()`](https://spacyr.quanteda.io/reference/spacy_match.md),
[`spacy_extract_entity()`](https://spacyr.quanteda.io/reference/spacy_extract_entity.md)
or
[`spacy_extract_nounphrases()`](https://spacyr.quanteda.io/reference/spacy_extract_nounphrases.md)
return into an index of quanteda, as
[`quanteda::index()`](https://quanteda.io/reference/index.html) makes,
so that [`quanteda::kwic()`](https://quanteda.io/reference/kwic.html)
can show each of them in its context. Making the index needs neither
quanteda nor spaCy.

## Usage

``` r
as_index(x)
```

## Arguments

- x:

  the output of
  [`spacy_match()`](https://spacyr.quanteda.io/reference/spacy_match.md),
  [`spacy_extract_entity()`](https://spacyr.quanteda.io/reference/spacy_extract_entity.md)
  or
  [`spacy_extract_nounphrases()`](https://spacyr.quanteda.io/reference/spacy_extract_nounphrases.md):
  a data.frame with the columns `doc_id`, `start_id` and `length`. It
  can also be `NULL`, which
  [`spacy_extract_entity()`](https://spacyr.quanteda.io/reference/spacy_extract_entity.md)
  and
  [`spacy_extract_nounphrases()`](https://spacyr.quanteda.io/reference/spacy_extract_nounphrases.md)
  return when they find nothing, and which gives an index with no rows.

## Value

An object of class `index`, as
[`quanteda::index()`](https://quanteda.io/reference/index.html) returns:
a data.frame with one row for each row of `x`, in the same order, and
the columns

- `docname` the document, from `doc_id`, in Unicode's composed form
  (NFC), as the details describe;

- `from` and `to` the positions of the first and last token, from
  `start_id` and `length`;

- `pattern` a factor: the `label` of a match, the `ent_type` of an
  entity, or `"nounphrase"` for a noun phrase.

## Details

The positions count spaCy's tokens from 1 in each document, with its
tokens of whitespace. They are the positions in
`quanteda::as.tokens(spacy_parse(x))` for the same texts and the same
pipeline, and not those in `quanteda::tokens(x)`, which are quanteda's
tokens, or in the output of
[`spacy_tokenize()`](https://spacyr.quanteda.io/reference/spacy_tokenize.md),
which by default leaves out whitespace. So give
[`quanteda::kwic()`](https://quanteda.io/reference/kwic.html) the tokens
of
[`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md),
as in the examples.
[`quanteda::kwic()`](https://quanteda.io/reference/kwic.html) does not
check that an index was made from the tokens it is given: with other
tokens, it shows whatever is at those positions.

[`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md)
needs the sentences of each document, which come from the parser of the
language model or from a sentence segmenter. In a pipeline that sets no
sentence boundaries,
[`spacy_match()`](https://spacyr.quanteda.io/reference/spacy_match.md)
still returns the positions of its matches, but
[`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md)
fails, and so cannot give the tokens for a concordance.

quanteda keeps the names of documents in Unicode's composed form (NFC),
so that an "e" followed by a combining accent becomes the single
accented character. `as_index()` does the same to `doc_id` when the
stringi package is installed, which quanteda needs: the matches of a
document whose name is not in that form then keep their place in the
concordance, which would otherwise drop them without a message. Giving
the same
[`quanteda::corpus()`](https://quanteda.io/reference/corpus.html) to
[`spacy_match()`](https://spacyr.quanteda.io/reference/spacy_match.md)
and to
[`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md)
has the same effect, since the names in a corpus are already in that
form.

A match of a dependency pattern has one row for each of its nodes, and
so one row in the index for each node, also when two nodes are the same
token. [`quanteda::kwic()`](https://quanteda.io/reference/kwic.html)
keeps the rows of the index in their order, and drops those of documents
that the tokens do not have. When the tokens have every document, row
`i` of the concordance is row `i` of `x`, so the other columns of `x`,
such as `match_id` and `node`, can be added to it.

The concordance shows the matches that it is given. Which matches
[`spacy_match()`](https://spacyr.quanteda.io/reference/spacy_match.md)
returns where they overlap is set by its `overlap`, whose rule is not
that of `quanteda::kwic(x, pattern)`, as the details of
[`spacy_match()`](https://spacyr.quanteda.io/reference/spacy_match.md)
describe. A concordance of matches keeps a "New York" inside another
label's "New York Times", for instance, which quanteda's own search for
the two would drop.

## See also

[`spacy_match()`](https://spacyr.quanteda.io/reference/spacy_match.md),
[`spacy_extract_entity()`](https://spacyr.quanteda.io/reference/spacy_extract_entity.md),
[`spacy_extract_nounphrases()`](https://spacyr.quanteda.io/reference/spacy_extract_nounphrases.md),
[`quanteda::kwic()`](https://quanteda.io/reference/kwic.html)

## Examples

``` r
# an index needs no spaCy: here, of matches written by hand
m <- data.frame(doc_id = c("d1", "d1"), label = c("city", "paper"),
                start_id = c(2, 2), length = c(2, 3))
as_index(m)
#>   docname from to pattern
#> 1      d1    2  3    city
#> 2      d1    2  4   paper
as_index(NULL)
#> [1] docname from    to      pattern
#> <0 rows> (or 0-length row.names)

if (FALSE) { # \dontrun{
spacy_initialize()
txt <- c(d1 = "The New York Times is a paper in New York.",
         d2 = "Jane Smith wrote the book in Boston.")
toks <- quanteda::as.tokens(spacy_parse(txt))

# matches in context
m <- spacy_match(txt, quanteda::phrase(c("new york", "the book")))
quanteda::kwic(toks, index = as_index(m), window = 3)

# entities and noun phrases
quanteda::kwic(toks, index = as_index(spacy_extract_entity(txt)), window = 3)
quanteda::kwic(toks, index = as_index(spacy_extract_nounphrases(txt)),
               window = 3)
spacy_finalize()
} # }
```
