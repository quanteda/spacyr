# A benchmark script for spacy_parse()
#
# This script compares the processing times for document parsing through 
# spaCy in python with different spacifications from simple tokenization to 
# full-fledged parsing.
# 
# Author: Akitaka Matsuo (A.Matsuo@lse.ac.uk)
# Created: 2016-11-11
# Modified: 2016-11-21
library(spacyr)
library(microbenchmark)

spacy_initialize()
microbenchmark(spacy_parse(inaugTexts, pos_tag = F, named_entity = F, dependency = F), 
               spacy_parse(inaugTexts, pos_tag = F, named_entity = F, dependency = T),
               spacy_parse(inaugTexts, pos_tag = F, named_entity = T, dependency = F),
               spacy_parse(inaugTexts, pos_tag = F, named_entity = T, dependency = T),
               spacy_parse(inaugTexts, pos_tag = T, named_entity = F, dependency = F),
               spacy_parse(inaugTexts, pos_tag = T, named_entity = F, dependency = T),
               spacy_parse(inaugTexts, pos_tag = T, named_entity = T, dependency = F),
               spacy_parse(inaugTexts, pos_tag = T, named_entity = T, dependency = T),
               times = 10)


