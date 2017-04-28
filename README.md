[![CRAN Version](https://www.r-pkg.org/badges/version/spacyr)](https://CRAN.R-project.org/package=spacyr) ![Downloads](https://cranlogs.r-pkg.org/badges/spacyr) [![Travis-CI Build Status](https://travis-ci.org/kbenoit/spacyr.svg?branch=master)](https://travis-ci.org/kbenoit/spacyr) [![Appveyor Build status](https://ci.appveyor.com/api/projects/status/jqt2atp1wqtxy5xd/branch/master?svg=true)](https://ci.appveyor.com/project/kbenoit/spacyr/branch/master) [![codecov.io](https://codecov.io/github/kbenoit/spacyr/spacyr.svg?branch=master)](https://codecov.io/github/kbenoit/spacyr/coverage.svg?branch=master)

spacyr: an R wrapper for spaCy
==============================

This package is an R wrapper to the spaCy "industrial strength natural language processing" Python library from <http://spacy.io>.

Installing the package
----------------------

For the installation of `spaCy` and `spacyr` in Mac OS X (in homebrew and default Pythons) and Windows you can find more detailed instructions in [Mac OS X Installation](inst/docs/MAC.md) and [Windows Installation](inst/docs/WINDOWS.md).

1.  Python (&gt; 2.7 or 3) must be installed on your system.

    **(Windows only)** If you have not yet installed Python, Download and install [Python for Windows](https://www.python.org/downloads/windows/). We strongly recommend to use Python 3, and the following instructions is based on the use of Python 3.

    We recommend the latest 3.6.\* release (currently 3.6.1). During the installation process, be sure to scroll down in the installation option window and find the "Add Python.exe to Path", and click on the small red "x."

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
# you may have to set the path to the python with spaCy 
# in this example spaCy is installed in the python 
# in "/usr/local/bin/python"
spacy_initialize(use_python = "/usr/local/bin/python")
#> spacy is successfully initialized
```

The `spacy_parse()` function calls spaCy to both tokenize and tag the texts. In addition, it provides a functionalities of dependency parsing and named entity recognition. The function returns a `data.table` of the results. The approach to tokenizing taken by spaCy is inclusive: it includes all tokens without restrictions. The default method for `tag()` is the [Google tagset for parts-of-speech](https://github.com/slavpetrov/universal-pos-tags).

``` r

txt <- c(fastest = "spaCy excells at large-scale information extraction tasks. It is written from the ground up in carefully memory-managed Cython. Independent research has confirmed that spaCy is the fastest in the world. If your application needs to process entire web dumps, spaCy is the library you want to be using.",
         getdone = "spaCy is designed to help you do real work — to build real products, or gather real insights. The library respects your time, and tries to avoid wasting it. It is easy to install, and its API is simple and productive. I like to think of spaCy as the Ruby on Rails of Natural Language Processing.")

# process documents and obtain a data.table
parsedtxt <- spacy_parse(txt)
head(parsedtxt)
#>    docname sentence_id token_id  tokens tag_detailed tag_google
#> 1: fastest           1        1   spaCy           NN       NOUN
#> 2: fastest           1        2 excells          NNS       NOUN
#> 3: fastest           1        3      at           IN        ADP
#> 4: fastest           1        4   large           JJ        ADJ
#> 5: fastest           1        5       -         HYPH      PUNCT
#> 6: fastest           1        6   scale           NN       NOUN
```

By default, `spacy_parse()` conduct tokenization and part-of-speech (POS) tagging. spacyr provides two tagsets, coarse-grained [Google](https://github.com/slavpetrov/universal-pos-tags) tagsets and finer-grained [Penn Treebank](https://www.ling.upenn.edu/courses/Fall_2003/ling001/penn_treebank_pos.html) tagsets. The `tag_google` or `tag_detailed` field in the data.table corresponds to each of these tagsets.

Many of the standard methods from [**quanteda**](http://githiub.com/kbenoit/quanteda) work on the new tagged token objects:

``` r
require(quanteda, warn.conflicts = FALSE, quietly = TRUE)
#> quanteda version 0.9.9.50
#> Using 3 of 4 cores for parallel computing
docnames(parsedtxt)
#> [1] "fastest" "getdone"
ndoc(parsedtxt)
#> [1] 2
ntoken(parsedtxt)
#> fastest getdone 
#>      57      63
ntype(parsedtxt)
#> fastest getdone 
#>      44      46
```

### Document processing with addiitonal features

The following codes conduct more detailed document processing, including dependency parsing and named entitiy recognition.

``` r
results_detailed <- spacy_parse(txt,
                                pos_tag = TRUE,
                                lemma = TRUE,
                                named_entity = TRUE,
                                dependency = TRUE)
head(results_detailed, 30)
#>     docname sentence_id token_id      tokens       lemma tag_detailed
#>  1: fastest           1        1       spaCy       spacy           NN
#>  2: fastest           1        2     excells      excell          NNS
#>  3: fastest           1        3          at          at           IN
#>  4: fastest           1        4       large       large           JJ
#>  5: fastest           1        5           -           -         HYPH
#>  6: fastest           1        6       scale       scale           NN
#>  7: fastest           1        7 information information           NN
#>  8: fastest           1        8  extraction  extraction           NN
#>  9: fastest           1        9       tasks        task          NNS
#> 10: fastest           1       10           .           .            .
#> 11: fastest           2       11          It      -PRON-          PRP
#> 12: fastest           2       12          is          be          VBZ
#> 13: fastest           2       13     written       write          VBN
#> 14: fastest           2       14        from        from           IN
#> 15: fastest           2       15         the         the           DT
#> 16: fastest           2       16      ground      ground           NN
#> 17: fastest           2       17          up          up           RB
#> 18: fastest           2       18          in          in           IN
#> 19: fastest           2       19   carefully   carefully           RB
#> 20: fastest           2       20      memory      memory           NN
#> 21: fastest           2       21           -           -         HYPH
#> 22: fastest           2       22     managed      manage          VBN
#> 23: fastest           2       23      Cython      cython          NNP
#> 24: fastest           2       24           .           .            .
#> 25: fastest           3       25 Independent independent           JJ
#> 26: fastest           3       26    research    research           NN
#> 27: fastest           3       27         has        have          VBZ
#> 28: fastest           3       28   confirmed     confirm          VBN
#> 29: fastest           3       29        that        that           IN
#> 30: fastest           3       30       spaCy       spacy          NNP
#>     docname sentence_id token_id      tokens       lemma tag_detailed
#>     tag_google head_token_id   dep_rel named_entity
#>  1:       NOUN             2  compound             
#>  2:       NOUN             2      ROOT             
#>  3:        ADP             2      prep             
#>  4:        ADJ             6      amod             
#>  5:      PUNCT             6     punct             
#>  6:       NOUN             7  compound             
#>  7:       NOUN             8  compound             
#>  8:       NOUN             9  compound             
#>  9:       NOUN             3      pobj             
#> 10:      PUNCT             2     punct             
#> 11:       PRON            13 nsubjpass             
#> 12:       VERB            13   auxpass             
#> 13:       VERB            13      ROOT             
#> 14:        ADP            13      prep             
#> 15:        DET            16       det             
#> 16:       NOUN            14      pobj             
#> 17:        ADV            13       prt             
#> 18:        ADP            17      prep             
#> 19:        ADV            22    advmod             
#> 20:       NOUN            22  npadvmod             
#> 21:      PUNCT            22     punct             
#> 22:       VERB            13      prep             
#> 23:      PROPN            22      dobj        ORG_B
#> 24:      PUNCT            13     punct             
#> 25:        ADJ            26      amod             
#> 26:       NOUN            28     nsubj             
#> 27:       VERB            28       aux             
#> 28:       VERB            28      ROOT             
#> 29:        ADP            31      mark             
#> 30:      PROPN            31     nsubj             
#>     tag_google head_token_id   dep_rel named_entity
```

### Use German language model

In default, `spacyr` load an English language model in spacy, but you also can load a German language model instead by specifying `lang` option when `spacy_initialize` is called.

``` r
spacy_initialize(lang = 'de')
#> spacy is already initialized
#> NULL

txt_german = c(R = "R ist eine freie Programmiersprache für statistische Berechnungen und Grafiken. Sie wurde von Statistikern für Anwender mit statistischen Aufgaben entwickelt. Die Syntax orientiert sich an der Programmiersprache S, mit der R weitgehend kompatibel ist, und die Semantik an Scheme. Als Standarddistribution kommt R mit einem Interpreter als Kommandozeilenumgebung mit rudimentären grafischen Schaltflächen. So ist R auf vielen Plattformen verfügbar; die Umgebung wird von den Entwicklern ausdrücklich ebenfalls als R bezeichnet. R ist Teil des GNU-Projekts.",
               python = "Python ist eine universelle, üblicherweise interpretierte höhere Programmiersprache. Sie will einen gut lesbaren, knappen Programmierstil fördern. So wird beispielsweise der Code nicht durch geschweifte Klammern, sondern durch Einrückungen strukturiert.")
results_german <- spacy_parse(txt_german,
                              pos_tag = TRUE,
                              lemma = TRUE,
                              named_entity = TRUE,
                              dependency = TRUE)
head(results_german, 30)
#>     docname sentence_id token_id             tokens              lemma
#>  1:       R           1        1                  R                  r
#>  2:       R           1        2                ist                ist
#>  3:       R           1        3               eine               eine
#>  4:       R           1        4              freie              freie
#>  5:       R           1        5 Programmiersprache programmiersprache
#>  6:       R           1        6                 fr                 fr
#>  7:       R           1        7       statistische       statistische
#>  8:       R           1        8       Berechnungen       berechnungen
#>  9:       R           1        9                und                und
#> 10:       R           1       10           Grafiken           grafiken
#> 11:       R           1       11                  .                  .
#> 12:       R           2       12                Sie                sie
#> 13:       R           2       13              wurde              wurde
#> 14:       R           2       14                von                von
#> 15:       R           2       15       Statistikern       statistikern
#> 16:       R           2       16                 fr                 fr
#> 17:       R           2       17           Anwender           anwender
#> 18:       R           2       18                mit                mit
#> 19:       R           2       19      statistischen      statistischen
#> 20:       R           2       20           Aufgaben           aufgaben
#> 21:       R           2       21         entwickelt         entwickelt
#> 22:       R           2       22                  .                  .
#> 23:       R           3       23                Die                die
#> 24:       R           3       24             Syntax             syntax
#> 25:       R           3       25         orientiert         orientiert
#> 26:       R           3       26               sich               sich
#> 27:       R           3       27                 an                 an
#> 28:       R           3       28                der                der
#> 29:       R           3       29 Programmiersprache programmiersprache
#> 30:       R           3       30                  S                  s
#>     docname sentence_id token_id             tokens              lemma
#>     tag_detailed tag_google head_token_id  dep_rel named_entity
#>  1:           NN       NOUN             4 compound             
#>  2:           NN       NOUN             3 compound             
#>  3:           NN       NOUN             4 compound             
#>  4:           NN       NOUN             8 compound             
#>  5:          NNP      PROPN             7 compound     PERSON_B
#>  6:          NNP      PROPN             7 compound     PERSON_I
#>  7:           NN       NOUN             8 compound             
#>  8:          NNP      PROPN            10 compound        ORG_B
#>  9:          VBD       VERB            10 compound             
#> 10:          NNP      PROPN            10     ROOT     PERSON_B
#> 11:            .      PUNCT            10    punct             
#> 12:          NNP      PROPN            13    nsubj     PERSON_B
#> 13:          VBD       VERB            13     ROOT             
#> 14:          NNP      PROPN            15 compound             
#> 15:          NNP      PROPN            21 compound             
#> 16:           IN        ADP            17 compound             
#> 17:          NNP      PROPN            21 compound             
#> 18:           NN       NOUN            19 compound             
#> 19:           NN       NOUN            21 compound             
#> 20:          NNP      PROPN            21 compound        ORG_B
#> 21:           NN       NOUN            13     dobj             
#> 22:            .      PUNCT            13    punct             
#> 23:           VB       VERB            40    advcl             
#> 24:          NNP      PROPN            25 compound             
#> 25:           NN       NOUN            26 compound             
#> 26:          VBZ       VERB            23     dobj             
#> 27:           DT        DET            28      det             
#> 28:           NN       NOUN            26    appos             
#> 29:          NNP      PROPN            30 compound        GPE_B
#> 30:          NNP      PROPN            28    appos        GPE_I
#>     tag_detailed tag_google head_token_id  dep_rel named_entity
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

If you have multiple Python executables in your systems (e.g. you, a Mac user, have brewed python2 or python3), then you will need to set the path to the Python executable with spaCy before you load spacy. In order to check whether this could be an issue, check the versions of Pythons in Terminal and R.

Open a Terminal window, and type

    $ python --version; which python

and in R, enter following

``` r
system('python --version; which python')
```

If the outputs are different, loading spaCy is likely to fail as the python executable the `spacyr` calls is different from the version of python spaCy is intalled.

To resolve the issue, you can alter an environmental variable when initializing `spaCy` by executing `spacy_initialize()`. Suppose that your python with spaCy is `/usr/local/bin/python`, run the following:

``` r
library(spacyr)
spacy_initialize(use_python = "/usr/local/bin/python")
```

If you've failed to set the python path when calling `spacy_initialize()`, you will get an error message like this:

    > library(spacyr)
    > spacy_initialize()
     Show Traceback
     
     Rerun with Debug
     Error in py_run_file_impl(file, convert) : 
      ImportError: No module named spacy

    Detailed traceback: 
      File "<string>", line 9, in <module> 

If this happened, please **restart R** and follow the appropriate steps to initialize spaCy. You cannot retry `spacy_initialize()` to resolve the issue because in the first try, the backend Python is started by R (in our package, we use [`reticulate`](https://github.com/rstudio/reticulate) to connect to Python), and you cannot switch to other Python executables.

### Step-by-step instructions for Windows users

Installation of `spaCy` and `spacyr` has not always been successful in our test environment (Windows 10 virtual machine on Parallels 10). Followings steps discribed in an issue comment are most likely to succeed in our experience:

<https://github.com/kbenoit/spacyr/issues/19#issuecomment-296362599>

Comments and feedback
---------------------

We welcome your comments and feedback. Please file issues on the [issues](https://github.com/kbenoit/spacyr/issues) page, and/or send us comments at <kbenoit@lse.ac.uk> and <A.Matsuo@lse.ac.uk>.
