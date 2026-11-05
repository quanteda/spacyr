# -*- coding: utf-8 -*-
# Sources:
#  Google universal: http://www.petrovi.de/data/universal.pdf
#  Penn treebank: http://web.mit.edu/6.863/www/PennTreebankTags.html
# Requires installation of spaCy: https://honnibal.github.io/spaCy/
from __future__ import unicode_literals
import os
import sys
import spacy
import time
import gc
import string
import random
import contextlib
import re

# This module is loaded by spacy_initialize() with reticulate::import_from_path().
# It keeps no state of its own: R holds the pipeline returned by load_model()
# and passes it, and all other values, as arguments.

def load_model(model, entity = True, max_length = None):
    if not entity:
        nlp = spacy.load(model, disable = ['ner'])
    else:
        nlp = spacy.load(model)
    if max_length is not None:
        nlp.max_length = int(max_length)
    return nlp

def spacy_version():
    return spacy.about.__version__

def id_generator(size=10, chars=string.ascii_uppercase + string.digits):
    return ''.join(random.choice(chars) for _ in range(size))

def _as_list(texts, docnames = None):
    # a single text arrives from R as a string rather than a list
    if isinstance(texts, list) == False:
        texts = [texts]
        if docnames is not None:
            docnames = [docnames]
    for i in range(len(texts)):
        try:
            if not isinstance(texts[i], unicode):
                texts[i] = unicode(texts[i], "utf-8", errors = "ignore")
        except NameError:
            pass
    return texts, docnames

## per-document processing, shared by both paths

def doc_tokens(doc, padding, remove_separators, **remove):
    toks = []
    for w in doc:
        text = w.text
        if rem_check(w, remove_separators = remove_separators, **remove):
            if padding:
                text = ""
            else:
                continue
        toks.append(text)
        if remove_separators == False and w.whitespace_:
            toks.append(w.whitespace_)
    return toks

def rem_check(w, remove_punct = False, remove_url = False,
              remove_numbers = False, remove_separators = True,
              remove_symbols = False):
    # check whether the token should be removed by tokenize()
    rem = False
    if remove_punct and w.is_punct:
        rem = True
    if remove_url and (w.like_url or w.like_email):
        rem = True
    if remove_numbers and w.like_num:
        rem = True
    if remove_separators == True and w.is_space:
        rem = True
    if remove_symbols == True:
        if w.is_currency:
            rem = True
        if  w.pos_ == "SYM":
            rem = True
    return(rem)

_regex_trailspace = re.compile(r'\s+$')

def doc_sentences(doc, remove_separators):
    sents = []
    for sent in doc.sents:
        sent_text = sent.text_with_ws
        if remove_separators:
            sent_text = _regex_trailspace.sub('', sent_text)
        sents.append(sent_text)
    return sents

_extended_list = ("DATE", "TIME", "PERCENT", "MONEY", "QUANTITY", "ORDINAL", "CARDINAL")

def doc_span_texts(doc, what, ent_type_category = "all"):
    items = []
    for chunk in getattr(doc, what):
        if what == "ents":
            if ent_type_category == "extended" and not (chunk.label_ in _extended_list):
                continue
            elif ent_type_category == "named" and (chunk.label_ in _extended_list):
                continue
        items.append(chunk.text)
    return items

def doc_span_table(doc, what):
    if what == "noun_chunks":
        df_doc = {"text": [], "root_text": [], "start_id": [], "root_id":[], "length": []}
    else:
        df_doc = {"text": [], "ent_type": [], "start_id": [], "length": []}
    for chunk in getattr(doc, what):
        df_doc['text'].append(chunk.text)
        df_doc['start_id'].append(chunk[0].i)
        df_doc['length'].append(len(chunk))
        if what == "noun_chunks":
            df_doc['root_text'].append(chunk.root.text)
            df_doc['root_id'].append(chunk.root.i)
        else:
            df_doc['ent_type'].append(chunk.label_)
    return df_doc

