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
        epoch_nanos = []
        if isinstance(texts, list) == False:
            texts = [texts]
        for text in texts:
            epoch_nano = int(time.time() * 1000000)
            self.outputs[epoch_nano] = self.nlp(unicode(text))
            epoch_nanos.append(epoch_nano)
        return epoch_nanos 
    
    def attributes(self, timestamps, attrname):
        all_attrs = {}
        if isinstance(timestamps, list) == False:
            timestamps = [timestamps]
        for ts in timestamps:
            ts = int(ts)
            c_output = self.outputs[ts]
            attrs = []
            for w in c_output:
                attrs.append(getattr(w, attrname))
            all_attrs[ts] = attrs
        return all_attrs
    
    def tokens(self, timestamps):
        all_tokens = self.attributes(timestamps, 'orth_')
        return all_tokens

    def tags(self, timestamps, tag_type):
        attr_name = "tag_" if tag_type == "penn" else "pos_"
        all_tokens = self.attributes(timestamps, attr_name)
        return all_tokens

# def tokens(self, timestamps):
    #     all_tokens = {}
    #     if isinstance(timestamps, list) == False:
    #         timestamps = [timestamps]
    #     for ts in timestamps:
    #         ts = int(ts)
    #         c_output = self.outputs[ts]
    #         tokens = []
    #         for w in c_output:
    #             tokens.append(w.orth_)
    #         all_tokens[ts] = tokens
    #     return all_tokens
    # 
    # def tags(self, timestamps):
    #     all_tags = {}
    #     if isinstance(timestamps, list) == False:
    #         timestamps = [timestamps]
    #     for ts in timestamps:
    #         ts = int(ts)
    #         c_output = self.outputs[ts]
    #         tags = []
    #         for w in c_output:
    #             tags.append(w.tag_)
    #         all_tags[ts] = tags
    #     return all_tags
    # 
    # def entities(self, timestamps):
    #     all_entities = {}
    #     for ts in timestamps:
    #         ts = int(ts)
    #         c_output = self.outputs[ts]
    #         ts = int(ts)
    #         entities = []
    #         for w in c_output:
    #             entities.append(w.ent_type_)
    #         all_entities[ts] = entities
    #     return all_entities

spobj = spacyr()

# def parse(texts):
#     epoch_nano = int(time.time() * 1000)
#     spacy_outputs[epoch_nano] = nlp(texts)
# 
# def tag(timestamp, mode):
#     return 0
# 
    
  
