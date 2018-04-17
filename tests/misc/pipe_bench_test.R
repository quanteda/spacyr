# devtools::install_github("quanteda/spacyr", ref = "test-pipe")
library(spacyr)
library(quanteda)
library(dplyr)
library(microbenchmark)
corpus_reshape(data_corpus_inaugural, to = "sentences") %>% texts %>% .[1:10000] -> texts

spacy_initialize(check_env = F, condaenv = "spacy_condaenv_latest")
#spacy_initialize(check_env = F, condaenv = "spacy_condaenv_v1.10.0")

microbenchmark(multithread = spacy_parse(texts),
               multithread = spacy_parse(texts, multithread = FALSE), 
               times = 10L)


## check the equivalence of the data
data_corpus_inaugural %>% texts %>% .[1:10] -> texts
data_with_pipe <- spacy_parse(texts)
data_no_pipe <- spacy_parse(texts, use_pipe = FALSE)
all.equal(data_with_pipe, data_no_pipe)

