#!/usr/local/bin/python

# Sources:
#  Google universal: http://www.petrovi.de/data/universal.pdf
#  Penn treebank: http://web.mit.edu/6.863/www/PennTreebankTags.html
# Requires installation of spaCy: https://honnibal.github.io/spaCy/
#
# written by Paul Nulty, 19 March 2015

# from __future__ import unicode_literals 
import os
import sys
import argparse
import codecs
import spacy.en
from spacy.parts_of_speech import *
import re

nlp = spacy.en.English()
