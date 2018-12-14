# spacy tokenizer bench
library(microbenchmark)
library(quanteda)
library(spacyr)
library(dplyr)

spacy_initialize()
text <- texts(data_corpus_irishbudget2010 %>% corpus_reshape("sentences"))
microbenchmark(just_tokenize = spacy_tokenize(text),
               remove_punct = spacy_tokenize(text, remove_punct = TRUE),
               quanteda = tokens(text),
               times = 3)
