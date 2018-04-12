#!/bin/bash

source activate spacy_condaenv_latest
python benchmark_small_docs.py 
python benchmark_small_docs.py -p
python benchmark_small_docs.py tagger   
python benchmark_small_docs.py tagger -p 
python benchmark_small_docs.py tagger,ner
python benchmark_small_docs.py tagger,ner -p

