# Extract matches of dependency patterns from texts using spaCy

Find tokens that are connected in the dependency parse in the way a
pattern describes, using spaCy's `DependencyMatcher` (see
<https://spacy.io/usage/rule-based-matching#dependencymatcher>). Where
[`spacy_extract_matches()`](https://spacyr.quanteda.io/reference/spacy_extract_matches.md)
finds sequences of adjacent tokens, a dependency pattern finds tokens by
their relations, wherever they are in the sentence, and returns each of
them: the verb of a passive clause together with its subject and its
agent, for instance.

## Usage

``` r
spacy_extract_dependency_matches(
  x,
  patterns,
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

  a named list of dependency patterns in spaCy's structure, in which
  each name is the label of a pattern. A pattern is a list of nodes,
  each a named list that describes one token:

  - `RIGHT_ID`: a name for the node, which labels the token it matches
    in the output;

  - `RIGHT_ATTRS`: the attributes of the token, as for a token of
    [`spacy_extract_matches()`](https://spacyr.quanteda.io/reference/spacy_extract_matches.md),
    such as `list(DEP = "nsubjpass")`; an empty
    [`list()`](https://rdrr.io/r/base/list.html) matches any token;

  - `LEFT_ID` and `REL_OP`, for every node but the first: the name of an
    earlier node, and the operator that relates that node to this one,
    such as `">"` when this node is a direct dependent of the earlier
    one.

  The names must be unique, and each label has one pattern: give
  alternative patterns labels of their own.

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

A `data.frame` with one row for each node of the pattern in each match,
and no rows when nothing matches. Two nodes of a pattern can match the
same token, which then has a row for each:

- `doc_id`:

  the document

- `match_id`:

  the number of the match within the document, starting at 1 in each
  document, so that `doc_id` and `match_id` together identify a match

- `label`:

  the label of the pattern

- `node`:

  the name of the node that the token matched, from `RIGHT_ID`

- `sentence_id`, `token_id`:

  the sentence of the token that the node matched, and its position in
  that sentence, both starting at 1 as in
  [`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md)

- `start_id`:

  the position of the token in the document, starting at 1

- `token`:

  the text of the token

Rows are in the order of the documents in `x`. Within a document,
matches are ordered by the positions of their tokens, taken in the order
of the pattern's nodes (so first by the token of the first node), then
by the order of the labels in `patterns`; `match_id` numbers them in
that order. The rows of a match are in the order of the nodes.

## Details

The operators in `REL_OP` are spaCy's: among others, `"A > B"` when B is
a direct dependent of A, `"A < B"` when B is the head of A, `"A >> B"`
when B is anywhere below A, and `"A . B"` when B directly follows A. See
the link above for all of them.

The pipeline needs a dependency parser, or another component that sets
dependencies: a pattern that relates nodes gives an error for a document
that has no dependency parse, rather than no matches. The labels of
dependency relations and tags differ between language models;
`spacy_parse(x, tag = TRUE, dependency = TRUE)` shows those of the model
in use. A match is only as good as the model's parse of the text.

A pattern can match many times in a sentence: a verb and any one of its
dependents gives one match for each dependent. Patterns that ask for an
entity type (`ENT_TYPE` or `ENT_IOB`) give a warning when no component
sets entities, since they then match nothing.

## See also

[`spacy_extract_matches()`](https://spacyr.quanteda.io/reference/spacy_extract_matches.md)
for sequences of adjacent tokens.

## Examples

``` r
if (FALSE) { # \dontrun{
spacy_initialize()

txt <- c(doc1 = "The book was written by Jane. Jane wrote the book.",
         doc2 = "Mistakes were made, and the report is being rewritten.")

# passive clauses, by the labels of the English models: a past participle
# with a passive subject and a passive auxiliary as its dependents
passive <- list(
  list(RIGHT_ID = "verb", RIGHT_ATTRS = list(TAG = "VBN")),
  list(LEFT_ID = "verb", REL_OP = ">", RIGHT_ID = "subject",
       RIGHT_ATTRS = list(DEP = "nsubjpass")),
  list(LEFT_ID = "verb", REL_OP = ">", RIGHT_ID = "aux",
       RIGHT_ATTRS = list(DEP = "auxpass"))
)
# the same, with the agent: "by" and its object
agent <- c(passive, list(
  list(LEFT_ID = "verb", REL_OP = ">", RIGHT_ID = "by",
       RIGHT_ATTRS = list(DEP = "agent")),
  list(LEFT_ID = "by", REL_OP = ">", RIGHT_ID = "agent",
       RIGHT_ATTRS = list(DEP = "pobj"))
))
m <- spacy_extract_dependency_matches(txt, list(PASSIVE = passive,
                                                PASSIVE_AGENT = agent))
m

# one row for each match, with a column for each node
reshape(m[m$label == "PASSIVE", c("doc_id", "match_id", "node", "token")],
        idvar = c("doc_id", "match_id"), timevar = "node",
        direction = "wide")
} # }
```
