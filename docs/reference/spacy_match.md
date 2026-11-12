# Match patterns in texts using spaCy

Find the tokens that match patterns, using spaCy's rule-based matchers
(see <https://spacy.io/usage/rule-based-matching>). A pattern describes
either a sequence of adjacent tokens, or tokens that are connected in
the dependency parse, wherever they are in the sentence: the verb of a
passive clause together with its subject and its agent, for instance. A
token is described by its attributes, which can be those that the
language model assigns, such as the part of speech or the dependency
relation. Words and phrases can be matched too, given as in
**quanteda**: as a character vector, a
[`quanteda::phrase()`](https://quanteda.io/reference/phrase.html) object
or a dictionary, with wildcards or regular expressions according to
`valuetype`. Every kind of pattern gives rows of the same table. Unlike
the patterns given to
[`spacy_initialize()`](https://spacyr.quanteda.io/reference/spacy_initialize.md)
as `entity_patterns`, these do not change the pipeline or the entities
of a document.

## Usage

``` r
spacy_match(
  x,
  pattern,
  valuetype = c("glob", "regex", "fixed"),
  case_insensitive = TRUE,
  overlap = c("longest", "all", "first"),
  n_process = 1L,
  batch_size = NULL,
  ...
)
```

## Arguments

- x:

  a character object, a **quanteda** corpus, or a TIF-compliant corpus
  data.frame (see <https://github.com/ropenscilabs/tif>)

- pattern:

  the patterns to match. The first four kinds are *lexical patterns*,
  which describe tokens by their text and to which `valuetype` and
  `case_insensitive` apply, as in **quanteda**:

  - a character vector, in which each element describes one token, such
    as `"tax*"`. The label of a match is the name of the element, or its
    text when it has no name; elements with the same name are
    alternatives for that label. An element is one token even when it
    contains a space, so `"new york"` matches nothing: give a sequence
    of tokens with
    [`quanteda::phrase()`](https://quanteda.io/reference/phrase.html).

  - a [`quanteda::phrase()`](https://quanteda.io/reference/phrase.html)
    object, or a list of character vectors, in which each element is a
    sequence of adjacent tokens, with one string for each token:
    `phrase("new york*")` is the same as `list(c("new", "york*"))`. The
    strings are used as they are given, and are not tokenized by spaCy,
    so that they set the token boundaries: `phrase("Acme , Inc.")`
    describes three tokens. The label is the name of the element, or
    else its strings joined by a space.

  - a **quanteda** dictionary, which is converted with
    [`as_entity_patterns()`](https://spacyr.quanteda.io/reference/as_entity_patterns.md),
    given `valuetype` and `case_insensitive`: the top-level keys are the
    labels. A value that has no wildcard (or any value, with
    `valuetype = "fixed"`) is a phrase that spaCy tokenizes; a value
    with a wildcard, or a regular expression, is split at its spaces,
    with one part for each token.

  - the collocations found by
    [`quanteda.textstats::textstat_collocations()`](https://quanteda.io/reference/textstat_collocations.html),
    each of which is a sequence of its words, labelled by the
    collocation. The words are matched as they are, as **quanteda**
    matches collocations: only `case_insensitive` applies, and a `*`
    matches a `*`. Use `phrase()` on the collocations to have them read
    according to `valuetype`.

  The others are in spaCy's own structure, and set how they match
  themselves:

  - a named list, in which each name is the label of a pattern, and each
    element is a pattern in spaCy's structure. The names must be unique.
    An element is one of two kinds, and a list can hold both:

    - a *token pattern*, for a sequence of adjacent tokens: a list with
      one named list of attributes for each token, such as
      `list(list(LOWER = "new"), list(LOWER = "york"))`. An element can
      also be a list of such token patterns, which are then alternatives
      for that label.

    - a *dependency pattern*, for tokens related in the dependency
      parse: a list of nodes, each a named list that describes one
      token, with `RIGHT_ID`, a name for the node, which labels the
      token it matches in the output; `RIGHT_ATTRS`, the attributes of
      the token as in a token pattern, such as
      `list(DEP = "nsubjpass")`, or an empty
      [`list()`](https://rdrr.io/r/base/list.html) for any token; and,
      for every node but the first, `LEFT_ID` and `REL_OP`, the name of
      an earlier node and the operator that relates that node to this
      one, such as `">"` when this node is a direct dependent of the
      earlier one. An element whose nodes have these keys is read as a
      dependency pattern. Each label has one dependency pattern: give
      alternative patterns labels of their own.

    Such a list can also hold character vectors, which are sequences as
    in a list of character vectors, and need no name.

  - a `spacyr_entity_patterns` object from
    [`as_entity_patterns()`](https://spacyr.quanteda.io/reference/as_entity_patterns.md),
    whose labels become the labels of the matches. Patterns with the
    same label are alternatives for that label, and the IDs of the
    patterns are ignored. The object can hold phrases as well as token
    patterns; its phrases are tokenized by spaCy, and match exactly or
    in any case as the object says.

- valuetype:

  how the strings of lexical patterns are read: `"glob"` (the default)
  for wildcards, where `*` stands for any number of characters and `?`
  for one; `"regex"` for regular expressions; or `"fixed"` for exact
  matching, as in **quanteda**. Each string is compared with one token,
  and a glob or a fixed string must match the whole of it, while a
  regular expression can match any part. Regular expressions are those
  of Python's `re` module, not of R or of **quanteda**: `"^\\p{L}+$"`,
  for instance, works in **quanteda** and is an error here.

- case_insensitive:

  logical; if `TRUE` (the default, as in **quanteda**), lexical patterns
  match in any case.

  `valuetype` and `case_insensitive` are an error when they are given
  and `pattern` holds no lexical pattern: only spaCy's token or
  dependency patterns, or a `spacyr_entity_patterns` object, whose
  phrases have their own `case_insensitive`.

- overlap:

  which matches of sequences to return where matches of the same label
  overlap: `"longest"` (the default) keeps the longest of them, and of
  those of the same length the one that starts first; `"first"` keeps
  the one that starts first, and of those with the same start the
  longest; `"all"` returns every match, including those inside or
  overlapping another, as spaCy does. Matches of different labels can
  overlap whatever the value. It does not apply to dependency patterns,
  all of whose matches are returned: in a list that holds both kinds it
  applies to the token patterns, and it has no effect when `pattern`
  holds only dependency patterns, so that it can be given whatever the
  patterns are.

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

  not used. An argument that is not one of those above is an error.

## Value

A `data.frame` with the same columns for every kind of pattern, and no
rows when nothing matches. A match of a sequence is one row. A match of
a dependency pattern is one row for each node of the pattern, each of
`length` 1, with the same `match_id`; two nodes can match the same
token, which then has a row for each.

- `doc_id`:

  the document

- `match_id`:

  the number of the match within the document, starting at 1 in each
  document, so that `doc_id` and `match_id` together identify a match

- `label`:

  the label of the pattern that matched. It does not say which of a
  label's alternative patterns matched, which spaCy does not report.

- `node`:

  for a dependency pattern, the name of the node that the token matched,
  from `RIGHT_ID`; `NA` for a sequence

- `sentence_id`, `token_id`:

  the sentence of the first token of the sequence, or of the node's
  token, and the position of that token in its sentence, both starting
  at 1 as in
  [`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md).
  A sequence that crosses a sentence boundary is given the sentence of
  its first token. Both are `NA` when the document has no sentence
  boundaries, as when the pipeline has neither a parser nor a sentence
  segmenter.

- `text`:

  the matched text: of the whole sequence, or of the node's token

- `start_id`:

  the position in the document of the first token of the sequence, or of
  the node's token, starting at 1 and counting every token of spaCy's,
  as the rows of
  [`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md)
  do

- `length`:

  the number of tokens: of the sequence, or 1 for a node

Rows are in the order of the documents in `x`. Within a document,
matches are in the order of the `start_id` of their first row: the first
token of a sequence, or the token of the first node of a dependency
pattern. Of the matches that start at the same token, sequences come
first, by `length` (the shortest first) and then by the order of the
labels in `pattern`; matches of dependency patterns follow, by the
positions of the tokens of their other nodes, taken in the order of the
nodes, and then by the order of the labels. `match_id` numbers the
matches of a document in that order, sequences and dependency matches
together, and the rows of a dependency match are in the order of the
pattern's nodes. The order does not depend on `overlap`.

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

Lexical patterns are compared with spaCy's tokens, which differ from
those of
[`quanteda::tokens()`](https://quanteda.io/reference/tokens.html):
spaCy's English models split `"U.K.-based"` into three tokens, for
instance. A string of a lexical pattern is one token, and matches only
where spaCy made the same token: `phrase("Acme, Inc.")` asks for a token
`Acme,`, which spaCy does not make, while `phrase("Acme , Inc.")`
matches the three tokens of `"Acme, Inc."`.
[`spacy_tokenize()`](https://spacyr.quanteda.io/reference/spacy_tokenize.md)
shows the tokens of a text. spaCy also makes a token of a space that
follows another space, which a pattern of a space matches. To match as
**quanteda** does on the same tokens, with its regular expressions,
apply [`quanteda::index()`](https://quanteda.io/reference/index.html) or
[`quanteda::tokens_lookup()`](https://quanteda.io/reference/tokens_lookup.html)
to `quanteda::as.tokens(spacy_parse(x))`.

A string without a wildcard is compared with the token's text or, with
`case_insensitive = TRUE`, its lower case form (spaCy's `ORTH` and
`LOWER`). A glob with a wildcard becomes a regular expression for the
whole of that text or lower case form, in which a wildcard stands for
any characters, including the newlines of spaCy's whitespace tokens.
Lower case is spaCy's throughout, so that a pattern ignores case in the
same way with a wildcard as without. A regular expression is applied to
the token's text, with the flag `(?i)` when `case_insensitive = TRUE`.

The phrases of a `spacyr_entity_patterns` object, and dictionary values
without a wildcard, are split into tokens by spaCy's tokenizer, and
match the same sequence of tokens in a document, as described for
[`as_entity_patterns()`](https://spacyr.quanteda.io/reference/as_entity_patterns.md).
They are matched with spaCy's `PhraseMatcher`, which stays fast for many
thousands of phrases, as are the sequences of lexical patterns that have
no wildcard or regular expression. A phrase that matches in any case, as
dictionary values do, is tokenized as it is written, and spaCy's
tokenizer can split the same word differently in another case: it keeps
`"Inc."` as one token but splits `"inc."` into two, so the phrase
`"acme widgets, inc."` does not match the text `"Acme Widgets, Inc."`,
while the phrase `"Acme Widgets, Inc."` in any case does. A warning is
given when a component of the pipeline, such as `merge_entities`,
changes the tokens of the documents, since these phrases may then not
match.

The operators in the `REL_OP` of a dependency pattern are spaCy's: among
others, `"A > B"` when B is a direct dependent of A, `"A < B"` when B is
the head of A, `"A >> B"` when B is anywhere below A, and `"A . B"` when
B directly follows A; see
<https://spacy.io/usage/rule-based-matching#dependencymatcher> for all
of them. A dependency pattern can match many times in a sentence: a verb
and any one of its dependents gives one match for each dependent. The
pipeline needs a dependency parser, or another component that sets
dependencies: when `pattern` holds a dependency pattern that relates
nodes, a document that has no dependency parse is an error, rather than
a document without matches.

Matching adds little to the time that parsing takes, except for many
token patterns: a few thousand make it much slower, so give phrases as
lexical patterns or phrases where you can, not as token patterns.
Lexical patterns and dictionary values with wildcards or regular
expressions are token patterns, but those of a single token are combined
into one for each label. Patterns that need no entities are faster after
`spacy_initialize(entity = FALSE)`.

## Kinds of pattern

What `pattern` can be, and which arguments apply to each kind:

|  |  |  |  |  |
|----|----|----|----|----|
| `pattern` | Meaning | Label | `valuetype`, `case_insensitive` | `overlap` |
| character vector | each element describes one token | its name, or else its text | apply | applies |
| `phrase()` object, or a list of character vectors | each element is a sequence, with one string for each token; the strings are not tokenized again | its name, or else its strings joined by a space | apply, to each string | applies |
| **quanteda** dictionary | converted by [`as_entity_patterns()`](https://spacyr.quanteda.io/reference/as_entity_patterns.md): a value without a wildcard is a phrase that spaCy tokenizes, and one with a wildcard or a regular expression is split at its spaces | the top-level key | apply | applies |
| collocations | each is a sequence of its words, matched as they are | the collocation | only `case_insensitive` applies; a `valuetype` other than `"fixed"` is an error | applies |
| named list of spaCy token patterns | a sequence of tokens described by their attributes | the name | an error if given | applies |
| `spacyr_entity_patterns` object | its phrases, tokenized by spaCy, and its token patterns | its `label` | an error if given | applies |
| named list of dependency patterns | one token for each node, anywhere in a sentence | the name | an error if given | does not apply, and has no effect when there are no other patterns |

A list can hold character vectors, token patterns and dependency
patterns together; `valuetype` and `case_insensitive` then apply to its
character vectors.

How each kind is matched:

|  |  |  |
|----|----|----|
|  | Sequences of tokens | Dependency patterns |
| Matched by spaCy's | `PhraseMatcher`, for lexical patterns and dictionary values without a wildcard or a regular expression, and for the phrases of entity patterns; otherwise `Matcher` | `DependencyMatcher` |
| Patterns for one label | any number, as alternatives | one |
| `n_process`, `batch_size` | apply | apply |
| Rows for one match | one | one for each node |
| The pipeline needs | the components that set the attributes asked for: only its tokenizer for lexical patterns and phrases | a dependency parse, in every document |

Patterns of every kind are matched in one pass over the documents, so
the texts are parsed once for a list that holds both token and
dependency patterns.

## Matches and quanteda

`overlap = "longest"`, the default, chooses among overlapping matches as
[`quanteda::tokens_lookup()`](https://quanteda.io/reference/tokens_lookup.html)
does with its default, `nested_scope = "key"`: no token is in two
matches of the same key, and a value that lies inside a value of another
key is a match for both keys. The two are equivalent when they start
from the same candidate spans under the same keys, and then give the
same number of matches for each key in each document. Applying
`tokens_lookup()` to spaCy's tokens,
`quanteda::as.tokens(spacy_parse(x))`, does not guarantee that. In
particular:

- A dictionary value without a wildcard is a phrase, which spaCy's
  tokenizer splits into tokens, while quanteda splits every value at its
  spaces. The value `"Acme, Inc."` matches the three tokens `Acme`, `,`
  and `Inc.` here, where `tokens_lookup()` looks for a token `Acme,` and
  finds nothing.

- The values of a dictionary's nested keys are labelled here by their
  top-level key, which corresponds to `tokens_lookup(levels = 1)`. Its
  default, `levels = 1:5`, reports nested keys such as `place.us`
  separately, and so also keeps matches of two of them that overlap.

A match is a distinct pair of `doc_id` and `match_id`, not a row: count
those to count matches, since a match of a dependency pattern has a row
for each node. With one row for each match,
`m1 <- m[!duplicated(m[c("doc_id", "match_id")]), ]`, the labels of each
document are tokens as `tokens_lookup()` returns them:
`quanteda::as.tokens(split(m1$label, factor(m1$doc_id, levels = ids)))`.
The levels `ids` are the identifiers of all the documents, which keep
those that have no match: `names(x)` for a named character vector,
`sprintf("text%d", seq_along(x))` for an unnamed one,
`as.character(x$doc_id)` for a data.frame with the columns `doc_id` and
`text`, and `quanteda::docnames(x)` for a corpus. The "Rule-Based
Matching" article shows the counts made from them.

[`quanteda::kwic()`](https://quanteda.io/reference/kwic.html) follows a
different rule, which no value of `overlap` gives: it drops a match only
when every one of its tokens is in another match, of any pattern. So it
drops "New York" inside another label's "New York Times", which
`overlap = "longest"` keeps, and keeps both of two matches of one label
that partly overlap, of which `overlap = "longest"` keeps one. A
concordance of the matches themselves, with `kwic(index = as_index(m))`,
shows the matches that `overlap` kept: see
[`as_index()`](https://spacyr.quanteda.io/reference/as_index.md).

## See also

[`as_entity_patterns()`](https://spacyr.quanteda.io/reference/as_entity_patterns.md)
and
[`spacy_initialize()`](https://spacyr.quanteda.io/reference/spacy_initialize.md)
to make matches named entities, and
[`as_index()`](https://spacyr.quanteda.io/reference/as_index.md) to show
matches in their context with
[`quanteda::kwic()`](https://quanteda.io/reference/kwic.html).

## Examples

``` r
if (FALSE) { # \dontrun{
spacy_initialize()

txt <- c(doc1 = "The book was written by Jane. Jane wrote the book.",
         doc2 = "Mistakes were made, and the report is being rewritten.")

# words, with wildcards as in quanteda, in any case
spacy_match(txt, "writ*")
# labelled by their names
spacy_match(txt, c(WRITE = "*writ*", WRITE = "wrote", ERROR = "mistake*"))

# a sequence of tokens needs phrase(): a character element is one token,
# also when it contains a space, so the first of these matches nothing
spacy_match(txt, "the book*")
spacy_match(txt, quanteda::phrase("the book*"))
# the same, as a list of character vectors, with a label
spacy_match(txt, list(TITLE = c("the", "book*")))

# regular expressions, which are Python's
spacy_match(txt, "^(re)?writ", valuetype = "regex")

# matching case
spacy_match(txt, c("the", "jane"), case_insensitive = FALSE)
spacy_match(txt, quanteda::phrase("The book"), valuetype = "fixed",
            case_insensitive = FALSE)

# passive verbs, by the dependency and tag labels of the English models:
# a passive auxiliary, any adverbs or further auxiliaries, and a past
# participle
passive <- list(list(DEP = "auxpass"),
                list(DEP = list(IN = c("advmod", "neg", "aux", "auxpass")),
                     OP = "*"),
                list(TAG = "VBN"))
spacy_match(txt, list(PASSIVE = passive))

# adjectives before a noun: the longest match where matches of a label
# overlap, which is the default, or every match
adj_noun <- list(ADJ_NOUN = list(list(POS = "ADJ", OP = "+"),
                                 list(POS = "NOUN")))
spacy_match("A big red shiny ball.", adj_noun)
spacy_match("A big red shiny ball.", adj_noun, overlap = "all")

# two labels, the second with alternative patterns
spacy_match(txt, list(
  DET_NOUN = list(list(POS = "DET"), list(POS = "NOUN")),
  WRITE = list(list(list(LEMMA = "write")),
               list(list(LEMMA = "rewrite")))
))

# phrases that spaCy tokenizes, matched exactly or in any case
spacy_match(txt, as_entity_patterns(c(TITLE = "the book")))
spacy_match(txt, as_entity_patterns(c(TITLE = "the book"),
                                    case_insensitive = TRUE))

# a quanteda dictionary, with its wildcards
dict <- quanteda::dictionary(list(writing = c("writ*", "wrote", "the book"),
                                  error = "mistake*"))
spacy_match(txt, dict)
spacy_match(txt, dict, case_insensitive = FALSE)

# a dependency pattern for passive clauses: a past participle with a
# passive subject and a passive auxiliary as its dependents
clause <- list(
  list(RIGHT_ID = "verb", RIGHT_ATTRS = list(TAG = "VBN")),
  list(LEFT_ID = "verb", REL_OP = ">", RIGHT_ID = "subject",
       RIGHT_ATTRS = list(DEP = "nsubjpass")),
  list(LEFT_ID = "verb", REL_OP = ">", RIGHT_ID = "aux",
       RIGHT_ATTRS = list(DEP = "auxpass"))
)
m <- spacy_match(txt, list(CLAUSE = clause))
m

# one row for each match, with a column for each node
reshape(m[, c("doc_id", "match_id", "node", "text")],
        idvar = c("doc_id", "match_id"), timevar = "node",
        direction = "wide")

# token and dependency patterns in one list
spacy_match(txt, list(PASSIVE = passive, CLAUSE = clause))
} # }
```
