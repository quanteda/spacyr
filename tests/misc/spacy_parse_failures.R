# ---
# title: "spacy_parse failures"
# author: "Kenneth Benoit"
# date: "11/11/2016"
# output: html_document
# ---

require(spacyr)
spacy_initialize()

### Issue #5: escaped space characters need special handling

spacy_parse("This \n newline fails.")
## Error in python.exec(python.command) : 
##  Invalid control character at: line 1 column 10 (char 9) 
spacy_parse("This \\n newline succeeds.")
##    docname id   tokens   lemma google penn
## 1:   text1  0     This    this    DET   DT
## 2:   text1  1      \n      \n   SPACE   SP
## 3:   text1  2  newline newline   NOUN   NN
## 4:   text1  3 succeeds succeed   VERB  VBZ
## 5:   text1  4        .       .  PUNCT    .
spacy_parse("This \t tab fails.")
## Error in python.exec(python.command) : 
##  Invalid control character at: line 1 column 10 (char 9) 
spacy_parse("This \\t tab succeeds.")
##    docname id   tokens   lemma google penn
## 1:   text1  0     This    this    DET   DT
## 2:   text1  1      \t      \t   SPACE   SP
## 3:   text1  2      tab     tab   NOUN   NN
## 4:   text1  3 succeeds succeed   VERB  VBZ
## 5:   text1  4        .       .  PUNCT    .

### Issue #6: escaped quotes need special handling

spacy_parse("Failure for \'single\' quotes.")
## File "<string>", line 2
##   texts =' [ "Failure for 'single' quotes." ] '
##                                  ^
## SyntaxError: invalid syntax
##    docname id   tokens   lemma google penn
## 1:   text1  0     This    this    DET   DT
## 2:   text1  1      \t      \t   SPACE   SP
## 3:   text1  2      tab     tab   NOUN   NN
## 4:   text1  3 succeeds succeed   VERB  VBZ
## 5:   text1  4        .       .  PUNCT    .

spacy_parse("Failure for \\\'single\\\' quotes.")
## File "<string>", line 2
##   texts =' [ "Failure for 'single' quotes." ] '
##                                  ^
## SyntaxError: invalid syntax
##    docname id   tokens   lemma google penn
## 1:   text1  0     This    this    DET   DT
## 2:   text1  1      \t      \t   SPACE   SP
## 3:   text1  2      tab     tab   NOUN   NN
## 4:   text1  3 succeeds succeed   VERB  VBZ
## 5:   text1  4        .       .  PUNCT    .

spacy_parse("Failure for \"double\" quotes.")
## Error in python.exec(python.command) : 
##  Expecting , delimiter: line 1 column 18 (char 17) 

spacy_parse("Success for \\\"double\\\" quotes.")
##    docname id  tokens   lemma google penn
## 1:   text1  0 Success success   NOUN   NN
## 2:   text1  1     for     for    ADP   IN
## 3:   text1  2       "       "  PUNCT   ``
## 4:   text1  3  double  double    ADJ   JJ
## 5:   text1  4       "       "  PUNCT   ''
## 6:   text1  5  quotes   quote   NOUN  NNS
## 7:   text1  6       .       .  PUNCT    .


### Issue #7: `spacy_parse()` returns previous object value after failure

spacy_parse("Parsing this sentence is easy.")
#    docname id   tokens    lemma google penn
# 1:   text1  0  Parsing    parse   VERB  VBG
# 2:   text1  1     this     this    DET   DT
# 3:   text1  2 sentence sentence   NOUN   NN
# 4:   text1  3       is       be   VERB  VBZ
# 5:   text1  4     easy     easy    ADJ   JJ
# 6:   text1  5        .        .  PUNCT    .

spacy_parse("Failure for \'single\' quotes.")
## File "<string>", line 2
##   texts =' [ "Failure for 'single' quotes." ] '
##                                  ^
## SyntaxError: invalid syntax
##    docname id   tokens    lemma google penn
## 1:   text1  0  Parsing    parse   VERB  VBG
## 2:   text1  1     this     this    DET   DT
## 3:   text1  2 sentence sentence   NOUN   NN
## 4:   text1  3       is       be   VERB  VBZ
## 5:   text1  4     easy     easy    ADJ   JJ
## 6:   text1  5        .        .  PUNCT    .


