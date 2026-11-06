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

def doc_entity_tags(doc):
    # "TYPE_B" or "TYPE_I" for tokens in an entity, "" otherwise
    tags = []
    for w in doc:
        tag = w.ent_type_ + "_" + w.ent_iob_.replace("O", "", 1)
        tags.append("" if tag == "_" else tag)
    return tags

def doc_nounphrase_tags(doc):
    # Label each token of a noun phrase "beg", "mid" or "end", with "_root"
    # added for the root of the phrase, and other tokens "". A token in more
    # than one noun phrase takes the label from the longest of them, or the
    # first if they are equally long.
    chunks = [(c.start, len(c), c.root.i) for c in doc.noun_chunks]
    best = {}
    for k, (start, length, root) in enumerate(chunks):
        for w in range(start, start + length):
            if w not in best or length > chunks[best[w]][1]:
                best[w] = k
    last = {}
    for w, k in best.items():
        last[k] = max(last.get(k, w), w)
    tags = []
    for w in range(len(doc)):
        if w not in best:
            tags.append("")
            continue
        k = best[w]
        start, length, root = chunks[k]
        tag = "beg" if w == start else ("end" if w == last[k] else "mid")
        if w == root:
            tag += "_root"
        tags.append(tag)
    return tags, len(chunks)

