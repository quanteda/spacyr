# Rule-Based Matching

## Introduction

[`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md)
returns what spaCy knows about each token: its lemma, its part of
speech, its place in the dependency parse. Many questions about a text
are about combinations of tokens: a passive verb, an adjective before a
noun, a verb with its subject and object. spaCy answers these with
*rule-based matching*, which finds the tokens that fit a pattern.
**spacyr** has two functions for it:

- [`spacy_extract_matches()`](https://spacyr.quanteda.io/reference/spacy_extract_matches.md)
  finds *sequences of adjacent tokens*, using spaCy’s `Matcher`. It also
  matches phrases, and the values of a **quanteda** dictionary: if you
  have a list of phrases or a dictionary, go straight to [Phrases and
  dictionaries](#phrases-and-dictionaries).
- [`spacy_extract_dependency_matches()`](https://spacyr.quanteda.io/reference/spacy_extract_dependency_matches.md)
  finds *tokens connected in the dependency parse*, wherever they are in
  the sentence, using spaCy’s `DependencyMatcher`.

Both take patterns written as R lists, in the structure that spaCy
documents in its guide to [rule-based
matching](https://spacy.io/usage/rule-based-matching), and both return a
data.frame. Neither changes the pipeline or the entities of a document:
to turn matches into named entities, see the article on [rule-based
named entities](https://spacyr.quanteda.io/articles/entity_rules.md).

\
[`library`](https://rdrr.io/r/base/library.html)`(`[`"spacyr"`](https://spacyr.quanteda.io)`)`\
[`spacy_initialize`](https://spacyr.quanteda.io/reference/spacy_initialize.md)`(``)`\
`## successfully initialized (spaCy Version: 3.8.18, language model: en_core_web_sm)`

## Token patterns

A token pattern is a list with one element for each token, and each
element is a named list of the attributes that the token must have. This
pattern matches the two tokens “new” and “york”, in any case:

\
`txt`` ``<-`` `[`c`](https://rdrr.io/r/base/c.html)`(``d1 ``=`` ``"New York is larger than York. I prefer new York."``,`\
`         d2 ``=`` ``"The New York Times is printed in New York."``)`\
[`spacy_extract_matches`](https://spacyr.quanteda.io/reference/spacy_extract_matches.md)`(``txt``, `[`list`](https://rdrr.io/r/base/list.html)`(``NY ``=`` `[`list`](https://rdrr.io/r/base/list.html)`(`[`list`](https://rdrr.io/r/base/list.html)`(``LOWER ``=`` ``"new"``)``, `[`list`](https://rdrr.io/r/base/list.html)`(``LOWER ``=`` ``"york"``)``)``)``)`\
`##   doc_id sentence_id token_id label     text start_id length`\
`## 1     d1           1        1    NY New York        1      2`\
`## 2     d1           2        3    NY new York       10      2`\
`## 3     d2           1        2    NY New York        2      2`\
`## 4     d2           1        8    NY New York        8      2`

The name of the pattern, `NY`, is its label. For each match, the result
has:

- the document, and the sentence and token of the first token of the
  match, numbered as in
  [`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md);
- the label and the matched text;
- `start_id`, the position of the first token in the document, and
  `length`, the number of tokens.

Attributes can be any that spaCy sets on a token, including those that
the language model assigns: `LEMMA`, `POS` and `TAG` for the part of
speech, `DEP` for the dependency relation, and `ENT_TYPE` for the entity
type. A token can also have an operator, `OP`, that says how often it
may occur: `"?"` for optional, `"+"` for one or more, `"*"` for none or
more. This pattern finds nouns with the adjectives before them:

\
`ball`` ``<-`` ``"A big red shiny ball and a small blue box."`\
`adj_noun`` ``<-`` `[`list`](https://rdrr.io/r/base/list.html)`(``ADJ_NOUN ``=`` `[`list`](https://rdrr.io/r/base/list.html)`(`[`list`](https://rdrr.io/r/base/list.html)`(``POS ``=`` ``"ADJ"``, OP ``=`` ``"+"``)``, `[`list`](https://rdrr.io/r/base/list.html)`(``POS ``=`` ``"NOUN"``)``)``)`\
[`spacy_extract_matches`](https://spacyr.quanteda.io/reference/spacy_extract_matches.md)`(``ball``, ``adj_noun``)`\
`##   doc_id sentence_id token_id    label               text start_id length`\
`## 1  text1           1        2 ADJ_NOUN big red shiny ball        2      4`\
`## 2  text1           1        3 ADJ_NOUN     red shiny ball        3      3`\
`## 3  text1           1        4 ADJ_NOUN         shiny ball        4      2`\
`## 4  text1           1        8 ADJ_NOUN     small blue box        8      3`\
`## 5  text1           1        9 ADJ_NOUN           blue box        9      2`

### Overlapping matches

That result has more rows than nouns, since spaCy returns every sequence
that fits the pattern: “shiny ball” matches, and so do “red shiny ball”
and “big red shiny ball”. This is the default, `overlap = "all"`, so
that nothing is left out unless you ask. With `overlap = "longest"`,
only the longest of the overlapping matches is kept, and with `"first"`,
the one that starts first:

\
[`spacy_extract_matches`](https://spacyr.quanteda.io/reference/spacy_extract_matches.md)`(``ball``, ``adj_noun``, overlap ``=`` ``"longest"``)`\
`##   doc_id sentence_id token_id    label               text start_id length`\
`## 1  text1           1        2 ADJ_NOUN big red shiny ball        2      4`\
`## 2  text1           1        8 ADJ_NOUN     small blue box        8      3`

`overlap` applies to the matches of one label. Matches of different
labels can still overlap.

### Several patterns

A list can hold several patterns, each with its own label. A label can
also have alternative patterns, given as a list of token patterns:

\
`pats`` ``<-`` `[`list`](https://rdrr.io/r/base/list.html)`(`\
`  ADJ_NOUN ``=`` `[`list`](https://rdrr.io/r/base/list.html)`(`[`list`](https://rdrr.io/r/base/list.html)`(``POS ``=`` ``"ADJ"``, OP ``=`` ``"+"``)``, `[`list`](https://rdrr.io/r/base/list.html)`(``POS ``=`` ``"NOUN"``)``)``,`\
`  COLOUR ``=`` `[`list`](https://rdrr.io/r/base/list.html)`(`[`list`](https://rdrr.io/r/base/list.html)`(`[`list`](https://rdrr.io/r/base/list.html)`(``LOWER ``=`` ``"red"``)``)``,`\
`                `[`list`](https://rdrr.io/r/base/list.html)`(`[`list`](https://rdrr.io/r/base/list.html)`(``LOWER ``=`` ``"blue"``)``)``)`\
`)`\
[`spacy_extract_matches`](https://spacyr.quanteda.io/reference/spacy_extract_matches.md)`(``ball``, ``pats``, overlap ``=`` ``"longest"``)`\
`##   doc_id sentence_id token_id    label               text start_id length`\
`## 1  text1           1        2 ADJ_NOUN big red shiny ball        2      4`\
`## 2  text1           1        3   COLOUR                red        3      1`\
`## 3  text1           1        8 ADJ_NOUN     small blue box        8      3`\
`## 4  text1           1        9   COLOUR               blue        9      1`

The values that an attribute may take can be listed with `IN`, so the
two colours could also be one pattern,
`list(list(LOWER = list(IN = c("red", "blue"))))`. Rows are in the order
of the documents and, within a document, of the matches’ positions.

## Example: passive verbs

Patterns can use the dependency relations that the parser assigns, which
makes them a way to find grammatical constructions. The labels of these
relations differ between language models, so the first step is to look
at how the model in use parses an example. This is `en_core_web_sm`:

\
`passive_txt`` ``<-`` `[`c`](https://rdrr.io/r/base/c.html)`(``p1 ``=`` ``"The book was written by Jane. Jane wrote the book."``,`\
`                 p2 ``=`` ``"Mistakes were made, and the report has not been finished."``)`\
`parsed`` ``<-`` `[`spacy_parse`](https://spacyr.quanteda.io/reference/spacy_parse.md)`(``passive_txt``, tag ``=`` ``TRUE``, dependency ``=`` ``TRUE``,`\
`                      lemma ``=`` ``FALSE``, entity ``=`` ``FALSE``)`\
`parsed``[``parsed``$``doc_id`` ``==`` ``"p1"`` ``&`` ``parsed``$``sentence_id`` ``==`` ``1``, ``]`\
`##   doc_id sentence_id token_id   token   pos tag head_token_id   dep_rel`\
`## 1     p1           1        1     The   DET  DT             2       det`\
`## 2     p1           1        2    book  NOUN  NN             4 nsubjpass`\
`## 3     p1           1        3     was   AUX VBD             4   auxpass`\
`## 4     p1           1        4 written  VERB VBN             4      ROOT`\
`## 5     p1           1        5      by   ADP  IN             4     agent`\
`## 6     p1           1        6    Jane PROPN NNP             5      pobj`\
`## 7     p1           1        7       . PUNCT   .             4     punct`

The English models label the auxiliary of a passive `auxpass`, and tag
the past participle `VBN`. A pattern for a passive verb is then a
passive auxiliary, any adverbs or negations in between, and a past
participle:

\
`passive`` ``<-`` `[`list`](https://rdrr.io/r/base/list.html)`(`\
`  PASSIVE ``=`` `[`list`](https://rdrr.io/r/base/list.html)`(`[`list`](https://rdrr.io/r/base/list.html)`(``DEP ``=`` ``"auxpass"``)``,`\
`                 `[`list`](https://rdrr.io/r/base/list.html)`(``DEP ``=`` `[`list`](https://rdrr.io/r/base/list.html)`(``IN ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"advmod"``, ``"neg"``)``)``, OP ``=`` ``"*"``)``,`\
`                 `[`list`](https://rdrr.io/r/base/list.html)`(``TAG ``=`` ``"VBN"``)``)`\
`)`\
[`spacy_extract_matches`](https://spacyr.quanteda.io/reference/spacy_extract_matches.md)`(``passive_txt``, ``passive``)`\
`##   doc_id sentence_id token_id   label          text start_id length`\
`## 1     p1           1        3 PASSIVE   was written        3      2`\
`## 2     p2           1        2 PASSIVE     were made        2      2`\
`## 3     p2           1       10 PASSIVE been finished       10      2`

It finds the three passives, and not “Jane wrote the book”. Because
`sentence_id` and `token_id` are numbered as in
[`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md),
matches can be joined to the parsed tokens on those two columns and
`doc_id`:

\
`matches`` ``<-`` `[`spacy_extract_matches`](https://spacyr.quanteda.io/reference/spacy_extract_matches.md)`(``passive_txt``, ``passive``)`\
`joined`` ``<-`` `[`merge`](https://rdrr.io/r/base/merge.html)`(``matches``[``, `[`c`](https://rdrr.io/r/base/c.html)`(``"doc_id"``, ``"sentence_id"``, ``"token_id"``, ``"text"``)``]``,`\
`                ``parsed``[``, `[`c`](https://rdrr.io/r/base/c.html)`(``"doc_id"``, ``"sentence_id"``, ``"token_id"``, ``"token"``, ``"dep_rel"``,`\
`                           ``"head_token_id"``)``]``)`\
`joined``[`[`order`](https://rdrr.io/r/base/order.html)`(``joined``$``doc_id``, ``joined``$``sentence_id``, ``joined``$``token_id``)``, ``]`\
`##   doc_id sentence_id token_id          text token dep_rel head_token_id`\
`## 1     p1           1        3   was written   was auxpass             4`\
`## 3     p2           1        2     were made  were auxpass             3`\
`## 2     p2           1       10 been finished  been auxpass            11`

The position of a match is that of its first token, which here is the
auxiliary, not the verb. The `head_token_id` of the auxiliary is the
`token_id` of the verb it belongs to: token 4 of the first sentence of
`p1` is “written”.

The same columns count the sentences that have a passive in each
document. `p2` has two passive matches, but both are in its one
sentence, so it counts once:

\
[`table`](https://rdrr.io/r/base/table.html)`(``matches``$``doc_id``)`\
`## `\
`## p1 p2 `\
`##  1  2`\
[`table`](https://rdrr.io/r/base/table.html)`(`[`unique`](https://rdrr.io/r/base/unique.html)`(``matches``[``, `[`c`](https://rdrr.io/r/base/c.html)`(``"doc_id"``, ``"sentence_id"``)``]``)``$``doc_id``)`\
`## `\
`## p1 p2 `\
`##  1  1`

## Phrases and dictionaries

Phrases are simpler to write than token patterns, and much faster to
match when there are many of them. They are given as an
[`as_entity_patterns()`](https://spacyr.quanteda.io/reference/as_entity_patterns.md)
object, which records the label of each phrase and whether it matches
exactly or in any case:

\
[`spacy_extract_matches`](https://spacyr.quanteda.io/reference/spacy_extract_matches.md)`(``txt``, `[`as_entity_patterns`](https://spacyr.quanteda.io/reference/as_entity_patterns.md)`(`[`c`](https://rdrr.io/r/base/c.html)`(``PLACE ``=`` ``"New York"``)``)``)`\
`##   doc_id sentence_id token_id label     text start_id length`\
`## 1     d1           1        1 PLACE New York        1      2`\
`## 2     d2           1        2 PLACE New York        2      2`\
`## 3     d2           1        8 PLACE New York        8      2`\
[`spacy_extract_matches`](https://spacyr.quanteda.io/reference/spacy_extract_matches.md)`(``txt``, `[`as_entity_patterns`](https://spacyr.quanteda.io/reference/as_entity_patterns.md)`(`[`c`](https://rdrr.io/r/base/c.html)`(``PLACE ``=`` ``"New York"``)``,`\
`                                              case_insensitive ``=`` ``TRUE``)``)`\
`##   doc_id sentence_id token_id label     text start_id length`\
`## 1     d1           1        1 PLACE New York        1      2`\
`## 2     d1           2        3 PLACE new York       10      2`\
`## 3     d2           1        2 PLACE New York        2      2`\
`## 4     d2           1        8 PLACE New York        8      2`

A **quanteda** dictionary can be given directly. Its top-level keys
become the labels, so the values under nested keys take the label of the
top-level key above them. Its values match in any case, with wildcards
as in **quanteda**:

\
`dict`` ``<-`` ``quanteda``::`[`dictionary`](https://quanteda.io/reference/dictionary.html)`(`[`list`](https://rdrr.io/r/base/list.html)`(``place ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"new york"``, ``"york"``)``,`\
`                                  size ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"larg*"``, ``"small*"``, ``"big*"``)``)``)`\
[`spacy_extract_matches`](https://spacyr.quanteda.io/reference/spacy_extract_matches.md)`(``txt``, ``dict``)`\
`##    doc_id sentence_id token_id label     text start_id length`\
`## 1      d1           1        1 place New York        1      2`\
`## 2      d1           1        2 place     York        2      1`\
`## 3      d1           1        4  size   larger        4      1`\
`## 4      d1           1        6 place     York        6      1`\
`## 5      d1           2        3 place new York       10      2`\
`## 6      d1           2        4 place     York       11      1`\
`## 7      d2           1        2 place New York        2      2`\
`## 8      d2           1        3 place     York        3      1`\
`## 9      d2           1        8 place New York        8      2`\
`## 10     d2           1        9 place     York        9      1`

Since “york” is itself a value, it also matches inside each “New York”.
[`quanteda::tokens_lookup()`](https://quanteda.io/reference/tokens_lookup.html)
counts such nested matches of a key once, and so does
`overlap = "longest"` here; the default, `overlap = "all"`, counts both.
Choose one before comparing counts with **quanteda**’s:

\
[`table`](https://rdrr.io/r/base/table.html)`(`[`spacy_extract_matches`](https://spacyr.quanteda.io/reference/spacy_extract_matches.md)`(``txt``, ``dict``)``$``label``)`\
`## `\
`## place  size `\
`##     9     1`\
[`table`](https://rdrr.io/r/base/table.html)`(`[`spacy_extract_matches`](https://spacyr.quanteda.io/reference/spacy_extract_matches.md)`(``txt``, ``dict``, overlap ``=`` ``"longest"``)``$``label``)`\
`## `\
`## place  size `\
`##     5     1`\
`quanteda``::`[`featfreq`](https://quanteda.io/reference/featfreq.html)`(``quanteda``::`[`dfm`](https://quanteda.io/reference/dfm.html)`(``quanteda``::`[`tokens_lookup`](https://quanteda.io/reference/tokens_lookup.html)`(``quanteda``::`[`tokens`](https://quanteda.io/reference/tokens.html)`(``txt``)``, ``dict``)``)``)`\
`## place  size `\
`##     5     1`

The counts can still differ for other texts, because the tokens are
spaCy’s and not **quanteda**’s. What
[`spacy_extract_matches()`](https://spacyr.quanteda.io/reference/spacy_extract_matches.md)
adds to a lookup is where each match is, in a form that joins to the
output of
[`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md).
A dictionary’s phrases and wildcard values can be combined with token
patterns by converting it with
[`as_entity_patterns()`](https://spacyr.quanteda.io/reference/as_entity_patterns.md)
and joining the two with [`c()`](https://rdrr.io/r/base/c.html).

Phrases are split into tokens by spaCy’s tokenizer, and match the same
sequence of tokens in a text. spaCy sometimes splits a word differently
in another case: it keeps `"Inc."` as one token, but splits `"inc."`
into two. So a phrase written as `"acme widgets, inc."` does not match
the text `"Acme Widgets, Inc."` even when it matches in any case, while
the phrase `"Acme Widgets, Inc."` does:

\
`inc`` ``<-`` ``"We wrote to Acme Widgets, Inc. yesterday."`\
[`nrow`](https://rdrr.io/r/base/nrow.html)`(`[`spacy_extract_matches`](https://spacyr.quanteda.io/reference/spacy_extract_matches.md)`(``inc``, `[`as_entity_patterns`](https://spacyr.quanteda.io/reference/as_entity_patterns.md)`(`[`c`](https://rdrr.io/r/base/c.html)`(``ORG ``=`` ``"acme widgets, inc."``)``,`\
`                                                   case_insensitive ``=`` ``TRUE``)``)``)`\
`## [1] 0`\
[`spacy_extract_matches`](https://spacyr.quanteda.io/reference/spacy_extract_matches.md)`(``inc``, `[`as_entity_patterns`](https://spacyr.quanteda.io/reference/as_entity_patterns.md)`(`[`c`](https://rdrr.io/r/base/c.html)`(``ORG ``=`` ``"Acme Widgets, Inc."``)``,`\
`                                              case_insensitive ``=`` ``TRUE``)``)`\
`##   doc_id sentence_id token_id label               text start_id length`\
`## 1  text1           1        4   ORG Acme Widgets, Inc.        4      4`

## Dependency patterns

A token pattern finds tokens that are next to each other. The parts of a
grammatical construction often are not: the subject of a passive verb
can be many words before it. A *dependency pattern* describes tokens by
their relations in the parse instead. It is a list of nodes, and each
node is a named list with:

- `RIGHT_ID`, a name for the node;
- `RIGHT_ATTRS`, the attributes of the token, as in a token pattern;
- for every node but the first, `LEFT_ID`, the name of an earlier node,
  and `REL_OP`, the relation between that node and this one. `">"` means
  that this node is a direct dependent of the earlier one.

This pattern is a past participle, with a passive subject and a passive
auxiliary as its dependents:

\
`passive_dep`` ``<-`` `[`list`](https://rdrr.io/r/base/list.html)`(`\
`  `[`list`](https://rdrr.io/r/base/list.html)`(``RIGHT_ID ``=`` ``"verb"``, RIGHT_ATTRS ``=`` `[`list`](https://rdrr.io/r/base/list.html)`(``TAG ``=`` ``"VBN"``)``)``,`\
`  `[`list`](https://rdrr.io/r/base/list.html)`(``LEFT_ID ``=`` ``"verb"``, REL_OP ``=`` ``">"``, RIGHT_ID ``=`` ``"subject"``,`\
`       RIGHT_ATTRS ``=`` `[`list`](https://rdrr.io/r/base/list.html)`(``DEP ``=`` ``"nsubjpass"``)``)``,`\
`  `[`list`](https://rdrr.io/r/base/list.html)`(``LEFT_ID ``=`` ``"verb"``, REL_OP ``=`` ``">"``, RIGHT_ID ``=`` ``"aux"``,`\
`       RIGHT_ATTRS ``=`` `[`list`](https://rdrr.io/r/base/list.html)`(``DEP ``=`` ``"auxpass"``)``)`\
`)`\
`m`` ``<-`` `[`spacy_extract_dependency_matches`](https://spacyr.quanteda.io/reference/spacy_extract_dependency_matches.md)`(``passive_txt``, `[`list`](https://rdrr.io/r/base/list.html)`(``PASSIVE ``=`` ``passive_dep``)``)`\
`m`\
`##   doc_id match_id   label    node sentence_id token_id start_id    token`\
`## 1     p1        1 PASSIVE    verb           1        4        4  written`\
`## 2     p1        1 PASSIVE subject           1        2        2     book`\
`## 3     p1        1 PASSIVE     aux           1        3        3      was`\
`## 4     p2        1 PASSIVE    verb           1        3        3     made`\
`## 5     p2        1 PASSIVE subject           1        1        1 Mistakes`\
`## 6     p2        1 PASSIVE     aux           1        2        2     were`\
`## 7     p2        2 PASSIVE    verb           1       11       11 finished`\
`## 8     p2        2 PASSIVE subject           1        7        7   report`\
`## 9     p2        2 PASSIVE     aux           1       10       10     been`

The result has one row for each node of the pattern in each match.
`node` says which part of the pattern the token matched, and `match_id`
numbers the matches within each document, so that `doc_id` and
`match_id` together identify a match. Unlike the token pattern, this one
also returns the subject of each passive, and finds the subject “report”
although three words separate it from its verb.

To get one row for each match, with a column for each node, reshape the
result:

\
`wide`` ``<-`` `[`reshape`](https://rdrr.io/r/stats/reshape.html)`(``m``[``, `[`c`](https://rdrr.io/r/base/c.html)`(``"doc_id"``, ``"match_id"``, ``"node"``, ``"token"``)``]``,`\
`                idvar ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"doc_id"``, ``"match_id"``)``, timevar ``=`` ``"node"``,`\
`                direction ``=`` ``"wide"``)`\
[`names`](https://rdrr.io/r/base/names.html)`(``wide``)`` ``<-`` `[`sub`](https://rdrr.io/r/base/grep.html)`(``"^token\\."``, ``""``, `[`names`](https://rdrr.io/r/base/names.html)`(``wide``)``)`\
`wide`\
`##   doc_id match_id     verb  subject  aux`\
`## 1     p1        1  written     book  was`\
`## 4     p2        1     made Mistakes were`\
`## 7     p2        2 finished   report been`

A pattern can follow the parse further. Adding the agent, “by” and its
object, finds who did what to what, for the passives that say so:

\
`agent`` ``<-`` `[`c`](https://rdrr.io/r/base/c.html)`(``passive_dep``, `[`list`](https://rdrr.io/r/base/list.html)`(`\
`  `[`list`](https://rdrr.io/r/base/list.html)`(``LEFT_ID ``=`` ``"verb"``, REL_OP ``=`` ``">"``, RIGHT_ID ``=`` ``"by"``,`\
`       RIGHT_ATTRS ``=`` `[`list`](https://rdrr.io/r/base/list.html)`(``DEP ``=`` ``"agent"``)``)``,`\
`  `[`list`](https://rdrr.io/r/base/list.html)`(``LEFT_ID ``=`` ``"by"``, REL_OP ``=`` ``">"``, RIGHT_ID ``=`` ``"agent"``,`\
`       RIGHT_ATTRS ``=`` `[`list`](https://rdrr.io/r/base/list.html)`(``DEP ``=`` ``"pobj"``)``)`\
`)``)`\
`m`` ``<-`` `[`spacy_extract_dependency_matches`](https://spacyr.quanteda.io/reference/spacy_extract_dependency_matches.md)`(``passive_txt``, `[`list`](https://rdrr.io/r/base/list.html)`(``PASSIVE_AGENT ``=`` ``agent``)``)`\
`m``[``m``$``node`` `[`%in%`](https://rdrr.io/r/base/match.html)` `[`c`](https://rdrr.io/r/base/c.html)`(``"subject"``, ``"verb"``, ``"agent"``)``, `[`c`](https://rdrr.io/r/base/c.html)`(``"doc_id"``, ``"node"``, ``"token"``)``]`\
`##   doc_id    node   token`\
`## 1     p1    verb written`\
`## 2     p1 subject    book`\
`## 5     p1   agent    Jane`

Each label has one dependency pattern, so alternatives, such as passives
with and without an agent, get labels of their own. The other relations
that `REL_OP` can take, such as `">>"` for a dependent at any depth and
`"."` for the next token, are listed in spaCy’s
[documentation](https://spacy.io/usage/rule-based-matching#dependencymatcher).

## What to keep in mind

**Labels belong to the model.** The tags and dependency labels above are
those of spaCy’s English models. Other languages’ models use other
labels, and some do not mark the passive at all. Look at the output of
`spacy_parse(x, tag = TRUE, dependency = TRUE)` for the model you use
before writing a pattern.

**A match is only as good as the parse.** The model tags and parses by
prediction, and makes mistakes. It also makes choices that a pattern has
to follow. Here the second verb of a coordination, “edited”, is attached
to the first as `conj` and has no subject or auxiliary of its own, so
neither passive pattern above finds it:

\
`coord`` ``<-`` ``"The book was written and edited by Jane."`\
[`spacy_extract_matches`](https://spacyr.quanteda.io/reference/spacy_extract_matches.md)`(``coord``, ``passive``)`\
`##   doc_id sentence_id token_id   label        text start_id length`\
`## 1  text1           1        3 PASSIVE was written        3      2`\
[`spacy_extract_dependency_matches`](https://spacyr.quanteda.io/reference/spacy_extract_dependency_matches.md)`(``coord``, `[`list`](https://rdrr.io/r/base/list.html)`(``PASSIVE ``=`` ``passive_dep``)``)``[``, `[`c`](https://rdrr.io/r/base/c.html)`(``"node"``, ``"token"``)``]`\
`##      node   token`\
`## 1    verb written`\
`## 2 subject    book`\
`## 3     aux     was`

A further pattern, for a participle coordinated with a passive verb,
finds it:

\
`conj`` ``<-`` `[`list`](https://rdrr.io/r/base/list.html)`(`\
`  `[`list`](https://rdrr.io/r/base/list.html)`(``RIGHT_ID ``=`` ``"first"``, RIGHT_ATTRS ``=`` `[`list`](https://rdrr.io/r/base/list.html)`(``TAG ``=`` ``"VBN"``)``)``,`\
`  `[`list`](https://rdrr.io/r/base/list.html)`(``LEFT_ID ``=`` ``"first"``, REL_OP ``=`` ``">"``, RIGHT_ID ``=`` ``"aux"``,`\
`       RIGHT_ATTRS ``=`` `[`list`](https://rdrr.io/r/base/list.html)`(``DEP ``=`` ``"auxpass"``)``)``,`\
`  `[`list`](https://rdrr.io/r/base/list.html)`(``LEFT_ID ``=`` ``"first"``, REL_OP ``=`` ``">"``, RIGHT_ID ``=`` ``"verb"``,`\
`       RIGHT_ATTRS ``=`` `[`list`](https://rdrr.io/r/base/list.html)`(``TAG ``=`` ``"VBN"``, DEP ``=`` ``"conj"``)``)`\
`)`\
[`spacy_extract_dependency_matches`](https://spacyr.quanteda.io/reference/spacy_extract_dependency_matches.md)`(``coord``, `[`list`](https://rdrr.io/r/base/list.html)`(``PASSIVE_CONJ ``=`` ``conj``)``)``[``, `[`c`](https://rdrr.io/r/base/c.html)`(``"node"``, ``"token"``)``]`\
`##    node   token`\
`## 1 first written`\
`## 2   aux     was`\
`## 3  verb  edited`

Testing patterns on examples of the constructions you want, and of those
you do not, is the way to find such cases.

**The pipeline has to set what a pattern asks for.** A pattern on `DEP`
needs the parser, and a dependency pattern needs a dependency parse;
both give an error without one. A pattern on `ENT_TYPE` gives a warning
when no component sets entities, as after
`spacy_initialize(entity = FALSE)`, since it would match nothing.

## Speed

Matching adds little to the time that spaCy takes to parse the texts. On
a test with 5,000 sentences, a dictionary of 10,000 phrases and several
hundred wildcard values took no longer than a single token pattern.
Token patterns are slower in large numbers, since spaCy checks each one
against the text: give phrases as phrases, not as token patterns, when
there are thousands of them.

Patterns that do not use entities are faster after
`spacy_initialize(entity = FALSE)`, which leaves out the named entity
recognizer.
[`spacy_initialize()`](https://spacyr.quanteda.io/reference/spacy_initialize.md)
does nothing while spaCy is running, as it has been since the start of
this article, so call
[`spacy_finalize()`](https://spacyr.quanteda.io/reference/spacy_finalize.md)
first:

\
[`spacy_finalize`](https://spacyr.quanteda.io/reference/spacy_finalize.md)`(``)`\
[`spacy_initialize`](https://spacyr.quanteda.io/reference/spacy_initialize.md)`(``entity ``=`` ``FALSE``)`\
`## successfully initialized (spaCy Version: 3.8.18, language model: en_core_web_sm)`\
[`spacy_extract_matches`](https://spacyr.quanteda.io/reference/spacy_extract_matches.md)`(``passive_txt``, ``passive``)`\
`##   doc_id sentence_id token_id   label          text start_id length`\
`## 1     p1           1        3 PASSIVE   was written        3      2`\
`## 2     p2           1        2 PASSIVE     were made        2      2`\
`## 3     p2           1       10 PASSIVE been finished       10      2`\
[`spacy_finalize`](https://spacyr.quanteda.io/reference/spacy_finalize.md)`(``)`

See the article on [improving
performance](https://spacyr.quanteda.io/articles/performance.md) for
more on this, and for `n_process` and `batch_size`, which both functions
also take.
