[![CRAN Version](https://www.r-pkg.org/badges/version/spacyr)](https://CRAN.R-project.org/package=spacyr) ![Downloads](https://cranlogs.r-pkg.org/badges/spacyr) [![Travis-CI Build Status](https://travis-ci.org/kbenoit/spacyr.svg?branch=master)](https://travis-ci.org/kbenoit/spacyr) [![Appveyor Build status](https://ci.appveyor.com/api/projects/status/jqt2atp1wqtxy5xd/branch/master?svg=true)](https://ci.appveyor.com/project/kbenoit/spacyr/branch/master) [![codecov.io](https://codecov.io/github/kbenoit/spacyr/coverage.svg?branch=master)](https://codecov.io/gh/kbenoit/spacyr/branch/master)

spacyr: an R wrapper for spaCy
==============================

This package is an R wrapper to the spaCy "industrial strength natural language processing" Python library from <http://spacy.io>.

Installing the package
----------------------

For the installation of `spaCy` and `spacyr` in Mac OS X (in homebrew and default Pythons) and Windows you can find more detailed instructions in [Mac OS X Installation](inst/docs/MAC.md) and [Windows Installation](inst/docs/WINDOWS.md).

1.  Python (&gt; 2.7 or 3) must be installed on your system.

    **(Windows only)** If you have not yet installed Python, Download and install [Python for Windows](https://www.python.org/downloads/windows/). We strongly recommend to use Python 3, and the following instructions is based on the use of Python 3. We recommend the latest 3.6.\* release (currently 3.6.1). During the installation process, be sure to scroll down in the installation option window and find the "Add Python.exe to Path", and click on the small red "x."

2.  A C++ compiler must be installed on your system.

    -   **(Mac only)** Install XTools. Either get the full XTools from the App Store, or install the command-line XTools using this command from the Terminal:

        ``` bash
        xcode-select --install
        ```

    -   **(Windows only)** Install the [Rtools](https://CRAN.R-project.org/bin/windows/Rtools/) software available from CRAN

        You will also need to install the [Visual Studio Express 2015](https://www.visualstudio.com/post-download-vs/?sku=xdesk&clcid=0x409&telem=ga#).

3.  You will need to install spaCy.

    Install spaCy and the English language model using these commands at the command line:

    ``` bash
    pip install -U spacy
    python -m spacy download en
    ```

    Test your installation at the command line using:

    ``` bash
    python -c "import spacy; spacy.load('en'); print('OK')"
    ```

    There are alternative methods of installing spaCy, especially if you have installed a different Python (e.g. through Anaconda). Full installation instructions are available from the [spaCy page](http://spacy.io/docs/).

4.  Installing the **spacyr** R package:

    To install the package from source, you can simply run the following.

    ``` r
    devtools::install_github("kbenoit/spacyr")
    ```

Examples
--------

When initializing spaCy, you need to set the python path if in your system, spaCy is installed in a Python which is not the system default. A detailed discussion about it is found in [Multiple Pythons](#multiplepythons) below.

``` r
require(spacyr)
#> Loading required package: spacyr
# start a python process and initialize spaCy in it.
# it takes several seconds for initialization.
# spacyr attempts to find python with spaCy
spacy_initialize()
#> Finding a python executable with spacy installed...
#> spaCy (language model: en) is installed in /usr/local/bin/python
#> successfully initialized (spaCy Version: 1.8.2, language model: en)
```

The `spacy_parse()` function calls spaCy to both tokenize and tag the texts. In addition, it provides a functionalities of dependency parsing and named entity recognition. The function returns a `data.table` of the results. The approach to tokenizing taken by spaCy is inclusive: it includes all tokens without restrictions. The default method for `tag()` is the [Google tagset for parts-of-speech](https://github.com/slavpetrov/universal-pos-tags).

``` r

txt <- c(d1 = "spaCy excels at large-scale information extraction tasks.",
         d2 = "Mr. Smith goes to North Carolina.")

# process documents and obtain a data.table
parsedtxt <- spacy_parse(txt)
parsedtxt
#>    doc_id sentence_id token_id       token       lemma   pos   entity
#> 1      d1           1        1       spaCy       spacy  NOUN         
#> 2      d1           1        2      excels       excel  VERB         
#> 3      d1           1        3          at          at   ADP         
#> 4      d1           1        4       large       large   ADJ         
#> 5      d1           1        5           -           - PUNCT         
#> 6      d1           1        6       scale       scale  NOUN         
#> 7      d1           1        7 information information  NOUN         
#> 8      d1           1        8  extraction  extraction  NOUN         
#> 9      d1           1        9       tasks        task  NOUN         
#> 10     d1           1       10           .           . PUNCT         
#> 11     d2           1        1         Mr.         mr. PROPN         
#> 12     d2           1        2       Smith       smith PROPN PERSON_B
#> 13     d2           1        3        goes          go  VERB         
#> 14     d2           1        4          to          to   ADP         
#> 15     d2           1        5       North       north PROPN    GPE_B
#> 16     d2           1        6    Carolina    carolina PROPN    GPE_I
#> 17     d2           1        7           .           . PUNCT
```

By default, `spacy_parse()` conduct tokenization and part-of-speech (POS) tagging. spacyr provides two tagsets, coarse-grained [Google](https://github.com/slavpetrov/universal-pos-tags) tagsets and finer-grained [Penn Treebank](https://www.ling.upenn.edu/courses/Fall_2003/ling001/penn_treebank_pos.html) tagsets. The `tag` option provides finer-grained part-of-speech tags:

``` r
spacy_parse(txt, tag = TRUE, entity = FALSE, lemma = FALSE)
#>    doc_id sentence_id token_id       token   pos  tag
#> 1      d1           1        1       spaCy  NOUN   NN
#> 2      d1           1        2      excels  VERB  VBZ
#> 3      d1           1        3          at   ADP   IN
#> 4      d1           1        4       large   ADJ   JJ
#> 5      d1           1        5           - PUNCT HYPH
#> 6      d1           1        6       scale  NOUN   NN
#> 7      d1           1        7 information  NOUN   NN
#> 8      d1           1        8  extraction  NOUN   NN
#> 9      d1           1        9       tasks  NOUN  NNS
#> 10     d1           1       10           . PUNCT    .
#> 11     d2           1        1         Mr. PROPN  NNP
#> 12     d2           1        2       Smith PROPN  NNP
#> 13     d2           1        3        goes  VERB  VBZ
#> 14     d2           1        4          to   ADP   IN
#> 15     d2           1        5       North PROPN  NNP
#> 16     d2           1        6    Carolina PROPN  NNP
#> 17     d2           1        7           . PUNCT    .
```

Many of the standard methods from [**quanteda**](http://githiub.com/kbenoit/quanteda) work on the new tagged token objects:

``` r
require(quanteda, warn.conflicts = FALSE, quietly = TRUE)
#> quanteda version 0.9.9.58
#> Using 7 of 8 cores for parallel computing
docnames(parsedtxt)
#> [1] "d1" "d2"
ndoc(parsedtxt)
#> [1] 2
ntoken(parsedtxt)
#> d1 d2 
#> 10  7
ntype(parsedtxt)
#> d1 d2 
#> 10  7
```

### Extracting entities

**spacyr** can extract entities:

``` r
entity_extract(parsedtxt)
#>   doc_id sentence_id         entity entity_type
#> 1     d2           1          Smith      PERSON
#> 2     d2           1 North Carolina         GPE
```

Or, convert multi-word named entities into single "tokens":

``` r
entity_consolidate(parsedtxt)
#>    doc_id sentence_id token_id          token          lemma    pos
#> 1      d1           1        1          spaCy          spacy   NOUN
#> 2      d1           1        2         excels          excel   VERB
#> 3      d1           1        3             at             at    ADP
#> 4      d1           1        4          large          large    ADJ
#> 5      d1           1        5              -              -  PUNCT
#> 6      d1           1        6          scale          scale   NOUN
#> 7      d1           1        7    information    information   NOUN
#> 8      d1           1        8     extraction     extraction   NOUN
#> 9      d1           1        9          tasks           task   NOUN
#> 10     d1           1       10              .              .  PUNCT
#> 11     d2           1        1            Mr.            mr.  PROPN
#> 12     d2           1        2          Smith          smith ENTITY
#> 13     d2           1        3           goes             go   VERB
#> 14     d2           1        4             to             to    ADP
#> 15     d2           1        5 North_Carolina north_carolina ENTITY
#> 16     d2           1        6              .              .  PUNCT
#>    entity_type
#> 1             
#> 2             
#> 3             
#> 4             
#> 5             
#> 6             
#> 7             
#> 8             
#> 9             
#> 10            
#> 11            
#> 12      PERSON
#> 13            
#> 14            
#> 15         GPE
#> 16
```

### Dependency parsing

It is possible to conduct more detailed parsing of syntactic dependencies:

``` r
results_detailed <- spacy_parse(txt, dependency = TRUE)
head(results_detailed, 30)
#>    doc_id sentence_id token_id       token       lemma   pos head_token_id
#> 1      d1           1        1       spaCy       spacy  NOUN             2
#> 2      d1           1        2      excels       excel  VERB             2
#> 3      d1           1        3          at          at   ADP             2
#> 4      d1           1        4       large       large   ADJ             6
#> 5      d1           1        5           -           - PUNCT             6
#> 6      d1           1        6       scale       scale  NOUN             7
#> 7      d1           1        7 information information  NOUN             9
#> 8      d1           1        8  extraction  extraction  NOUN             9
#> 9      d1           1        9       tasks        task  NOUN             3
#> 10     d1           1       10           .           . PUNCT             2
#> 11     d2           1        1         Mr.         mr. PROPN             2
#> 12     d2           1        2       Smith       smith PROPN             3
#> 13     d2           1        3        goes          go  VERB             3
#> 14     d2           1        4          to          to   ADP             3
#> 15     d2           1        5       North       north PROPN             6
#> 16     d2           1        6    Carolina    carolina PROPN             4
#> 17     d2           1        7           .           . PUNCT             3
#>     dep_rel   entity
#> 1     nsubj         
#> 2      ROOT         
#> 3      prep         
#> 4      amod         
#> 5     punct         
#> 6  compound         
#> 7  compound         
#> 8  compound         
#> 9      pobj         
#> 10    punct         
#> 11 compound         
#> 12    nsubj PERSON_B
#> 13     ROOT         
#> 14     prep         
#> 15 compound    GPE_B
#> 16     pobj    GPE_I
#> 17    punct
```

### Using other language models

In default, `spacyr` load an English language model in spacy, but you also can load a German language model instead by specifying `model` option when `spacy_initialize` is called.

``` r
## first finalize the spacy if it's loaded
spacy_finalize()
spacy_initialize(model = "de")
#> Python space is already attached.  If you want to swtich to a different Python, please restart R.
#> successfully initialized (spaCy Version: 1.8.2, language model: de)

txt_german <- c(R = "R ist eine freie Programmiersprache für statistische Berechnungen und Grafiken. Sie wurde von Statistikern für Anwender mit statistischen Aufgaben entwickelt.",
               python = "Python ist eine universelle, üblicherweise interpretierte höhere Programmiersprache. Sie will einen gut lesbaren, knappen Programmierstil fördern.")
results_german <- spacy_parse(txt_german, dependency = TRUE, tag = TRUE)
results_german
#>    doc_id sentence_id token_id              token              lemma   pos
#> 1       R           1        1                  R                  r     X
#> 2       R           1        2                ist                ist   AUX
#> 3       R           1        3               eine               eine   DET
#> 4       R           1        4              freie              freie   ADJ
#> 5       R           1        5 Programmiersprache programmiersprache  NOUN
#> 6       R           1        6                 fr                 fr PROPN
#> 7       R           1        7       statistische       statistische   ADJ
#> 8       R           1        8       Berechnungen       berechnungen  NOUN
#> 9       R           1        9                und                und  CONJ
#> 10      R           1       10           Grafiken           grafiken  NOUN
#> 11      R           1       11                  .                  . PUNCT
#> 12      R           2        1                Sie                sie  PRON
#> 13      R           2        2              wurde              wurde   AUX
#> 14      R           2        3                von                von   ADP
#> 15      R           2        4       Statistikern       statistikern  NOUN
#> 16      R           2        5                 fr                 fr PROPN
#> 17      R           2        6           Anwender           anwender  NOUN
#> 18      R           2        7                mit                mit   ADP
#> 19      R           2        8      statistischen      statistischen   ADJ
#> 20      R           2        9           Aufgaben           aufgaben  NOUN
#> 21      R           2       10         entwickelt         entwickelt  VERB
#> 22      R           2       11                  .                  . PUNCT
#> 23 python           1        1             Python             python PROPN
#> 24 python           1        2                ist                ist   AUX
#> 25 python           1        3               eine               eine   DET
#> 26 python           1        4        universelle        universelle   ADJ
#> 27 python           1        5                  ,                  , PUNCT
#> 28 python           1        6       blicherweise       blicherweise   ADV
#> 29 python           1        7     interpretierte     interpretierte   ADJ
#> 30 python           1        8              hhere              hhere   ADJ
#> 31 python           1        9 Programmiersprache programmiersprache  NOUN
#> 32 python           1       10                  .                  . PUNCT
#> 33 python           2        1                Sie                sie  PRON
#> 34 python           2        2               will               will  VERB
#> 35 python           2        3              einen              einen   DET
#> 36 python           2        4                gut                gut   ADJ
#> 37 python           2        5           lesbaren           lesbaren   ADJ
#> 38 python           2        6                  ,                  , PUNCT
#> 39 python           2        7            knappen            knappen   ADJ
#> 40 python           2        8    Programmierstil    programmierstil  NOUN
#> 41 python           2        9             frdern             frdern  VERB
#> 42 python           2       10                  .                  . PUNCT
#>      tag head_token_id dep_rel   entity
#> 1     XY             2      sb         
#> 2  VAFIN             2    ROOT         
#> 3    ART             5      nk         
#> 4   ADJA             5      nk         
#> 5     NN             2      pd         
#> 6     NE             5      nk         
#> 7   ADJA             8      nk         
#> 8     NN             2      pd         
#> 9    KON             8      cd         
#> 10    NN             9      cj         
#> 11    $.             2   punct         
#> 12  PPER             2      sb         
#> 13 VAFIN             2    ROOT         
#> 14  APPR             6      pg         
#> 15    NN             3      nk         
#> 16    NE             6      nk         
#> 17    NN            10      oa         
#> 18  APPR            10      mo         
#> 19  ADJA             9      nk         
#> 20    NN             7      nk         
#> 21  VVPP             2      oc         
#> 22    $.             2   punct         
#> 23    NE             2      sb PERSON_B
#> 24 VAFIN             2    ROOT         
#> 25   ART             9      nk         
#> 26  ADJA             9      nk         
#> 27    $,             4   punct         
#> 28   ADV             7      mo         
#> 29  ADJA             4      cj         
#> 30  ADJA             4  cj||cj         
#> 31    NN             2      pd         
#> 32    $.             2   punct         
#> 33  PPER             2      sb         
#> 34 VMFIN             2    ROOT         
#> 35   ART             8      nk         
#> 36  ADJD             5      mo         
#> 37  ADJA             8      nk         
#> 38    $,             5   punct         
#> 39  ADJA             5      cj         
#> 40    NN             9      oa         
#> 41 VVINF             2      oc         
#> 42    $.             2   punct
```

The German language model has to be installed (`python -m spacy download de`) before you call `spacy_initialize`.

### When you finish

A background process of spaCy is initiated when you ran `spacy_initialize`. Because of the size of language models of `spaCy`, this takes up a lot of memory (typically 1.5GB). When you do not need the python connection any longer, you can finalize the python (and terminate terminate the process) by running `spacy_finalize()` function.

``` r
spacy_finalize()
```

By calling `spacy_initialize()` again, you can restart the backend spaCy.

<a name="multiplepythons"></a>Multiple Python executables in your system
------------------------------------------------------------------------

If you have multiple Python executables in your systems (e.g. you, a Mac user, have brewed python2 or python3), `spacy_initialize` function will check whether each of them have spaCy installed or not. To save the time for this checking, you can specify the particular python when initializing `spaCy` by executing `spacy_initialize()`. Suppose that your python with spaCy is `/usr/local/bin/python`, run the following:

``` r
library(spacyr)
spacy_initialize(use_python = "/usr/local/bin/python")
```

Comments and feedback
---------------------

We welcome your comments and feedback. Please file issues on the [issues](https://github.com/kbenoit/spacyr/issues) page, and/or send us comments at <kbenoit@lse.ac.uk> and <A.Matsuo@lse.ac.uk>.
