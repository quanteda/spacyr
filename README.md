[![CRAN Version](http://www.r-pkg.org/badges/version/spacyr)](http://cran.r-project.org/package=spacyr) ![Downloads](http://cranlogs.r-pkg.org/badges/spacyr) [![Travis-CI Build Status](https://travis-ci.org/kbenoit/spacyr.svg?branch=master)](https://travis-ci.org/kbenoit/spacyr) [![codecov.io](https://codecov.io/github/kbenoit/spacyr/spacyr.svg?branch=master)](https://codecov.io/github/kbenoit/spacyr/coverage.svg?branch=master)

(note: the Travis build fails because our script does not install spaCy and the English language files - once these are installed, it passes the R Check.)

spacyr: an R wrapper for spaCy
==============================

This package is an R wrapper to the spaCy "industrial strength natural language processing" Python library from <http://spacy.io>.

### Prerequisites

1.  Python must be installed on your system.

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

The `tag()` function calls spaCy to both tokenize and tag the texts, and returns a special class of tokenizedText object (see [**quanteda**](http://githiub.com/kbenoit/quanteda)) that has both tokens and tags. The approach to tokenizing taken by spaCy is inclusive: it includes all tokens without restrictions. The default method for `tag()` is the [Google tagset for parts-of-speech](https://github.com/slavpetrov/universal-pos-tags).

``` r
require(spacyr)
#> Loading required package: spacyr
#> Loading required package: quanteda
#> quanteda version 0.9.9.2
#> 
#> Attaching package: 'quanteda'
#> The following object is masked from 'package:base':
#> 
#>     sample
# find spaCy and set the correct environment variables
initialize_spacy()
#> tag() is ready to run

# show tag on some sample sentences
head(data_sentences)
#> [1] "They can at any moment have peace simply by laying down their arms and submitting to the national authority under the Constitution."                                                                                                                                                    
#> [2] "But our laws have provided no means by which this could be accomplished, or by which the losses of the regiments when once sent to the front could be repaired."                                                                                                                        
#> [3] "The negotiation with France has been conducted by our minister with zeal and ability, and in all respects to my entire satisfaction."                                                                                                                                                   
#> [4] "So again, if you have specific plans to cut costs, cover more people, and increase choice - tell America what you'd do differently."                                                                                                                                                    
#> [5] "They are trying to shake the will of our country and our friends, but the United States of America will never be intimidated by thugs and assassins."                                                                                                                                   
#> [6] "Some expansion in peacetime medical research and other programs of the Public Health Service is provided for in the appropriation estimates for these purposes totaling approximately 87 million dollars for the fiscal year 1947 which are submitted under provisions of existing law."
taggedsents <- tag(data_sentences[1:6])
taggedsents
#> tokenizedText_tagged object from 2 documents (tagset = google).
#> text1 :
#>  [1] "They_PRON"          "can_VERB"           "at_ADP"            
#>  [4] "any_DET"            "moment_NOUN"        "have_VERB"         
#>  [7] "peace_NOUN"         "simply_ADV"         "by_ADP"            
#> [10] "laying_VERB"        "down_PART"          "their_ADJ"         
#> [13] "arms_NOUN"          "and_CONJ"           "submitting_VERB"   
#> [16] "to_ADP"             "the_DET"            "national_ADJ"      
#> [19] "authority_NOUN"     "under_ADP"          "the_DET"           
#> [22] "Constitution_PROPN" "._PUNCT"           
#> 
#> text2 :
#>  [1] "But_CONJ"          "our_ADJ"           "laws_NOUN"        
#>  [4] "have_VERB"         "provided_VERB"     "no_DET"           
#>  [7] "means_NOUN"        "by_ADP"            "which_ADJ"        
#> [10] "this_DET"          "could_VERB"        "be_VERB"          
#> [13] "accomplished_VERB" ",_PUNCT"           "or_CONJ"          
#> [16] "by_ADP"            "which_ADJ"         "the_DET"          
#> [19] "losses_NOUN"       "of_ADP"            "the_DET"          
#> [22] "regiments_NOUN"    "when_ADV"          "once_ADP"         
#> [25] "sent_VERB"         "to_ADP"            "the_DET"          
#> [28] "front_NOUN"        "could_VERB"        "be_VERB"          
#> [31] "repaired_VERB"     "._PUNCT"          
#> 
#> text3 :
#>  [1] "The_DET"           "negotiation_NOUN"  "with_ADP"         
#>  [4] "France_PROPN"      "has_VERB"          "been_VERB"        
#>  [7] "conducted_VERB"    "by_ADP"            "our_ADJ"          
#> [10] "minister_NOUN"     "with_ADP"          "zeal_NOUN"        
#> [13] "and_CONJ"          "ability_NOUN"      ",_PUNCT"          
#> [16] "and_CONJ"          "in_ADP"            "all_DET"          
#> [19] "respects_NOUN"     "to_ADP"            "my_ADJ"           
#> [22] "entire_ADJ"        "satisfaction_NOUN" "._PUNCT"          
#> 
#> text4 :
#>  [1] "So_ADV"          "again_ADV"       ",_PUNCT"        
#>  [4] "if_ADP"          "you_PRON"        "have_VERB"      
#>  [7] "specific_ADJ"    "plans_NOUN"      "to_PART"        
#> [10] "cut_VERB"        "costs_NOUN"      ",_PUNCT"        
#> [13] "cover_VERB"      "more_ADJ"        "people_NOUN"    
#> [16] ",_PUNCT"         "and_CONJ"        "increase_VERB"  
#> [19] "choice_NOUN"     "-_PUNCT"         "tell_VERB"      
#> [22] "America_PROPN"   "what_NOUN"       "you_PRON"       
#> [25] "'d_VERB"         "do_VERB"         "differently_ADV"
#> [28] "._PUNCT"        
#> 
#> text5 :
#>  [1] "They_PRON"        "are_VERB"         "trying_VERB"     
#>  [4] "to_PART"          "shake_VERB"       "the_DET"         
#>  [7] "will_NOUN"        "of_ADP"           "our_ADJ"         
#> [10] "country_NOUN"     "and_CONJ"         "our_ADJ"         
#> [13] "friends_NOUN"     ",_PUNCT"          "but_CONJ"        
#> [16] "the_DET"          "United_PROPN"     "States_PROPN"    
#> [19] "of_ADP"           "America_PROPN"    "will_VERB"       
#> [22] "never_ADV"        "be_VERB"          "intimidated_VERB"
#> [25] "by_ADP"           "thugs_NOUN"       "and_CONJ"        
#> [28] "assassins_NOUN"   "._PUNCT"         
#> 
#> text6 :
#>  [1] "Some_DET"           "expansion_NOUN"     "in_ADP"            
#>  [4] "peacetime_NOUN"     "medical_ADJ"        "research_NOUN"     
#>  [7] "and_CONJ"           "other_ADJ"          "programs_NOUN"     
#> [10] "of_ADP"             "the_DET"            "Public_PROPN"      
#> [13] "Health_PROPN"       "Service_PROPN"      "is_VERB"           
#> [16] "provided_VERB"      "for_ADP"            "in_ADP"            
#> [19] "the_DET"            "appropriation_NOUN" "estimates_NOUN"    
#> [22] "for_ADP"            "these_DET"          "purposes_NOUN"     
#> [25] "totaling_VERB"      "approximately_ADV"  "87_NUM"            
#> [28] "million_NUM"        "dollars_NOUN"       "for_ADP"           
#> [31] "the_DET"            "fiscal_ADJ"         "year_NOUN"         
#> [34] "1947_NUM"           "which_ADJ"          "are_VERB"          
#> [37] "submitted_VERB"     "under_ADP"          "provisions_NOUN"   
#> [40] "of_ADP"             "existing_ADJ"       "law_NOUN"          
#> [43] "._PUNCT"
```

Note that while the printed structure appears to append the token and its tag, in fact the structure of the object records these separately:

``` r
str(taggedsents)
#> List of 2
#>  $ tokens:List of 6
#>   ..$ text1: chr [1:23] "They" "can" "at" "any" ...
#>   ..$ text2: chr [1:32] "But" "our" "laws" "have" ...
#>   ..$ text3: chr [1:24] "The" "negotiation" "with" "France" ...
#>   ..$ text4: chr [1:28] "So" "again" "," "if" ...
#>   ..$ text5: chr [1:29] "They" "are" "trying" "to" ...
#>   ..$ text6: chr [1:43] "Some" "expansion" "in" "peacetime" ...
#>  $ tags  :List of 6
#>   ..$ text1: chr [1:23] "PRON" "VERB" "ADP" "DET" ...
#>   ..$ text2: chr [1:32] "CONJ" "ADJ" "NOUN" "VERB" ...
#>   ..$ text3: chr [1:24] "DET" "NOUN" "ADP" "PROPN" ...
#>   ..$ text4: chr [1:28] "ADV" "ADV" "PUNCT" "ADP" ...
#>   ..$ text5: chr [1:29] "PRON" "VERB" "VERB" "PART" ...
#>   ..$ text6: chr [1:43] "DET" "NOUN" "ADP" "NOUN" ...
#>  - attr(*, "tagset")= chr "google"
#>  - attr(*, "class")= chr [1:2] "tokenizedTexts_tagged" "list"
```

To get a summary of the parts of speech for each document, use the data.frame returned by the `summary()` method for this new object class:

``` r
summary(taggedsents)
#>       ADJ ADP ADV CONJ DET NOUN PART PRON PROPN PUNCT VERB NUM
#> text1   2   4   1    1   3    4    1    1     1     1    4   0
#> text2   3   5   1    2   5    5    0    0     0     2    9   0
#> text3   3   5   0    2   2    6    0    0     1     2    3   0
#> text4   2   1   3    1   0    5    1    2     1     5    7   0
#> text5   2   3   1    3   2    5    1    1     3     2    6   0
#> text6   5   8   1    1   5   11    0    0     3     1    5   3
```

Alternatively the [Penn Treebank](https://www.ling.upenn.edu/courses/Fall_2003/ling001/penn_treebank_pos.html) part-of-speech tagset can be applied:

``` r
taggedsents2 <- tag(data_sentences[1:6], tagset = "penn")
summary(taggedsents2)
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

``` r
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

Comments and feedback
---------------------

We welcome your comments and feedback. Please file issues on the issues page, and/or send me comments at <kbenoit@lse.ac.uk>.

Plans moving ahead include finding much more efficient methods of calling spaCy from R than [the current use of `system2()`](https://github.com/kbenoit/spacyr/blob/master/R/tag.R#L71).
