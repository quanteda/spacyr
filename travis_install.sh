#!/bin/bash

# create virtualenv
# deactivate
virtualenv -p /usr/bin/python3 --system-site-packages testenv
source testenv/bin/activate

# Python dependencies
pip install --upgrade pip
pip install --upgrade html5lib 
pip install spacy
python -m spacy download en
