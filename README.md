[![CRAN Version](http://www.r-pkg.org/badges/version/spacyr)](http://cran.r-project.org/package=spacyr) ![Downloads](http://cranlogs.r-pkg.org/badges/spacyr) [![Travis-CI Build Status](https://travis-ci.org/kbenoit/spacyr.svg?branch=master)](https://travis-ci.org/kbenoit/spacyr) [![codecov.io](https://codecov.io/github/kbenoit/spacyr/spacyr.svg?branch=master)](https://codecov.io/github/kbenoit/spacyr/coverage.svg?branch=master)

spacyr: an R wrapper for spaCy
==============================

This package is an R wrapper to the spaCy "industrial strength natural language processing" Python library from <http://spacy.io>.

### Prerequisites

1.  Python (&gt; 2.7 or 3) must be installed on your system.

2.  spaCy must be installed on your system. Follow [these instructions](http://spacy.io/docs/).

    Installation on Windows:
    1.  (If you have not yet installed Python:) Download and install [Python for Windows](https://www.python.org/downloads/windows/). We recommend the 2.7.12, using (if appropriate) the Windows x86-64 MSI installer. During the installation process, be sure to scroll down in the installation option window and find the "Add Python.exe to Path", and click on the small red "x."
    2.  Install spaCy and the English language model using these commands at the command line:

            pip install -U spacy
            python -m spacy.en.download

        For alternative installations or troubleshooting, see the [spaCy docs](https://spacy.io/docs/).
    3.  Test your installation at the command line using:

            python -c "import spacy; spacy.load('en'); print('OK')"

3.  You need (of course) to install this package:

    ``` r
    devtools::install_github("kbenoit/spacyr")
    ```

### Examples

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
#> 1: fastest  0   spaCy            
#> 2: fastest  1 excells            
#> 3: fastest  2      at            
#> 4: fastest  3   large            
#> 5: fastest  4       -            
#> 6: fastest  5   scale
```

By default, `spacy_parse()` conduct tokenization and part-of-speech (POS) tagging. spacyr provides two tagsets, coarse-grained [Google](https://github.com/slavpetrov/universal-pos-tags) tagsets and finer-grained [Penn Treebank](https://www.ling.upenn.edu/courses/Fall_2003/ling001/penn_treebank_pos.html) tagsets. The `google` or `penn` field in the data.table corresponds to each of these tagsets.

Many of the standard methods from [**quanteda**](http://githiub.com/kbenoit/quanteda) work on the new tagged token objects:

``` r
require(quanteda, warn.conflicts = FALSE, quietly = TRUE)
#> quanteda version 0.9.9.24
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
#>     docname id      tokens google penn head_id dep_rel named_entity
#>  1: fastest  0       spaCy                   0                     
#>  2: fastest  1     excells                   1                     
#>  3: fastest  2          at                   2                     
#>  4: fastest  3       large                   3                     
#>  5: fastest  4           -                   4                     
#>  6: fastest  5       scale                   5                     
#>  7: fastest  6 information                   6                     
#>  8: fastest  7  extraction                   7                     
#>  9: fastest  8       tasks                   8                     
#> 10: fastest  9           .                   9                     
#> 11: fastest 10          It                  10                     
#> 12: fastest 11          is                  11                     
#> 13: fastest 12     written                  12                     
#> 14: fastest 13        from                  13                     
#> 15: fastest 14         the                  14                     
#> 16: fastest 15      ground                  15                     
#> 17: fastest 16          up                  16                     
#> 18: fastest 17          in                  17                     
#> 19: fastest 18   carefully                  18                     
#> 20: fastest 19      memory                  19                     
#> 21: fastest 20           -                  20                     
#> 22: fastest 21     managed                  21                     
#> 23: fastest 22      Cython                  22                     
#> 24: fastest 23           .                  23                     
#> 25: fastest 24 Independent                  24                     
#> 26: fastest 25    research                  25                     
#> 27: fastest 26         has                  26                     
#> 28: fastest 27   confirmed                  27                     
#> 29: fastest 28        that                  28                     
#> 30: fastest 29       spaCy                  29                     
#>     docname id      tokens google penn head_id dep_rel named_entity
```

When you finish
---------------

A background process of python is initiated when you ran `spacy_initialize`. Because of the size of English language module of `spaCy`, this takes up a lot of memory (typically 1.5GB). When you do not need the python connection any longer, you can finalize the python (and terminate terminate the process) by running `spacy_finalize()` function.

``` r
spacy_finalize()
```

Notes for Mac Users using Homebrew (or other) Version of Python
---------------------------------------------------------------

If you install Python other than the system default and installed spaCy on that Python, you need to set the path to the python executable with spaCy and build `spacyr`. In order to check whether this could be an issue, check the versions of Pythons in Terminal and R.

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

Comments and feedback
---------------------

We welcome your comments and feedback. Please file issues on the issues page, and/or send us comments at <kbenoit@lse.ac.uk> and <A.Matsuo@lse.ac.uk>.
