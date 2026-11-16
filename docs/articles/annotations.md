# From Text to Auditable Annotations

## Introduction

Much analysis of text with spaCy ends in a count: how often presidents
speak of Congress, or how many passive verbs a manifesto has. A count
does not show what was counted. Before relying on it, you want to see
each thing that was found, in the text where it was found, and to change
the rule that found it when the rule is wrong.

This article does that for one small example: references to the
legislature and to the courts in four inaugural addresses of US
presidents. It arrives at this, a passage of George Bush’s address of
1989 with its entities highlighted, and every reference to the
legislature in that address in its context:

We need a new engagement, too, between the Executive LOC and the
Congress LEGISLATURE . The challenges before us will be thrashed out
with the House LEGISLATURE and the Senate LEGISLATURE .

    ## Keyword-in-context with 5 matches.
    ##                                                                                    
    ##  [1989-Bush, 1574:1574] the Executive and the | Congress  | . The challenges before
    ##  [1989-Bush, 1585:1586]  be thrashed out with | the House | and the Senate.        
    ##  [1989-Bush, 1589:1589]     the House and the |  Senate   | . We must bring        
    ##  [1989-Bush, 1655:1655]      voices. \n\n For | Congress  | , too, has             
    ##  [1989-Bush, 1926:1926]  Majority Leader, the | Congress  | and the Executive were

Version 2.0 of **spacyr** adds what this takes:

