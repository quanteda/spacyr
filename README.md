[![CRAN
Version](https://www.r-pkg.org/badges/version/spacyr)](https://CRAN.R-project.org/package=spacyr)
![Downloads](https://cranlogs.r-pkg.org/badges/spacyr) [![Travis-CI
Build
Status](https://travis-ci.org/quanteda/spacyr.svg?branch=master)](https://travis-ci.org/quanteda/spacyr)
[![Appveyor Build
status](https://ci.appveyor.com/api/projects/status/jqt2atp1wqtxy5xd/branch/master?svg=true)](https://ci.appveyor.com/project/quanteda/spacyr/branch/master)
[![codecov.io](https://codecov.io/github/quanteda/spacyr/coverage.svg?branch=master)](https://codecov.io/gh/quanteda/spacyr/branch/master)

spacyr: an R wrapper for spaCy
==============================

This package is an R wrapper to the spaCy “industrial strength natural
language processing” Python library from <http://spacy.io>.

Installing the package
----------------------

1.  Install miniconda

    The easiest way to install spaCy and **spacyr** is through an
    auto-installation function in **spacyr** package. This function
    utilizes a conda environment and therefore, some version of conda
    has to be installed in the system. You can install miniconda from
    <https://conda.io/miniconda.html> (Choose 64-bit version for your
    system).

    If you have any version of conda, you can skip this step. You can
    check it by entering `conda --version` in Console.

2.  Install the **spacyr** R package:

    -   From GitHub:

        To install the latest package from source, you can simply run
        the following.

    ``` r
    devtools::install_github("quanteda/spacyr", build_vignettes = FALSE)
    ```

    -   From CRAN:

    ``` r
    install.packages("spacyr")
    ```

3.  Install spaCy in a conda environment

    -   For Windows, you need to run R as an administrator to make
        installation work properly. To do so, right click Rstudio (or R
        desktop icon) and select “Run as administrator” when
        launching R.

    -   To install spaCy, you can simply run

    ``` r
    library(spacy)
    spacy_install()
    ```

    This will install the latest version of spaCy (and its required
    packages) and English language model. After installation, you can
    initialize spacy in R with

    ``` r
    spacy_initialize()
    ```

    This will return the following message if spaCy was installed with
    this method.

    ``` r
    ## Found 'spacy_condaenv'. spacyr will use this environment
    ## successfully initialized (spaCy Version: 2.0.11, language model: en)
    ## (python options: type = "condaenv", value = "spacy_condaenv")
    ```

4.  (optional) Add more language models

    For spaCy installed by `spacy_install()`, **spacyr** provides a
    useful helper function to install additional language models. For
    instance, to install Gernman language model

    ``` r
    spacy_download_langmodel("de")
    ```

    (Again, Windows users have to run this command as an administrator.
    Otherwise, sim-link to language model will fail.)

Comments and feedback
---------------------

We welcome your comments and feedback. Please file issues on the
[issues](https://github.com/quanteda/spacyr/issues) page, and/or send us
comments at <kbenoit@lse.ac.uk> and <A.Matsuo@lse.ac.uk>.

A walkthrough of **spacyr**
---------------------------

### Starting a **spacyr** session

To allow R to access the underlying Python functionality, it must open a
connection by being initialized within your R session.

We provide a function for this, `spacy_initialize()`, which attempts to
make this process as painless as possible by searching your system for
Python executables, and testing which have spaCy installed. For power
users (such as those with multiple installations of Python), it is
possible to specify the path manually through the `python_executable`
argument, which also makes initialization faster. (You will need to
change the value on your system of the Python executable.)

``` r
library("spacyr")
spacy_initialize()
## Found 'spacy_condaenv'. spacyr will use this environment
## successfully initialized (spaCy Version: 2.0.11, language model: en)
## (python options: type = "condaenv", value = "spacy_condaenv")
```

### Tokenizing and tagging texts

The `spacy_parse()` is **spacyr**’s main function. It calls spaCy both
to tokenize and tag the texts. It provides two options for part of
speech tagging, plus options to return word lemmas, entity recognition,
and dependency parsing. It returns a `data.frame` corresponding to the
emerging [*text interchange format*](https://github.com/ropensci/tif)
for token data.frames.

The approach to tokenizing taken by spaCy is inclusive: it includes all
tokens without restrictions, including punctuation characters and
symbols.

Example:

``` r
txt <- c(d1 = "spaCy excels at large-scale information extraction tasks.",
         d2 = "Mr. Smith goes to North Carolina.")

# process documents and obtain a data.table
parsedtxt <- spacy_parse(txt)
parsedtxt
##    doc_id sentence_id token_id       token       lemma   pos   entity
## 1      d1           1        1       spaCy       spacy   ADJ         
## 2      d1           1        2      excels       excel  NOUN         
## 3      d1           1        3          at          at   ADP         
## 4      d1           1        4       large       large   ADJ         
## 5      d1           1        5           -           - PUNCT         
## 6      d1           1        6       scale       scale  NOUN         
## 7      d1           1        7 information information  NOUN         
## 8      d1           1        8  extraction  extraction  NOUN         
## 9      d1           1        9       tasks        task  NOUN         
## 10     d1           1       10           .           . PUNCT         
## 11     d2           1        1         Mr.         mr. PROPN         
## 12     d2           1        2       Smith       smith PROPN PERSON_B
## 13     d2           1        3        goes          go  VERB         
## 14     d2           1        4          to          to   ADP         
## 15     d2           1        5       North       north PROPN    GPE_B
## 16     d2           1        6    Carolina    carolina PROPN    GPE_I
## 17     d2           1        7           .           . PUNCT
```

Two fields are available for part-of-speech tags. The `pos` field
returned is the [Universal tagset for
parts-of-speech](http://universaldependencies.org/u/pos/all.html), a
general scheme that most users will find serves their needs, and also
that provides equivalencies across langages. **spacyr** also provides a
more detailed tagset, defined in each spaCy language model. For English,
this is the [OntoNotes 5 version of the Penn Treebank tag
set](https://spacy.io/docs/usage/pos-tagging#pos-tagging-english).

``` r
spacy_parse(txt, tag = TRUE, entity = FALSE, lemma = FALSE)
##    doc_id sentence_id token_id       token   pos  tag
## 1      d1           1        1       spaCy   ADJ   JJ
## 2      d1           1        2      excels  NOUN  NNS
## 3      d1           1        3          at   ADP   IN
## 4      d1           1        4       large   ADJ   JJ
## 5      d1           1        5           - PUNCT HYPH
## 6      d1           1        6       scale  NOUN   NN
## 7      d1           1        7 information  NOUN   NN
## 8      d1           1        8  extraction  NOUN   NN
## 9      d1           1        9       tasks  NOUN  NNS
## 10     d1           1       10           . PUNCT    .
## 11     d2           1        1         Mr. PROPN  NNP
## 12     d2           1        2       Smith PROPN  NNP
## 13     d2           1        3        goes  VERB  VBZ
## 14     d2           1        4          to   ADP   IN
## 15     d2           1        5       North PROPN  NNP
## 16     d2           1        6    Carolina PROPN  NNP
## 17     d2           1        7           . PUNCT    .
```

For the German language model, the Universal tagset (`pos`) remains the
same, but the detailed tagset (`tag`) is the [TIGER
Treebank](https://spacy.io/docs/usage/pos-tagging#pos-tagging-german)
scheme.

### Extracting entities

**spacyr** can extract entities, either named or
[“extended”](https://spacy.io/docs/usage/entity-recognition#entity-types).

``` r
parsedtxt <- spacy_parse(txt, lemma = FALSE)
entity_extract(parsedtxt)
##   doc_id sentence_id         entity entity_type
## 1     d2           1          Smith      PERSON
## 2     d2           1 North Carolina         GPE
```

``` r
entity_extract(parsedtxt, type = "all")
##   doc_id sentence_id         entity entity_type
## 1     d2           1          Smith      PERSON
## 2     d2           1 North Carolina         GPE
```

Or, convert multi-word entities into single “tokens”:

``` r
entity_consolidate(parsedtxt)
##    doc_id sentence_id token_id          token    pos entity_type
## 1      d1           1        1          spaCy    ADJ            
## 2      d1           1        2         excels   NOUN            
## 3      d1           1        3             at    ADP            
## 4      d1           1        4          large    ADJ            
## 5      d1           1        5              -  PUNCT            
## 6      d1           1        6          scale   NOUN            
## 7      d1           1        7    information   NOUN            
## 8      d1           1        8     extraction   NOUN            
## 9      d1           1        9          tasks   NOUN            
## 10     d1           1       10              .  PUNCT            
## 11     d2           1        1            Mr.  PROPN            
## 12     d2           1        2          Smith ENTITY      PERSON
## 13     d2           1        3           goes   VERB            
## 14     d2           1        4             to    ADP            
## 15     d2           1        5 North_Carolina ENTITY         GPE
## 16     d2           1        6              .  PUNCT
```

### Dependency parsing

Detailed parsing of syntactic dependencies is possible with the
`dependency = TRUE` option:

``` r
spacy_parse(txt, dependency = TRUE, lemma = FALSE, pos = FALSE)
##    doc_id sentence_id token_id       token head_token_id  dep_rel   entity
## 1      d1           1        1       spaCy             2    nsubj         
## 2      d1           1        2      excels             2     ROOT         
## 3      d1           1        3          at             2     prep         
## 4      d1           1        4       large             6     amod         
## 5      d1           1        5           -             6    punct         
## 6      d1           1        6       scale             9 compound         
## 7      d1           1        7 information             8 compound         
## 8      d1           1        8  extraction             9 compound         
## 9      d1           1        9       tasks             3     pobj         
## 10     d1           1       10           .             2    punct         
## 11     d2           1        1         Mr.             2 compound         
## 12     d2           1        2       Smith             3    nsubj PERSON_B
## 13     d2           1        3        goes             3     ROOT         
## 14     d2           1        4          to             3     prep         
## 15     d2           1        5       North             6 compound    GPE_B
## 16     d2           1        6    Carolina             4     pobj    GPE_I
## 17     d2           1        7           .             3    punct
```

### Using other language models

By default, **spacyr** loads an English language model. You also can
load SpaCy’s other [language models](https://spacy.io/docs/usage/models)
or use one of the [language models with alpha
support](https://spacy.io/docs/api/language-models#alpha-support) by
specifying the `model` option when calling `spacy_initialize()`. We have
sucessfully tested following language models with spacy version 2.0.1.

| Language   | ModelName |
|:-----------|:----------|
| German     | `de`      |
| Spanish    | `es`      |
| Portuguese | `pt`      |
| French     | `fr`      |
| Italian    | `it`      |
| Dutch      | `nl`      |

This is an example of parsing German texts.

``` r
## first finalize the spacy if it's loaded
spacy_finalize()
spacy_initialize(model = "de")
## Python space is already attached.  If you want to switch to a different Python, please restart R.
## successfully initialized (spaCy Version: 2.0.11, language model: de)
## (python options: type = "condaenv", value = "spacy_condaenv")

txt_german <- c(R = "R ist eine freie Programmiersprache für statistische Berechnungen und Grafiken. Sie wurde von Statistikern für Anwender mit statistischen Aufgaben entwickelt.",
               python = "Python ist eine universelle, üblicherweise interpretierte höhere Programmiersprache. Sie will einen gut lesbaren, knappen Programmierstil fördern.")
results_german <- spacy_parse(txt_german, dependency = TRUE, lemma = FALSE, tag = TRUE)
results_german
##    doc_id sentence_id token_id              token   pos   tag
## 1       R           1        1                  R PROPN    NE
## 2       R           1        2                ist   AUX VAFIN
## 3       R           1        3               eine   DET   ART
## 4       R           1        4              freie   ADJ  ADJA
## 5       R           1        5 Programmiersprache  NOUN    NN
## 6       R           1        6                für   ADP  APPR
## 7       R           1        7       statistische   ADJ  ADJA
## 8       R           1        8       Berechnungen  NOUN    NN
## 9       R           1        9                und  CONJ   KON
## 10      R           1       10           Grafiken  NOUN    NN
## 11      R           1       11                  . PUNCT    $.
## 12      R           2        1                Sie  PRON  PPER
## 13      R           2        2              wurde   AUX VAFIN
## 14      R           2        3                von   ADP  APPR
## 15      R           2        4       Statistikern  NOUN    NN
## 16      R           2        5                für   ADP  APPR
## 17      R           2        6           Anwender  NOUN    NN
## 18      R           2        7                mit   ADP  APPR
## 19      R           2        8      statistischen   ADJ  ADJA
## 20      R           2        9           Aufgaben  NOUN    NN
## 21      R           2       10         entwickelt  VERB  VVPP
## 22      R           2       11                  . PUNCT    $.
## 23 python           1        1             Python  NOUN    NN
## 24 python           1        2                ist   AUX VAFIN
## 25 python           1        3               eine   DET   ART
## 26 python           1        4        universelle   ADJ  ADJA
## 27 python           1        5                  , PUNCT    $,
## 28 python           1        6      üblicherweise   ADV   ADV
## 29 python           1        7     interpretierte   ADJ  ADJA
## 30 python           1        8             höhere   ADJ  ADJA
## 31 python           1        9 Programmiersprache  NOUN    NN
## 32 python           1       10                  . PUNCT    $.
## 33 python           2        1                Sie  PRON  PPER
## 34 python           2        2               will  VERB VMFIN
## 35 python           2        3              einen   DET   ART
## 36 python           2        4                gut   ADJ  ADJD
## 37 python           2        5           lesbaren   ADJ  ADJA
## 38 python           2        6                  , PUNCT    $,
## 39 python           2        7            knappen   ADJ  ADJA
## 40 python           2        8    Programmierstil  NOUN    NN
## 41 python           2        9            fördern  VERB VVFIN
## 42 python           2       10                  . PUNCT    $.
##    head_token_id dep_rel entity
## 1              2      sb       
## 2              2    ROOT       
## 3              5      nk       
## 4              5      nk       
## 5              2      pd       
## 6              5     mnr       
## 7              8      nk       
## 8              6      nk       
## 9              8      cd       
## 10             9      cj       
## 11             2   punct       
## 12             2      sb       
## 13             2    ROOT       
## 14            10     sbp       
## 15             3      nk  LOC_B
## 16             4     mnr       
## 17             5      nk       
## 18            10      mo       
## 19             9      nk       
## 20             7      nk       
## 21             2      oc       
## 22             2   punct       
## 23             2      sb MISC_B
## 24             2    ROOT       
## 25             9      nk       
## 26             9      nk       
## 27             4   punct       
## 28             7      mo       
## 29             4      cj       
## 30             9      nk       
## 31             2      pd       
## 32             2   punct       
## 33             2      sb       
## 34             2    ROOT       
## 35             8      nk       
## 36             5      mo       
## 37             8      nk       
## 38             5   punct       
## 39             5      cj       
## 40             9      oa       
## 41             2      oc       
## 42             2   punct
```

Note that the additional language models must first be installed in
spaCy. The German language model, for example, can be installed
(`python -m spacy download de`) before you call `spacy_initialize()`.

### When you finish

A background process of spaCy is initiated when you ran
`spacy_initialize()`. Because of the size of language models of spaCy,
this takes up a lot of memory (typically 1.5GB). When you do not need
the Python connection any longer, you can finalize the python connection
(and terminate the process) by calling the `spacy_finalize()` function.

``` r
spacy_finalize()
```

By calling `spacy_initialize()` again, you can restart the backend
spaCy.

### Permanently seting the default Python

If you want to skip **spacyr** searching for Python intallation with
spaCy, you can do so by permanently setting the path to the
spaCy-enabled Python by specifying it in an R-startup file (For
Mac/Linux, the file is `~/.Rprofile`), which is read every time a new
`R` is launched. You can set the option permanently when you call
`spacy_initialize`:

``` r
spacy_initialize(save_profile = TRUE)
```

Once this is appropriately set up, the message from `spacy_initialize()`
changes to something like:

    ## spacy python option is already set, spacyr will use:
    ##  condaenv = "spacy_condaenv"
    ## successfully initialized (spaCy Version: 2.0.11, language model: en)
    ## (python options: type = "condaenv", value = "spacy_condaenv")

To ignore the permanently set options, you can initialize spacy with
`refresh_settings = TRUE`.

Using **spacyr** with other packages
------------------------------------

### **quanteda**

Some of the token- and type-related standard methods from
[**quanteda**](http://githiub.com/quanteda/quanteda) also work on the
new tagged token objects:

``` r
require(quanteda, warn.conflicts = FALSE, quietly = TRUE)
## Package version: 1.2.0
## Parallel computing: 4 of 8 threads used.
## See https://quanteda.io for tutorials and examples.
docnames(parsedtxt)
## [1] "d1" "d2"
ndoc(parsedtxt)
## [1] 2
ntoken(parsedtxt)
## d1 d2 
## 10  7
ntype(parsedtxt)
## d1 d2 
## 10  7
```

### Conformity to the *Text Interchange Format*

The [Text Interchange Format](https://github.com/ropensci/tif) is an
emerging standard structure for text package objects in R, such as
corpus and token objects. `spacy_initialize()` can take a TIF corpus
data.frame or character object as a valid input. Moreover, the
data.frames returned by `spacy_parse()` and `entity_consolidate()`
conform to the TIF tokens standard for data.frame tokens objects. This
will make it easier to use with any text analysis package for R that
works with TIF standard objects.
