# -*- coding: utf-8 -*-
# Sources:
#  Google universal: http://www.petrovi.de/data/universal.pdf
#  Penn treebank: http://web.mit.edu/6.863/www/PennTreebankTags.html
# Requires installation of spaCy: https://honnibal.github.io/spaCy/
import spacy
from spacy.matcher import Matcher, DependencyMatcher
import time
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

from spacy.lang.char_classes import ALPHA as _ALPHA

# a single hyphen joining two letters, or a letter and a digit in either
# order: the boundary that split_hyphens = FALSE keeps within a token
_HYPHEN = "[-\u2010]"
_HYPHEN_JOIN = ("(?:(?<=[{a}]){h}(?=[{a}0-9])|(?<=[0-9]){h}(?=[{a}]))"
                .format(a = _ALPHA, h = _HYPHEN))
_HYPHEN_PROBES = ("a-b", "a-1", "1-a")
_Pattern = type(re.compile(""))

def splits_hyphens(nlp):
    # whether the tokenizer splits a word joined by a hyphen between letters,
    # a digit and a letter, or a letter and a digit, each probed on its own;
    # the tokenizer itself, since nlp.make_doc() checks nlp.max_length
    return any(len(nlp.tokenizer(w)) > 1 for w in ("aa-bb", "2-day", "x-2"))

def keep_hyphens(nlp):
    # Stop the tokenizer splitting words at a single hyphen between letters,
    # or between a letter and a digit, as in "eye-opening" or "X-1". Each of
    # the language's default infix rules that splits one of these is changed
    # so that it no longer matches there, and splits as before everywhere
    # else, as at "3-4", "a--b" or the end of a word. The tokenizer is left as
    # it is when its infix rules are not the language's defaults, as in a
    # model saved with rules of its own, or when they are not a regular
    # expression, as with tokenizers that are not spaCy's rule-based one.
    # Returns whether the tokenizer was changed, whether it still splits
    # hyphenated words, and, when it was changed, the active components with
    # phrase patterns, which were tokenized before the change.
    tokenizer = nlp.tokenizer
    finditer = getattr(tokenizer, "infix_finditer", None)
    owner = getattr(finditer, "__self__", None)
    infixes = list(nlp.Defaults.infixes or [])
    changed = False
    if isinstance(owner, _Pattern) and infixes and \
            owner.pattern == spacy.util.compile_infix_regex(infixes).pattern:
        rules = [_guard_hyphen(x) for x in infixes]
        if rules != infixes:
            before = _probe_tokens(tokenizer)
            tokenizer.infix_finditer = spacy.util.compile_infix_regex(rules).finditer
            # a rule may match one of the probes without splitting the word,
            # when other rules keep it whole
            changed = _probe_tokens(tokenizer) != before
            if not changed:
                tokenizer.infix_finditer = finditer
    phrase_rulers = []
    if changed:
        for name, proc in nlp.pipeline:
            if any(isinstance(p.get("pattern"), str) for p in _patterns_of(proc)):
                phrase_rulers.append(name)
    return {"changed": changed, "splits": splits_hyphens(nlp),
            "phrase_rulers": phrase_rulers}

def _probe_tokens(tokenizer):
    return [t.text for t in tokenizer(" ".join("x" + p + "x" for p in _HYPHEN_PROBES))]

def _patterns_of(proc):
    # the patterns of a ruler, such as entity_ruler or span_ruler
    try:
        patterns = proc.patterns
    except Exception:
        return []
    return [p for p in patterns if isinstance(p, dict)] if isinstance(patterns, list) else []

def _guard_hyphen(rule):
    # the rule, unable to match a hyphen that joins a word, if it splits one
    if not any(_matches_hyphen(rule, probe) for probe in _HYPHEN_PROBES):
        return rule
    guarded = "(?!" + _HYPHEN_JOIN + ")(?:" + rule + ")"
    try:
        re.compile(guarded)
    except re.error:
        return rule
    return guarded

def _matches_hyphen(rule, probe):
    try:
        return any(m.start() <= 1 < m.end() for m in re.finditer(rule, probe))
    except re.error:
        return False

def _pipe_meta(nlp, name):
    try:
        return nlp.get_pipe_meta(name)
    except Exception:
        return None

def sets_entities(nlp, name):
    # whether an active component sets entities: spaCy records "doc.ents" in
    # the assigns of ner and entity_ruler, but a span_ruler sets them only
    # when it is configured to annotate entities
    meta = _pipe_meta(nlp, name)
    if meta is not None and "doc.ents" in meta.assigns:
        return True
    return bool(getattr(nlp.get_pipe(name), "annotate_ents", False))

def retokenizes(nlp, name):
    # whether an active component changes the tokens, as merge_entities does
    meta = _pipe_meta(nlp, name)
    return meta is not None and bool(meta.retokenizes)

def free_ruler_name(nlp, name = "spacyr_entity_ruler"):
    # a name used by no component, including disabled ones, so that a
    # pipeline saved with spacyr's ruler can be given another
    used = set(nlp.component_names)
    candidate, k = name, 1
    while candidate in used:
        k += 1
        candidate = name + "_" + str(k)
    return candidate

