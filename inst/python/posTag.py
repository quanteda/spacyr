#!/usr/local/bin/python

# Sources:
#  Google universal: http://www.petrovi.de/data/universal.pdf
#  Penn treebank: http://web.mit.edu/6.863/www/PennTreebankTags.html
# Requires installation of spaCy: https://honnibal.github.io/spaCy/
#
# written by Paul Nulty, 19 March 2015

from __future__ import unicode_literals 
import os
import sys
import argparse
import codecs
import spacy.en
from spacy.parts_of_speech import *
import re

# command line arguments
ap = argparse.ArgumentParser(description='Apply the spaCy part-of-speech tagger to a file.')
ap.add_argument('-w','--words', action="store_true", default=False, help="Keep the original words and append POS tags")
ap.add_argument('-s','--sep',  default='_', help="If --words is true, --sep is the character used to separate the word and the tag")
ap.add_argument('-p','--penn', action="store_true", default=False, help="Use Penn treebank tagset instead of Google universal")

args = ap.parse_args()
nlp = spacy.en.English()
for line in sys.stdin:
	outs = ""
	line=re.sub(' +',' ',line.strip())
	taggedWords = nlp(unicode(line), tag=True, parse=False)
	for w in taggedWords:
		thisTag = w.tag_ if args.penn else w.pos_
		if not args.words:
			outs = outs+" "+thisTag
		else:
			outs=outs+" "+thisTag+args.sep + w.orth_
	print(outs.strip())
