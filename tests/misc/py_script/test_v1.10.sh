#!/bin/bash

source activate spacy_condaenv_v1.10.0
python benchmark_small_docs.py -v
python benchmark_small_docs.py -p -v
python benchmark_small_docs.py tagger -v
python benchmark_small_docs.py tagger -p -v
python benchmark_small_docs.py tagger,ner -v
python benchmark_small_docs.py tagger,ner -p -v

