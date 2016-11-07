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
import time

#nlp = spacy.en.English()


class spacyr:
    def __init__(self):
        self.nlp = spacy.en.English()
        self.outputs = {}
    
    def parse(self, texts):
        epoch_mils = []
        if isinstance(texts, list) == False:
            texts = [texts]
        for text in texts:
            epoch_mil = int(time.time() * 1000)
            self.outputs[epoch_mil] = self.nlp(unicode(text))
            epoch_mils.append(epoch_mil)
        return epoch_mils 
    
    def tokens(self, timestamps):
        all_tokens = {}
        for ts in timestamps:
            c_output = self.outputs[ts]
            tokens = []
            for w in c_output:
                tokens.append(w.orth_)
            all_tokens[ts] = tokens
        return all_tokens
    
    def tags(self, timestamps):
        all_tags = {}
        for ts in timestamps:
            c_output = self.outputs[ts]
            tags = []
            for w in c_output:
                tags.append(w.tag_)
            all_tags[ts] = tags
        return all_tags
    
    def entities(self, timestamps):
        all_entities = {}
        for ts in timestamps:
            c_output = self.outputs[ts]
            entities = []
            for w in c_output:
                entities.append(w.ent_type_)
            all_entities[ts] = entities
        return all_entities

    # def named_entities(timestamps)
    
    # def dependency_lists
    
    #

spobj = spacyr()

# def parse(texts):
#     epoch_mil = int(time.time() * 1000)
#     spacy_outputs[epoch_mil] = nlp(texts)
# 
# def tag(timestamp, mode):
#     return 0
# 
    
  
