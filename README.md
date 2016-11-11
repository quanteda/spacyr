---
output:
  md_document:
    variant: markdown_github
---



[![CRAN Version](http://www.r-pkg.org/badges/version/spacyr)](http://cran.r-project.org/package=spacyr) ![Downloads](http://cranlogs.r-pkg.org/badges/spacyr) [![Travis-CI Build Status](https://travis-ci.org/kbenoit/spacyr.svg?branch=master)](https://travis-ci.org/kbenoit/spacyr) [![codecov.io](https://codecov.io/github/kbenoit/spacyr/spacyr.svg?branch=master)](https://codecov.io/github/kbenoit/spacyr/coverage.svg?branch=master)

(note: the Travis build fails because our script does not install spaCy and the English language files - once these are installed, it passes the R Check.)

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

# process documents and obtain a data.table
head(data_sentences)
#> [1] "They can at any moment have peace simply by laying down their arms and submitting to the national authority under the Constitution."                                                                                                                                                    
#> [2] "But our laws have provided no means by which this could be accomplished, or by which the losses of the regiments when once sent to the front could be repaired."                                                                                                                        
#> [3] "The negotiation with France has been conducted by our minister with zeal and ability, and in all respects to my entire satisfaction."                                                                                                                                                   
#> [4] "So again, if you have specific plans to cut costs, cover more people, and increase choice - tell America what you'd do differently."                                                                                                                                                    
#> [5] "They are trying to shake the will of our country and our friends, but the United States of America will never be intimidated by thugs and assassins."                                                                                                                                   
#> [6] "Some expansion in peacetime medical research and other programs of the Public Health Service is provided for in the appropriation estimates for these purposes totaling approximately 87 million dollars for the fiscal year 1947 which are submitted under provisions of existing law."
results <- spacy_parse(data_sentences[1:6])
head(results)
#>    docname id tokens  lemma google penn
#> 1:   text1  0   They   they   PRON  PRP
#> 2:   text1  1    can    can   VERB   MD
#> 3:   text1  2     at     at    ADP   IN
#> 4:   text1  3    any    any    DET   DT
#> 5:   text1  4 moment moment   NOUN   NN
#> 6:   text1  5   have   have   VERB   VB
```

By default, `spacy_parse()` conduct tokenization and part-of-speech (POS) tagging. spacyr provides two tagsets, coarse-grained [Google](https://github.com/slavpetrov/universal-pos-tags) tagsets and finer-grained [Penn Treebank](https://www.ling.upenn.edu/courses/Fall_2003/ling001/penn_treebank_pos.html) tagsets. The `google` or `penn` field in the data.table corresponds to each of these tagsets.


The package spacyr works nicely with quanteda. The fist step is to generate a tokenized texts object from the results of `spacy_parse()`. 

```r
taggedsents <- tokens_tags_out(results, tagset = "penn")
taggedsents
#> tokenizedText_tagged object from 6 documents (tagset = ).
#> text1 :
#>  [1] "They_PRP"         "can_MD"           "at_IN"           
#>  [4] "any_DT"           "moment_NN"        "have_VB"         
#>  [7] "peace_NN"         "simply_RB"        "by_IN"           
#> [10] "laying_VBG"       "down_RP"          "their_PRP$"      
#> [13] "arms_NNS"         "and_CC"           "submitting_VBG"  
#> [16] "to_IN"            "the_DT"           "national_JJ"     
#> [19] "authority_NN"     "under_IN"         "the_DT"          
#> [22] "Constitution_NNP" "._."             
#> 
#> text2 :
#>  [1] "But_CC"           "our_PRP$"         "laws_NNS"        
#>  [4] "have_VBP"         "provided_VBN"     "no_DT"           
#>  [7] "means_NNS"        "by_IN"            "which_WDT"       
#> [10] "this_DT"          "could_MD"         "be_VB"           
#> [13] "accomplished_VBN" ",_,"              "or_CC"           
#> [16] "by_IN"            "which_WDT"        "the_DT"          
#> [19] "losses_NNS"       "of_IN"            "the_DT"          
#> [22] "regiments_NNS"    "when_WRB"         "once_IN"         
#> [25] "sent_VBN"         "to_IN"            "the_DT"          
#> [28] "front_NN"         "could_MD"         "be_VB"           
#> [31] "repaired_VBN"     "._."             
#> 
#> text3 :
#>  [1] "The_DT"          "negotiation_NN"  "with_IN"        
#>  [4] "France_NNP"      "has_VBZ"         "been_VBN"       
#>  [7] "conducted_VBN"   "by_IN"           "our_PRP$"       
#> [10] "minister_NN"     "with_IN"         "zeal_NN"        
#> [13] "and_CC"          "ability_NN"      ",_,"            
#> [16] "and_CC"          "in_IN"           "all_DT"         
#> [19] "respects_NNS"    "to_IN"           "my_PRP$"        
#> [22] "entire_JJ"       "satisfaction_NN" "._."            
#> 
#> text4 :
#>  [1] "So_RB"          "again_RB"       ",_,"            "if_IN"         
#>  [5] "you_PRP"        "have_VBP"       "specific_JJ"    "plans_NNS"     
#>  [9] "to_TO"          "cut_VB"         "costs_NNS"      ",_,"           
#> [13] "cover_VBP"      "more_JJR"       "people_NNS"     ",_,"           
#> [17] "and_CC"         "increase_VB"    "choice_NN"      "-_HYPH"        
#> [21] "tell_VB"        "America_NNP"    "what_WP"        "you_PRP"       
#> [25] "d_MD"           "do_VB"          "differently_RB" "._."           
#> 
#> text5 :
#>  [1] "They_PRP"        "are_VBP"         "trying_VBG"     
#>  [4] "to_TO"           "shake_VB"        "the_DT"         
#>  [7] "will_NN"         "of_IN"           "our_PRP$"       
#> [10] "country_NN"      "and_CC"          "our_PRP$"       
#> [13] "friends_NNS"     ",_,"             "but_CC"         
#> [16] "the_DT"          "United_NNP"      "States_NNP"     
#> [19] "of_IN"           "America_NNP"     "will_MD"        
#> [22] "never_RB"        "be_VB"           "intimidated_VBN"
#> [25] "by_IN"           "thugs_NNS"       "and_CC"         
#> [28] "assassins_NNS"   "._."            
#> 
#> text6 :
#>  [1] "Some_DT"          "expansion_NN"     "in_IN"           
#>  [4] "peacetime_NN"     "medical_JJ"       "research_NN"     
#>  [7] "and_CC"           "other_JJ"         "programs_NNS"    
#> [10] "of_IN"            "the_DT"           "Public_NNP"      
#> [13] "Health_NNP"       "Service_NNP"      "is_VBZ"          
#> [16] "provided_VBN"     "for_IN"           "in_IN"           
#> [19] "the_DT"           "appropriation_NN" "estimates_NNS"   
#> [22] "for_IN"           "these_DT"         "purposes_NNS"    
#> [25] "totaling_VBG"     "approximately_RB" "87_CD"           
#> [28] "million_CD"       "dollars_NNS"      "for_IN"          
#> [31] "the_DT"           "fiscal_JJ"        "year_NN"         
#> [34] "1947_CD"          "which_WDT"        "are_VBP"         
#> [37] "submitted_VBN"    "under_IN"         "provisions_NNS"  
#> [40] "of_IN"            "existing_JJ"      "law_NN"          
#> [43] "._."
```


Note that while the printed structure appears to append the token and its tag, in fact the structure of the object records these separately:

```r
str(taggedsents)
#> List of 6
#>  $ text1: chr [1:23] "They" "can" "at" "any" ...
#>  $ text2: chr [1:32] "But" "our" "laws" "have" ...
#>  $ text3: chr [1:24] "The" "negotiation" "with" "France" ...
#>  $ text4: chr [1:28] "So" "again" "," "if" ...
#>  $ text5: chr [1:29] "They" "are" "trying" "to" ...
#>  $ text6: chr [1:43] "Some" "expansion" "in" "peacetime" ...
#>  - attr(*, "class")= chr [1:3] "tokenizedTexts_tagged" "tokenizedText" "list"
#>  - attr(*, "what")= chr "word"
#>  - attr(*, "ngrams")= num 1
#>  - attr(*, "concatenator")= chr ""
#>  - attr(*, "tags")=List of 6
#>   ..$ text1: chr [1:23] "PRP" "MD" "IN" "DT" ...
#>   ..$ text2: chr [1:32] "CC" "PRP$" "NNS" "VBP" ...
#>   ..$ text3: chr [1:24] "DT" "NN" "IN" "NNP" ...
#>   ..$ text4: chr [1:28] "RB" "RB" "," "IN" ...
#>   ..$ text5: chr [1:29] "PRP" "VBP" "VBG" "TO" ...
#>   ..$ text6: chr [1:43] "DT" "NN" "IN" "NN" ...
```
This object has the identical structure of quanteda's tokenizedText objects with an additional attribute of tags and will work with methods applied to tokenizedText in quanteda. 

To get a summary of the parts of speech for each document, use the data.frame returned by the `summary()` method for this new object class:

```r
summary(taggedsents)
#>       . CC DT IN JJ MD NN NNP NNS PRP PRP. RB RP VB VBG X. VBN VBP WDT WRB
#> text1 1  1  3  4  1  1  3   1   1   1    1  1  1  1   2  0   0   0   0   0
#> text2 1  2  5  5  0  2  1   0   4   0    1  0  0  2   0  1   4   1   2   1
#> text3 1  2  2  5  1  0  5   1   1   0    2  0  0  0   0  1   2   0   0   0
#> text4 1  1  0  1  1  1  1   1   3   2    0  3  0  4   0  3   0   2   0   0
#> text5 1  3  2  3  0  1  2   3   3   1    2  1  0  2   1  1   1   1   0   0
#> text6 1  1  5  8  4  0  6   3   5   0    0  1  0  0   1  0   2   1   1   0
#>       VBZ HYPH JJR TO WP CD
#> text1   0    0   0  0  0  0
#> text2   0    0   0  0  0  0
#> text3   1    0   0  0  0  0
#> text4   0    1   1  1  1  0
#> text5   0    0   0  1  0  0
#> text6   1    0   0  0  0  3
```


Many of the standard methods from [**quanteda**](http://githiub.com/kbenoit/quanteda) work on the new tagged token objects:

```r
docnames(taggedsents)
#> [1] "text1" "text2" "text3" "text4" "text5" "text6"
ndoc(taggedsents)
#> [1] 6
ntoken(taggedsents)
#> text1 text2 text3 text4 text5 text6 
#>    23    32    24    28    29    43
ntype(taggedsents)
#> text1 text2 text3 text4 text5 text6 
#>    22    26    22    25    24    37
```

### Document processing with addiitonal features

The following codes conduct more detailed document processing, including dependency parsing and named entitiy recognition.


```r
results_detailed <- spacy_parse(data_sentences[1:6], 
                                pos_tag = TRUE,
                                named_entity = TRUE,
                                dependency = TRUE)
head(results_detailed)
#>    docname id tokens  lemma google penn head_id dep_rel named_entity
#> 1:   text1  0   They   they   PRON  PRP       5   nsubj             
#> 2:   text1  1    can    can   VERB   MD       5     aux             
#> 3:   text1  2     at     at    ADP   IN       5    prep             
#> 4:   text1  3    any    any    DET   DT       4     det             
#> 5:   text1  4 moment moment   NOUN   NN       2    pobj             
#> 6:   text1  5   have   have   VERB   VB       5    ROOT
```
When a named entity recognition was conducted the list of all named entities are provided with:


```r
all_named_entities(results_detailed)
#>    ent_id docname id entity_type                           entity
#> 1:      1   text1 21         LAW                     Constitution
#> 2:      2   text3  3         GPE                           France
#> 3:      3   text4 21         GPE                          America
#> 4:      4   text5 15         GPE     the United States of America
#> 5:      5   text6 10         ORG        the Public Health Service
#> 6:      6   text6 25       MONEY approximately 87 million dollars
#> 7:      7   text6 30        DATE             the fiscal year 1947
```


#### Support of hashed tokens class of quanteda

Recent versions of quanteda provides a new class of object called `tokens`. The spacyr package provides a support for this new class.

```r
results_hashed <- spacy_parse(data_sentences[1:6], 
                              hash_tokens = TRUE)
head(results_hashed)
#>    docname id tokens  lemma google penn
#> 1:   text1  0   They   they   PRON  PRP
#> 2:   text1  1    can    can   VERB   MD
#> 3:   text1  2     at     at    ADP   IN
#> 4:   text1  3    any    any    DET   DT
#> 5:   text1  4 moment moment   NOUN   NN
#> 6:   text1  5   have   have   VERB   VB
taggedsents_hashed <- tokens_tags_out(results_hashed)
str(taggedsents_hashed)
#> List of 6
#>  $ text1: num [1:23] 1 2 3 4 5 6 7 8 9 10 ...
#>  $ text2: num [1:32] 23 24 25 6 26 27 28 9 29 30 ...
#>  $ text3: num [1:24] 44 45 46 47 48 49 50 9 24 51 ...
#>  $ text4: num [1:28] 60 61 34 62 63 6 64 65 16 66 ...
#>  $ text5: num [1:29] 1 80 81 16 82 17 83 37 24 84 ...
#>  $ text6: num [1:43] 93 94 54 95 96 97 14 98 99 37 ...
#>  - attr(*, "class")= chr [1:3] "tokenizedTexts_tagged" "tokens" "list"
#>  - attr(*, "types")= chr [1:120] "They" "can" "at" "any" ...
#>  - attr(*, "what")= chr "word"
#>  - attr(*, "ngrams")= num 1
#>  - attr(*, "concatenator")= chr ""
#>  - attr(*, "tags")=List of 6
#>   ..$ text1: chr [1:23] "PRP" "MD" "IN" "DT" ...
#>   ..$ text2: chr [1:32] "CC" "PRP$" "NNS" "VBP" ...
#>   ..$ text3: chr [1:24] "DT" "NN" "IN" "NNP" ...
#>   ..$ text4: chr [1:28] "RB" "RB" "," "IN" ...
#>   ..$ text5: chr [1:29] "PRP" "VBP" "VBG" "TO" ...
#>   ..$ text6: chr [1:43] "DT" "NN" "IN" "NN" ...
```


## Notes for Mac Users using Homebrew (or other) Version of Python

If you install Python other than the system default and installed spaCy on that Python, you might have to reinstall `rPython` to re-set the python path. In order to check whether this is an issue, check the versions of Pythons in Terminal and R. 

In Terminal, type
```
$ python --version
```
and in R, enter following

```r
library(rPython)
python.exec("import platform\nprint(platform.python_version())")
```
If the outputs are different, loading spaCy is likely to fail as the python executable the R system calls is different from the version of python spaCy is intalled.

To resolve the issue please follow the step. Open R *from Terminal* (just enter `R`), then reinstall rPython from source by entering

```r
install.packages("rPython", type = "source")
```
then execute the R-commands above again to check the version of Python calling from rPython.



## Comments and feedback

We welcome your comments and feedback.  Please file issues on the issues page, and/or send me comments at kbenoit@lse.ac.uk.

Plans moving ahead include finding much more efficient methods of calling spaCy from R than [the current use of `system2()`](https://github.com/kbenoit/spacyr/blob/master/R/tag.R#L71).


