


[![CRAN Version](http://www.r-pkg.org/badges/version/spacyr)](http://cran.r-project.org/package=spacyr) ![Downloads](http://cranlogs.r-pkg.org/badges/spacyr) [![Travis-CI Build Status](https://travis-ci.org/kbenoit/spacyr.svg?branch=master)](https://travis-ci.org/kbenoit/spacyr) [![codecov.io](https://codecov.io/github/kbenoit/spacyr/spacyr.svg?branch=master)](https://codecov.io/github/kbenoit/spacyr/coverage.svg?branch=master)


# spacyr: an R wrapper for spaCy

This package is an R wrapper to the spaCy "industrial strength natural language processing" Python library from http://spacy.io.

### Prerequisites

1.  Python (> 2.7 or 3) must be installed on your system.  

2.  spaCy must be installed on your system.  Follow [these instructions](http://spacy.io/docs/).

    Installation on Windows:  
    a)  (If you have not yet installed Python:)  Download and install [Python for Windows](https://www.python.org/downloads/windows/).  We recommend the 2.7.12, using (if appropriate) the Windows x86-64 MSI installer.  During the installation process, be sure to scroll down in the installation option window and find the "Add Python.exe to Path", and click on the small red "x."  
    b)  Install spaCy and the English language model using these commands at the command line:  
        ```
        pip install -U spacy
        python -m spacy.en.download
        ```
        For alternative installations or troubleshooting, see the [spaCy docs](https://spacy.io/docs/).  
    c)  Test your installation at the command line using:  
        ```
        python -c "import spacy; spacy.load('en'); print('OK')"
        ```

3.  You need (of course) to install this package:  
    
    ```r
    devtools::install_github("kbenoit/spacyr")
    ```


### Examples

The `spacy_parse()` function calls spaCy to both tokenize and tag the texts. In addition, it provides a functionalities of dependency parsing and named entity recognition. The function returns a `data.table` of the results. The approach to tokenizing taken by spaCy is inclusive: it includes all tokens without restrictions.  The default method for `tag()` is the [Google tagset for parts-of-speech](https://github.com/slavpetrov/universal-pos-tags).


```r
require(spacyr)
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

```r
require(quanteda, warn.conflicts = FALSE, quietly = TRUE)
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


```r
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



## Notes for Mac Users using Homebrew (or other) Version of Python

If you install Python other than the system default and installed spaCy on that Python, you need to set the path to the python executable with spaCy and build `spacyr`. In order to check whether this could be an issue, check the versions of Pythons in Terminal and R.

Open a Terminal window, and type
```
$ python --version; which python
```
and in R, enter following

```r
system('python --version; which python')
```
If the outputs are different, loading spaCy is likely to fail as the python executable the `spacyr` calls is different from the version of python spaCy is intalled.

To resolve the issue, you can alter an environmental variable and then reinstall `spacyr`. Suppose that your python with spaCy is  `/usr/local/bin/python`, run the following:

```r
Sys.setenv(SPACY_PYTHON="/usr/local/bin/python")
devtools::install_github("kbenoit/spacyr")
```

## Comments and feedback

We welcome your comments and feedback.  Please file issues on the issues page, and/or send us comments at kbenoit@lse.ac.uk and A.Matsuo@lse.ac.uk.
