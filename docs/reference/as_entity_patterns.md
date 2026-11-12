# Create patterns for rule-based named entities

Turn phrases, spaCy-style pattern lists or a data.frame of patterns into
a `spacyr_entity_patterns` object: a checked set of rules for spaCy's
`entity_ruler`, which finds named entities by matching phrases or
sequences of tokens. Creating the object needs neither Python nor spaCy;
pass it to
[`spacy_initialize()`](https://spacyr.quanteda.io/reference/spacy_initialize.md)
as `entity_patterns` to add the rules to the pipeline.

## Usage

``` r
as_entity_patterns(x, ...)

# S3 method for class 'character'
as_entity_patterns(
  x,
  label = NULL,
  id = NULL,
  case_insensitive = FALSE,
  valuetype = c("fixed", "glob", "regex"),
  ...
)

# S3 method for class 'list'
as_entity_patterns(x, case_insensitive = FALSE, ...)

# S3 method for class 'data.frame'
as_entity_patterns(x, case_insensitive = FALSE, concatenator = NULL, ...)

# S3 method for class 'dictionary2'
as_entity_patterns(
  x,
  case_insensitive = TRUE,
  valuetype = c("glob", "regex", "fixed"),
  levels = 1,
  ...
)
```

## Arguments

- x:

  the patterns to convert:

  - a character vector of phrases, each matched exactly as a sequence of
    spaCy's tokens. Labels come from the names of `x`, as in
    `c(ORG = "Acme Widgets")`, or from `label`. With
    `valuetype = "glob"` or `"regex"`, they can have wildcards or be
    regular expressions, as the values of a dictionary can.

  - a list of patterns in spaCy's own structure, each a list with the
    elements `label`, `pattern` and optionally `id`. `pattern` is either
    a single phrase or a list of token patterns, one per token, each a
    named list of token attributes such as `list(LOWER = "dr")`. See
    spaCy's [rule-based
    matching](https://spacy.io/usage/rule-based-matching) for the
    attributes and operators available. A single pattern may also be
    given on its own, rather than in a list of patterns.

  - a data.frame with the columns `label` and `pattern`, and optionally
    `id` and `case_insensitive`. `pattern` is a character column of
    phrases, or a list column holding phrases or token patterns.

  - the entities found by
    [`spacy_extract_entity()`](https://spacyr.quanteda.io/reference/spacy_extract_entity.md),
    a data.frame with the columns `text` and `ent_type`, which become
    phrases and their labels. This turns the entities found in one set
    of texts into rules for others.

  - the entities found by
    [`entity_extract()`](https://spacyr.quanteda.io/reference/entity_extract.md),
    with the columns `entity` and `entity_type`, given with the
    `concatenator` that joined their tokens.

  - a quanteda dictionary, made by
    [`quanteda::dictionary()`](https://quanteda.io/reference/dictionary.html).
    Its top-level keys are the labels, with the values of any nested
    keys under them, unless `levels` says otherwise. A value without
    wildcards becomes a phrase. A value with wildcards (`*` for any
    characters, `?` for one) becomes a token pattern with one token for
    each part separated by spaces, as quanteda matches dictionary values
    to tokens, so that `"dr * who"` matches three tokens.

  - `NULL`, as
    [`spacy_extract_entity()`](https://spacyr.quanteda.io/reference/spacy_extract_entity.md)
    returns when it finds no entities, which gives an empty set of
    patterns.

  - a `spacyr_entity_patterns` object, which is checked again, since it
    may have been edited as a data.frame.

- ...:

  not used.

- label:

  character; the entity label of each phrase, such as `"PERSON"` or
  `"ORG"`, either one for all phrases or one per phrase. If `NULL` (the
  default), the names of `x` are used.

- id:

  character; an optional ID for each phrase, either one for all phrases
  or one per phrase. spaCy gives the ID of the pattern that matched as
  each entity's `ent_id_`.

- case_insensitive:

  logical; if `TRUE`, phrases match regardless of case. The default,
  `FALSE`, matches them exactly, as spaCy does, except for a dictionary,
  where it is `TRUE`, as in quanteda. It also applies to the parts of
  phrases and dictionary values that have wildcards or are regular
  expressions. It does not apply to token patterns, which set case
  through the attribute they match, such as `ORTH` (exact) or `LOWER`
  (any case). For a list, it applies to the patterns that do not set
  `case_insensitive` themselves; for a data.frame, it applies when there
  is no `case_insensitive` column.

- valuetype:

  how phrases and the values of a dictionary are read: `"fixed"` for
  exact phrases, `"glob"` for wildcards (`*` for any characters, `?` for
  one), or `"regex"` for regular expressions, as in
  [`quanteda::tokens_lookup()`](https://quanteda.io/reference/tokens_lookup.html).
  The default is `"fixed"` for a character vector, as suits the names of
  entities, and `"glob"` for a dictionary, as in quanteda. A phrase or
  value with a wildcard, and any with `"regex"`, becomes a token pattern
  with one token for each part separated by spaces; any other is a
  phrase, which spaCy tokenizes. With `"regex"`, each part is a regular
  expression for one of spaCy's tokens, in the dialect of Python's `re`
  module, not of R: for instance, `"^\\p{L}+$"` works in quanteda but
  stops
  [`spacy_initialize()`](https://spacyr.quanteda.io/reference/spacy_initialize.md)
  with the error "bad escape \p". Since
  [`quanteda::dictionary()`](https://quanteda.io/reference/dictionary.html)
  lowercases values by default, which changes escapes such as `"\\D"` to
  `"\\d"`, make a dictionary of regular expressions with
  `tolower = FALSE`.

- concatenator:

  for the output of
  [`entity_extract()`](https://spacyr.quanteda.io/reference/entity_extract.md),
  the character(s) that joined the tokens of each entity, which are
  replaced by spaces. It must be given, since a token that itself
  contains the concatenator, such as an underscore, is changed too; the
  output of
  [`spacy_extract_entity()`](https://spacyr.quanteda.io/reference/spacy_extract_entity.md)
  keeps the text of each entity as it was, and is the better input.

- levels:

  for a dictionary, the levels of its keys that become labels, as in
  [`quanteda::tokens_lookup()`](https://quanteda.io/reference/tokens_lookup.html).
  The default, `1`, labels every value by its top-level key. With more
  than one level, a value is labelled by its keys at those levels,
  joined by `"."`: with `levels = 1:2`, the values under `us` in `place`
  have the label `"place.us"`. Values with no key at any of the levels
  are left out.

  `valuetype` and `levels` are an error for an input that has no use for
  them: `levels` for anything but a dictionary, and `valuetype` for a
  list, a data.frame or a `spacyr_entity_patterns` object, whose phrases
  are matched as they are.

## Value

A `spacyr_entity_patterns` object: a data.frame with one row per pattern
and the columns

- `label` the entity label;

- `pattern` a list column, holding for each pattern a single phrase or a
  list of token patterns;

- `id` the pattern's ID, or `NA`;

- `case_insensitive` for phrases, whether they match regardless of case;
  `NA` for token patterns.

Duplicated patterns are removed.

## Details

Token patterns are checked for their structure only: that each is a list
with one named list per token. spaCy checks the attribute names,
operators and values when the patterns are added to a pipeline, and
reports any errors then.

Two conversions make patterns from R reach spaCy in the form it expects.
The values of spaCy's set operators (`IN`, `NOT_IN`, `IS_SUBSET`,
`IS_SUPERSET` and `INTERSECTS`) are always stored as lists, so that
`list(LOWER = list(IN = "dr"))` stays a list of one value, rather than
becoming a single string. Whole numbers stored as doubles, such as `3`
in `list(LENGTH = 3)`, become integers, since spaCy does not accept
decimal numbers in token patterns.

Phrases, including dictionary values without wildcards, are split into
tokens by the pipeline's own tokenizer, and some of its rules depend on
case: spaCy's English models keep `"Inc."` as one token, but split
`"inc."` into `"inc"` and `"."`. So write phrases in their usual case,
even with `case_insensitive = TRUE`, and make dictionaries with
`quanteda::dictionary(tolower = FALSE)`, since by default it lowercases
their values.

With `case_insensitive = TRUE`, the parts of a phrase or dictionary
value that has a wildcard are put in lower case by R when the patterns
are made, since making them does not need spaCy, while spaCy compares
them with its own lower case form of each token. The two differ for a
few characters, such as the dotted capital I of Turkish, and a value
with such a character and a wildcard may then not match. This holds
wherever the patterns are used, in
[`spacy_initialize()`](https://spacyr.quanteda.io/reference/spacy_initialize.md)
or in
[`spacy_match()`](https://spacyr.quanteda.io/reference/spacy_match.md).
Given the character vector or the dictionary itself, and not patterns
made from it,
[`spacy_match()`](https://spacyr.quanteda.io/reference/spacy_match.md)
lowercases with spaCy and does not have this limit.

Patterns match spaCy's tokens, not characters. For instance, spaCy's
English models make "Prof." a single token, so a pattern for academic
titles needs to list both `"prof"` and `"prof."`, to match titles
written with and without a full stop.

## See also

[`entity_patterns_read()`](https://spacyr.quanteda.io/reference/entity_patterns_read.md)
and
[`entity_patterns_write()`](https://spacyr.quanteda.io/reference/entity_patterns_read.md)
to read and write patterns as files,
[`spacy_initialize()`](https://spacyr.quanteda.io/reference/spacy_initialize.md)
to use them, and
[`as.dictionary.spacyr_entity_patterns()`](https://spacyr.quanteda.io/reference/as.dictionary.spacyr_entity_patterns.md)
to make a quanteda dictionary of patterns that are all phrases

## Examples

``` r
# phrases, labelled by their names or by `label`
as_entity_patterns(c(ORG = "Acme Widgets", GPE = "San Francisco"))
#> Entity patterns: 2 patterns (ORG: 1, GPE: 1)
#>   ORG  "Acme Widgets"
#>   GPE  "San Francisco"
as_entity_patterns(c("Acme Widgets", "Globex"), label = "ORG")
#> Entity patterns: 2 patterns (ORG: 2)
#>   ORG  "Acme Widgets"
#>   ORG  "Globex"

# phrases with wildcards, in any case
as_entity_patterns(c(ORG = "acme*", ORG = "globex corp*"),
                   valuetype = "glob", case_insensitive = TRUE)
#> Entity patterns: 2 patterns (ORG: 2)
#>   ORG  [LOWER ~ /\Aacme[\s\S]*\Z/]
#>   ORG  [LOWER = globex] [LOWER ~ /\Acorp[\s\S]*\Z/]

# a token pattern for people with academic titles: a title, followed by
# the first token of a person the model recognises (ENT_IOB "B") and the
# rest of that person (ENT_IOB "I"), so that it extends one entity without
# running into a person who follows it
titles <- c("dr", "dr.", "prof", "prof.")
as_entity_patterns(list(
  label = "PERSON",
  pattern = list(list(LOWER = list(IN = titles)),
                 list(ENT_TYPE = "PERSON", ENT_IOB = "B"),
                 list(ENT_TYPE = "PERSON", ENT_IOB = "I", OP = "*"))
))
#> Entity patterns: 1 pattern (PERSON: 1)
#>   PERSON  [LOWER in (dr, dr., prof, prof.)] [ENT_TYPE = PERSON, ENT_IOB = B] [ENT_TYPE = PERSON, ENT_IOB = I]*

# a data.frame of patterns
as_entity_patterns(data.frame(label = c("ORG", "ORG"),
                              pattern = c("Acme Widgets", "Globex")))
#> Entity patterns: 2 patterns (ORG: 2)
#>   ORG  "Acme Widgets"
#>   ORG  "Globex"

# a quanteda dictionary, with labels from its keys
if (requireNamespace("quanteda", quietly = TRUE)) {
  dict <- quanteda::dictionary(list(ORG = c("acme widgets", "globex*"),
                                    PERSON = "dr * who"))
  as_entity_patterns(dict)

  # labels from the first two levels of its keys
  nested <- quanteda::dictionary(list(
    place = list(us = c("new york", "boston"), uk = "london")))
  as_entity_patterns(nested)
  as_entity_patterns(nested, levels = 1:2)
}
#> Entity patterns: 3 patterns (place.us: 2, place.uk: 1)
#>   place.us  "new york" (any case)
#>   place.us  "boston" (any case)
#>   place.uk  "london" (any case)

# entities found by spaCy, to use as rules for other texts
if (FALSE) { # \dontrun{
spacy_initialize()
found <- spacy_extract_entity("Acme Widgets hired Jane Smith.")
as_entity_patterns(found)
spacy_finalize()
} # }

# combine sets of patterns
c(as_entity_patterns(c(ORG = "Globex")),
  as_entity_patterns(c(PERSON = "Jane Smith")))
#> Entity patterns: 2 patterns (ORG: 1, PERSON: 1)
#>   ORG     "Globex"
#>   PERSON  "Jane Smith"
```