- rules written in R, as a **quanteda** dictionary or as patterns, which
  [`spacy_match()`](https://spacyr.quanteda.io/reference/spacy_match.md)
  finds in the texts and
  [`spacy_initialize()`](https://spacyr.quanteda.io/reference/spacy_initialize.md)
  adds to the pipeline as named entities;
- the position of every match, entity and token, in spaCy’s tokens and,
  with `offsets = TRUE`, in the characters of the original text;
- [`entity_visualize()`](https://spacyr.quanteda.io/reference/entity_visualize.md),
  which shows the text with its entities highlighted;
- [`as_index()`](https://spacyr.quanteda.io/reference/as_index.md),
  which gives matches to
  [`quanteda::kwic()`](https://quanteda.io/reference/kwic.html) for a
  concordance, and methods that turn a parse into **quanteda** tokens,
  with the document variables of the corpus that was parsed.

The article goes through these in turn. For more detail on each step,
see the articles on [rule-based
matching](https://spacyr.quanteda.io/articles/matching.md), [rule-based
named entities](https://spacyr.quanteda.io/articles/entity_rules.md) and
[improving
performance](https://spacyr.quanteda.io/articles/performance.md).

## The texts

The texts are four of the inaugural addresses in **quanteda**’s
`data_corpus_inaugural`, a corpus whose document variables record the
year, the president and the party:

\
[`library`](https://rdrr.io/r/base/library.html)`(`[`"spacyr"`](https://spacyr.quanteda.io)`)`\
[`library`](https://rdrr.io/r/base/library.html)`(`[`"quanteda"`](https://quanteda.io)`)`\
`corp`` ``<-`` `[`corpus_subset`](https://quanteda.io/reference/corpus_subset.html)`(``data_corpus_inaugural``, ``Year`` `[`%in%`](https://rdrr.io/r/base/match.html)` `[`c`](https://rdrr.io/r/base/c.html)`(``1789``, ``1861``, ``1933``, ``1989``)``)`\
[`docvars`](https://quanteda.io/reference/docvars.html)`(``corp``)`\
`##   Year  President   FirstName      Party`\
`## 1 1789 Washington      George       none`\
`## 2 1861    Lincoln     Abraham Republican`\
`## 3 1933  Roosevelt Franklin D. Democratic`\
`## 4 1989       Bush      George Republican`

## Define what to find

A **quanteda** dictionary says what to find. Its keys are the labels,
and its values are the words and phrases to find under each:

\
`dict`` ``<-`` `[`dictionary`](https://quanteda.io/reference/dictionary.html)`(`[`list`](https://rdrr.io/r/base/list.html)`(``LEGISLATURE ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"Congress"``, ``"Senate"``, ``"House of Representatives"``, ``"House"``)``,`\
`                        JUDICIARY ``=`` ``"Supreme Court"``)``,`\
`                   tolower ``=`` ``FALSE``)`

[`spacy_match()`](https://spacyr.quanteda.io/reference/spacy_match.md)
finds them in the texts. It returns a data.frame with one row for each
match: the document, the label, the matched text, and where the match
is.

\
[`spacy_initialize`](https://spacyr.quanteda.io/reference/spacy_initialize.md)`(``)`\
`## successfully initialized (spaCy Version: 3.8.18, language model: en_core_web_sm)`\
`m`` ``<-`` `[`spacy_match`](https://spacyr.quanteda.io/reference/spacy_match.md)`(``corp``, ``dict``)`\
[`head`](https://rdrr.io/r/utils/head.html)`(``m``, ``3``)`\
`##            doc_id match_id       label node sentence_id token_id                     text start_id`\
`## 1 1789-Washington        1 LEGISLATURE <NA>           1        6                   Senate        6`\
`## 2 1789-Washington        2 LEGISLATURE <NA>           1       10 House of Representatives       10`\
`## 3 1789-Washington        3 LEGISLATURE <NA>          19       19 House of Representatives     1281`\
`##   length`\
`## 1      1`\
`## 2      3`\
`## 3      3`\
[`table`](https://rdrr.io/r/base/table.html)`(``m``$``doc_id``, ``m``$``label``)`\
`##                  `\
`##                   JUDICIARY LEGISLATURE`\
`##   1789-Washington         0           3`\
`##   1861-Lincoln            2           5`\
`##   1933-Roosevelt          0           5`\
`##   1989-Bush               0           6`

That is 21 references. Whether they are what we meant is the next
question.

## Inspect the matches

[`quanteda::kwic()`](https://quanteda.io/reference/kwic.html) shows each
occurrence of a pattern with the words around it. It can do the same for
positions found elsewhere, given as an index, and
[`as_index()`](https://spacyr.quanteda.io/reference/as_index.md) makes
one from a table of matches. The positions count spaCy’s tokens, so the
tokens to give [`kwic()`](https://quanteda.io/reference/kwic.html) are
those of
[`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md)
for the same texts, which
[`as.tokens()`](https://quanteda.io/reference/as.tokens.html) converts.
Only the tokens are needed here, so the parse leaves out the lemmas, the
parts of speech and the entities:

\
`toks`` ``<-`` `[`as.tokens`](https://quanteda.io/reference/as.tokens.html)`(`[`spacy_parse`](https://spacyr.quanteda.io/reference/spacy_parse.md)`(``corp``, lemma ``=`` ``FALSE``, pos ``=`` ``FALSE``, entity ``=`` ``FALSE``)``)`\
[`kwic`](https://quanteda.io/reference/kwic.html)`(``toks``, index ``=`` `[`as_index`](https://spacyr.quanteda.io/reference/as_index.md)`(``m``)``, window ``=`` ``5``)`\
`## Keyword-in-context with 21 matches.`\
`##                                                                                          `\
`##        [1789-Washington, 6:6]       Fellow - Citizens of the |          Senate          |`\
`##      [1789-Washington, 10:12]          the Senate and of the | House of Representatives |`\
`##  [1789-Washington, 1281:1283] most properly addressed to the | House of Representatives |`\
`##       [1861-Lincoln, 608:608]            law. All members of |         Congress         |`\
`##       [1861-Lincoln, 906:906]  to specify particular acts of |         Congress         |`\
`##     [1861-Lincoln, 2259:2259]         not expressly say. May |         Congress         |`\
`##     [1861-Lincoln, 2274:2274]        not expressly say. Must |         Congress         |`\
`##     [1861-Lincoln, 2588:2589]           to be decided by the |      Supreme Court       |`\
`##     [1861-Lincoln, 2735:2736]      fixed by decisions of the |      Supreme Court       |`\
`##     [1861-Lincoln, 3394:3394]          not seen - has passed |         Congress         |`\
`##   [1933-Roosevelt, 1169:1169]      presently urge upon a new |         Congress         |`\
`##   [1933-Roosevelt, 1205:1205]    to putting our own national |          house           |`\
`##   [1933-Roosevelt, 1788:1788]     such other measures as the |         Congress         |`\
`##   [1933-Roosevelt, 1820:1820]          in the event that the |         Congress         |`\
`##   [1933-Roosevelt, 1862:1862]              . I shall ask the |         Congress         |`\
`##        [1989-Bush, 1487:1487]           on this in the White |          House           |`\
`##        [1989-Bush, 1574:1574]  between the Executive and the |         Congress         |`\
`##        [1989-Bush, 1586:1586]       be thrashed out with the |          House           |`\
`##        [1989-Bush, 1589:1589]         with the House and the |          Senate          |`\
`##        [1989-Bush, 1655:1655]    discordant voices. \n\n For |         Congress         |`\
`##        [1989-Bush, 1926:1926]       Mr. Majority Leader, the |         Congress         |`\
`##                                      `\
`##  and of the House of                 `\
`##  : \n\n Among the vicissitudes       `\
`##  . It concerns myself,               `\
`##  swear their support to the          `\
`##  as proper to be enforced            `\
`##  prohibit slavery in the Territories `\
`##  protect slavery in the Territories  `\
`##  , nor do I deny                     `\
`##  , the instant they are              `\
`##  , to the effect that                `\
`##  in special session detailed measures`\
`##  in order and making income          `\
`##  may build out of its                `\
`##  shall fail to take one              `\
`##  for the one remaining instrument    `\
`##  , in the Cabinet agencies           `\
`##  . The challenges before us          `\
`##  and the Senate. We                  `\
`##  . We must bring the                 `\
`##  , too, has changed                  `\
`##  and the Executive were capable`

Two of the 21 are not references to the legislature: Roosevelt’s “our
own national house”, and the “House” of Bush’s “White House”. Both come
from the value `"House"`, which matches in any case and wherever the
word is, as a dictionary value does in **quanteda**. The table of counts
could not have shown this.

## Revise the rules

Two changes remove them: the value becomes `"the House"`, and the values
match in their own case.
[`as_entity_patterns()`](https://spacyr.quanteda.io/reference/as_entity_patterns.md)
makes a set of rules from a dictionary with that setting. Both
[`spacy_match()`](https://spacyr.quanteda.io/reference/spacy_match.md)
and
[`spacy_initialize()`](https://spacyr.quanteda.io/reference/spacy_initialize.md)
take the rules.

\
`dict`` ``<-`` `[`dictionary`](https://quanteda.io/reference/dictionary.html)`(`[`list`](https://rdrr.io/r/base/list.html)`(``LEGISLATURE ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"Congress"``, ``"Senate"``, ``"House of Representatives"``, ``"the House"``)``,`\
`                        JUDICIARY ``=`` ``"Supreme Court"``)``,`\
`                   tolower ``=`` ``FALSE``)`\
`rules`` ``<-`` `[`as_entity_patterns`](https://spacyr.quanteda.io/reference/as_entity_patterns.md)`(``dict``, case_insensitive ``=`` ``FALSE``)`\
`rules`\
`## Entity patterns: 5 patterns (LEGISLATURE: 4, JUDICIARY: 1)`\
`##   LEGISLATURE  "Congress"`\
`##   LEGISLATURE  "Senate"`\
`##   LEGISLATURE  "House of Representatives"`\
`##   LEGISLATURE  "the House"`\
`##   JUDICIARY    "Supreme Court"`

\
`m`` ``<-`` `[`spacy_match`](https://spacyr.quanteda.io/reference/spacy_match.md)`(``corp``, ``rules``, offsets ``=`` ``TRUE``)`\
[`kwic`](https://quanteda.io/reference/kwic.html)`(``toks``, index ``=`` `[`as_index`](https://spacyr.quanteda.io/reference/as_index.md)`(``m``[`[`grepl`](https://rdrr.io/r/base/grep.html)`(``"House"``, ``m``$``text``)``, ``]``)``, window ``=`` ``5``)`\
`## Keyword-in-context with 3 matches.`\
`##                                                                                          `\
`##      [1789-Washington, 10:12]          the Senate and of the | House of Representatives |`\
`##  [1789-Washington, 1281:1283] most properly addressed to the | House of Representatives |`\
`##        [1989-Bush, 1585:1586]      will be thrashed out with |        the House         |`\
`##                               `\
`##  : \n\n Among the vicissitudes`\
`##  . It concerns myself,        `\
`##  and the Senate. We`\
[`table`](https://rdrr.io/r/base/table.html)`(``m``$``doc_id``, ``m``$``label``)`\
`##                  `\
`##                   JUDICIARY LEGISLATURE`\
`##   1789-Washington         0           3`\
`##   1861-Lincoln            2           5`\
`##   1933-Roosevelt          0           4`\
`##   1989-Bush               0           5`

The two false matches are gone, and the House that Bush meant is still
found. A rule has its limits too: this one would miss a sentence that
began with “The House”, and none of these addresses has one.

Matching does not change the pipeline, so rules can be tried and revised
like this without starting spaCy again. Rules need not be words and
phrases.
[`spacy_match()`](https://spacyr.quanteda.io/reference/spacy_match.md)
also takes patterns that describe tokens by their attributes, such as
their part of speech, and patterns that describe tokens connected in the
dependency parse; the article on [rule-based
matching](https://spacyr.quanteda.io/articles/matching.md) uses them to
find passive verbs.

## Back to the original text

With `offsets = TRUE`, each match also has `start` and `end`, the
positions of its first and last characters in the document. They count
characters from 1, as R does, so
[`substring()`](https://rdrr.io/r/base/substr.html) recovers the match
from the original text, or the match with as much of the text around it
as you want:

\
`txt`` ``<-`` `[`as.character`](https://rdrr.io/r/base/character.html)`(``corp``)`\
[`all`](https://rdrr.io/r/base/all.html)`(`[`substring`](https://rdrr.io/r/base/substr.html)`(``txt``[``m``$``doc_id``]``, ``m``$``start``, ``m``$``end``)`` ``==`` ``m``$``text``)`\
`## [1] TRUE`\
`court`` ``<-`` ``m``[``m``$``label`` ``==`` ``"JUDICIARY"``, ``]`\
[`data.frame`](https://rdrr.io/r/base/data.frame.html)`(``doc_id ``=`` ``court``$``doc_id``,`\
`           context ``=`` `[`substring`](https://rdrr.io/r/base/substr.html)`(``txt``[``court``$``doc_id``]``, ``court``$``start`` ``-`` ``30``, ``court``$``end`` ``+`` ``30``)``)`\
`##         doc_id                                                                   context`\
`## 1 1861-Lincoln ions are to be decided by the Supreme Court, nor do I deny that such deci`\
`## 2 1861-Lincoln bly fixed by decisions of the Supreme Court, the instant they are made in`

Unlike the positions of tokens, these do not depend on how the text was
split into tokens. They can mark the matches in the documents
themselves, or send them to another program or to a human coder.

## Rules as named entities

Rules that find what they should can become part of the pipeline.
`spacy_initialize(entity_patterns = )` adds them to it as spaCy’s entity
ruler, and what they find is then among the named entities of every
parse. spaCy is running without the rules, so it is finalized first:

\
[`spacy_finalize`](https://spacyr.quanteda.io/reference/spacy_finalize.md)`(``)`

Then it is initialized with the rules, and the texts are parsed, with
the offsets of their tokens:

\
[`spacy_initialize`](https://spacyr.quanteda.io/reference/spacy_initialize.md)`(``entity_patterns ``=`` ``rules``)`\
`## successfully initialized (spaCy Version: 3.8.18, language model: en_core_web_sm)`\
`parsed`` ``<-`` `[`spacy_parse`](https://spacyr.quanteda.io/reference/spacy_parse.md)`(``corp``, offsets ``=`` ``TRUE``)`

The `entity` column of the parse has the labels of the rules next to
those of the language model. These are the first two sentences in which
Bush refers to the legislature, and the last tokens of the second:

\
`bush`` ``<-`` ``parsed``[``parsed``$``doc_id`` ``==`` ``"1989-Bush"``, ``]`\
`sentences`` ``<-`` `[`unique`](https://rdrr.io/r/base/unique.html)`(``bush``$``sentence_id``[`[`grepl`](https://rdrr.io/r/base/grep.html)`(``"^LEGISLATURE"``, ``bush``$``entity``)``]``)`\
`passage`` ``<-`` ``bush``[``bush``$``sentence_id`` `[`%in%`](https://rdrr.io/r/base/match.html)` ``sentences``[``1``:``2``]``, ``]`\
[`tail`](https://rdrr.io/r/utils/head.html)`(``passage``, ``7``)`\
`##         doc_id sentence_id token_id  token start  end  lemma   pos        entity`\
`## 9287 1989-Bush          78        9   with  7315 7318   with   ADP              `\
`## 9288 1989-Bush          78       10    the  7320 7322    the   DET LEGISLATURE_B`\
`## 9289 1989-Bush          78       11  House  7324 7328  House PROPN LEGISLATURE_I`\
`## 9290 1989-Bush          78       12    and  7330 7332    and CCONJ              `\
`## 9291 1989-Bush          78       13    the  7334 7336    the   DET              `\
`## 9292 1989-Bush          78       14 Senate  7338 7343 Senate PROPN LEGISLATURE_B`\
`## 9293 1989-Bush          78       15      .  7344 7344      . PUNCT`

`offsets = TRUE` works for
[`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md)
as it does for
[`spacy_match()`](https://spacyr.quanteda.io/reference/spacy_match.md),
and gives the position of each token in the text. Counting the entities
of each type gives the model’s entities and ours, and the same 17 and 2
that
[`spacy_match()`](https://spacyr.quanteda.io/reference/spacy_match.md)
found:

\
[`table`](https://rdrr.io/r/base/table.html)`(`[`entity_extract`](https://spacyr.quanteda.io/reference/entity_extract.md)`(``parsed``)``$``entity_type``)`\
`## `\
`##       EVENT         FAC         GPE   JUDICIARY         LAW LEGISLATURE         LOC        NORP `\
`##           2           1          27           2          23          17           9          12 `\
`##         ORG      PERSON WORK_OF_ART `\
`##          34          11           3`

Matches and entities serve different purposes.
[`spacy_match()`](https://spacyr.quanteda.io/reference/spacy_match.md)
leaves the pipeline as it is and returns a table. Its matches can
overlap when their labels differ, and it takes patterns for things that
are not entities. Entities are part of the parse. No two of them
overlap, and where a rule’s entity overlaps one of the model’s, the
rule’s is kept, unless `overwrite_entities = FALSE`. Every function that
works with entities then has them:
[`entity_extract()`](https://spacyr.quanteda.io/reference/entity_extract.md),
[`entity_consolidate()`](https://spacyr.quanteda.io/reference/entity_extract.md),
[`spacy_extract_entity()`](https://spacyr.quanteda.io/reference/spacy_extract_entity.md)
and
[`entity_visualize()`](https://spacyr.quanteda.io/reference/entity_visualize.md).

## Highlight the entities

[`entity_visualize()`](https://spacyr.quanteda.io/reference/entity_visualize.md)
shows parsed documents with their entities highlighted and labelled, as
HTML. Because the parse has the offsets of its tokens, the text is
spaced as the original was. With `view = TRUE` the result opens in the
browser. In an R Markdown document,
[`knitr::raw_html()`](https://rdrr.io/pkg/knitr/man/raw_block.html) puts
it into the page:

\
`knitr``::`[`raw_html`](https://rdrr.io/pkg/knitr/man/raw_block.html)`(`[`entity_visualize`](https://spacyr.quanteda.io/reference/entity_visualize.md)`(``passage``, colors ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``LEGISLATURE ``=`` ``"#ffd966"``)``)``)`

We need a new engagement, too, between the Executive LOC and the
Congress LEGISLATURE . The challenges before us will be thrashed out
with the House LEGISLATURE and the Senate LEGISLATURE .

Labels of the model have colours of their own, and `colors` sets one for
a label of ours, which would otherwise be grey. The passage also shows
what the model does by itself: it takes “the Executive” for a location.
To show only some labels, name them, as in
`entity_visualize(parsed, entities = names(dict))`.

## Back in quanteda

[`as.tokens()`](https://quanteda.io/reference/as.tokens.html) turns the
parse into **quanteda** tokens, and restores the document variables of
the corpus that was parsed. The counts can then be set beside the year
and the party of each address, and the tokens go on to any analysis in
**quanteda**:

\
`toks`` ``<-`` `[`as.tokens`](https://quanteda.io/reference/as.tokens.html)`(``parsed``)`\
`counts`` ``<-`` `[`table`](https://rdrr.io/r/base/table.html)`(`[`factor`](https://rdrr.io/r/base/factor.html)`(``m``$``doc_id``, levels ``=`` `[`docnames`](https://quanteda.io/reference/docnames.html)`(``toks``)``)``, ``m``$``label``)`\
[`cbind`](https://rdrr.io/r/base/cbind.html)`(`[`docvars`](https://quanteda.io/reference/docvars.html)`(``toks``)``, `[`unclass`](https://rdrr.io/r/base/class.html)`(``counts``)``)`\
`##                 Year  President   FirstName      Party JUDICIARY LEGISLATURE`\
`## 1789-Washington 1789 Washington      George       none         0           3`\
`## 1861-Lincoln    1861    Lincoln     Abraham Republican         2           5`\
`## 1933-Roosevelt  1933  Roosevelt Franklin D. Democratic         0           4`\
`## 1989-Bush       1989       Bush      George Republican         0           5`

The levels of the factor are the names of all the documents, so that a
document without a match would stay in the table, with zeros.

## Larger corpora

For a larger corpus, it matters that the functions run no more of
spaCy’s pipeline than they need.
[`spacy_match()`](https://spacyr.quanteda.io/reference/spacy_match.md)
runs only the components that its patterns ask for, and words and
phrases need only the parser.
[`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md)
leaves out the components of the columns that are not asked for, as the
parse for the concordance did above. Both take `batch_size` and
`n_process`, for the number of documents that spaCy handles at a time
and the number of processes it uses. Whether more processes are faster
depends on the number and the length of the documents, so time them on a
sample first. The article on [improving
performance](https://spacyr.quanteda.io/articles/performance.md) has the
measurements.

\
[`spacy_finalize`](https://spacyr.quanteda.io/reference/spacy_finalize.md)`(``)`

## Upgrading from 1.4.0

Most code written for **spacyr** 1.4.0 runs unchanged in 2.0. What can
need attention is listed under “Upgrading from 1.4.0” in the
[news](https://spacyr.quanteda.io/news/index.md): the versions of R and
spaCy that are needed, `n_process` and `batch_size` in place of
`multithread`, and the functions that are deprecated or have a new name.
