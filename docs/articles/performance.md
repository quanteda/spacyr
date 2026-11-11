# Improving Performance

## Introduction

Almost all of the time that **spacyr** takes to parse texts is spent in
spaCy’s *pipeline*: the sequence of components that the language model
applies to each document after splitting it into tokens. The pipeline of
spaCy’s small English model, `en_core_web_sm`, has six components:

- `tok2vec`, which computes the vectors for each token that the next
  components use;
- `tagger`, for the detailed part-of-speech tags;
- `parser`, for the dependencies, which also sets the sentence
  boundaries and the noun phrases;
- `attribute_ruler`, which maps the tags to universal part-of-speech
  tags;
- `lemmatizer`, for the lemmas;
- `ner`, the named entity recogniser.

Making **spacyr** faster mostly means running fewer of these components,
running them on more documents at once, or running them in several
processes. This article shows what each of these does, using the 60 US
presidential inaugural addresses from **quanteda**, about 155,000
tokens, as texts:

\
[`library`](https://rdrr.io/r/base/library.html)`(`[`"spacyr"`](https://spacyr.quanteda.io)`)`\
[`library`](https://rdrr.io/r/base/library.html)`(`[`"quanteda"`](https://quanteda.io)`)`\
\
`txt`` ``<-`` `[`as.character`](https://rdrr.io/r/base/character.html)`(``data_corpus_inaugural``)`\
`sents`` ``<-`` `[`as.character`](https://rdrr.io/r/base/character.html)`(`[`corpus_reshape`](https://quanteda.io/reference/corpus_reshape.html)`(``data_corpus_inaugural``, to ``=`` ``"sentences"``)``)`\
[`length`](https://rdrr.io/r/base/length.html)`(``txt``)`\
`## [1] 60`\
[`length`](https://rdrr.io/r/base/length.html)`(``sents``)`\
`## [1] 5473`

To time each call, we use a small function that runs it three times, and
returns the median of the elapsed seconds:

\
`seconds`` ``<-`` ``function``(``expr``, ``times`` ``=`` ``3``)`` ``{`\
`  ``expr`` ``<-`` `[`substitute`](https://rdrr.io/r/base/substitute.html)`(``expr``)`\
`  ``env`` ``<-`` `[`parent.frame`](https://rdrr.io/r/base/sys.parent.html)`(``)`\
`  `[`round`](https://rdrr.io/r/base/Round.html)`(`[`median`](https://rdrr.io/r/stats/median.html)`(`[`replicate`](https://rdrr.io/r/base/lapply.html)`(``times``, `[`system.time`](https://rdrr.io/r/base/system.time.html)`(`[`eval`](https://rdrr.io/r/base/eval.html)`(``expr``, ``env``)``)``[[``"elapsed"``]``]``)``)``, ``1``)`\
`}`

The times below are from the machine described at the end of this
article. They will be different on yours, and vary somewhat from one run
to the next, so what matters is how they compare, not their values.
Since the first calls after
[`spacy_initialize()`](https://spacyr.quanteda.io/reference/spacy_initialize.md)
take longer, while spaCy finishes loading, we parse the texts once
before timing anything:

\
[`spacy_initialize`](https://spacyr.quanteda.io/reference/spacy_initialize.md)`(``)`\
`## successfully initialized (spaCy Version: 3.8.18, language model: en_core_web_sm)`\
[`invisible`](https://rdrr.io/r/base/invisible.html)`(`[`spacy_parse`](https://spacyr.quanteda.io/reference/spacy_parse.md)`(``txt``, entity ``=`` ``FALSE``)``)`

## Ask only for what you need, from the right function

The options of
[`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md),
such as `pos`, `lemma` or `dependency`, choose the columns of its
output. They do not turn components of the pipeline on or off: every
component runs whatever the options are. So returning the dependencies
costs little more than leaving them out, as reported in
[\#188](https://github.com/quanteda/spacyr/issues/188), and the same
holds for turning several options off, or on, together:

\
[`data.frame`](https://rdrr.io/r/base/data.frame.html)`(`\
`  options ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"defaults"``,`\
`              ``"adding dependency"``,`\
`              ``"no pos, lemma or entity"``,`\
`              ``"adding tag, dependency and nounphrase"``)``,`\
`  seconds ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``seconds``(`[`spacy_parse`](https://spacyr.quanteda.io/reference/spacy_parse.md)`(``txt``)``)``,`\
`              ``seconds``(`[`spacy_parse`](https://spacyr.quanteda.io/reference/spacy_parse.md)`(``txt``, dependency ``=`` ``TRUE``)``)``,`\
`              ``seconds``(`[`spacy_parse`](https://spacyr.quanteda.io/reference/spacy_parse.md)`(``txt``, pos ``=`` ``FALSE``, lemma ``=`` ``FALSE``, entity ``=`` ``FALSE``)``)``,`\
`              ``seconds``(`[`spacy_parse`](https://spacyr.quanteda.io/reference/spacy_parse.md)`(``txt``, tag ``=`` ``TRUE``, dependency ``=`` ``TRUE``, nounphrase ``=`` ``TRUE``)``)``)`\
`)`\
`##                                 options seconds`\
`## 1                              defaults     2.6`\
`## 2                     adding dependency     2.7`\
`## 3               no pos, lemma or entity     2.6`\
`## 4 adding tag, dependency and nounphrase     2.8`

What extra time there is comes from building the extra columns, not from
running the pipeline.

So it is better to ask for all the columns you will need in one call,
than to call
[`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md)
once for each.
[`entity_extract()`](https://spacyr.quanteda.io/reference/entity_extract.md)
and
[`nounphrase_extract()`](https://spacyr.quanteda.io/reference/nounphrase_extract.md)
take the entities and noun phrases from the output of
[`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md),
without parsing the texts again:

\
`parsed`` ``<-`` `[`spacy_parse`](https://spacyr.quanteda.io/reference/spacy_parse.md)`(``txt``[``1``:``2``]``, nounphrase ``=`` ``TRUE``)`\
[`head`](https://rdrr.io/r/utils/head.html)`(`[`entity_extract`](https://spacyr.quanteda.io/reference/entity_extract.md)`(``parsed``)``, ``3``)`\
`##            doc_id sentence_id                       entity entity_type`\
`## 1 1789-Washington           1            Fellow_-_Citizens         ORG`\
`## 2 1789-Washington           1                       Senate         ORG`\
`## 3 1789-Washington           1 the_House_of_Representatives         ORG`\
[`head`](https://rdrr.io/r/utils/head.html)`(`[`nounphrase_extract`](https://spacyr.quanteda.io/reference/nounphrase_extract.md)`(``parsed``)``, ``3``)`\
`##            doc_id sentence_id      nounphrase`\
`## 1 1789-Washington           1 Fellow-Citizens`\
`## 2 1789-Washington           1      the_Senate`\
`## 3 1789-Washington           1       the_House`

The exception is
[`spacy_tokenize()`](https://spacyr.quanteda.io/reference/spacy_tokenize.md),
which turns off every component, and only splits the texts into tokens:

\
`seconds``(`[`spacy_tokenize`](https://spacyr.quanteda.io/reference/spacy_tokenize.md)`(``txt``)``)`\
`## [1] 0.2`

If you need only the tokens,
[`spacy_tokenize()`](https://spacyr.quanteda.io/reference/spacy_tokenize.md)
is many times faster than
[`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md).
Its options `remove_punct`, `remove_numbers` and `remove_url` depend
only on the tokens, and keep it fast, but two of its options need the
pipeline, and make it run all of the components: `remove_symbols`, which
uses the part-of-speech tags, and `what = "sentence"`, since the
sentence boundaries come from the parser:

\
[`data.frame`](https://rdrr.io/r/base/data.frame.html)`(`\
`  call ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``'spacy_tokenize(txt)'``,`\
`           ``'spacy_tokenize(txt, remove_punct = TRUE)'``,`\
`           ``'spacy_tokenize(txt, remove_symbols = TRUE)'``,`\
`           ``'spacy_tokenize(txt, what = "sentence")'``)``,`\
`  seconds ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``seconds``(`[`spacy_tokenize`](https://spacyr.quanteda.io/reference/spacy_tokenize.md)`(``txt``)``)``,`\
`              ``seconds``(`[`spacy_tokenize`](https://spacyr.quanteda.io/reference/spacy_tokenize.md)`(``txt``, remove_punct ``=`` ``TRUE``)``)``,`\
`              ``seconds``(`[`spacy_tokenize`](https://spacyr.quanteda.io/reference/spacy_tokenize.md)`(``txt``, remove_symbols ``=`` ``TRUE``)``)``,`\
`              ``seconds``(`[`spacy_tokenize`](https://spacyr.quanteda.io/reference/spacy_tokenize.md)`(``txt``, what ``=`` ``"sentence"``)``)``)`\
`)`\
`##                                         call seconds`\
`## 1                        spacy_tokenize(txt)     0.2`\
`## 2   spacy_tokenize(txt, remove_punct = TRUE)     0.2`\
`## 3 spacy_tokenize(txt, remove_symbols = TRUE)     2.6`\
`## 4     spacy_tokenize(txt, what = "sentence")     2.5`

To remove symbols quickly, tokenize with
[`spacy_tokenize()`](https://spacyr.quanteda.io/reference/spacy_tokenize.md),
and remove them afterwards, for instance with **quanteda**’s
`tokens(remove_symbols = TRUE)`, which removes tokens made of symbol
characters instead of using the tags. The two can differ: **quanteda**
removes `+` and `©`, for instance, where spaCy may tag them otherwise
and keep them.

## Turn off the entity recogniser

The one component that **spacyr** can turn off is the named entity
recogniser. `spacy_initialize(entity = FALSE)` loads the model with the
recogniser disabled, so that it does not run when texts are parsed,
which here saves about a quarter of the parsing time:

\
`with_ner`` ``<-`` ``seconds``(`[`spacy_parse`](https://spacyr.quanteda.io/reference/spacy_parse.md)`(``sents``, entity ``=`` ``FALSE``)``)`\
[`spacy_finalize`](https://spacyr.quanteda.io/reference/spacy_finalize.md)`(``)`\
\
[`spacy_initialize`](https://spacyr.quanteda.io/reference/spacy_initialize.md)`(``entity ``=`` ``FALSE``)`\
`## successfully initialized (spaCy Version: 3.8.18, language model: en_core_web_sm)`\
[`invisible`](https://rdrr.io/r/base/invisible.html)`(`[`spacy_parse`](https://spacyr.quanteda.io/reference/spacy_parse.md)`(``txt``, entity ``=`` ``FALSE``)``)`\
`without_ner`` ``<-`` ``seconds``(`[`spacy_parse`](https://spacyr.quanteda.io/reference/spacy_parse.md)`(``sents``, entity ``=`` ``FALSE``)``)`\
[`spacy_finalize`](https://spacyr.quanteda.io/reference/spacy_finalize.md)`(``)`\
\
[`data.frame`](https://rdrr.io/r/base/data.frame.html)`(``ner ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"in the pipeline"``, ``"disabled"``)``,`\
`           seconds ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``with_ner``, ``without_ner``)``)`\
`##               ner seconds`\
`## 1 in the pipeline     2.7`\
`## 2        disabled     2.0`

[`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md)
then has no entities to return, and says so if asked for them, unless
entity rules are added with `spacy_initialize(entity_patterns = )` (see
the article on [entity
rules](https://spacyr.quanteda.io/articles/entity_rules.md)). The rules
work without the recogniser, so long as they do not build on the
entities it finds.

## Choose the model

The models of a language differ mostly in their size and accuracy. Here,
`en_core_web_lg` takes about as long as `en_core_web_sm`:

\
[`spacy_initialize`](https://spacyr.quanteda.io/reference/spacy_initialize.md)`(``model ``=`` ``"en_core_web_lg"``)`\
`## successfully initialized (spaCy Version: 3.8.18, language model: en_core_web_lg)`\
[`invisible`](https://rdrr.io/r/base/invisible.html)`(`[`spacy_parse`](https://spacyr.quanteda.io/reference/spacy_parse.md)`(``txt``, entity ``=`` ``FALSE``)``)`\
`seconds``(`[`spacy_parse`](https://spacyr.quanteda.io/reference/spacy_parse.md)`(``txt``)``)`\
`## [1] 3`\
[`spacy_finalize`](https://spacyr.quanteda.io/reference/spacy_finalize.md)`(``)`

since the two have the same components; most of what makes the large
model large is its table of word vectors, which takes more memory and
longer to load, but little more time to use. The transformer models,
such as `en_core_web_trf`, are more accurate, but much slower,
especially without a GPU.

## Batch size

spaCy processes documents in *batches*, a number of documents at a time,
and **spacyr**’s functions pass the `batch_size` argument to spaCy to
set how many. The default, `batch_size = NULL`, uses the model’s own
setting, which is 256 documents for `en_core_web_sm`. Very small batches
are slower, but beyond some size, larger ones make little difference:

\
[`spacy_initialize`](https://spacyr.quanteda.io/reference/spacy_initialize.md)`(``)`\
`## successfully initialized (spaCy Version: 3.8.18, language model: en_core_web_sm)`\
[`invisible`](https://rdrr.io/r/base/invisible.html)`(`[`spacy_parse`](https://spacyr.quanteda.io/reference/spacy_parse.md)`(``txt``, entity ``=`` ``FALSE``)``)`\
\
`sizes`` ``<-`` `[`c`](https://rdrr.io/r/base/c.html)`(``1``, ``10``, ``100``, ``1000``)`\
[`data.frame`](https://rdrr.io/r/base/data.frame.html)`(``batch_size ``=`` ``sizes``,`\
`           seconds ``=`` `[`sapply`](https://rdrr.io/r/base/lapply.html)`(``sizes``, ``function``(``b``)`` ``seconds``(`[`spacy_parse`](https://spacyr.quanteda.io/reference/spacy_parse.md)`(``sents``, batch_size ``=`` ``b``)``)``)``)`\
`##   batch_size seconds`\
`## 1          1     6.0`\
`## 2         10     3.7`\
`## 3        100     2.8`\
`## 4       1000     2.8`

The default is usually a good choice. A batch of long documents takes
more memory than one of short documents, so with long documents, a
smaller batch can avoid running out of memory.

## Processes

The `n_process` argument starts that many Python processes, each with
its own copy of the model, which share the documents between them;
`n_process = -1` uses all the CPUs. Starting the processes, loading the
model in each, and sending the parsed documents back all take time, so
they help only with many documents. For 5,473 sentences, more processes
are slower:

\
`procs`` ``<-`` `[`c`](https://rdrr.io/r/base/c.html)`(``1``, ``2``, ``4``)`\
[`data.frame`](https://rdrr.io/r/base/data.frame.html)`(``n_process ``=`` ``procs``,`\
`           seconds ``=`` `[`sapply`](https://rdrr.io/r/base/lapply.html)`(``procs``, ``function``(``p``)`` ``seconds``(`[`spacy_parse`](https://spacyr.quanteda.io/reference/spacy_parse.md)`(``sents``, n_process ``=`` ``p``)``)``)``)`\
`##   n_process seconds`\
`## 1         1     2.7`\
`## 2         2     3.4`\
`## 3         4     4.1`

and for six times as many, timed once each, they make little difference:

\
`more`` ``<-`` `[`unname`](https://rdrr.io/r/base/unname.html)`(`[`rep`](https://rdrr.io/r/base/rep.html)`(``sents``, ``6``)``)`\
[`data.frame`](https://rdrr.io/r/base/data.frame.html)`(``n_process ``=`` ``procs``,`\
`           seconds ``=`` `[`sapply`](https://rdrr.io/r/base/lapply.html)`(``procs``, ``function``(``p``)`` ``seconds``(`[`spacy_parse`](https://spacyr.quanteda.io/reference/spacy_parse.md)`(``more``, n_process ``=`` ``p``)``, times ``=`` ``1``)``)``)`\
`##   n_process seconds`\
`## 1         1    16.4`\
`## 2         2    15.1`\
`## 3         4    14.9`

So on this machine, with this model and these texts, there is little to
gain. The gain may differ with other models, texts and machines, so time
`n_process` on a sample of your own texts before relying on it.
**spacyr** itself also adds some cost with more than one process, which
[\#289](https://github.com/quanteda/spacyr/issues/289) is about. Since
[`spacy_tokenize()`](https://spacyr.quanteda.io/reference/spacy_tokenize.md)
runs no components, it gains nothing from more processes, and only pays
the costs of starting them and of sending the documents between them:

\
[`data.frame`](https://rdrr.io/r/base/data.frame.html)`(``n_process ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``1``, ``4``)``,`\
`           seconds ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``seconds``(`[`spacy_tokenize`](https://spacyr.quanteda.io/reference/spacy_tokenize.md)`(``more``)``, times ``=`` ``1``)``,`\
`                       ``seconds``(`[`spacy_tokenize`](https://spacyr.quanteda.io/reference/spacy_tokenize.md)`(``more``, n_process ``=`` ``4``)``, times ``=`` ``1``)``)``)`\
`##   n_process seconds`\
`## 1         1     0.8`\
`## 2         4    11.4`

A few things to keep in mind with more than one process:

- Each process has its own copy of the model, so they need more memory.
  A process started by copying the R session’s Python process (“fork”)
  can share much of that memory with it at first.
- How Python starts the processes depends on the system and the version
  of Python. On macOS and Windows, it starts each process afresh
  (“spawn”), which takes longer. On Linux, it copies the R session’s
  Python process (“fork”), or from Python 3.14 starts the processes from
  a separate server process (“forkserver”); see Python’s documentation
  on [start
  methods](https://docs.python.org/3/library/multiprocessing.html#contexts-and-start-methods).
- A custom pipeline component must be defined in a Python module that
  the other processes can import.
- With a pipeline that uses Hugging Face’s **tokenizers** library, as
  some transformer pipelines do, see the section below.

The output does not depend on `n_process` or `batch_size`: documents
come back in their original order.

## Long documents

spaCy accepts documents of up to 1,000,000 characters, unless
`spacy_initialize(max_length = )` sets another limit, and a document
longer than the limit gives an error. spaCy’s rule of thumb is that the
parser and the entity recogniser need roughly 1GB of temporary memory
for each 100,000 characters of a document, so very long documents can
use a great deal of memory. Splitting long documents into paragraphs or
sentences first, for instance with **quanteda**’s
[`corpus_reshape()`](https://quanteda.io/reference/corpus_reshape.html),
keeps each piece within the limit, uses less memory, and gives the
batches and processes more documents to share. It has costs, however.
Each piece becomes a document of its own, with its own name, so the
results must be put back together by document if needed; and spaCy
cannot see across the places where the documents were split, so sentence
boundaries, dependencies and entities there can differ from those it
would find in the whole document. Splitting at paragraphs keeps these
differences fewest.

## Transformer pipelines and `TOKENIZERS_PARALLELISM`

Some pipelines, such as those built with **spacy-transformers**, use
Hugging Face’s **tokenizers** library.
[`spacy_initialize()`](https://spacyr.quanteda.io/reference/spacy_initialize.md)
sets the environment variable `TOKENIZERS_PARALLELISM` to `"false"`,
unless it is already set, which stops older versions of that library
from printing a warning again and again once the R process has been
forked ([\#233](https://github.com/quanteda/spacyr/issues/233)). The
setting turns off the library’s own threads for tokenizing, and how much
that matters for the total time depends on the pipeline and the texts.
Setting it to `"true"` before calling
[`spacy_initialize()`](https://spacyr.quanteda.io/reference/spacy_initialize.md)
turns them back on, but also turns off the library’s safeguard against
deadlocks: a process forked from the R session after the R session has
used the library, such as a worker of
[`parallel::mclapply()`](https://rdrr.io/r/parallel/mclapply.html), or
of `n_process` greater than 1 when the workers are started by fork, can
then hang if it uses the library too. Leave it at `"false"` whenever
that can happen.

## Summary

- Use
  [`spacy_tokenize()`](https://spacyr.quanteda.io/reference/spacy_tokenize.md)
  when you need only the tokens. Its `remove_symbols` option runs the
  whole pipeline; removing symbols afterwards, by their characters, is
  faster, if that definition of a symbol suits your task.
- Ask
  [`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md)
  for all the columns you need in a single call; turning its options off
  saves little time.
- Use `spacy_initialize(entity = FALSE)` when you do not need named
  entities.
- Leave `batch_size` at its default, unless memory runs short.
- Try `n_process` greater than 1 only for large numbers of documents,
  after timing it on a sample.
- Split very long documents into smaller ones.

\
[`spacy_finalize`](https://spacyr.quanteda.io/reference/spacy_finalize.md)`(``)`

The times in this article were computed on this machine:

\
[`Sys.info`](https://rdrr.io/r/base/Sys.info.html)`(``)``[[``"sysname"``]``]`\
`## [1] "Darwin"`\
`parallel``::`[`detectCores`](https://rdrr.io/r/parallel/detectCores.html)`(``)`\
`## [1] 10`\
`R.version.string`\
`## [1] "R version 4.6.1 (2026-06-24)"`