def ruler_patterns(nlp, patterns, lower_phrases = False):
    # spaCy's form of the patterns from R. A phrase marked case_insensitive is
    # matched by the ruler's phrase matcher on LOWER when lower_phrases is
    # True (all phrases are case-insensitive), and otherwise becomes a token
    # pattern matching the lower case form of each of the tokens that the
    # pipeline's own tokenizer makes of it, which is slower. Patterns of a
    # single token matching a regular expression, as dictionary values with
    # wildcards become, are merged into one per label, ID and attribute,
    # since spaCy checks each regular expression on every token.
    out = []
    regexes = {}
    for p in patterns:
        p = dict(p)
        ci = p.pop("case_insensitive", False)
        if isinstance(p["pattern"], str):
            if ci and not lower_phrases:
                p["pattern"] = [{"LOWER": t.lower_} for t in nlp.make_doc(p["pattern"])]
        else:
            single = _single_regex(p["pattern"])
            if single is not None:
                regexes.setdefault((p["label"], p.get("id"), single[0]), []).append(single[1])
                continue
        out.append(p)
    for (label, id_, attr), rxs in regexes.items():
        rx = rxs[0] if len(rxs) == 1 else "|".join("(?:" + r + ")" for r in rxs)
        p = {"label": label, "pattern": [{attr: {"REGEX": rx}}]}
        if id_ is not None:
            p["id"] = id_
        out.append(p)
    return out

def _single_regex(pattern):
    # (attribute, regular expression) for a pattern of one token with only a
    # REGEX, or None. Left as it is: one with inline flags, which must start a
    # regular expression; one that does not compile; and one with capturing
    # groups, since merging renumbers them, which changes backreferences
    if not isinstance(pattern, list) or len(pattern) != 1 or len(pattern[0]) != 1:
        return None
    (attr, value), = pattern[0].items()
    if not isinstance(value, dict) or list(value.keys()) != ["REGEX"]:
        return None
    rx = value["REGEX"]
    if not isinstance(rx, str) or "(?" in rx:
        return None
    try:
        compiled = re.compile(rx)
    except re.error:
        return None
    if compiled.groups > 0:
        return None
    return attr.upper(), rx

def add_entity_ruler(nlp, patterns, overwrite = True):
    # Add spacyr's entity ruler as the last component of the pipeline, after
    # every component that sets entities, with a name of its own, so that any
    # entity_ruler saved with the model stays in place. Returns the ruler's
    # name, whether a component before it sets entities, the components
    # before it that change the tokens, and whether ner is disabled.
    upstream = [name for name in nlp.pipe_names]
    info = {"sets_entities": any(sets_entities(nlp, n) for n in upstream),
            "retokenizers": [n for n in upstream if retokenizes(nlp, n)],
            "ner_disabled": "ner" in nlp.disabled}
    name = free_ruler_name(nlp)
    phrases = [p for p in patterns if isinstance(p["pattern"], str)]
    lower_phrases = len(phrases) > 0 and all(p.get("case_insensitive", False) for p in phrases)
    config = {"overwrite_ents": bool(overwrite), "validate": True}
    if lower_phrases:
        config["phrase_matcher_attr"] = "LOWER"
    ruler = nlp.add_pipe("entity_ruler", name = name, last = True, config = config)
    # the ruler makes a Doc of each phrase with the components before it;
    # tokenizing is all that matching phrases on ORTH needs
    try:
        with nlp.select_pipes(disable = upstream):
            ruler.add_patterns(ruler_patterns(nlp, patterns, lower_phrases))
    except Exception:
        nlp.remove_pipe(name)
        raise
    info["name"] = name
    return info

def any_sets_entities(nlp):
    # whether any active component of the pipeline sets entities
    return any(sets_entities(nlp, name) for name in nlp.pipe_names)

