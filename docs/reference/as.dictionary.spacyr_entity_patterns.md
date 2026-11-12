# Convert entity patterns of phrases to a quanteda dictionary

A method of
[`quanteda::as.dictionary()`](https://quanteda.io/reference/as.dictionary.html)
for the entity patterns that
[`as_entity_patterns()`](https://spacyr.quanteda.io/reference/as_entity_patterns.md)
makes, when all of them are phrases: each label becomes a key, and the
phrases with that label become its values. It needs the quanteda
package, and is available when quanteda is loaded.

## Usage

``` r
# S3 method for class 'spacyr_entity_patterns'
as.dictionary(x, ...)
```

## Arguments

- x:

  a `spacyr_entity_patterns` object, as
  [`as_entity_patterns()`](https://spacyr.quanteda.io/reference/as_entity_patterns.md)
  or
  [`entity_patterns_read()`](https://spacyr.quanteda.io/reference/entity_patterns_read.md)
  returns, whose patterns are all phrases

- ...:

  not used; any argument given here is an error

## Value

A quanteda dictionary with one key for each label of `x`, in the order
in which the labels first occur. Its values are the different phrases
with that label, in the case in which they are written.

## Details

A dictionary holds words and phrases, so `x` can hold only phrases.
Token patterns have no counterpart in a dictionary: when `x` has any,
the conversion stops with an error that names their labels.

A dictionary has less than the entity patterns have, so the conversion
keeps the different pairs of a label and a phrase, and nothing else:

- The `id` of a pattern is dropped.

- So is `case_insensitive`. A dictionary does not say how its values are
  matched: that is set where it is used, as by `case_insensitive` in
  [`quanteda::tokens_lookup()`](https://quanteda.io/reference/tokens_lookup.html)
  or in
  [`as_entity_patterns()`](https://spacyr.quanteda.io/reference/as_entity_patterns.md).

- [`quanteda::dictionary()`](https://quanteda.io/reference/dictionary.html)
  removes the whitespace at the start and the end of a value, and a
  phrase that occurs more than once under a label is kept once.

- The values are grouped by key, so their order is not the order of the
  patterns when the patterns of a label are not next to each other.

quanteda reads `*` and `?` in a dictionary value as wildcards, since its
default is `valuetype = "glob"`, while in a phrase of an entity pattern
they are those characters themselves. The conversion gives a warning
when a phrase has one. To match such values as they are written, use
`valuetype = "fixed"`, as in
`quanteda::tokens_lookup(x, dictionary, valuetype = "fixed")`.

An object with no patterns gives a dictionary with no keys, which
[`as_entity_patterns()`](https://spacyr.quanteda.io/reference/as_entity_patterns.md)
makes into no patterns again. quanteda takes such a dictionary in
[`quanteda::kwic()`](https://quanteda.io/reference/kwic.html) and
[`quanteda::dfm_lookup()`](https://quanteda.io/reference/dfm_lookup.html),
but
[`quanteda::tokens_lookup()`](https://quanteda.io/reference/tokens_lookup.html)
stops with an error for it (in quanteda 4.5.1), so check
[`length()`](https://rdrr.io/r/base/length.html) of the dictionary first
where it can be empty.

To make entity patterns of the dictionary again, with the phrases as
they are written and matched in their own case, use
`as_entity_patterns(d, valuetype = "fixed", case_insensitive = FALSE)`.
Without those arguments,
[`as_entity_patterns()`](https://spacyr.quanteda.io/reference/as_entity_patterns.md)
reads the values of a dictionary as quanteda does: as globs, matched in
any case.

## See also

[`as_entity_patterns()`](https://spacyr.quanteda.io/reference/as_entity_patterns.md),
[`quanteda::dictionary()`](https://quanteda.io/reference/dictionary.html),
[`quanteda::tokens_lookup()`](https://quanteda.io/reference/tokens_lookup.html)

## Examples

``` r
pat <- as_entity_patterns(c(ORG = "Acme Widgets", ORG = "Globex",
                            GPE = "New York"))
d <- quanteda::as.dictionary(pat)
d
#> Dictionary object with 2 key entries.
#> - [ORG]:
#>   - Acme Widgets, Globex
#> - [GPE]:
#>   - New York

# and back, as phrases matched in their own case
as_entity_patterns(d, valuetype = "fixed", case_insensitive = FALSE)
#> Entity patterns: 3 patterns (ORG: 2, GPE: 1)
#>   ORG  "Acme Widgets"
#>   ORG  "Globex"
#>   GPE  "New York"
```
