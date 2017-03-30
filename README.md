[![CRAN Version](http://www.r-pkg.org/badges/version/spacyr)](http://cran.r-project.org/package=spacyr) ![Downloads](http://cranlogs.r-pkg.org/badges/spacyr) [![Travis-CI Build Status](https://travis-ci.org/kbenoit/spacyr.svg?branch=master)](https://travis-ci.org/kbenoit/spacyr) [![Appveyor Build status](https://ci.appveyor.com/api/projects/status/jqt2atp1wqtxy5xd/branch/master?svg=true)](https://ci.appveyor.com/project/kbenoit/spacyr/branch/master) [![codecov.io](https://codecov.io/github/kbenoit/spacyr/spacyr.svg?branch=master)](https://codecov.io/github/kbenoit/spacyr/coverage.svg?branch=master)

spacyr: an R wrapper for spaCy
==============================

This package is an R wrapper to the spaCy "industrial strength natural language processing" Python library from <http://spacy.io>.

### Prerequisites

1.  Python (&gt; 2.7 or 3) must be installed on your system.

    **(Windows only)** If you have not yet installed Python, Download and install [Python for Windows](https://www.python.org/downloads/windows/). We recommend the latest 2.7.x release (currently 2.7.13). During the installation process, be sure to scroll down in the installation option window and find the "Add Python.exe to Path", and click on the small red "x."

2.  A C++ compiler must be installed on your system.

    -   **(Mac only)** Install XTools. Either get the full XTools from the App Store, or install the command-line XTools using this command from the Terminal:

        ``` bash
        xcode-select --install
        ```

    -   **(Windows only)** Install the [Rtools](https://CRAN.R-project.org/bin/windows/Rtools/) software available from CRAN

        You will also need to install the [Microsoft Visual C++ Compiler for Python 2.7](http://aka.ms/vcpython27).

        In addition to have `spaCy` on your system, you need to have `libpython` package installed in your Python. If `libpython` is available for `pip` install for your version of Python, you can just type:

        ``` bash
        pip install libpython
        ```

        or for conda Python:

        ``` bash
        conda install -c anaconda libpython=2.0
        ```

3.  You will need to install spaCy. (More [instructions](http://spacy.io/docs/) are here.)

    Install spaCy and the English language model using these commands at the command line:

    ``` bash
    pip install -U spacy
    python -m spacy download en
    ```

4.  Test your installation at the command line using:

    ``` bash
    python -c "import spacy; spacy.load('en'); print('OK')"
    ```

5.  Installing the **spacyr** R package:

    This needs an environment variable set to the location of your Python executable, and then you need to install the package from source. Note that depending on your operating system and Python installation, the first command might be slightly different.

    ``` r
    Sys.setenv(SPACY_PYTHON="/usr/local/bin/python")
    devtools::install_github("kbenoit/spacyr")
    ```

If these steps do not work, see [Installation Problems](#installproblems) below.

Examples
--------

The `spacy_parse()` function calls spaCy to both tokenize and tag the texts. In addition, it provides a functionalities of dependency parsing and named entity recognition. The function returns a `data.table` of the results. The approach to tokenizing taken by spaCy is inclusive: it includes all tokens without restrictions. The default method for `tag()` is the [Google tagset for parts-of-speech](https://github.com/slavpetrov/universal-pos-tags).

``` r
require(spacyr)
#> Loading required package: spacyr
# start a python process and initialize spaCy in it.
# it takes several seconds for initialization.
spacy_initialize()

txt <- c(fastest = "spaCy excells at large-scale information extraction tasks. It is written from the ground up in carefully memory-managed Cython. Independent research has confirmed that spaCy is the fastest in the world. If your application needs to process entire web dumps, spaCy is the library you want to be using.",
         getdone = "spaCy is designed to help you do real work — to build real products, or gather real insights. The library respects your time, and tries to avoid wasting it. It is easy to install, and its API is simple and productive. I like to think of spaCy as the Ruby on Rails of Natural Language Processing.")

# process documents and obtain a data.table
parsedtxt <- spacy_parse(txt)
head(parsedtxt)
#>    docname id  tokens google penn
#> 1: fastest  0   spaCy   NOUN   NN
#> 2: fastest  1 excells   NOUN  NNS
#> 3: fastest  2      at    ADP   IN
#> 4: fastest  3   large    ADJ   JJ
#> 5: fastest  4       -  PUNCT HYPH
#> 6: fastest  5   scale   NOUN   NN
```

By default, `spacy_parse()` conduct tokenization and part-of-speech (POS) tagging. spacyr provides two tagsets, coarse-grained [Google](https://github.com/slavpetrov/universal-pos-tags) tagsets and finer-grained [Penn Treebank](https://www.ling.upenn.edu/courses/Fall_2003/ling001/penn_treebank_pos.html) tagsets. The `google` or `penn` field in the data.table corresponds to each of these tagsets.

Many of the standard methods from [**quanteda**](http://githiub.com/kbenoit/quanteda) work on the new tagged token objects:

``` r
require(quanteda, warn.conflicts = FALSE, quietly = TRUE)
#> quanteda version 0.9.9.42
#> Using 7 of 8 cores for parallel computing
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
                                named_entity = TRUE,
                                dependency = TRUE)
head(results_detailed, 30)
#>     docname id      tokens google penn head_id   dep_rel named_entity
#>  1: fastest  0       spaCy   NOUN   NN       1  compound    PRODUCT_B
#>  2: fastest  1     excells   NOUN  NNS       1      ROOT             
#>  3: fastest  2          at    ADP   IN       1      prep             
#>  4: fastest  3       large    ADJ   JJ       5      amod             
#>  5: fastest  4           -  PUNCT HYPH       5     punct             
#>  6: fastest  5       scale   NOUN   NN       8  compound             
#>  7: fastest  6 information   NOUN   NN       7  compound             
#>  8: fastest  7  extraction   NOUN   NN       8  compound             
#>  9: fastest  8       tasks   NOUN  NNS       2      pobj             
#> 10: fastest  9           .  PUNCT    .       1     punct             
#> 11: fastest 10          It   PRON  PRP      12 nsubjpass             
#> 12: fastest 11          is   VERB  VBZ      12   auxpass             
#> 13: fastest 12     written   VERB  VBN      12      ROOT             
#> 14: fastest 13        from    ADP   IN      12      prep             
#> 15: fastest 14         the    DET   DT      15       det             
#> 16: fastest 15      ground   NOUN   NN      13      pobj             
#> 17: fastest 16          up    ADV   RB      12    advmod             
#> 18: fastest 17          in    ADP   IN      12      prep             
#> 19: fastest 18   carefully    ADV   RB      21    advmod             
#> 20: fastest 19      memory   NOUN   NN      21  npadvmod             
#> 21: fastest 20           -  PUNCT HYPH      21     punct             
#> 22: fastest 21     managed   VERB  VBN      12      conj             
#> 23: fastest 22      Cython  PROPN  NNP      21      dobj        ORG_B
#> 24: fastest 23           .  PUNCT    .      12     punct             
#> 25: fastest 24 Independent    ADJ   JJ      25      amod             
#> 26: fastest 25    research   NOUN   NN      27     nsubj             
#> 27: fastest 26         has   VERB  VBZ      27       aux             
#> 28: fastest 27   confirmed   VERB  VBN      27      ROOT             
#> 29: fastest 28        that    ADP   IN      30      mark             
#> 30: fastest 29       spaCy  PROPN  NNP      30     nsubj    PRODUCT_B
#>     docname id      tokens google penn head_id   dep_rel named_entity
```

### Use German language model

In default, `spacyr` load an English language model in spacy, but you also can load a German language model instead by specifying `lang` option when `spacy_initialize` is called.

``` r
spacy_initialize(lang = 'de')

txt_german = c(R = "R ist eine freie Programmiersprache für statistische Berechnungen und Grafiken. Sie wurde von Statistikern für Anwender mit statistischen Aufgaben entwickelt. Die Syntax orientiert sich an der Programmiersprache S, mit der R weitgehend kompatibel ist, und die Semantik an Scheme. Als Standarddistribution kommt R mit einem Interpreter als Kommandozeilenumgebung mit rudimentären grafischen Schaltflächen. So ist R auf vielen Plattformen verfügbar; die Umgebung wird von den Entwicklern ausdrücklich ebenfalls als R bezeichnet. R ist Teil des GNU-Projekts.",
               python = "Python ist eine universelle, üblicherweise interpretierte höhere Programmiersprache. Sie will einen gut lesbaren, knappen Programmierstil fördern. So wird beispielsweise der Code nicht durch geschweifte Klammern, sondern durch Einrückungen strukturiert.")
results_german <- spacy_parse(txt_german,
                                pos_tag = TRUE,
                                named_entity = TRUE,
                                dependency = TRUE)
head(results_german, 30)
#>     docname id             tokens google penn head_id  dep_rel
#>  1:       R  0                  R   NOUN   NN       2 compound
#>  2:       R  1                ist   NOUN   NN       2 compound
#>  3:       R  2               eine   NOUN   NN       3    nsubj
#>  4:       R  3              freie   VERB  VBZ       3     ROOT
#>  5:       R  4 Programmiersprache  PROPN  NNP       5     amod
#>  6:       R  5                für      X   FW       7     nmod
#>  7:       R  6       statistische      X   FW       7     nmod
#>  8:       R  7       Berechnungen  PROPN  NNP       9 compound
#>  9:       R  8                und    ADV   RB       9 compound
#> 10:       R  9           Grafiken  PROPN  NNP       3     dobj
#> 11:       R 10                  .  PUNCT    .       3    punct
#> 12:       R 11                Sie  PROPN  NNP      12    nsubj
#> 13:       R 12              wurde   VERB  VBD      12     ROOT
#> 14:       R 13                von  PROPN  NNP      14 compound
#> 15:       R 14       Statistikern  PROPN  NNP      17 compound
#> 16:       R 15                für   NOUN   NN      17 compound
#> 17:       R 16           Anwender  PROPN  NNP      17 compound
#> 18:       R 17                mit   NOUN   NN      12     dobj
#> 19:       R 18      statistischen   NOUN   NN      20 compound
#> 20:       R 19           Aufgaben  PROPN  NNP      20 compound
#> 21:       R 20         entwickelt   NOUN   NN      17    appos
#> 22:       R 21                  .  PUNCT    .      12    punct
#> 23:       R 22                Die   VERB   VB      25 npadvmod
#> 24:       R 23             Syntax  PROPN  NNP      24 compound
#> 25:       R 24         orientiert   NOUN   NN      25    nsubj
#> 26:       R 25               sich   VERB  VBZ      25     ROOT
#> 27:       R 26                 an    DET   DT      27      det
#> 28:       R 27                der   NOUN   NN      29 compound
#> 29:       R 28 Programmiersprache  PROPN  NNP      29 compound
#> 30:       R 29                  S  PROPN  NNP      25    nsubj
#>     docname id             tokens google penn head_id  dep_rel
#>      named_entity
#>  1:              
#>  2:              
#>  3:              
#>  4:              
#>  5: WORK_OF_ART_B
#>  6:              
#>  7:              
#>  8:              
#>  9:              
#> 10:              
#> 11:              
#> 12:      PERSON_B
#> 13:              
#> 14:      PERSON_B
#> 15:      PERSON_I
#> 16:              
#> 17:              
#> 18:              
#> 19:              
#> 20:         ORG_B
#> 21:              
#> 22:              
#> 23:              
#> 24:              
#> 25:              
#> 26:              
#> 27:              
#> 28:              
#> 29:     PRODUCT_B
#> 30:     PRODUCT_I
#>      named_entity
```

The German language model has to be installed (`python -m spacy.en.download all`) before you call `spacy_initialize`.

### When you finish

A background process of python is initiated when you ran `spacy_initialize`. Because of the size of English language module of `spaCy`, this takes up a lot of memory (typically 1.5GB). When you do not need the python connection any longer, you can finalize the python (and terminate terminate the process) by running `spacy_finalize()` function.

``` r
spacy_finalize()
```

<a name="installproblems"></a>Installation Problems
---------------------------------------------------

### macOS using Homebrew (or other) versions of Python

If you installed a Python other than the system default and installed spaCy on that Python, then you will need to set the path to the Python executable with spaCy and build `spacyr`. In order to check whether this could be an issue, check the versions of Pythons in Terminal and R.

Open a Terminal window, and type

    $ python --version; which python

and in R, enter following

``` r
system('python --version; which python')
```

If the outputs are different, loading spaCy is likely to fail as the python executable the `spacyr` calls is different from the version of python spaCy is intalled.

To resolve the issue, you can alter an environmental variable and then reinstall `spacyr`. Suppose that your python with spaCy is `/usr/local/bin/python`, run the following:

``` r
Sys.setenv(SPACY_PYTHON="/usr/local/bin/python")
devtools::install_github("kbenoit/spacyr")
```

### Multiple Python executables in your system

If you have multiple python executables in your system, you should be able to specify the Python path using the same method described above, which is to set an enviromental variable `SPACY_PYTHON`. Example:

``` r
Sys.setenv(SPACY_PYTHON = "C:/Users/***/Anaconda2/python.exe")
devtools::install_github("kbenoit/spacyr")
```

Comments and feedback
---------------------

We welcome your comments and feedback. Please file issues on the [issues](https://github.com/kbenoit/spacyr/issues) page, and/or send us comments at <kbenoit@lse.ac.uk> and <A.Matsuo@lse.ac.uk>.