def sentence_positions(doc):
    # (sentence_id, token_id) of each token, both starting at 1 as in
    # spacy_parse(), or None when the document has no sentence boundaries,
    # since doc.sents then raises E030
    if not doc.has_annotation("SENT_START"):
        return None
    positions = [None] * len(doc)
    for sent_id, sent in enumerate(doc.sents, 1):
        for token_id, w in enumerate(sent, 1):
            positions[w.i] = (sent_id, token_id)
    return positions

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

    def release_pipeline(self):
        # Drop the reference to the pipeline, so that it can be freed (for
        # instance by spacy_finalize()) while the parsed documents are kept.
        # The documents keep only the vocabulary they share with it.
        self.nlp = None

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
        # disable the pipeline components unless they are needed, as for
        # remove_symbols; the context manager restores them even if
        # tokenization fails
        if turn_off_pipes and not remove_symbols:
            pipes_context = self.nlp.select_pipes(disable = self.nlp.pipe_names)
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

    def match_table(self, texts, docnames, labels, patterns, greedy = None,
                    batch_size = None, n_process = 1):
        # The columns of spacy_extract_matches(): one row for each match of
        # spaCy's Matcher. labels and patterns are parallel lists, with the
        # alternative token patterns of each label. The matcher runs here, on
        # each document as nlp.pipe() returns it, also when n_process > 1.
        # Labels are read from the spans, since match IDs are 64-bit hashes
        # that R cannot hold. spaCy returns matches grouped by label rather
        # than in document order, so each document's matches are sorted by
        # their first token, then their length, then the order of the labels.
        # start_id counts tokens from 1 in the document; sentence_id and
        # token_id are those of the first token, as in spacy_parse(), or 0
        # when the document has no sentence boundaries.
        texts, docnames = _as_list(texts, docnames)
        if not isinstance(labels, list):
            labels = [labels]
            patterns = [patterns]
        matcher = Matcher(self.nlp.vocab, validate = True)
        for label, alternatives in zip(labels, patterns):
            matcher.add(label, alternatives, greedy = greedy)
        order = dict((label, k) for k, label in enumerate(labels))
        cols = {"doc_id": [], "sentence_id": [], "token_id": [], "label": [],
                "text": [], "start_id": [], "length": []}
        for id_, doc in self.docs(texts, docnames, batch_size, n_process):
            spans = matcher(doc, as_spans = True)
            if not spans:
                continue
            spans.sort(key = lambda s: (s.start, s.end, order[s.label_]))
            positions = sentence_positions(doc)
            for span in spans:
                sent_id, token_id = positions[span.start] if positions else (0, 0)
                cols["doc_id"].append(id_)
                cols["sentence_id"].append(sent_id)
                cols["token_id"].append(token_id)
                cols["label"].append(span.label_)
                cols["text"].append(span.text)
                cols["start_id"].append(span.start + 1)
                cols["length"].append(span.end - span.start)
        return cols

    def dependency_match_table(self, texts, docnames, labels, patterns,
                               batch_size = None, n_process = 1):
        # The columns of spacy_extract_dependency_matches(): one row for each
        # token of each match of spaCy's DependencyMatcher. labels and
        # patterns are parallel lists, with one pattern for each label: the
        # matcher returns a label and one token for each node of the pattern,
        # in the order of the nodes, which would not say which of several
        # patterns of a label had matched. The nodes are named by their
        # RIGHT_ID. spaCy returns matches grouped by label, so each
        # document's matches are sorted by the positions of their tokens,
        # taken in the order of the nodes, then by the order of the labels,
        # and numbered from 1 in that order. Positions are as in match_table().
        # A pattern with relations between nodes needs the dependency parse:
        # without it, spaCy gives an error (E155) only when a node asks for
        # an attribute such as DEP, and otherwise finds nothing, as if the
        # document had no match. So a document with tokens and no dependency
        # annotation is an error, whichever component would have set it.
        texts, docnames = _as_list(texts, docnames)
        if not isinstance(labels, list):
            labels = [labels]
            patterns = [patterns]
        matcher = DependencyMatcher(self.nlp.vocab, validate = True)
        nodes = {}
        for label, pattern in zip(labels, patterns):
            matcher.add(label, [pattern])
            nodes[label] = [node["RIGHT_ID"] for node in pattern]
        relations = any(len(ids) > 1 for ids in nodes.values())
        order = dict((label, k) for k, label in enumerate(labels))
        strings = self.nlp.vocab.strings
        cols = {"doc_id": [], "match_id": [], "label": [], "node": [],
                "sentence_id": [], "token_id": [], "start_id": [], "token": []}
        for id_, doc in self.docs(texts, docnames, batch_size, n_process):
            if relations and len(doc) > 0 and not doc.has_annotation("DEP"):
                raise ValueError(
                    "Document '" + str(id_) + "' has no dependency parse, which "
                    "patterns with relations between nodes need. The pipeline "
                    "needs a parser, or another component that sets dependencies.")
            matches = [(strings[key], token_ids) for key, token_ids in matcher(doc)]
            if not matches:
                continue
            matches.sort(key = lambda m: (m[1], order[m[0]]))
            positions = sentence_positions(doc)
            for match_id, (label, token_ids) in enumerate(matches, 1):
                for node, i in zip(nodes[label], token_ids):
                    sent_id, token_id = positions[i] if positions else (0, 0)
                    cols["doc_id"].append(id_)
                    cols["match_id"].append(match_id)
                    cols["label"].append(label)
                    cols["node"].append(node)
                    cols["sentence_id"].append(sent_id)
                    cols["token_id"].append(token_id)
                    cols["start_id"].append(i + 1)
                    cols["token"].append(doc[i].text)
        return cols

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

    def attributes(self, timestamps, attrname):
        all_attrs = []
        if isinstance(timestamps, list) == False:
            timestamps = [timestamps]
        for ts in timestamps:
            c_document = self.documents[ts]
            attrs = []
            for w in c_document:
                attrs.append(getattr(w, attrname))
            all_attrs.extend(attrs)
        return all_attrs

    def tokens(self, timestamps):
        all_tokens = self.attributes(timestamps, 'text')
        return all_tokens

    def tags(self, timestamps, tag_type):
        if isinstance(timestamps, list) == False:
            timestamps = [timestamps]
        attr_name = "tag_" if tag_type == "detailed" else "pos_"
        all_tokens = self.attributes(timestamps, attr_name)
        return all_tokens

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
