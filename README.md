[![CRAN Version](http://www.r-pkg.org/badges/version/spacyr)](http://cran.r-project.org/package=spacyr) ![Downloads](http://cranlogs.r-pkg.org/badges/spacyr) [![Travis-CI Build Status](https://travis-ci.org/kbenoit/spacyr.svg?branch=master)](https://travis-ci.org/kbenoit/spacyr) [![codecov.io](https://codecov.io/github/kbenoit/spacyr/spacyr.svg?branch=master)](https://codecov.io/github/kbenoit/spacyr/coverage.svg?branch=master)

# spacyr: an R wrapper for spaCy

This package is an R wrapper to the spaCy "industrial strength natural language processing" library from http://spacy.io.


### Prerequisites

1.  Python must be installed on your system.  

2.  spaCy must be installed on your system.  Follow [these instructions](http://spacy.io/docs/).

```{r}
require(spacyr)
#> Loading required package: spacyr
#> Loading required package: quanteda
#> quanteda version 0.9.6.9
#> 
#> Attaching package: 'quanteda'
#> The following object is masked from 'package:base':
#> 
#>     sample

# read in the dictionary
liwc2007dict <- dictionary(file = "~/Dropbox/QUANTESS/dictionaries/LIWC/LIWC2007.cat", 
                           format = "wordstat")
#> Warning in strsplit(w, "\\("): input string 1 is invalid in this locale
tail(liwc2007dict, 1)
#> $`SPOKEN CATEGORIES.FILLERS`
#>  [1] "blah"         NA             "idontknow"    "imean"       
#>  [5] "ohwell"       "oranything*"  "orsomething*" "orwhatever*" 
#>  [9] "rr*"          "yakn*"        "ykn*"         "youknow*"

# our test data
testphrases
#>  [1] "Test sentence for spacyr.  Second sentence."                   
#>  [2] "Each row is a document."                                          
#>  [3] "Comma, period."                                                   
#>  [4] "The red-shirted lawyer gave her ex-boyfriend $300 out of pity :(."
#>  [5] "LOL :)."                                                          
#>  [6] "(Parentheses) for $100."                                          
#>  [7] "Say \"what\" again!!"                                             
#>  [8] "Why are we here?"                                                 
#>  [9] "Other punctation: ^; %, &."                                       
#> [10] "Sentence one.  Sentence two! :-)"

# call spacyr
output <- spacyr(testphrases, liwc2007dict)

# view some results
output[, c(1:7, ncol(output)-2)]
#>    docname Segment WC WPS Sixltr    Dic
#> 1    text1       1  6   3  50.00  83.33
#> 2    text2       2  5   5  20.00 200.00
#> 3    text3       3  2   2   0.00 100.00
#> 4    text4       4 12  12  16.67 250.00
#> 5    text5       5  1   1   0.00 300.00
#> 6    text6       6  3   3  33.33 133.33
#> 7    text7       7  3   3   0.00 333.33
#> 8    text8       8  4   4   0.00 375.00
#> 9    text9       9  2   2  50.00 150.00
#> 10  text10      10  4   2  50.00 100.00
#>    LINGUISTIC PROCESSES.FUNCTION WORDS Apostro
#> 1                                33.33       0
#> 2                                50.00       0
#> 3                                 0.00       0
#> 4                                66.67       0
#> 5                                 0.00       0
#> 6                                16.67       0
#> 7                                33.33       0
#> 8                                50.00       0
#> 9                                16.67       0
#> 10                               33.33       0
```

How to Install
--------------

**spacyr** is currently only available on GitHub, not on CRAN. The best method of installing it is through the **devtools** package:

    devtools::install_github("kbenoit/spacyr")

This will also automatically install the **quanteda** package on which **spacyr** is built.

Comments and feedback
---------------------

I welcome your comments and feedback. Please file issues on the issues page, and/or send me comments at <kbenoit@lse.ac.uk>.