class spacyr:
    def __init__(self, nlp):
        self.nlp = nlp
        self.documents = {}
        self.skipped = []

    def docs(self, texts, ids, batch_size = None, n_process = 1):
        # Parse the texts, in order, with spaCy's nlp.pipe(), which processes
        # them in batches and calls each component's pipe() method rather
        # than its __call__() (see tests/testthat/test-pipeline-paths.R).
        # Yields (id, doc) pairs. Each id travels with its text through the
        # pipeline, because nlp.pipe() leaves out a document when a component
        # fails on it and the pipeline's error handler suppresses the error;
        # the ids of documents left out are stored in self.skipped.
        # batch_size and n_process are passed to nlp.pipe(): None uses the
        # pipeline's default batch size, and n_process = -1 uses all CPUs.
        self.skipped = []
        seen = set()
        for doc, id_ in self.nlp.pipe(zip(texts, ids), as_tuples = True,
                                     batch_size = batch_size, n_process = n_process):
            seen.add(id_)
            yield id_, doc
        self.skipped = [id_ for id_ in ids if id_ not in seen]

    def parse(self, texts, docnames, batch_size = None, n_process = 1):
        texts, docnames = _as_list(texts, docnames)
        epoch_nanos = {}
        for id_, doc in self.docs(texts, docnames, batch_size, n_process):
            epoch_nano = str(int(time.time() * 1000000)) + id_generator()
            self.documents[epoch_nano] = doc
            epoch_nanos[id_] = epoch_nano
        return epoch_nanos

    def parse_table(self, texts, docnames, lemma = True, pos = True, tag = False,
                    dependency = False, entity = True, nounphrase = False,
                    attributes = None, batch_size = None, n_process = 1):
        # The columns of spacy_parse(), built in one pass over the documents
        # as they are parsed. Token and sentence ids start at 1, and
        # head_token_id is the position of the head in its sentence.
        texts, docnames = _as_list(texts, docnames)
        if attributes is None:
            attributes = []
        elif not isinstance(attributes, list):
            attributes = [attributes]
        cols = {"doc_id": [], "sentence_id": [], "token_id": [], "token": []}
        if lemma:
            cols["lemma"] = []
        if pos:
            cols["pos"] = []
        if tag:
            cols["tag"] = []
        if dependency:
            cols["head_token_id"] = []
            cols["dep_rel"] = []
        if entity:
            cols["entity"] = []
        if nounphrase:
            cols["nounphrase"] = []
            cols["whitespace"] = []
        # additional attributes are returned apart from the other columns,
        # since their names can be the same as those of other columns
        extra = dict((att, []) for att in attributes)
        n_nounphrases = 0
        for id_, doc in self.docs(texts, docnames, batch_size, n_process):
            for sent_id, sent in enumerate(doc.sents, 1):
                for token_id, w in enumerate(sent, 1):
                    cols["doc_id"].append(id_)
                    cols["sentence_id"].append(sent_id)
                    cols["token_id"].append(token_id)
                    cols["token"].append(w.text)
                    if lemma:
                        cols["lemma"].append(w.lemma_)
                    if pos:
                        cols["pos"].append(w.pos_)
                    if tag:
                        cols["tag"].append(w.tag_)
                    if dependency:
                        cols["head_token_id"].append(w.head.i - sent.start + 1)
                        cols["dep_rel"].append(w.dep_)
                    if nounphrase:
                        cols["whitespace"].append(len(w.whitespace_) > 0)
                    for att in extra:
                        extra[att].append(getattr(w, att))
            if entity:
                cols["entity"].extend(doc_entity_tags(doc))
            if nounphrase:
                tags, n = doc_nounphrase_tags(doc)
                cols["nounphrase"].extend(tags)
                n_nounphrases += n
        return {"columns": cols, "attributes": extra, "n_nounphrases": n_nounphrases}

    def tokenize(self, texts, docnames, turn_off_pipes = True,
                 remove_punct = False,
                 remove_numbers = False,
                 remove_url = False,
                 remove_separators = True,
                 remove_symbols = False,
                 padding = False,
                 batch_size = None,
                 n_process = 1):
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
            for id_, doc in self.docs(texts, docnames, batch_size, n_process):
                tokens_out[id_] = doc_tokens(doc, padding,
                                             remove_separators = remove_separators,
                                             remove_punct = remove_punct,
                                             remove_numbers = remove_numbers,
                                             remove_url = remove_url,
                                             remove_symbols = remove_symbols)
            return tokens_out

    def tokenize_sentence(self, texts, docnames, remove_separators = False,
                          batch_size = None, n_process = 1):
        texts, docnames = _as_list(texts, docnames)
        tokens_out = {}
        for id_, doc in self.docs(texts, docnames, batch_size, n_process):
            tokens_out[id_] = doc_sentences(doc, remove_separators)
        return tokens_out

    def extract_nounphrases_list(self, texts, docnames, batch_size = None, n_process = 1):
        return self.extract_np_ne_list(texts, docnames, what = "noun_chunks",
                                       batch_size = batch_size, n_process = n_process)

    def extract_entity_list(self, texts, docnames, ent_type_category = "all",
                            batch_size = None, n_process = 1):
        return self.extract_np_ne_list(texts, docnames, what = "ents",
                                       ent_type_category = ent_type_category,
                                       batch_size = batch_size, n_process = n_process)

    def extract_np_ne_list(self, texts, docnames, what = "noun_chunks", ent_type_category = 'all',
                           batch_size = None, n_process = 1):
        texts, docnames = _as_list(texts, docnames)
        items = {}
        for id_, doc in self.docs(texts, docnames, batch_size, n_process):
            items[id_] = doc_span_texts(doc, what, ent_type_category)
        return items

    def extract_nounphrases_dataframe(self, docnames, texts = [], timestamps = [],
                                      batch_size = None, n_process = 1):
        return self.extract_np_ne_dataframe(docnames, texts, timestamps, what = "noun_chunks",
                                            batch_size = batch_size, n_process = n_process)

    def extract_entity_dataframe(self, docnames, texts = [], timestamps = [],
                                 batch_size = None, n_process = 1):
        return self.extract_np_ne_dataframe(docnames, texts, timestamps, what = "ents",
                                            batch_size = batch_size, n_process = n_process)

    def extract_np_ne_dataframe(self, docnames, texts = [], timestamps = [], what = "noun_chunks",
                                batch_size = None, n_process = 1):
        if timestamps:
            # documents already parsed by parse()
            if isinstance(timestamps, list) == False:
                timestamps = [timestamps]
                docnames = [docnames]
            docs = zip(docnames, (self.documents[ts] for ts in timestamps))
        else:
            texts, docnames = _as_list(texts, docnames)
            docs = self.docs(texts, docnames, batch_size, n_process)
        df_all = {}
        for id_, doc in docs:
            df_doc = doc_span_table(doc, what)
            # documents without spans are left out; R would drop them anyway
            if len(df_doc['text']) == 0:
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