class spacyr:
    def __init__(self, nlp):
        self.nlp = nlp
        self.documents = {}

    def docs(self, texts, multithread = True):
        # Parse the texts, in order. With multithread, spaCy's nlp.pipe()
        # processes them in batches and calls each component's pipe() method;
        # otherwise each text is processed by nlp(), which calls each
        # component on the single document. A custom component can behave
        # differently in the two, so the choice is kept as it was in 1.4.0
        # (see tests/testthat/test-pipeline-paths.R).
        if multithread == True:
            return self.nlp.pipe(texts)
        return (self.nlp(text) for text in texts)

    def parse(self, texts, multithread = True):
        texts, _ = _as_list(texts)
        epoch_nanos = []
        for doc in self.docs(texts, multithread):
            epoch_nano = str(int(time.time() * 1000000)) + id_generator()
            self.documents[epoch_nano] = doc
            epoch_nanos.append(epoch_nano)
        return epoch_nanos

    def tokenize(self, texts, docnames, turn_off_pipes = True,
                 remove_punct = False,
                 remove_numbers = False,
                 remove_url = False,
                 remove_separators = True,
                 remove_symbols = False,
                 padding = False,
                 multithread = True):
        # disable the pipeline components for plain tokenization; the context
        # manager restores them even if tokenization fails
        if turn_off_pipes and remove_symbols == False:
            if hasattr(self.nlp, "select_pipes"):
                pipes_context = self.nlp.select_pipes(disable = self.nlp.pipe_names)
            else:
                # spaCy 2.x; its DisabledPipes also restores the pipes on exit
                pipes_context = self.nlp.disable_pipes(*self.nlp.pipe_names)
        else:
            pipes_context = contextlib.nullcontext()
        texts, docnames = _as_list(texts, docnames)
        with pipes_context:
            tokens_out = {}
            for id_, doc in zip(docnames, self.docs(texts, multithread)):
                tokens_out[id_] = doc_tokens(doc, padding,
                                             remove_separators = remove_separators,
                                             remove_punct = remove_punct,
                                             remove_numbers = remove_numbers,
                                             remove_url = remove_url,
                                             remove_symbols = remove_symbols)
            return tokens_out

    def tokenize_sentence(self, texts, docnames, multithread = True, remove_separators = False):
        texts, docnames = _as_list(texts, docnames)
        tokens_out = {}
        for id_, doc in zip(docnames, self.docs(texts, multithread)):
            tokens_out[id_] = doc_sentences(doc, remove_separators)
        return tokens_out

    def extract_nounphrases_list(self, texts, docnames, multithread = True):
        return self.extract_np_ne_list(texts, docnames, multithread, what = "noun_chunks")

    def extract_entity_list(self, texts, docnames, multithread = True, ent_type_category = "all"):
        return self.extract_np_ne_list(texts, docnames, multithread, what = "ents", ent_type_category = ent_type_category)

    def extract_np_ne_list(self, texts, docnames, multithread = True, what = "noun_chunks", ent_type_category = 'all'):
        texts, docnames = _as_list(texts, docnames)
        items = {}
        for id_, doc in zip(docnames, self.docs(texts, multithread)):
            items[id_] = doc_span_texts(doc, what, ent_type_category)
        return items

    def extract_nounphrases_dataframe(self, docnames, texts = [], timestamps = [], multithread = True):
        return self.extract_np_ne_dataframe(docnames, texts, timestamps, multithread, what = "noun_chunks")

    def extract_entity_dataframe(self, docnames, texts = [], timestamps = [], multithread = True):
        return self.extract_np_ne_dataframe(docnames, texts, timestamps, multithread, what = "ents")

    def extract_np_ne_dataframe(self, docnames, texts = [], timestamps = [], multithread = True, what = "noun_chunks"):
        if timestamps:
            # documents already parsed by parse()
            if isinstance(timestamps, list) == False:
                timestamps = [timestamps]
                docnames = [docnames]
            docs = (self.documents[ts] for ts in timestamps)
            multithread = False
        else:
            texts, docnames = _as_list(texts, docnames)
            docs = self.docs(texts, multithread)
        df_all = {}
        for id_, doc in zip(docnames, docs):
            df_doc = doc_span_table(doc, what)
            # as in 1.4.0, documents without spans are left out only with
            # multithread; R drops them either way
            if multithread == True and len(df_doc['text']) == 0:
                continue
            df_all[id_] = df_doc
        return df_all

    def ntokens(self, timestamps):
        ntok = []
        if isinstance(timestamps, list) == False:
            timestamps = [timestamps]
        for ts in timestamps:
            c_document = self.documents[ts]
            ntok.append(len(c_document))
        return ntok

    def ntokens_by_sent(self, timestamps):
        ntok_by_sent = []
        if isinstance(timestamps, list) == False:
            timestamps = [timestamps]
        for ts in timestamps:
            c_document = self.documents[ts]
            ntok_in_sent = []
            for sent in c_document.sents:
                ntok_in_sent.append(len(sent))
            ntok_by_sent.append(ntok_in_sent)
        return ntok_by_sent

    def attributes(self, timestamps, attrname, deal_utf8 = 0):
        all_attrs = []
        if isinstance(timestamps, list) == False:
            timestamps = [timestamps]
        for ts in timestamps:
            c_document = self.documents[ts]
            attrs = []
            for w in c_document:
                attrs.append(getattr(w, attrname))
            all_attrs.extend(attrs)
        if deal_utf8 == 1:
            if sys.version_info.major == 2:
                for i in range(len(all_attrs)):
                    all_attrs[i] = all_attrs[i].encode('utf-8')
        return all_attrs

    def tokens(self, timestamps):
        all_tokens = self.attributes(timestamps, 'text', 1)
        return all_tokens

    def tags(self, timestamps, tag_type):
        if isinstance(timestamps, list) == False:
            timestamps = [timestamps]
        attr_name = "tag_" if tag_type == "detailed" else "pos_"
        all_tokens = self.attributes(timestamps, attr_name)
        return all_tokens

    def run_entity(self, timestamps):
        if isinstance(timestamps, list) == False:
            timestamps = [timestamps]
        for ts in timestamps:
            self.nlp.entity(self.documents[ts])

    def run_tagger(self, timestamps):
        if isinstance(timestamps, list) == False:
            timestamps = [timestamps]
        for ts in timestamps:
            self.nlp.tagger(self.documents[ts])

    def run_dependency_parser(self, timestamps):
        if isinstance(timestamps, list) == False:
            timestamps = [timestamps]
        for ts in timestamps:
            self.nlp.parser(self.documents[ts])

    def list_entities(self, timestamps):
        all_entities = {}
        if isinstance(timestamps, list) == False:
            timestamps = [timestamps]
        for ts in timestamps:
            c_document = self.documents[ts]
            ents = list(c_document.ents)
            entities = []
            for entity in ents:
                entities.append((entity.label_, ' '.join(t.orth_ for t in entity)))
            all_entities[ts] = entities
        return all_entities

    def dep_head_id(self, timestamps):
        all_head_ids = []
        if isinstance(timestamps, list) == False:
            timestamps = [timestamps]
        for ts in timestamps:
            c_document = self.documents[ts]
            head_ids = []
            for sent in c_document.sents:
                for w in sent:
                    head_ids.append(w.head.i)
            all_head_ids.extend(head_ids)
        return all_head_ids
