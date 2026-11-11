# Adding Rule-Based Named Entities

## Introduction

spaCy’s language models recognise named entities statistically, from
what they learned in training. They often miss entities that matter for
a particular study: names specific to a field, organisations the model
has never seen, or entities that the model’s training data marked
differently from how a researcher would. A common example
([\#234](https://github.com/quanteda/spacyr/issues/234)) is people’s
academic titles, which spaCy’s English models leave out of a `PERSON`
entity.

spaCy solves this with an *entity ruler*, a pipeline component that adds
entities by matching rules: phrases, or sequences of tokens described by
their attributes. **spacyr** lets you create these rules in R, and adds
them to the pipeline when it initializes spaCy:

- [`as_entity_patterns()`](https://spacyr.quanteda.io/reference/as_entity_patterns.md)
  creates a set of rules from phrases, spaCy’s own pattern structure, a
  data.frame, a **quanteda** dictionary, or entities that spaCy has
  already found;
- [`entity_patterns_read()`](https://spacyr.quanteda.io/reference/entity_patterns_read.md)
  and
  [`entity_patterns_write()`](https://spacyr.quanteda.io/reference/entity_patterns_read.md)
  read and write rules as files, in spaCy’s JSONL format;
- `spacy_initialize(entity_patterns = )` adds the rules to the pipeline.

Creating rules needs neither Python nor spaCy, so the rules are ordinary
R objects that can be inspected, combined and saved.

If spaCy is already running in your R session, call
[`spacy_finalize()`](https://spacyr.quanteda.io/reference/spacy_finalize.md)
before calling
[`spacy_initialize()`](https://spacyr.quanteda.io/reference/spacy_initialize.md)
with a new set of rules.

\
[`library`](https://rdrr.io/r/base/library.html)`(`[`"spacyr"`](https://spacyr.quanteda.io)`)`

## Phrases

The simplest rule is a phrase with a label. The names of a character
vector give the labels:

\
`pats`` ``<-`` `[`as_entity_patterns`](https://spacyr.quanteda.io/reference/as_entity_patterns.md)`(`[`c`](https://rdrr.io/r/base/c.html)`(``ORG ``=`` ``"Acme Widgets"``, GPE ``=`` ``"Ruritania"``)``)`\
`pats`\
`## Entity patterns: 2 patterns (ORG: 1, GPE: 1)`\
`##   ORG  "Acme Widgets"`\
`##   GPE  "Ruritania"`

Without rules, the model finds some of these entities, but not as we
would label them:

\
`txt`` ``<-`` ``"Acme Widgets opened a factory in Ruritania, said Jane Smith."`\
[`spacy_initialize`](https://spacyr.quanteda.io/reference/spacy_initialize.md)`(``)`\
`## successfully initialized (spaCy Version: 3.8.18, language model: en_core_web_sm)`\
[`spacy_extract_entity`](https://spacyr.quanteda.io/reference/spacy_extract_entity.md)`(``txt``)`\
`##   doc_id         text ent_type start_id length`\
`## 1  text1 Acme Widgets   PERSON        1      2`\
`## 2  text1    Ruritania      GPE        7      1`\
`## 3  text1   Jane Smith   PERSON       10      2`\
[`spacy_finalize`](https://spacyr.quanteda.io/reference/spacy_finalize.md)`(``)`

With the rules, it finds both, with our labels, and still finds the
entities that the rules say nothing about:

\
[`spacy_initialize`](https://spacyr.quanteda.io/reference/spacy_initialize.md)`(``entity_patterns ``=`` ``pats``)`\
`## successfully initialized (spaCy Version: 3.8.18, language model: en_core_web_sm)`\
[`spacy_extract_entity`](https://spacyr.quanteda.io/reference/spacy_extract_entity.md)`(``txt``)`\
`##   doc_id         text ent_type start_id length`\
`## 1  text1 Acme Widgets      ORG        1      2`\
`## 2  text1    Ruritania      GPE        7      1`\
`## 3  text1   Jane Smith   PERSON       10      2`\
[`spacy_parse`](https://spacyr.quanteda.io/reference/spacy_parse.md)`(``txt``, pos ``=`` ``FALSE``, lemma ``=`` ``FALSE``)`\
`##    doc_id sentence_id token_id     token   entity`\
`## 1   text1           1        1      Acme    ORG_B`\
`## 2   text1           1        2   Widgets    ORG_I`\
`## 3   text1           1        3    opened         `\
`## 4   text1           1        4         a         `\
`## 5   text1           1        5   factory         `\
`## 6   text1           1        6        in         `\
`## 7   text1           1        7 Ruritania    GPE_B`\
`## 8   text1           1        8         ,         `\
`## 9   text1           1        9      said         `\
`## 10  text1           1       10      Jane PERSON_B`\
`## 11  text1           1       11     Smith PERSON_I`\
`## 12  text1           1       12         .`\
[`spacy_finalize`](https://spacyr.quanteda.io/reference/spacy_finalize.md)`(``)`

Phrases match spaCy’s tokens exactly, including their case. With
`case_insensitive = TRUE`, they match in any case:

\
`pats`` ``<-`` `[`as_entity_patterns`](https://spacyr.quanteda.io/reference/as_entity_patterns.md)`(`[`c`](https://rdrr.io/r/base/c.html)`(``"Acme Widgets"``, ``"Globex"``)``, label ``=`` ``"ORG"``,`\
`                           case_insensitive ``=`` ``TRUE``)`\
`pats`\
`## Entity patterns: 2 patterns (ORG: 2)`\
`##   ORG  "Acme Widgets" (any case)`\
`##   ORG  "Globex" (any case)`\
[`spacy_initialize`](https://spacyr.quanteda.io/reference/spacy_initialize.md)`(``entity_patterns ``=`` ``pats``)`\
`## successfully initialized (spaCy Version: 3.8.18, language model: en_core_web_sm)`\
[`spacy_extract_entity`](https://spacyr.quanteda.io/reference/spacy_extract_entity.md)`(``"ACME WIDGETS and globex announced a merger."``)`\
`##   doc_id         text ent_type start_id length`\
`## 1  text1 ACME WIDGETS      ORG        1      2`\
`## 2  text1       globex      ORG        4      1`\
[`spacy_finalize`](https://spacyr.quanteda.io/reference/spacy_finalize.md)`(``)`

A phrase is split into tokens by the pipeline’s own tokenizer, so
`"Globex, Inc."` is matched as the three tokens `Globex`, `,` and
`Inc.`, as in a text. Some rules of the tokenizer depend on case,
though: spaCy’s English models keep `"Inc."` as one token, but split
`"inc."` into `"inc"` and `"."`. So write phrases in their usual case,
even when they should match in any case.

## Token patterns

Rules can also describe a sequence of tokens by their attributes, in
[spaCy’s own structure](https://spacy.io/usage/rule-based-matching): a
list with one element per token, each a named list of attributes such as
`LOWER` (the token in lower case), `IS_TITLE`, `ENT_TYPE` (the type of
entity a token belongs to) or `OP` (how many times the token may occur).

To include academic titles in `PERSON` entities, we match a title,
followed by the tokens of a person that the model has already
recognised:

\
`titles`` ``<-`` `[`c`](https://rdrr.io/r/base/c.html)`(``"dr"``, ``"dr."``, ``"prof"``, ``"prof."``, ``"professor"``)`\
`title_rule`` ``<-`` `[`as_entity_patterns`](https://spacyr.quanteda.io/reference/as_entity_patterns.md)`(`[`list`](https://rdrr.io/r/base/list.html)`(`\
`  label ``=`` ``"PERSON"``,`\
`  pattern ``=`` `[`list`](https://rdrr.io/r/base/list.html)`(`[`list`](https://rdrr.io/r/base/list.html)`(``LOWER ``=`` `[`list`](https://rdrr.io/r/base/list.html)`(``IN ``=`` ``titles``)``)``,`\
`                 `[`list`](https://rdrr.io/r/base/list.html)`(``ENT_TYPE ``=`` ``"PERSON"``, ENT_IOB ``=`` ``"B"``)``,`\
`                 `[`list`](https://rdrr.io/r/base/list.html)`(``ENT_TYPE ``=`` ``"PERSON"``, ENT_IOB ``=`` ``"I"``, OP ``=`` ``"*"``)``)`\
`)``)`\
`title_rule`\
`## Entity patterns: 1 pattern (PERSON: 1)`\
`##   PERSON  [LOWER in (dr, dr., prof, prof., professor)] [ENT_TYPE = PERSON, ENT_IOB = B] [ENT_TYPE = PERSON, ENT_IOB = I]*`

The second token begins a `PERSON` entity (`ENT_IOB = "B"`), and the
third matches the rest of that entity (`ENT_IOB = "I"`), zero or more
times. A simpler rule, a title followed by
`list(ENT_TYPE = "PERSON", OP = "+")`, would also match, but it would
run on into a second person who directly follows the first, joining
“Prof. Jane Smith” and “Bob Jones” into one entity. Both titles need to
be listed with and without a full stop, since the English models keep
“Prof.” as one token.

\
`txt`` ``<-`` ``"Prof. Jane Smith Bob Jones and Dr. Kim Park spoke."`\
[`spacy_initialize`](https://spacyr.quanteda.io/reference/spacy_initialize.md)`(``)`\
`## successfully initialized (spaCy Version: 3.8.18, language model: en_core_web_sm)`\
[`spacy_extract_entity`](https://spacyr.quanteda.io/reference/spacy_extract_entity.md)`(``txt``)`\
`##   doc_id       text ent_type start_id length`\
`## 1  text1 Jane Smith   PERSON        2      2`\
`## 2  text1  Bob Jones   PERSON        4      2`\
`## 3  text1   Kim Park   PERSON        8      2`\
[`spacy_finalize`](https://spacyr.quanteda.io/reference/spacy_finalize.md)`(``)`\
\
[`spacy_initialize`](https://spacyr.quanteda.io/reference/spacy_initialize.md)`(``entity_patterns ``=`` ``title_rule``)`\
`## successfully initialized (spaCy Version: 3.8.18, language model: en_core_web_sm)`\
[`spacy_extract_entity`](https://spacyr.quanteda.io/reference/spacy_extract_entity.md)`(``txt``)`\
`##   doc_id             text ent_type start_id length`\
`## 1  text1 Prof. Jane Smith   PERSON        1      3`\
`## 2  text1        Bob Jones   PERSON        4      2`\
`## 3  text1     Dr. Kim Park   PERSON        7      3`\
[`spacy_finalize`](https://spacyr.quanteda.io/reference/spacy_finalize.md)`(``)`

[`as_entity_patterns()`](https://spacyr.quanteda.io/reference/as_entity_patterns.md)
checks the structure of token patterns, and converts them to the form
spaCy expects: for instance, the values of `IN` stay a list even when
there is only one. spaCy checks the attribute names and values when the
rules are added, and
[`spacy_initialize()`](https://spacyr.quanteda.io/reference/spacy_initialize.md)
shows its message if it does not accept them.

## Rules and the model

**spacyr** adds its entity ruler at the end of the pipeline, after the
model’s named entity recognizer and anything else that sets entities.
This is what allows the title rule to build on the model’s `PERSON`
entities.

Where a rule’s entity overlaps one that the model found, the rule’s
entity is kept. With `overwrite_entities = FALSE`, the model’s entity is
kept instead, so that the rules only add entities where the model found
none:

\
`txt`` ``<-`` ``"Jane Smith flew to Paris."`\
[`spacy_initialize`](https://spacyr.quanteda.io/reference/spacy_initialize.md)`(``entity_patterns ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``LOC ``=`` ``"Paris"``)``)`\
`## successfully initialized (spaCy Version: 3.8.18, language model: en_core_web_sm)`\
[`spacy_extract_entity`](https://spacyr.quanteda.io/reference/spacy_extract_entity.md)`(``txt``)`\
`##   doc_id       text ent_type start_id length`\
`## 1  text1 Jane Smith   PERSON        1      2`\
`## 2  text1      Paris      LOC        5      1`\
[`spacy_finalize`](https://spacyr.quanteda.io/reference/spacy_finalize.md)`(``)`\
\
[`spacy_initialize`](https://spacyr.quanteda.io/reference/spacy_initialize.md)`(``entity_patterns ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``LOC ``=`` ``"Paris"``)``, overwrite_entities ``=`` ``FALSE``)`\
`## successfully initialized (spaCy Version: 3.8.18, language model: en_core_web_sm)`\
[`spacy_extract_entity`](https://spacyr.quanteda.io/reference/spacy_extract_entity.md)`(``txt``)`\
`##   doc_id       text ent_type start_id length`\
`## 1  text1 Jane Smith   PERSON        1      2`\
`## 2  text1      Paris      GPE        5      1`\
[`spacy_finalize`](https://spacyr.quanteda.io/reference/spacy_finalize.md)`(``)`

When two rules overlap, spaCy prefers the match that spans more tokens.
If they span the same number of tokens, the one that starts earlier
takes priority. See [spaCy’s entity ruler
guide](https://spacy.io/usage/rule-based-matching#entityruler).

Set `entity = FALSE` to disable the model’s named entity recogniser
(`ner`). Rules based on token attributes such as `IS_TITLE` still work:

\
`name_rule`` ``<-`` `[`as_entity_patterns`](https://spacyr.quanteda.io/reference/as_entity_patterns.md)`(`[`list`](https://rdrr.io/r/base/list.html)`(`\
`  label ``=`` ``"NAME"``,`\
`  pattern ``=`` `[`list`](https://rdrr.io/r/base/list.html)`(`[`list`](https://rdrr.io/r/base/list.html)`(``IS_TITLE ``=`` ``TRUE``)``, `[`list`](https://rdrr.io/r/base/list.html)`(``IS_TITLE ``=`` ``TRUE``)``)`\
`)``)`\
[`spacy_initialize`](https://spacyr.quanteda.io/reference/spacy_initialize.md)`(``entity ``=`` ``FALSE``, entity_patterns ``=`` ``name_rule``)`\
`## successfully initialized (spaCy Version: 3.8.18, language model: en_core_web_sm)`\
[`spacy_parse`](https://spacyr.quanteda.io/reference/spacy_parse.md)`(``"We met Jane Smith there."``, pos ``=`` ``FALSE``, lemma ``=`` ``FALSE``)`\
`##   doc_id sentence_id token_id token entity`\
`## 1  text1           1        1    We       `\
`## 2  text1           1        2   met       `\
`## 3  text1           1        3  Jane NAME_B`\
`## 4  text1           1        4 Smith NAME_I`\
`## 5  text1           1        5 there       `\
`## 6  text1           1        6     .`\
[`spacy_finalize`](https://spacyr.quanteda.io/reference/spacy_finalize.md)`(``)`

The title rule relies on entity annotations (`ENT_TYPE` and `ENT_IOB`)
from an earlier component. With `ner` disabled and no other component
supplying entities,
[`spacy_initialize()`](https://spacyr.quanteda.io/reference/spacy_initialize.md)
warns that the title rule will not match:

\
[`spacy_initialize`](https://spacyr.quanteda.io/reference/spacy_initialize.md)`(``entity ``=`` ``FALSE``, entity_patterns ``=`` ``title_rule``)`\
`## Warning: Some patterns need entities that an earlier component found (ENT_TYPE`\
`## or ENT_IOB), but no component before spacyr's entity ruler sets entities, so`\
`## they will not match; use spacy_initialize(entity = TRUE)`\
`## successfully initialized (spaCy Version: 3.8.18, language model: en_core_web_sm)`\
[`spacy_finalize`](https://spacyr.quanteda.io/reference/spacy_finalize.md)`(``)`

A saved ruler stays in the pipeline and can supply entities even with
`entity = FALSE`. **spacyr** adds its own ruler after it, using
`spacyr_entity_ruler` or a numbered variant if that name is already in
use.

## Dictionaries

A **quanteda** dictionary becomes a set of rules labelled by its
top-level keys. As in **quanteda**, its values match in any case, and
they can have wildcards: `*` for any characters, and `?` for one. A
value with wildcards matches one token for each part separated by
spaces, as **quanteda** matches dictionary values to tokens, so
`"dr * who"` matches three tokens.

\
[`library`](https://rdrr.io/r/base/library.html)`(`[`"quanteda"`](https://quanteda.io)`)`\
`dict`` ``<-`` `[`dictionary`](https://quanteda.io/reference/dictionary.html)`(`[`list`](https://rdrr.io/r/base/list.html)`(`\
`  ORG ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"Acme Widgets"``, ``"Globex*"``, ``"Initech, Inc."``)``,`\
`  PERSON ``=`` ``"dr * who"`\
`)``, tolower ``=`` ``FALSE``)`\
[`as_entity_patterns`](https://spacyr.quanteda.io/reference/as_entity_patterns.md)`(``dict``)`\
`## Entity patterns: 4 patterns (ORG: 3, PERSON: 1)`\
`##   ORG     "Acme Widgets" (any case)`\
`##   ORG     [LOWER ~ /^globex.*$/]`\
`##   ORG     "Initech, Inc." (any case)`\
`##   PERSON  [LOWER = dr] [LOWER ~ /^.*$/] [LOWER = who]`

[`dictionary()`](https://quanteda.io/reference/dictionary.html)
lowercases its values by default, so this one is made with
`tolower = FALSE`, to keep `"Inc."` as spaCy’s tokenizer expects it.
Here the model’s recognizer is off, so that all the entities come from
the dictionary:

\
[`spacy_initialize`](https://spacyr.quanteda.io/reference/spacy_initialize.md)`(``entity ``=`` ``FALSE``, entity_patterns ``=`` ``dict``)`\
`## successfully initialized (spaCy Version: 3.8.18, language model: en_core_web_sm)`\
[`spacy_extract_entity`](https://spacyr.quanteda.io/reference/spacy_extract_entity.md)`(``"ACME WIDGETS and Globexcorp met Dr Hal Who at INITECH, Inc."``)`\
`##   doc_id          text ent_type start_id length`\
`## 1  text1  ACME WIDGETS      ORG        1      2`\
`## 2  text1    Globexcorp      ORG        4      1`\
`## 3  text1    Dr Hal Who   PERSON        6      3`\
`## 4  text1 INITECH, Inc.      ORG       10      3`\
[`spacy_finalize`](https://spacyr.quanteda.io/reference/spacy_finalize.md)`(``)`

With `valuetype = "regex"`, each part of a value is a regular expression
for one token. These are regular expressions in the dialect of Python,
which differs from that of R in some details: for instance, Python does
not support `"\\p{L}"` for letters. Make such a dictionary with
`tolower = FALSE`, so that escapes such as `"\\D"` keep their case.

## Reusing the entities found

The entities that spaCy finds in one set of texts can become rules for
another, for instance to make sure that the entities found in a
carefully reviewed corpus are found again, or to carry entities over to
a model for another language. The output of
[`spacy_extract_entity()`](https://spacyr.quanteda.io/reference/spacy_extract_entity.md)
keeps the text of each entity as it was, and
[`as_entity_patterns()`](https://spacyr.quanteda.io/reference/as_entity_patterns.md)
makes a phrase of each:

\
[`spacy_initialize`](https://spacyr.quanteda.io/reference/spacy_initialize.md)`(``)`\
`## successfully initialized (spaCy Version: 3.8.18, language model: en_core_web_sm)`\
`found`` ``<-`` `[`spacy_extract_entity`](https://spacyr.quanteda.io/reference/spacy_extract_entity.md)`(`[`c`](https://rdrr.io/r/base/c.html)`(`\
`  ``"Acme Widgets hired Jane Smith."``,`\
`  ``"Jane Smith moved to Ruritania."`\
`)``)`\
[`spacy_finalize`](https://spacyr.quanteda.io/reference/spacy_finalize.md)`(``)`\
`found`\
`##   doc_id         text ent_type start_id length`\
`## 1  text1 Acme Widgets   PERSON        1      2`\
`## 2  text1   Jane Smith   PERSON        4      2`\
`## 3  text2   Jane Smith   PERSON        1      2`\
`## 4  text2    Ruritania      GPE        5      1`

The model took “Acme Widgets” for a person. Reviewing the entities
before reusing them lets us correct that, and keep only the types we
want, here people and organisations. Duplicates, such as the second
“Jane Smith”, are dropped:

\
`found``$``ent_type``[``found``$``text`` ``==`` ``"Acme Widgets"``]`` ``<-`` ``"ORG"`\
`found`` ``<-`` ``found``[``found``$``ent_type`` `[`%in%`](https://rdrr.io/r/base/match.html)` `[`c`](https://rdrr.io/r/base/c.html)`(``"PERSON"``, ``"ORG"``)``, ``]`\
`pats`` ``<-`` `[`as_entity_patterns`](https://spacyr.quanteda.io/reference/as_entity_patterns.md)`(``found``)`\
`pats`\
`## Entity patterns: 2 patterns (ORG: 1, PERSON: 1)`\
`##   ORG     "Acme Widgets"`\
`##   PERSON  "Jane Smith"`\
\
[`spacy_initialize`](https://spacyr.quanteda.io/reference/spacy_initialize.md)`(``entity ``=`` ``FALSE``, entity_patterns ``=`` ``pats``)`\
`## successfully initialized (spaCy Version: 3.8.18, language model: en_core_web_sm)`\
[`spacy_extract_entity`](https://spacyr.quanteda.io/reference/spacy_extract_entity.md)`(``"Later, Jane Smith left Acme Widgets."``)`\
`##   doc_id         text ent_type start_id length`\
`## 1  text1   Jane Smith   PERSON        3      2`\
`## 2  text1 Acme Widgets      ORG        6      2`\
[`spacy_finalize`](https://spacyr.quanteda.io/reference/spacy_finalize.md)`(``)`

[`entity_extract()`](https://spacyr.quanteda.io/reference/entity_extract.md),
which works on the output of
[`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md),
joins the tokens of each entity with an underscore.
[`as_entity_patterns()`](https://spacyr.quanteda.io/reference/as_entity_patterns.md)
converts its output too, but needs to be told the `concatenator`, since
a token that itself contains one would be changed.
[`spacy_extract_entity()`](https://spacyr.quanteda.io/reference/spacy_extract_entity.md)
is the better source.

## Combining and saving rules

Sets of rules combine with [`c()`](https://rdrr.io/r/base/c.html), and
are data.frames, with one row per rule:

\
`all_rules`` ``<-`` `[`c`](https://rdrr.io/r/base/c.html)`(``title_rule``, `[`as_entity_patterns`](https://spacyr.quanteda.io/reference/as_entity_patterns.md)`(`[`c`](https://rdrr.io/r/base/c.html)`(``ORG ``=`` ``"Acme Widgets"``, GPE ``=`` ``"Ruritania"``)``)``)`\
`all_rules`\
`## Entity patterns: 3 patterns (PERSON: 1, ORG: 1, GPE: 1)`\
`##   PERSON  [LOWER in (dr, dr., prof, prof., professor)] [ENT_TYPE = PERSON, ENT_IOB = B] [ENT_TYPE = PERSON, ENT_IOB = I]*`\
`##   ORG     "Acme Widgets"`\
`##   GPE     "Ruritania"`\
[`as.data.frame`](https://rdrr.io/r/base/as.data.frame.html)`(``all_rules``)``[``, `[`c`](https://rdrr.io/r/base/c.html)`(``"label"``, ``"id"``, ``"case_insensitive"``)``]`\
`##    label   id case_insensitive`\
`## 1 PERSON <NA>               NA`\
`## 2    ORG <NA>            FALSE`\
`## 3    GPE <NA>            FALSE`

[`entity_patterns_write()`](https://spacyr.quanteda.io/reference/entity_patterns_read.md)
saves them in spaCy’s JSONL format, with one rule per line, which spaCy
can also load on its own, and
[`entity_patterns_read()`](https://spacyr.quanteda.io/reference/entity_patterns_read.md)
reads them back:

\
`file`` ``<-`` `[`tempfile`](https://rdrr.io/r/base/tempfile.html)`(``fileext ``=`` ``".jsonl"``)`\
[`entity_patterns_write`](https://spacyr.quanteda.io/reference/entity_patterns_read.md)`(``all_rules``, ``file``)`\
[`cat`](https://rdrr.io/r/base/cat.html)`(`[`readLines`](https://rdrr.io/r/base/readLines.html)`(``file``)``, sep ``=`` ``"\n"``)`\
`## {"label":"PERSON","pattern":[{"LOWER":{"IN":["dr","dr.","prof","prof.","professor"]}},{"ENT_TYPE":"PERSON","ENT_IOB":"B"},{"ENT_TYPE":"PERSON","ENT_IOB":"I","OP":"*"}]}`\
`## {"label":"ORG","pattern":"Acme Widgets"}`\
`## {"label":"GPE","pattern":"Ruritania"}`\
[`identical`](https://rdrr.io/r/base/identical.html)`(`[`entity_patterns_read`](https://spacyr.quanteda.io/reference/entity_patterns_read.md)`(``file``)``, ``all_rules``)`\
`## [1] TRUE`

spacyr preserves `case_insensitive` when writing and reading JSONL.
Native spaCy ignores this field, so its default ruler matches those
phrases case-sensitively.

[`entity_patterns_read()`](https://spacyr.quanteda.io/reference/entity_patterns_read.md)
also reads a JSON array of rules, or a text file with one phrase per
line, given a `label`.

## Speed

On a test with 5,000 sentences, 10,000 phrases added little parsing time
when all used the same case-matching setting. **spacyr** can also
combine simple single-token regular expressions, such as dictionary
globs, when they share a label, ID and token attribute. Other token
patterns are checked one by one. Mixing case-sensitive and
case-insensitive phrases also makes large rule sets slower, because the
case-insensitive phrases are matched as token patterns.
