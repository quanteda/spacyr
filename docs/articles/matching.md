# Rule-Based Matching

## Introduction

[`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md)
returns what spaCy knows about each token: its lemma, its part of
speech, its place in the dependency parse. Many questions about a text
are about combinations of tokens: a passive verb, an adjective before a
noun, a verb with its subject and object. spaCy answers these with
*rule-based matching*, which finds the tokens that fit a pattern. In
**spacyr**,
[`spacy_match()`](https://spacyr.quanteda.io/reference/spacy_match.md)
does this, for two kinds of pattern:

- a *token pattern* finds a *sequence of adjacent tokens*, using spaCy’s
  `Matcher`. Words and phrases are matched as sequences too, and are
  given as in **quanteda**: as a character vector, a
  [`phrase()`](https://quanteda.io/reference/phrase.html) object or a
  dictionary, with wildcards. If words or phrases are what you want to
  find, go straight to [Words, phrases and
  dictionaries](#words-phrases-and-dictionaries).
- a *dependency pattern* finds *tokens connected in the dependency
  parse*, wherever they are in the sentence, using spaCy’s
  `DependencyMatcher`.

Token and dependency patterns are written as R lists, in the structure
that spaCy documents in its guide to [rule-based
matching](https://spacy.io/usage/rule-based-matching). Whatever the
pattern, the result is a data.frame with the same columns. Matching does
not change the pipeline or the entities of a document: to turn matches
into named entities, see the article on [rule-based named
entities](https://spacyr.quanteda.io/articles/entity_rules.md).

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
[`spacy_match`](https://spacyr.quanteda.io/reference/spacy_match.md)`(``txt``, `[`list`](https://rdrr.io/r/base/list.html)`(``NY ``=`` `[`list`](https://rdrr.io/r/base/list.html)`(`[`list`](https://rdrr.io/r/base/list.html)`(``LOWER ``=`` ``"new"``)``, `[`list`](https://rdrr.io/r/base/list.html)`(``LOWER ``=`` ``"york"``)``)``)``)`\
`##   doc_id match_id label node sentence_id token_id     text start_id length`\
`## 1     d1        1    NY <NA>           1        1 New York        1      2`\
`## 2     d1        2    NY <NA>           2        3 new York       10      2`\
`## 3     d2        1    NY <NA>           1        2 New York        2      2`\
`## 4     d2        2    NY <NA>           1        8 New York        8      2`

The name of the pattern, `NY`, is its label. For each match, the result
has:

- the document, and `match_id`, the number of the match within the
  document;
- the label, and `node`, which is `NA` for a sequence and is used by
  [dependency patterns](#dependency-patterns);
- the sentence and token of the first token of the match, numbered as in
  [`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md);
- the matched text;
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
[`spacy_match`](https://spacyr.quanteda.io/reference/spacy_match.md)`(``ball``, ``adj_noun``)`\
`##   doc_id match_id    label node sentence_id token_id               text start_id length`\
`## 1  text1        1 ADJ_NOUN <NA>           1        2 big red shiny ball        2      4`\
`## 2  text1        2 ADJ_NOUN <NA>           1        8     small blue box        8      3`

### Overlapping matches

More sequences fit that pattern than the two returned: “shiny ball”
does, and so do “red shiny ball” and “big red shiny ball”. spaCy finds
every one of them, and `overlap` says which to keep where the matches of
a label overlap. The default, `overlap = "longest"`, keeps the longest;
`"first"` keeps the one that starts first; and `"all"` returns every
match:

\
[`spacy_match`](https://spacyr.quanteda.io/reference/spacy_match.md)`(``ball``, ``adj_noun``, overlap ``=`` ``"all"``)`\
`##   doc_id match_id    label node sentence_id token_id               text start_id length`\
`## 1  text1        1 ADJ_NOUN <NA>           1        2 big red shiny ball        2      4`\
`## 2  text1        2 ADJ_NOUN <NA>           1        3     red shiny ball        3      3`\
`## 3  text1        3 ADJ_NOUN <NA>           1        4         shiny ball        4      2`\
`## 4  text1        4 ADJ_NOUN <NA>           1        8     small blue box        8      3`\
`## 5  text1        5 ADJ_NOUN <NA>           1        9           blue box        9      2`

`overlap` applies to the matches of one label. Matches of different
labels can overlap whatever its value.

### Several patterns

A list can hold several patterns, each with its own label. A label can
also have alternative patterns, given as a list of token patterns:

\
`pats`` ``<-`` `[`list`](https://rdrr.io/r/base/list.html)`(`\
`  ADJ_NOUN ``=`` `[`list`](https://rdrr.io/r/base/list.html)`(`[`list`](https://rdrr.io/r/base/list.html)`(``POS ``=`` ``"ADJ"``, OP ``=`` ``"+"``)``, `[`list`](https://rdrr.io/r/base/list.html)`(``POS ``=`` ``"NOUN"``)``)``,`\
`  COLOUR ``=`` `[`list`](https://rdrr.io/r/base/list.html)`(`[`list`](https://rdrr.io/r/base/list.html)`(`[`list`](https://rdrr.io/r/base/list.html)`(``LOWER ``=`` ``"red"``)``)``,`\
`                `[`list`](https://rdrr.io/r/base/list.html)`(`[`list`](https://rdrr.io/r/base/list.html)`(``LOWER ``=`` ``"blue"``)``)``)`\
`)`\
[`spacy_match`](https://spacyr.quanteda.io/reference/spacy_match.md)`(``ball``, ``pats``)`\
`##   doc_id match_id    label node sentence_id token_id               text start_id length`\
`## 1  text1        1 ADJ_NOUN <NA>           1        2 big red shiny ball        2      4`\
`## 2  text1        2   COLOUR <NA>           1        3                red        3      1`\
`## 3  text1        3 ADJ_NOUN <NA>           1        8     small blue box        8      3`\
`## 4  text1        4   COLOUR <NA>           1        9               blue        9      1`

The values that an attribute may take can be listed with `IN`, so the
two colours could also be one pattern,
`list(list(LOWER = list(IN = c("red", "blue"))))`. Rows are in the order
of the documents and, within a document, of the matches’ positions, and
`match_id` numbers them in that order.

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
[`spacy_match`](https://spacyr.quanteda.io/reference/spacy_match.md)`(``passive_txt``, ``passive``)`\
`##   doc_id match_id   label node sentence_id token_id          text start_id length`\
`## 1     p1        1 PASSIVE <NA>           1        3   was written        3      2`\
`## 2     p2        1 PASSIVE <NA>           1        2     were made        2      2`\
`## 3     p2        2 PASSIVE <NA>           1       10 been finished       10      2`

It finds the three passives, and not “Jane wrote the book”. Because
`sentence_id` and `token_id` are numbered as in
[`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md),
matches can be joined to the parsed tokens on those two columns and
`doc_id`:

\
`matches`` ``<-`` `[`spacy_match`](https://spacyr.quanteda.io/reference/spacy_match.md)`(``passive_txt``, ``passive``)`\
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

## Words, phrases and dictionaries

Words and phrases need no token pattern. They are *lexical patterns*,
which describe tokens by their text, and
[`spacy_match()`](https://spacyr.quanteda.io/reference/spacy_match.md)
takes them as **quanteda**’s functions do, with the same arguments:
`valuetype`, which is `"glob"` by default, for wildcards, and
`case_insensitive`, which is `TRUE` by default.

### Words

Each element of a character vector describes one token. With the default
`valuetype`, `*` stands for any number of characters and `?` for one:

\
[`spacy_match`](https://spacyr.quanteda.io/reference/spacy_match.md)`(``txt``, `[`c`](https://rdrr.io/r/base/c.html)`(``"york*"``, ``"print*"``)``)`\
`##   doc_id match_id  label node sentence_id token_id    text start_id length`\
`## 1     d1        1  york* <NA>           1        2    York        2      1`\
`## 2     d1        2  york* <NA>           1        6    York        6      1`\
`## 3     d1        3  york* <NA>           2        4    York       11      1`\
`## 4     d2        1  york* <NA>           1        3    York        3      1`\
`## 5     d2        2 print* <NA>           1        6 printed        6      1`\
`## 6     d2        3  york* <NA>           1        9    York        9      1`

The label of a match is the pattern’s text, or its name when it has one;
elements with the same name are alternatives for one label:

\
[`spacy_match`](https://spacyr.quanteda.io/reference/spacy_match.md)`(``txt``, `[`c`](https://rdrr.io/r/base/c.html)`(``PLACE ``=`` ``"york"``, SIZE ``=`` ``"larg*"``, SIZE ``=`` ``"small*"``)``)`\
`##   doc_id match_id label node sentence_id token_id   text start_id length`\
`## 1     d1        1 PLACE <NA>           1        2   York        2      1`\
`## 2     d1        2  SIZE <NA>           1        4 larger        4      1`\
`## 3     d1        3 PLACE <NA>           1        6   York        6      1`\
`## 4     d1        4 PLACE <NA>           2        4   York       11      1`\
`## 5     d2        1 PLACE <NA>           1        3   York        3      1`\
`## 6     d2        2 PLACE <NA>           1        9   York        9      1`

`valuetype = "regex"` reads the patterns as regular expressions, and
`"fixed"` takes them as they are. `case_insensitive = FALSE` matches
case:

\
[`spacy_match`](https://spacyr.quanteda.io/reference/spacy_match.md)`(``txt``, ``"^(new|york)$"``, valuetype ``=`` ``"regex"``, case_insensitive ``=`` ``FALSE``)`\
`##   doc_id match_id        label node sentence_id token_id text start_id length`\
`## 1     d1        1 ^(new|york)$ <NA>           2        3  new       10      1`

Regular expressions are those of Python’s `re` module, since spaCy
applies them, and not those of R or **quanteda**: `"^\\p{L}+$"` works in
**quanteda** and is an error here. A regular expression can match any
part of a token, while a glob or a fixed pattern must match all of it.

### Phrases

As in **quanteda**, an element of a character vector is one token even
when it contains a space, so `"new york"` finds nothing. A sequence of
tokens is given with
[`quanteda::phrase()`](https://quanteda.io/reference/phrase.html), which
splits its argument at the spaces, or as a list of character vectors
with one string for each token:

\
[`nrow`](https://rdrr.io/r/base/nrow.html)`(`[`spacy_match`](https://spacyr.quanteda.io/reference/spacy_match.md)`(``txt``, ``"new york"``)``)`\
`## [1] 0`\
[`spacy_match`](https://spacyr.quanteda.io/reference/spacy_match.md)`(``txt``, ``quanteda``::`[`phrase`](https://quanteda.io/reference/phrase.html)`(``"new york*"``)``)`\
`##   doc_id match_id     label node sentence_id token_id     text start_id length`\
`## 1     d1        1 new york* <NA>           1        1 New York        1      2`\
`## 2     d1        2 new york* <NA>           2        3 new York       10      2`\
`## 3     d2        1 new york* <NA>           1        2 New York        2      2`\
`## 4     d2        2 new york* <NA>           1        8 New York        8      2`\
[`spacy_match`](https://spacyr.quanteda.io/reference/spacy_match.md)`(`[`c`](https://rdrr.io/r/base/c.html)`(``txt``, d3 ``=`` ``"Two New Yorkers."``)``, `[`list`](https://rdrr.io/r/base/list.html)`(``NY ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"new"``, ``"york*"``)``)``)`\
`##   doc_id match_id label node sentence_id token_id        text start_id length`\
`## 1     d1        1    NY <NA>           1        1    New York        1      2`\
`## 2     d1        2    NY <NA>           2        3    new York       10      2`\
`## 3     d2        1    NY <NA>           1        2    New York        2      2`\
`## 4     d2        2    NY <NA>           1        8    New York        8      2`\
`## 5     d3        1    NY <NA>           1        2 New Yorkers        2      2`

These are the matches that **quanteda** finds for the same pattern in
spaCy’s tokens, which
[`quanteda::as.tokens()`](https://quanteda.io/reference/as.tokens.html)
takes from the output of
[`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md):

\
`quanteda``::`[`index`](https://quanteda.io/reference/index.html)`(``quanteda``::`[`as.tokens`](https://quanteda.io/reference/as.tokens.html)`(`[`spacy_parse`](https://spacyr.quanteda.io/reference/spacy_parse.md)`(``txt``)``)``, ``quanteda``::`[`phrase`](https://quanteda.io/reference/phrase.html)`(``"new york*"``)``)`\
`##   docname from to   pattern`\
`## 1      d1    1  2 new york*`\
`## 2      d1   10 11 new york*`\
`## 3      d2    2  3 new york*`\
`## 4      d2    8  9 new york*`

The strings of a phrase are the tokens: spaCy does not tokenize them
again. So they match only where spaCy made the same tokens of the text,
and spaCy’s tokens are not always those that the spaces suggest.
[`spacy_tokenize()`](https://spacyr.quanteda.io/reference/spacy_tokenize.md)
shows them:

\
`acme`` ``<-`` ``"She joined Acme, Inc. last year."`\
[`spacy_tokenize`](https://spacyr.quanteda.io/reference/spacy_tokenize.md)`(``acme``)``[[``1``]``]`\
`## [1] "She"    "joined" "Acme"   ","      "Inc."   "last"   "year"   "."`\
[`nrow`](https://rdrr.io/r/base/nrow.html)`(`[`spacy_match`](https://spacyr.quanteda.io/reference/spacy_match.md)`(``acme``, ``quanteda``::`[`phrase`](https://quanteda.io/reference/phrase.html)`(``"Acme, Inc."``)``)``)`\
`## [1] 0`\
[`spacy_match`](https://spacyr.quanteda.io/reference/spacy_match.md)`(``acme``, ``quanteda``::`[`phrase`](https://quanteda.io/reference/phrase.html)`(``"Acme , Inc."``)``)``[``, `[`c`](https://rdrr.io/r/base/c.html)`(``"label"``, ``"text"``, ``"start_id"``, ``"length"``)``]`\
`##         label       text start_id length`\
`## 1 Acme , Inc. Acme, Inc.        3      3`

The collocations that
[`quanteda.textstats::textstat_collocations()`](https://quanteda.io/reference/textstat_collocations.html)
finds can be given as they are. Each is the sequence of its words, which
are matched as they are, as **quanteda** matches collocations: only
`case_insensitive` applies to them.

`valuetype` and `case_insensitive` apply to lexical patterns only. Token
patterns and dependency patterns say how they match through their
attributes, and the phrases of an
[`as_entity_patterns()`](https://spacyr.quanteda.io/reference/as_entity_patterns.md)
object each have their own setting, so giving either argument with only
such patterns is an error, rather than being ignored.

### Phrases that spaCy tokenizes

To have spaCy split a phrase into tokens, as it splits the text, give
the phrase as an
[`as_entity_patterns()`](https://spacyr.quanteda.io/reference/as_entity_patterns.md)
object, which records the label of each phrase and whether it matches
exactly or in any case. Unlike the patterns above, these match exactly
by default:

\
[`spacy_match`](https://spacyr.quanteda.io/reference/spacy_match.md)`(``txt``, `[`as_entity_patterns`](https://spacyr.quanteda.io/reference/as_entity_patterns.md)`(`[`c`](https://rdrr.io/r/base/c.html)`(``PLACE ``=`` ``"New York"``)``)``)`\
`##   doc_id match_id label node sentence_id token_id     text start_id length`\
`## 1     d1        1 PLACE <NA>           1        1 New York        1      2`\
`## 2     d2        1 PLACE <NA>           1        2 New York        2      2`\
`## 3     d2        2 PLACE <NA>           1        8 New York        8      2`\
[`spacy_match`](https://spacyr.quanteda.io/reference/spacy_match.md)`(``acme``, `[`as_entity_patterns`](https://spacyr.quanteda.io/reference/as_entity_patterns.md)`(`[`c`](https://rdrr.io/r/base/c.html)`(``ORG ``=`` ``"Acme, Inc."``)``)``)``[``, `[`c`](https://rdrr.io/r/base/c.html)`(``"label"``, ``"text"``, ``"start_id"``, ``"length"``)``]`\
`##   label       text start_id length`\
`## 1   ORG Acme, Inc.        3      3`

### Dictionaries

A **quanteda** dictionary can be given directly. Its top-level keys
become the labels, so the values under nested keys take the label of the
top-level key above them. Its values match in any case, with wildcards
as in **quanteda**, unless `valuetype` or `case_insensitive` say
otherwise:

\
`dict`` ``<-`` ``quanteda``::`[`dictionary`](https://quanteda.io/reference/dictionary.html)`(`[`list`](https://rdrr.io/r/base/list.html)`(``place ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"new york"``, ``"york"``)``,`\
`                                  size ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"larg*"``, ``"small*"``, ``"big*"``)``)``)`\
[`spacy_match`](https://spacyr.quanteda.io/reference/spacy_match.md)`(``txt``, ``dict``)`\
`##   doc_id match_id label node sentence_id token_id     text start_id length`\
`## 1     d1        1 place <NA>           1        1 New York        1      2`\
`## 2     d1        2  size <NA>           1        4   larger        4      1`\
`## 3     d1        3 place <NA>           1        6     York        6      1`\
`## 4     d1        4 place <NA>           2        3 new York       10      2`\
`## 5     d2        1 place <NA>           1        2 New York        2      2`\
`## 6     d2        2 place <NA>           1        8 New York        8      2`

Since “york” is itself a value, it also matches inside each “New York”.
With the default, `overlap = "longest"`, such a nested match of the same
key is dropped, which is what
[`quanteda::tokens_lookup()`](https://quanteda.io/reference/tokens_lookup.html)
does with its own default, `nested_scope = "key"`. For this dictionary
and these texts, the number of matches of each label is then the count
that
[`tokens_lookup()`](https://quanteda.io/reference/tokens_lookup.html)
gives for that key, when it is applied to spaCy’s tokens, which
[`quanteda::as.tokens()`](https://quanteda.io/reference/as.tokens.html)
takes from the output of
[`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md).
Each match of a dictionary value is one row, so
[`table()`](https://rdrr.io/r/base/table.html) counts matches. With
`overlap = "all"`, the nested matches are counted too:

\
[`table`](https://rdrr.io/r/base/table.html)`(`[`spacy_match`](https://spacyr.quanteda.io/reference/spacy_match.md)`(``txt``, ``dict``)``$``label``)`\
`## `\
`## place  size `\
`##     5     1`\
`spacy_tokens`` ``<-`` ``quanteda``::`[`as.tokens`](https://quanteda.io/reference/as.tokens.html)`(`[`spacy_parse`](https://spacyr.quanteda.io/reference/spacy_parse.md)`(``txt``)``)`\
`quanteda``::`[`featfreq`](https://quanteda.io/reference/featfreq.html)`(``quanteda``::`[`dfm`](https://quanteda.io/reference/dfm.html)`(``quanteda``::`[`tokens_lookup`](https://quanteda.io/reference/tokens_lookup.html)`(``spacy_tokens``, ``dict``)``)``)`\
`## place  size `\
`##     5     1`\
[`table`](https://rdrr.io/r/base/table.html)`(`[`spacy_match`](https://spacyr.quanteda.io/reference/spacy_match.md)`(``txt``, ``dict``, overlap ``=`` ``"all"``)``$``label``)`\
`## `\
`## place  size `\
`##     9     1`

The two agree whenever they start from the same candidate matches under
the same keys, since they then choose among overlapping matches by the
same rule. Using spaCy’s tokens for both does not guarantee that:

- A value without a wildcard is a phrase, which spaCy’s tokenizer splits
  into tokens, while **quanteda** splits every value at its spaces. The
  value `"Acme, Inc."` is the three tokens `Acme`, `,` and `Inc.` for
  [`spacy_match()`](https://spacyr.quanteda.io/reference/spacy_match.md),
  which finds it;
  [`tokens_lookup()`](https://quanteda.io/reference/tokens_lookup.html)
  looks for a token `Acme,` and finds nothing:

\
`acme_dict`` ``<-`` ``quanteda``::`[`dictionary`](https://quanteda.io/reference/dictionary.html)`(`[`list`](https://rdrr.io/r/base/list.html)`(``ORG ``=`` ``"Acme, Inc."``)``, tolower ``=`` ``FALSE``)`\
[`spacy_match`](https://spacyr.quanteda.io/reference/spacy_match.md)`(``acme``, ``acme_dict``)``[``, `[`c`](https://rdrr.io/r/base/c.html)`(``"label"``, ``"text"``, ``"start_id"``, ``"length"``)``]`\
`##   label       text start_id length`\
`## 1   ORG Acme, Inc.        3      3`\
`quanteda``::`[`tokens_lookup`](https://quanteda.io/reference/tokens_lookup.html)`(``quanteda``::`[`as.tokens`](https://quanteda.io/reference/as.tokens.html)`(`[`spacy_parse`](https://spacyr.quanteda.io/reference/spacy_parse.md)`(``acme``)``)``, ``acme_dict``)`\
`## tokens of 1 document (0 tokens, 1 type).`\
`## text1 :`\
`## character(0)`

- For a dictionary with nested keys, the labels here are the top-level
  keys, which corresponds to `tokens_lookup(levels = 1)`. Its default,
  `levels = 1:5`, counts nested keys such as `place.us` separately.

The counts can also differ from a lookup on `quanteda::tokens(txt)`,
because the tokens are then **quanteda**’s and not spaCy’s. What
[`spacy_match()`](https://spacyr.quanteda.io/reference/spacy_match.md)
adds to a lookup is where each match is, in a form that joins to the
output of
[`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md).
A dictionary’s phrases and wildcard values can be combined with token
patterns by converting it with
[`as_entity_patterns()`](https://spacyr.quanteda.io/reference/as_entity_patterns.md)
and joining the two with [`c()`](https://rdrr.io/r/base/c.html). To have
the values of a dictionary split at their spaces, as **quanteda** does,
give them with [`phrase()`](https://quanteda.io/reference/phrase.html).

[`quanteda::kwic()`](https://quanteda.io/reference/kwic.html) follows
another rule than
[`tokens_lookup()`](https://quanteda.io/reference/tokens_lookup.html),
which no value of `overlap` gives: it drops a match only when all of its
tokens are in another match, of any pattern. It would drop a “New York”
that lies inside another label’s “New York Times”, which
`overlap = "longest"` keeps, since labels are separate; and it would
keep both of two matches of one label that partly overlap, where
`overlap = "longest"` keeps one.

The phrases of an
[`as_entity_patterns()`](https://spacyr.quanteda.io/reference/as_entity_patterns.md)
object, and dictionary values without a wildcard, are split into tokens
by spaCy’s tokenizer, and match the same sequence of tokens in a text.
spaCy sometimes splits a word differently in another case: it keeps
`"Inc."` as one token, but splits `"inc."` into two. So a phrase written
as `"acme widgets, inc."` does not match the text `"Acme Widgets, Inc."`
even when it matches in any case, while the phrase
`"Acme Widgets, Inc."` does:

\
`inc`` ``<-`` ``"We wrote to Acme Widgets, Inc. yesterday."`\
[`nrow`](https://rdrr.io/r/base/nrow.html)`(`[`spacy_match`](https://spacyr.quanteda.io/reference/spacy_match.md)`(``inc``, `[`as_entity_patterns`](https://spacyr.quanteda.io/reference/as_entity_patterns.md)`(`[`c`](https://rdrr.io/r/base/c.html)`(``ORG ``=`` ``"acme widgets, inc."``)``,`\
`                                         case_insensitive ``=`` ``TRUE``)``)``)`\
`## [1] 0`\
[`spacy_match`](https://spacyr.quanteda.io/reference/spacy_match.md)`(``inc``, `[`as_entity_patterns`](https://spacyr.quanteda.io/reference/as_entity_patterns.md)`(`[`c`](https://rdrr.io/r/base/c.html)`(``ORG ``=`` ``"Acme Widgets, Inc."``)``,`\
`                                    case_insensitive ``=`` ``TRUE``)``)`\
`##   doc_id match_id label node sentence_id token_id               text start_id length`\
`## 1  text1        1   ORG <NA>           1        4 Acme Widgets, Inc.        4      4`

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

A dependency pattern goes in the same named list as a token pattern, and
[`spacy_match()`](https://spacyr.quanteda.io/reference/spacy_match.md)
tells the two apart by these keys. This pattern is a past participle,
with a passive subject and a passive auxiliary as its dependents:

\
`passive_dep`` ``<-`` `[`list`](https://rdrr.io/r/base/list.html)`(`\
`  `[`list`](https://rdrr.io/r/base/list.html)`(``RIGHT_ID ``=`` ``"verb"``, RIGHT_ATTRS ``=`` `[`list`](https://rdrr.io/r/base/list.html)`(``TAG ``=`` ``"VBN"``)``)``,`\
`  `[`list`](https://rdrr.io/r/base/list.html)`(``LEFT_ID ``=`` ``"verb"``, REL_OP ``=`` ``">"``, RIGHT_ID ``=`` ``"subject"``,`\
`       RIGHT_ATTRS ``=`` `[`list`](https://rdrr.io/r/base/list.html)`(``DEP ``=`` ``"nsubjpass"``)``)``,`\
`  `[`list`](https://rdrr.io/r/base/list.html)`(``LEFT_ID ``=`` ``"verb"``, REL_OP ``=`` ``">"``, RIGHT_ID ``=`` ``"aux"``,`\
`       RIGHT_ATTRS ``=`` `[`list`](https://rdrr.io/r/base/list.html)`(``DEP ``=`` ``"auxpass"``)``)`\
`)`\
`m`` ``<-`` `[`spacy_match`](https://spacyr.quanteda.io/reference/spacy_match.md)`(``passive_txt``, `[`list`](https://rdrr.io/r/base/list.html)`(``PASSIVE ``=`` ``passive_dep``)``)`\
`m`\
`##   doc_id match_id   label    node sentence_id token_id     text start_id length`\
`## 1     p1        1 PASSIVE    verb           1        4  written        4      1`\
`## 2     p1        1 PASSIVE subject           1        2     book        2      1`\
`## 3     p1        1 PASSIVE     aux           1        3      was        3      1`\
`## 4     p2        1 PASSIVE    verb           1        3     made        3      1`\
`## 5     p2        1 PASSIVE subject           1        1 Mistakes        1      1`\
`## 6     p2        1 PASSIVE     aux           1        2     were        2      1`\
`## 7     p2        2 PASSIVE    verb           1       11 finished       11      1`\
`## 8     p2        2 PASSIVE subject           1        7   report        7      1`\
`## 9     p2        2 PASSIVE     aux           1       10     been       10      1`

The columns are the same as for a sequence, but a match now has one row
for each node of the pattern, each for a single token. `node` says which
part of the pattern the token matched, and the rows of a match share its
`match_id`, so that `doc_id` and `match_id` together identify a match.
Unlike the token pattern, this one also returns the subject of each
passive, and finds the subject “report” although three words separate it
from its verb.

To get one row for each match, with a column for each node, reshape the
result:

\
`wide`` ``<-`` `[`reshape`](https://rdrr.io/r/stats/reshape.html)`(``m``[``, `[`c`](https://rdrr.io/r/base/c.html)`(``"doc_id"``, ``"match_id"``, ``"node"``, ``"text"``)``]``,`\
`                idvar ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"doc_id"``, ``"match_id"``)``, timevar ``=`` ``"node"``,`\
`                direction ``=`` ``"wide"``)`\
[`names`](https://rdrr.io/r/base/names.html)`(``wide``)`` ``<-`` `[`sub`](https://rdrr.io/r/base/grep.html)`(``"^text\\."``, ``""``, `[`names`](https://rdrr.io/r/base/names.html)`(``wide``)``)`\
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
`m`` ``<-`` `[`spacy_match`](https://spacyr.quanteda.io/reference/spacy_match.md)`(``passive_txt``, `[`list`](https://rdrr.io/r/base/list.html)`(``PASSIVE_AGENT ``=`` ``agent``)``)`\
`m``[``m``$``node`` `[`%in%`](https://rdrr.io/r/base/match.html)` `[`c`](https://rdrr.io/r/base/c.html)`(``"subject"``, ``"verb"``, ``"agent"``)``, `[`c`](https://rdrr.io/r/base/c.html)`(``"doc_id"``, ``"node"``, ``"text"``)``]`\
`##   doc_id    node    text`\
`## 1     p1    verb written`\
`## 2     p1 subject    book`\
`## 5     p1   agent    Jane`

Each label has one dependency pattern, so alternatives, such as passives
with and without an agent, get labels of their own. The other relations
that `REL_OP` can take, such as `">>"` for a dependent at any depth and
`"."` for the next token, are listed in spaCy’s
[documentation](https://spacy.io/usage/rule-based-matching#dependencymatcher).
`overlap` does not apply to dependency patterns: every match is
returned, whatever its value.

### Both kinds of pattern together

A list can hold token patterns and dependency patterns, each under its
own label. They are matched in one pass over the texts, and the matches
come back in one table:

\
`both`` ``<-`` `[`spacy_match`](https://spacyr.quanteda.io/reference/spacy_match.md)`(``passive_txt``[``"p1"``]``, `[`c`](https://rdrr.io/r/base/c.html)`(``passive``, `[`list`](https://rdrr.io/r/base/list.html)`(``CLAUSE ``=`` ``passive_dep``)``)``)`\
`both`\
`##   doc_id match_id   label    node sentence_id token_id        text start_id length`\
`## 1     p1        1 PASSIVE    <NA>           1        3 was written        3      2`\
`## 2     p1        2  CLAUSE    verb           1        4     written        4      1`\
`## 3     p1        2  CLAUSE subject           1        2        book        2      1`\
`## 4     p1        2  CLAUSE     aux           1        3         was        3      1`

Within a document, matches are in the order of the position of their
first row, which for a dependency pattern is the token of its first
node, and `match_id` numbers the two kinds together. A match is a
distinct pair of `doc_id` and `match_id`, not a row: `both` has two
matches in four rows. `overlap` applies to the token patterns of such a
list. Every row is a span of tokens with a `start_id` and a `length`, so
the rows of both kinds can be handled alike: here, to look up each in
the output of
[`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md).

\
`parsed_p1`` ``<-`` ``parsed``[``parsed``$``doc_id`` ``==`` ``"p1"``, ``]`\
[`cbind`](https://rdrr.io/r/base/cbind.html)`(``both``[``, `[`c`](https://rdrr.io/r/base/c.html)`(``"match_id"``, ``"label"``, ``"node"``, ``"text"``)``]``,`\
`      first_token ``=`` ``parsed_p1``$``token``[``both``$``start_id``]``)`\
`##   match_id   label    node        text first_token`\
`## 1        1 PASSIVE    <NA> was written         was`\
`## 2        2  CLAUSE    verb     written     written`\
`## 3        2  CLAUSE subject        book        book`\
`## 4        2  CLAUSE     aux         was         was`

## Matches in context

[`quanteda::kwic()`](https://quanteda.io/reference/kwic.html) shows each
occurrence of a pattern with the tokens around it. It can do the same
for positions found elsewhere, given as an *index*, and
[`as_index()`](https://spacyr.quanteda.io/reference/as_index.md) makes
one from the output of
[`spacy_match()`](https://spacyr.quanteda.io/reference/spacy_match.md).
The positions in a table of matches count spaCy’s tokens, with its
tokens of whitespace, so the tokens to give
[`kwic()`](https://quanteda.io/reference/kwic.html) are those of
[`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md)
for the same texts, and not those of
[`quanteda::tokens()`](https://quanteda.io/reference/tokens.html):

\
`spacy_tokens`` ``<-`` ``quanteda``::`[`as.tokens`](https://quanteda.io/reference/as.tokens.html)`(`[`spacy_parse`](https://spacyr.quanteda.io/reference/spacy_parse.md)`(``txt``)``)`\
`m`` ``<-`` `[`spacy_match`](https://spacyr.quanteda.io/reference/spacy_match.md)`(``txt``, ``dict``)`\
`quanteda``::`[`kwic`](https://quanteda.io/reference/kwic.html)`(``spacy_tokens``, index ``=`` `[`as_index`](https://spacyr.quanteda.io/reference/as_index.md)`(``m``)``, window ``=`` ``3``)`\
`## Keyword-in-context with 6 matches.`\
`##                                                          `\
`##    [d1, 1:2]                | New York | is larger than  `\
`##    [d1, 4:4]    New York is |  larger  | than York.      `\
`##    [d1, 6:6] is larger than |   York   | . I prefer      `\
`##  [d1, 10:11]     . I prefer | new York | .               `\
`##    [d2, 2:3]            The | New York | Times is printed`\
`##    [d2, 8:9]  is printed in | New York | .`

The index has one row for each row of the matches, in the same order, so
the other columns of the matches can be put beside the concordance. For
a dependency pattern, that says which node each line is:

\
`dep`` ``<-`` `[`spacy_match`](https://spacyr.quanteda.io/reference/spacy_match.md)`(``passive_txt``, `[`list`](https://rdrr.io/r/base/list.html)`(``CLAUSE ``=`` ``passive_dep``)``)`\
`kw`` ``<-`` ``quanteda``::`[`kwic`](https://quanteda.io/reference/kwic.html)`(``quanteda``::`[`as.tokens`](https://quanteda.io/reference/as.tokens.html)`(``parsed``)``, index ``=`` `[`as_index`](https://spacyr.quanteda.io/reference/as_index.md)`(``dep``)``, window ``=`` ``2``)`\
[`cbind`](https://rdrr.io/r/base/cbind.html)`(``dep``[``, `[`c`](https://rdrr.io/r/base/c.html)`(``"match_id"``, ``"node"``)``]``, `[`as.data.frame`](https://rdrr.io/r/base/as.data.frame.html)`(``kw``)``[``, `[`c`](https://rdrr.io/r/base/c.html)`(``"docname"``, ``"pre"``, ``"keyword"``, ``"post"``)``]``)`\
`##   match_id    node docname           pre  keyword        post`\
`## 1        1    verb      p1      book was  written     by Jane`\
`## 2        1 subject      p1           The     book was written`\
`## 3        1     aux      p1      The book      was  written by`\
`## 4        1    verb      p2 Mistakes were     made       , and`\
`## 5        1 subject      p2               Mistakes   were made`\
`## 6        1     aux      p2      Mistakes     were      made ,`\
`## 7        2    verb      p2      not been finished           .`\
`## 8        2 subject      p2       and the   report     has not`\
`## 9        2     aux      p2       has not     been  finished .`

A concordance made this way shows the matches that
[`spacy_match()`](https://spacyr.quanteda.io/reference/spacy_match.md)
returned, chosen by `overlap` where they overlap. That is not always
what [`kwic()`](https://quanteda.io/reference/kwic.html) finds when it
searches for the same patterns itself, since its rule is another, as
described [above](#dictionaries): here it leaves out the “York” inside
each “New York”, which belongs to another pattern, where
`overlap = "all"` keeps them.

\
`all_matches`` ``<-`` `[`spacy_match`](https://spacyr.quanteda.io/reference/spacy_match.md)`(``txt``, ``quanteda``::`[`phrase`](https://quanteda.io/reference/phrase.html)`(`[`c`](https://rdrr.io/r/base/c.html)`(``"new york"``, ``"york"``)``)``, overlap ``=`` ``"all"``)`\
[`nrow`](https://rdrr.io/r/base/nrow.html)`(``quanteda``::`[`kwic`](https://quanteda.io/reference/kwic.html)`(``spacy_tokens``, index ``=`` `[`as_index`](https://spacyr.quanteda.io/reference/as_index.md)`(``all_matches``)``)``)`\
`## [1] 9`\
[`nrow`](https://rdrr.io/r/base/nrow.html)`(``quanteda``::`[`kwic`](https://quanteda.io/reference/kwic.html)`(``spacy_tokens``, ``quanteda``::`[`phrase`](https://quanteda.io/reference/phrase.html)`(`[`c`](https://rdrr.io/r/base/c.html)`(``"new york"``, ``"york"``)``)``)``)`\
`## [1] 5`

[`as_index()`](https://spacyr.quanteda.io/reference/as_index.md) also
takes the output of
[`spacy_extract_entity()`](https://spacyr.quanteda.io/reference/spacy_extract_entity.md)
and of
[`spacy_extract_nounphrases()`](https://spacyr.quanteda.io/reference/spacy_extract_nounphrases.md),
whose positions are counted in the same way:

\
`quanteda``::`[`kwic`](https://quanteda.io/reference/kwic.html)`(``spacy_tokens``, index ``=`` `[`as_index`](https://spacyr.quanteda.io/reference/as_index.md)`(`[`spacy_extract_entity`](https://spacyr.quanteda.io/reference/spacy_extract_entity.md)`(``txt``)``)``, window ``=`` ``3``)`\
`## Keyword-in-context with 4 matches.`\
`##                                                                 `\
`##    [d1, 1:2]               |      New York      | is larger than`\
`##  [d1, 10:11]    . I prefer |      new York      | .             `\
`##    [d2, 1:4]               | The New York Times | is printed in `\
`##    [d2, 8:9] is printed in |      New York      | .`

## Counting matches

[`quanteda::tokens_lookup()`](https://quanteda.io/reference/tokens_lookup.html)
replaces the tokens of each document by the keys of the dictionary
values found in it, and a document-feature matrix of the result counts
each key in each document. The matches of
[`spacy_match()`](https://spacyr.quanteda.io/reference/spacy_match.md)
give the same kind of object in two steps. The first keeps one row for
each match, which is a distinct pair of `doc_id` and `match_id`. The
second splits the labels by document, and makes tokens of them:

\
`m`` ``<-`` `[`spacy_match`](https://spacyr.quanteda.io/reference/spacy_match.md)`(``txt``, ``dict``)`\
`m1`` ``<-`` ``m``[``!`[`duplicated`](https://rdrr.io/r/base/duplicated.html)`(``m``[`[`c`](https://rdrr.io/r/base/c.html)`(``"doc_id"``, ``"match_id"``)``]``)``, ``]`\
`labels`` ``<-`` ``quanteda``::`[`as.tokens`](https://quanteda.io/reference/as.tokens.html)`(`[`split`](https://rdrr.io/r/base/split.html)`(``m1``$``label``, `[`factor`](https://rdrr.io/r/base/factor.html)`(``m1``$``doc_id``, levels ``=`` `[`names`](https://rdrr.io/r/base/names.html)`(``txt``)``)``)``)`\
`labels`\
`## tokens of 2 documents (6 tokens, 2 types).`\
`## d1 :`\
`## [1] "place" "size"  "place" "place"`\
`## `\
`## d2 :`\
`## [1] "place" "place"`\
`quanteda``::`[`dfm`](https://quanteda.io/reference/dfm.html)`(``labels``, tolower ``=`` ``FALSE``)`\
`## dfm of 2 documents x 2 features (6 occurrences, 25.00% sparsity).`\
`##     features`\
`## docs place size`\
`##   d1     3    1`\
`##   d2     2    0`

Three details matter:

- The levels of the factor are the names of all the documents, so a
  document without a match stays in the result, with no tokens. Without
  them, [`split()`](https://rdrr.io/r/base/split.html) would leave it
  out. They have to be the identifiers that
  [`spacy_match()`](https://spacyr.quanteda.io/reference/spacy_match.md)
  gives in `doc_id`: `names(x)` for a named character vector, as here;
  `sprintf("text%d", seq_along(x))` for an unnamed one;
  `as.character(x$doc_id)` for a data.frame with the columns `doc_id`
  and `text`; and `quanteda::docnames(x)` for a corpus.
- `tolower = FALSE` keeps the labels as they are:
  [`dfm()`](https://quanteda.io/reference/dfm.html) would otherwise put
  a label such as `PASSIVE` in lower case.
- The matrix has a column for each label that was found.
  [`tokens_lookup()`](https://quanteda.io/reference/tokens_lookup.html)
  gives one for every key, also for a key that matched nothing;
  `quanteda::dfm_match(x, names(dict))` adds those, in the order of the
  dictionary.

For this dictionary and these texts, the result is the matrix that
[`tokens_lookup()`](https://quanteda.io/reference/tokens_lookup.html)
gives on spaCy’s tokens, since the two find the same candidate matches
under the same keys, as described [above](#dictionaries):

\
`quanteda``::`[`dfm`](https://quanteda.io/reference/dfm.html)`(``quanteda``::`[`tokens_lookup`](https://quanteda.io/reference/tokens_lookup.html)`(``spacy_tokens``, ``dict``)``, tolower ``=`` ``FALSE``)`\
`## dfm of 2 documents x 2 features (6 occurrences, 25.00% sparsity).`\
`##     features`\
`## docs place size`\
`##   d1     3    1`\
`##   d2     2    0`

The first step matters for dependency patterns, whose matches have one
row for each node. Counting rows would count each passive clause here
three times:

\
`dep`` ``<-`` `[`spacy_match`](https://spacyr.quanteda.io/reference/spacy_match.md)`(``passive_txt``, `[`list`](https://rdrr.io/r/base/list.html)`(``CLAUSE ``=`` ``passive_dep``)``)`\
[`table`](https://rdrr.io/r/base/table.html)`(``dep``$``doc_id``, ``dep``$``label``)`\
`##     `\
`##      CLAUSE`\
`##   p1      3`\
`##   p2      6`\
`dep1`` ``<-`` ``dep``[``!`[`duplicated`](https://rdrr.io/r/base/duplicated.html)`(``dep``[`[`c`](https://rdrr.io/r/base/c.html)`(``"doc_id"``, ``"match_id"``)``]``)``, ``]`\
`quanteda``::`[`dfm`](https://quanteda.io/reference/dfm.html)`(``quanteda``::`[`as.tokens`](https://quanteda.io/reference/as.tokens.html)`(`[`split`](https://rdrr.io/r/base/split.html)`(``dep1``$``label``, `[`factor`](https://rdrr.io/r/base/factor.html)`(``dep1``$``doc_id``, levels ``=`` `[`names`](https://rdrr.io/r/base/names.html)`(``passive_txt``)``)``)``)``,`\
`              tolower ``=`` ``FALSE``)`\
`## dfm of 2 documents x 1 feature (3 occurrences, 0.00% sparsity).`\
`##     features`\
`## docs CLAUSE`\
`##   p1      1`\
`##   p2      2`

## A dictionary of the matches

The texts that a pattern matched can become the values of a **quanteda**
dictionary, with the labels as its keys, for instance to look up in
other texts what a wildcard found in these. Each different text is kept
once, and `tolower = FALSE` keeps the texts in their own case, which
[`quanteda::dictionary()`](https://quanteda.io/reference/dictionary.html)
would otherwise lower:

\
`m`` ``<-`` `[`spacy_match`](https://spacyr.quanteda.io/reference/spacy_match.md)`(``txt``, ``dict``)`\
`quanteda``::`[`dictionary`](https://quanteda.io/reference/dictionary.html)`(`[`lapply`](https://rdrr.io/r/base/lapply.html)`(`[`split`](https://rdrr.io/r/base/split.html)`(``m``$``text``, ``m``$``label``)``, ``unique``)``, tolower ``=`` ``FALSE``)`\
`## Dictionary object with 2 key entries.`\
`## - [place]:`\
`##   - New York, York, new York`\
`## - [size]:`\
`##   - larger`

This is for matches of sequences, whose `text` is the whole match. A
match of a dependency pattern has a row for each node, whose `text` is
one token of the construction, so a dictionary of those rows would hold
its single words. In a table with both kinds, keep the sequence matches,
which have no `node`:

\
`mixed`` ``<-`` `[`spacy_match`](https://spacyr.quanteda.io/reference/spacy_match.md)`(``passive_txt``, `[`c`](https://rdrr.io/r/base/c.html)`(``passive``, `[`list`](https://rdrr.io/r/base/list.html)`(``CLAUSE ``=`` ``passive_dep``)``)``)`\
`seqs`` ``<-`` ``mixed``[`[`is.na`](https://rdrr.io/r/base/NA.html)`(``mixed``$``node``)``, ``]`\
`quanteda``::`[`dictionary`](https://quanteda.io/reference/dictionary.html)`(`[`lapply`](https://rdrr.io/r/base/lapply.html)`(`[`split`](https://rdrr.io/r/base/split.html)`(``seqs``$``text``, ``seqs``$``label``)``, ``unique``)``, tolower ``=`` ``FALSE``)`\
`## Dictionary object with 1 key entry.`\
`## - [PASSIVE]:`\
`##   - was written, were made, been finished`

As [above](#dictionaries), a value such as `"Acme, Inc."` is found by
[`spacy_match()`](https://spacyr.quanteda.io/reference/spacy_match.md),
which lets spaCy split it into tokens, and not by
[`quanteda::tokens_lookup()`](https://quanteda.io/reference/tokens_lookup.html),
which splits it at its spaces. The article on [rule-based named
entities](https://spacyr.quanteda.io/articles/entity_rules.md) shows the
same for entities, and
[`as.dictionary()`](https://quanteda.io/reference/as.dictionary.html)
for entity patterns that are all phrases.

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
[`spacy_match`](https://spacyr.quanteda.io/reference/spacy_match.md)`(``coord``, `[`c`](https://rdrr.io/r/base/c.html)`(``passive``, `[`list`](https://rdrr.io/r/base/list.html)`(``CLAUSE ``=`` ``passive_dep``)``)``)``[``, `[`c`](https://rdrr.io/r/base/c.html)`(``"label"``, ``"node"``, ``"text"``)``]`\
`##     label    node        text`\
`## 1 PASSIVE    <NA> was written`\
`## 2  CLAUSE    verb     written`\
`## 3  CLAUSE subject        book`\
`## 4  CLAUSE     aux         was`

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
[`spacy_match`](https://spacyr.quanteda.io/reference/spacy_match.md)`(``coord``, `[`list`](https://rdrr.io/r/base/list.html)`(``PASSIVE_CONJ ``=`` ``conj``)``)``[``, `[`c`](https://rdrr.io/r/base/c.html)`(``"node"``, ``"text"``)``]`\
`##    node    text`\
`## 1 first written`\
`## 2   aux     was`\
`## 3  verb  edited`

Testing patterns on examples of the constructions you want, and of those
you do not, is the way to find such cases.

**The pipeline has to set what a pattern asks for.** A pattern on `DEP`
needs the parser, and a dependency pattern needs a dependency parse;
both give an error without one, which stops the call, whatever other
patterns were given with them. A pattern on `ENT_TYPE` gives a warning
when no component sets entities, as after
`spacy_initialize(entity = FALSE)`, since it would match nothing.

## Speed

Matching adds little to the time that spaCy takes to parse the texts. On
a test with 5,000 sentences, a dictionary of 10,000 phrases and several
hundred wildcard values took no longer than a single token pattern.
Token patterns are slower in large numbers, since spaCy checks each one
against the text: give phrases as lexical patterns or as phrases, not as
token patterns, when there are thousands of them. Lexical patterns
without a wildcard or a regular expression are matched as phrases are,
by spaCy’s `PhraseMatcher`; those with one become token patterns, of
which the single words are combined into one pattern for each label.

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
[`spacy_match`](https://spacyr.quanteda.io/reference/spacy_match.md)`(``passive_txt``, ``passive``)`\
`##   doc_id match_id   label node sentence_id token_id          text start_id length`\
`## 1     p1        1 PASSIVE <NA>           1        3   was written        3      2`\
`## 2     p2        1 PASSIVE <NA>           1        2     were made        2      2`\
`## 3     p2        2 PASSIVE <NA>           1       10 been finished       10      2`\
[`spacy_finalize`](https://spacyr.quanteda.io/reference/spacy_finalize.md)`(``)`

See the article on [improving
performance](https://spacyr.quanteda.io/articles/performance.md) for
more on this, and for `n_process` and `batch_size`, which
[`spacy_match()`](https://spacyr.quanteda.io/reference/spacy_match.md)
also takes.
