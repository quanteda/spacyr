# comparison between rPython and Rcpp
#
# This script compares the processing times for document parsing through 
# spaCy in python with different spacifications from simple tokenization to 
# full-fledged parsing.
# 
# Author: Akitaka Matsuo (A.Matsuo@lse.ac.uk)
# Created: 2016-11-21
# Modified: 2016-11-21
library(spacyr)
library(microbenchmark)

spacy_initialize("rPython")
spacy_initialize("Rcpp")
microbenchmark(spacy_parse(inaugTexts, pos_tag = T, named_entity = T, dependency = T, python_exec = "rPython"),
               spacy_parse(inaugTexts, pos_tag = T, named_entity = T, dependency = T, python_exec = "Rcpp"),
               times = 10)