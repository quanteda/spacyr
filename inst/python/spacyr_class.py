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
import itertools

def id_generator(size=10, chars=string.ascii_uppercase + string.digits):
    return ''.join(random.choice(chars) for _ in range(size))

## generator function for itertools
def gen_items(doc_id, texts):
    for i in range(len(doc_id)):
        yield (doc_id[i], texts[i])

class spacyr:
    def __init__(self):
        self.nlp = nlp
        self.documents = {}

    def parse(self, texts, multithread = True):
        epoch_nanos = []
        if isinstance(texts, list) == False:
            texts = [texts]
        for i in range(len(texts)):
            try:
                if not isinstance(texts[i], unicode):
                    texts[i] = unicode(texts[i], "utf-8", errors = "ignore")
            except NameError:
                pass
        if multithread == True:
            for doc in self.nlp.pipe(texts):
                epoch_nano = str(int(time.time() * 1000000)) + id_generator()
                self.documents[epoch_nano] = doc
                epoch_nanos.append(epoch_nano)
        else:
            for text in texts:
                epoch_nano = str(int(time.time() * 1000000)) + id_generator()
                # try:
                #     if not isinstance(text, unicode):
                #         text = unicode(text, "utf-8", errors = "ignore")
                # except NameError:
                #     pass
                doc = self.nlp(text)
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
        if VersionParser(spacy_version) >= VersionParser("2") and turn_off_pipes and remove_symbols == False:
            pipes = self.nlp.pipe_names
            disabled_pipes = self.nlp.disable_pipes(*pipes)
        if isinstance(texts, list) == False:
            texts = [texts]
            docnames = [docnames]
        for i in range(len(texts)):
            try:
                if not isinstance(texts[i], unicode):
                    texts[i] = unicode(texts[i], "utf-8", errors = "ignore")
            except NameError:
                pass
        tokens_out = {}
        # this multithread solution is suggested by @honnibal
        # https://github.com/explosion/spaCy/issues/172
        if multithread == True:
            gen1, gen2 = itertools.tee(gen_items(docnames, texts))
            ids = (id_ for (id_, text) in gen1)
            texts = (text for (id_, text) in gen2)
            docs = nlp.pipe(texts)
            for id_, doc in zip(ids, docs):
                toks = []
                for w in doc:
                    rem = self.rem_check(w)
                    text = w.text
                    if rem:
                        if padding:
                            text = ""
                        else:
                            continue
                    toks.append(text)
                    if remove_separators == False and w.whitespace_:
                        toks.append(w.whitespace_)
                tokens_out[id_] = toks
        else:
            for i in range(len(texts)):
                text = texts[i]
                doc = self.nlp(text)
                toks = []
                for w in doc:
                    rem = self.rem_check(w)
                    text = w.text
                    if rem:
                        if padding:
                            text = ""
                        else:
                            continue
                    toks.append(text)
                    if remove_separators == False and w.whitespace_:
                        toks.append(w.whitespace_)
                tokens_out[docnames[i]] = toks
        if VersionParser(spacy_version) >= VersionParser("2")  and turn_off_pipes and remove_symbols == False:
            disabled_pipes.restore()
        return tokens_out
    
    def rem_check(self, w): # part of tokernize. Check if the token should be removed
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

    def tokenize_sentence(self, texts, docnames, multithread = True, remove_separators = False):
        if isinstance(texts, list) == False:
            texts = [texts]
            docnames = [docnames]
        for i in range(len(texts)):
            try:
                if not isinstance(texts[i], unicode):
                    texts[i] = unicode(texts[i], "utf-8", errors = "ignore")
            except NameError:
                pass
        tokens_out = {}
        regex_trailspace = re.compile('\s+$')
        # this multithread solution is suggested by @honnibal
        # https://github.com/explosion/spaCy/issues/172
        if multithread == True:
            gen1, gen2 = itertools.tee(gen_items(docnames, texts))
            ids = (id_ for (id_, text) in gen1)
            texts = (text for (id_, text) in gen2)
            docs = self.nlp.pipe(texts)
            for id_, doc in zip(ids, docs):
                toks = []
                for sent in doc.sents:
                    toks.append(regex_trailspace.sub('', sent.text))
                tokens_out[id_] = toks
        else:
            for i in range(len(texts)):
                text = texts[i]
                doc = self.nlp(text)
                toks = []
                for sent in doc.sents:
                    sent_text =  sent.text
                    if remove_separators:
                        sent_text = regex_trailspace.sub('', sent_text)
                    toks.append(sent_text)
                tokens_out[docnames[i]] = toks
        return tokens_out

    def extract_nounphrases_list(self, texts, docnames, multithread = True):
        return self.extract_np_ne_list(texts, docnames, multithread, what = "noun_chunks")

    def extract_entity_list(self, texts, docnames, multithread = True, ent_type_category = "all"):
        return self.extract_np_ne_list(texts, docnames, multithread, what = "ents", ent_type_category = ent_type_category)

    def extract_np_ne_list(self, texts, docnames, multithread = True, what = "noun_chunks", ent_type_category = 'all'):
        if isinstance(texts, list) == False:
            texts = [texts]
            docnames = [docnames]
        for i in range(len(texts)):
            try:
                if not isinstance(texts[i], unicode):
                    texts[i] = unicode(texts[i], "utf-8", errors = "ignore")
            except NameError:
                pass
        extended_list = ("DATE", "TIME", "PERCENT", "MONEY", "QUANTITY", "ORDINAL", "CARDINAL")
        # this multithread solution is suggested by @honnibal
        # https://github.com/explosion/spaCy/issues/172
        items = {}
        if multithread == True:
            gen1, gen2 = itertools.tee(gen_items(docnames, texts))
            ids = (id_ for (id_, text) in gen1)
            texts = (text for (id_, text) in gen2)
            docs = self.nlp.pipe(texts)
            for id_, doc in zip(ids, docs):
                items_in_doc = []
                for chunk in getattr(doc, what):
                    if what == "ents":
                        if ent_type_category == "extended" and not (chunk.label_ in extended_list):
                            continue
                        elif ent_type_category == "named" and (chunk.label_ in extended_list):
                            continue
                    items_in_doc.append(chunk.text)
                items[id_] = items_in_doc
        else:
            for i in range(len(texts)):
                text = texts[i]
                doc = self.nlp(text)
                items_in_doc = []
                for chunk in getattr(doc, what):
                    if what == "ents":
                        if ent_type_category == "extended" and not (chunk.label_ in extended_list):
                            continue
                        elif ent_type_category == "named" and (chunk.label_ in extended_list):
                            continue
                    items_in_doc.append(chunk.text)
                items[docnames[i]] = items_in_doc
        return items

    def extract_nounphrases_dataframe(self, docnames, texts = [], timestamps = [], multithread = True):
        return self.extract_np_ne_dataframe(docnames, texts, timestamps, multithread, what = "noun_chunks")

    def extract_entity_dataframe(self, docnames, texts = [], timestamps = [], multithread = True):
        return self.extract_np_ne_dataframe(docnames, texts, timestamps, multithread, what = "ents")

    def extract_np_ne_dataframe(self, docnames, texts = [], timestamps = [], multithread = True, what = "noun_chunks"):
        if timestamps:
            multithread = False
            if isinstance(timestamps, list) == False:
                timestamps = [timestamps]
                docnames = [docnames]
            ndocs = len(timestamps)
        else:
            if isinstance(texts, list) == False:
                texts = [texts]
                docnames = [docnames]
            ndocs = len(texts)
            for i in range(len(texts)):
                try:
                    if not isinstance(texts[i], unicode):
                        texts[i] = unicode(texts[i], "utf-8", errors = "ignore")
                except NameError:
                    pass
        # this multithread solution is suggested by @honnibal
        # https://github.com/explosion/spaCy/issues/172
        df_all = {}
        if multithread == True:
            gen1, gen2 = itertools.tee(gen_items(docnames, texts))
            ids = (id_ for (id_, text) in gen1)
            texts = (text for (id_, text) in gen2)
            docs = self.nlp.pipe(texts)
            for id_, doc in zip(ids, docs):
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
                if len(df_doc['text']) == 0:
                    continue
                df_all[id_] = df_doc
        else:
            for i in range(ndocs):
                if timestamps:
                    doc = self.documents[timestamps[i]]
                else:
                    text = texts[i]
                    doc = self.nlp(text)
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
                df_all[docnames[i]] = df_doc
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

    def attributes_by_sent(self, timestamps, attrname):
        all_attrs = []
        if isinstance(timestamps, list) == False:
            timestamps = [timestamps]
        for ts in timestamps:
            c_document = self.documents[ts]
            attrs = []
            for sent in c_document.sents:
                for w in sent:
                    attrs.append(getattr(w, attrname))
                all_attrs.extend(attrs)
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
