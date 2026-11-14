# -*- coding: utf-8 -*-
# Sources:
#  Google universal: http://www.petrovi.de/data/universal.pdf
#  Penn treebank: http://web.mit.edu/6.863/www/PennTreebankTags.html
# Requires installation of spaCy: https://honnibal.github.io/spaCy/
import spacy
from spacy.matcher import Matcher, PhraseMatcher, DependencyMatcher
from spacy.tokens import Doc
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
    # groups, since merging renumbers them, which changes backreferences;
    # and one on "_", where REGEX is the name of a custom attribute whose
    # value must equal the string, not an operator
    if not isinstance(pattern, list) or len(pattern) != 1 or len(pattern[0]) != 1:
        return None
    (attr, value), = pattern[0].items()
    if attr == "_":
        return None
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

def retokenizers(nlp):
    # the active components that change the tokens, as merge_entities does
    return [name for name in nlp.pipe_names if retokenizes(nlp, name)]

# What spacy_parse() needs to know of a component to leave it out of a call:
# what it sets, what it may read of what earlier components set, and whether
# it can be left out at all. These are kinds of annotation, of which
# spacy_parse() returns some: the tags (TAG, POS and MORPH), the lemmas, the
# dependencies, the sentences and the entities; "other" is anything else.
_ALL_KINDS = {"tags", "lemma", "deps", "sents", "ents", "other"}
_ATTR_KINDS = {"TAG": "tags", "POS": "tags", "MORPH": "tags",
               "LEMMA": "lemma",
               "DEP": "deps", "HEAD": "deps",
               "SENT_START": "sents", "IS_SENT_START": "sents",
               "IS_SENT_END": "sents",
               "ENT_TYPE": "ents", "ENT_IOB": "ents", "ENT_ID": "ents",
               "ENT_KB_ID": "ents"}

def _attr_name(key):
    # the name of a token attribute, which spaCy also accepts as its number
    if isinstance(key, int):
        from spacy.attrs import NAMES
        return NAMES[key]
    return str(key).upper()

def _ruler_effects(ruler):
    # What the rules of an attribute ruler set, and what their patterns ask
    # for. spaCy's English models, for instance, have rules that set the
    # dependency of whitespace tokens as well as the tags. An attribute that
    # is none of those above is "other" when a rule sets it, if it is one
    # of a token's text, and otherwise may stand for any annotation, set and
    # read, as an extension attribute with a setter can. In a pattern,
    # the annotations above matter, and not the attributes of the token's
    # text, such as LOWER (_TEXT_ATTRS); any other attribute, such as an
    # extension attribute, may stand for any annotation.
    sets, reads = set(), set()
    for rule in ruler.patterns:
        for key in rule["attrs"]:
            name = _attr_name(key)
            if name in _ATTR_KINDS:
                sets.add(_ATTR_KINDS[name])
            elif name in _TEXT_ATTRS:
                sets.add("other")
            else:
                # an attribute that is not known, such as an extension
                # attribute ("_"), whose setter is a function that may read
                # and set any annotation
                sets |= _ALL_KINDS
                reads |= _ALL_KINDS
        for pattern in rule["patterns"]:
            for token in pattern:
                for key in token:
                    name = _attr_name(key)
                    if name in _ATTR_KINDS:
                        reads.add(_ATTR_KINDS[name])
                    elif name not in _TEXT_ATTRS:
                        # an attribute that is not known, such as an
                        # extension attribute ("_"), whose function may
                        # read any annotation
                        reads |= _ALL_KINDS
    return sets, reads

# The architectures whose inputs _model_reads() can tell from their settings
_KNOWN_ARCHITECTURES = ("spacy.", "spacy-legacy.", "spacy-transformers.",
                        "spacy-curated-transformers.")

def _model_reads(model):
    # What the model of a trainable component may read of what earlier
    # components set, from its settings. A model reads the attributes that
    # it embeds, which are those of the token's text by default (NORM,
    # PREFIX, SUFFIX and SHAPE), but can be set to others, such as POS: the
    # attrs of spaCy's MultiHashEmbed, the feature of its CharacterEmbed and
    # the columns of its FeatureExtractor. A model built by a function that
    # is not spaCy's own, or whose settings are not as expected, may read
    # anything.
    reads = set()
    def kinds(attrs):
        for attr in attrs:
            kind = _ATTR_KINDS.get(_attr_name(attr))
            if kind is not None:
                reads.add(kind)
    def scan(node):
        if isinstance(node, dict):
            for key, value in node.items():
                if str(key).startswith("@"):
                    if not str(value).startswith(_KNOWN_ARCHITECTURES):
                        raise ValueError(value)
                elif key in ("attrs", "columns"):
                    if not isinstance(value, (list, tuple)) or \
                            not all(isinstance(v, (str, int)) for v in value):
                        raise ValueError(key)
                    kinds(value)
                elif key == "feature":
                    if not isinstance(value, (str, int)):
                        raise ValueError(key)
                    kinds([value])
                else:
                    scan(value)
        elif isinstance(node, (list, tuple)):
            for value in node:
                scan(value)
    try:
        scan(model)
    except Exception:
        return set(_ALL_KINDS)
    return reads

def _pipe_effects(nlp, name, factory):
    # As _factory_effects(), with what the component's model may read
    effects = _factory_effects(nlp, name, factory)
    if effects is None:
        return None
    sets, reads, can_leave_out = effects
    try:
        model = nlp.get_pipe_config(name).get("model")
    except Exception:
        return sets, set(_ALL_KINDS), can_leave_out
    if model is not None:
        reads = reads | _model_reads(model)
    return sets, reads, can_leave_out

def _factory_effects(nlp, name, factory):
    # (what it sets, what it may read, whether it can be left out) for a
    # component of spaCy's, by the name of its factory, or None for a
    # component that is not one of these. tok2vec and transformer, which
    # other components share, and the components that set sentences are
    # never left out: without the parser, sentences would come from another
    # component, with other boundaries. The lemmatizer reads the tags, ner
    # keeps the entities that are already set, and the rules of an entity
    # ruler can ask for any attribute. What a component's model reads
    # besides is added by _pipe_effects().
    if factory in ("tok2vec", "transformer"):
        return set(), set(), False
    if factory in ("parser", "beam_parser"):
        return {"deps", "sents"}, set(), False
    if factory in ("senter", "sentencizer"):
        return {"sents"}, set(), False
    if factory in ("tagger", "morphologizer"):
        return {"tags"}, set(), True
    if factory in ("lemmatizer", "trainable_lemmatizer"):
        return {"lemma"}, {"tags"}, True
    if factory in ("ner", "beam_ner"):
        return {"ents"}, {"ents"}, True
    if factory == "entity_ruler":
        return {"ents"}, set(_ALL_KINDS), True
    if factory == "attribute_ruler":
        try:
            sets, reads = _ruler_effects(nlp.get_pipe(name))
        except Exception:
            # rules that cannot be read: it stays, and so does all before it
            return set(_ALL_KINDS), set(_ALL_KINDS), False
        return sets, reads, True
    return None

def unneeded_pipes(nlp, lemma = True, pos = True, tag = False,
                   entity = True, nounphrase = False, attributes = None,
                   dependency = False):
    # The names of the active components that a call of spacy_parse() with
    # these options can leave out without changing its output (see
    # pipes_unneeded_for()). The call uses the tags for pos, tag and the
    # noun phrases, which need the part of speech; the lemmas for lemma; the
    # entities for entity; and the dependencies for dependency and the noun
    # phrases. Nothing is left out when additional attributes are asked
    # for, which any component may set.
    if attributes:
        return []
    used = set()
    if pos or tag:
        used.add("tags")
    if lemma:
        used.add("lemma")
    if entity:
        used.add("ents")
    if dependency:
        used.add("deps")
    if nounphrase:
        chunks = spans_use(nlp, "noun_chunks")
        if chunks is None:
            return []
        used |= chunks
    return pipes_unneeded_for(nlp, used)

def spans_use(nlp, what):
    # The kinds of annotation that the extractors use: the entities, or for
    # the noun phrases what the language's noun chunk iterator reads. Those
    # of spaCy's languages, in spacy.lang.<language>.syntax_iterators, read
    # the dependencies and the tags. A pipeline can have another, set as
    # Vocab.get_noun_chunks, which may read anything, such as the lemmas:
    # None then, for which nothing is left out.
    if what == "ents":
        return {"ents"}
    iterator = nlp.vocab.get_noun_chunks
    module = str(getattr(iterator, "__module__", ""))
    if iterator is not None and module.startswith("spacy.lang.") and \
            module.endswith(".syntax_iterators"):
        return {"tags", "deps"}
    return None

def _own_tokenizer(nlp):
    # Whether the documents are made by spaCy's own code: a language class
    # and a tokenizer of spaCy's. Another tokenizer can do more than split
    # the text. It can give each document functions of its own, such as
    # Doc.user_hooks["sents"], by which doc.sents then finds the sentences,
    # and such a function may read any annotation, such as the part of
    # speech. That cannot be told from the pipeline's components.
    def own(obj):
        return str(type(obj).__module__).split(".")[0] == "spacy"
    return own(nlp) and own(nlp.tokenizer)

# The attributes of a token pattern that are those of the token's text, or
# of the pattern itself, and need no component. NORM is one: a component
# that sets it sets "other", and so is never left out.
_TEXT_ATTRS = {"ORTH", "TEXT", "LOWER", "NORM", "LENGTH", "SHAPE", "PREFIX",
               "SUFFIX", "SPACY", "IS_ALPHA", "IS_ASCII", "IS_DIGIT",
               "IS_LOWER", "IS_UPPER", "IS_TITLE", "IS_PUNCT", "IS_SPACE",
               "IS_STOP", "IS_BRACKET", "IS_QUOTE", "IS_LEFT_PUNCT",
               "IS_RIGHT_PUNCT", "IS_CURRENCY", "LIKE_NUM", "LIKE_URL",
               "LIKE_EMAIL", "OP"}

def match_use(patterns, dependency):
    # The kinds of annotation that the patterns of spacy_match() ask for:
    # patterns holds, for each label, its alternative token patterns, and
    # dependency the dependency patterns, as match_table() takes them.
    # Phrases are matched on the text of the tokens, and use none. A
    # dependency pattern uses the dependencies. None, for which nothing is
    # left out, when a pattern asks for an attribute that is not known
    # here, such as an extension attribute ("_").
    used = set()
    def tokens_use(tokens):
        for token in tokens:
            for key in token:
                name = _attr_name(key)
                if name in _ATTR_KINDS:
                    used.add(_ATTR_KINDS[name])
                elif name not in _TEXT_ATTRS:
                    return False
        return True
    try:
        for alternatives in patterns or []:
            for pattern in alternatives:
                if not tokens_use(pattern):
                    return None
        for p in dependency or []:
            used.add("deps")
            if not tokens_use([node.get("RIGHT_ATTRS", {}) for node in p["pattern"]]):
                return None
    except Exception:
        return None
    return used

def pipes_unneeded_for(nlp, used):
    # The names of the active components that a call can leave out without
    # changing its output, when its output uses only these kinds of
    # annotation, and the sentences, which every call uses. A component can
    # be left out when the call uses nothing of what it sets, and no later
    # component that stays may read it. Nothing is left out when the
    # pipeline has a component that is not one of spaCy's that
    # _factory_effects() knows, which may read or change anything; when
    # its tokenizer or its language class is not spaCy's (see
    # _own_tokenizer()); or when what the call uses is not known (None).
    if used is None or not _own_tokenizer(nlp):
        return []
    names = nlp.pipe_names
    effects = {}
    for name in names:
        meta = _pipe_meta(nlp, name)
        effects[name] = _pipe_effects(nlp, name,
                                      meta.factory if meta is not None else None)
        if effects[name] is None:
            return []
    unused = {"tags", "lemma", "ents", "deps"} - set(used)
    out = set(name for name in names
              if effects[name][2] and effects[name][0] <= unused)
    changed = True
    while changed:
        changed = False
        for i, name in enumerate(names):
            if name in out and any(later not in out and
                                   effects[name][0] & effects[later][1]
                                   for later in names[i + 1:]):
                out.discard(name)
                changed = True
    return [name for name in names if name in out]

def lower_strings(nlp, strings):
    # each string in lower case as the vocabulary has it in LOWER, which is
    # what a phrase matcher on LOWER compares
    if isinstance(strings, str):
        strings = [strings]
    return [nlp.vocab[s].lower_ for s in strings]

def filter_overlaps(matches, greedy):
    # Keep one of the overlapping matches of each label, as spaCy's Matcher
    # does with greedy = "FIRST" or "LONGEST": the matches of a label are
    # taken in order of their start (the longest of those with the same
    # start first), or of their length (the earliest of those with the same
    # length first), and a match is kept when none of its tokens is in a
    # match already kept. matches are (label, start, end) tuples.
    by_label = {}
    for label, start, end in matches:
        by_label.setdefault(label, []).append((start, end))
    kept = []
    for label, pairs in by_label.items():
        if greedy == "FIRST":
            pairs.sort(key = lambda x: (x[0], -x[1]))
        else:
            pairs.sort(key = lambda x: (x[1] - x[0], -x[0]), reverse = True)
        taken = set()
        for start, end in pairs:
            if taken.isdisjoint(range(start, end)):
                kept.append((label, start, end))
                taken.update(range(start, end))
    return kept

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

def doc_span_table(doc, what, offsets = None):
    # offsets holds the positions of the document's tokens in its input, as
    # doc_token_offsets() gives them, for the start and end of each span
    if what == "noun_chunks":
        df_doc = {"text": [], "root_text": [], "start_id": [], "root_id":[], "length": []}
    else:
        df_doc = {"text": [], "ent_type": [], "start_id": [], "length": []}
    if offsets is not None:
        starts, ends = offsets
        df_doc["start"] = []
        df_doc["end"] = []
    for chunk in getattr(doc, what):
        df_doc['text'].append(chunk.text)
        df_doc['start_id'].append(chunk[0].i)
        df_doc['length'].append(len(chunk))
        if offsets is not None:
            df_doc["start"].append(starts[chunk.start])
            df_doc["end"].append(ends[chunk.end - 1])
        if what == "noun_chunks":
            df_doc['root_text'].append(chunk.root.text)
            df_doc['root_id'].append(chunk.root.i)
        else:
            df_doc['ent_type'].append(chunk.label_)
    return df_doc

def doc_token_offsets(doc, text, id_):
    # The positions in text, the input of the document, of the first and
    # the last character of each token, counted from 1 in code points, as R
    # counts characters. Token.idx is a position in doc.text, which is the
    # input when the tokenizer is spaCy's rule-based one. Other tokenizers,
    # such as the one for Korean, can build the document with other
    # whitespace than the input has. Its tokens are then looked for in the
    # input, in order, with nothing but whitespace before, between and
    # after them.
    if doc.text == text:
        starts = [w.idx + 1 for w in doc]
        return starts, [w.idx + len(w.text) for w in doc]
    changed = ("offsets = TRUE needs the tokens as they are in the input, "
               "but the tokenizer changed the text of document '%s': " % id_)
    starts, ends = [], []
    cursor = 0
    for w in doc:
        at = text.find(w.text, cursor)
        if at < 0 or text[cursor:at].strip() != "":
            raise ValueError(
                changed + "token %d, '%s', is not at its place in the input"
                % (w.i + 1, w.text))
        starts.append(at + 1)
        cursor = at + len(w.text)
        ends.append(cursor)
    if text[cursor:].strip() != "":
        raise ValueError(
            changed + "the input has text after the last token"
            if len(doc) > 0 else
            changed + "the input has text, but the document has no tokens")
    return starts, ends

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
        # the components that the last call left out
        self.disabled = []

    def docs(self, texts, ids, batch_size = None, n_process = 1):
        # Parse the texts, in order, with spaCy's nlp.pipe(), which processes
        # them in batches and calls each component's pipe() method rather
        # than its __call__() (see tests/testthat/test-pipeline-paths.R).
        # Yields (id, doc) pairs. nlp.pipe() leaves out a document when a
        # component fails on it and the pipeline's error handler suppresses
        # the error; the ids of documents left out are stored in self.skipped.
        # batch_size and n_process are passed to nlp.pipe(): None uses the
        # pipeline's default batch size, and n_process = -1 uses all CPUs.
        self.skipped = []
        if n_process == 1 or self.needs_document_ids():
            # each id travels with its text through the pipeline, which
            # keeps the names if documents are left out or reordered
            seen = set()
            for doc, id_ in self.nlp.pipe(zip(texts, ids), as_tuples = True,
                                         batch_size = batch_size, n_process = n_process):
                seen.add(id_)
                yield id_, doc
            self.skipped = [id_ for id_ in ids if id_ not in seen]
            return
        # With more than one process, ids that travel with the texts are
        # costly: nlp.pipe() then makes each document in this process and
        # sends it to the others, instead of sending its text (#289).
        # Here the pipeline is expected to return one document per text in
        # input order. Check the count before returning results to R.
        # A text longer than nlp.max_length gives spaCy's error here, as with
        # one process, rather than wrapped in that of another process.
        max_length = getattr(self.nlp, "max_length", None)
        if max_length is not None:
            for text in texts:
                if len(text) > max_length:
                    self.nlp.make_doc(text)
        n = 0
        for doc in self.nlp.pipe(texts, batch_size = batch_size, n_process = n_process):
            n += 1
            if n > len(ids):
                break
            yield ids[n - 1], doc
        if n == len(ids):
            return
        raise ValueError(
            "spaCy's pipeline did not return one document for each text, so "
            "the documents cannot be matched to their names; "
            "use n_process = 1 for this pipeline")

    def needs_document_ids(self):
        # Custom error handlers can suppress failures. Custom components
        # can also reorder or omit documents in pipe() without raising.
        # Use positional IDs only with spaCy's built-in components and
        # default error handlers.
        try:
            from spacy.util import raise_error
        except ImportError:
            return True
        if getattr(self.nlp, "default_error_handler", None) is not raise_error:
            return True
        for _, proc in self.nlp.pipeline:
            # a component with no module name counts as a custom one
            module = str(getattr(proc, "__module__", type(proc).__module__))
            if not (module.startswith("spacy.pipeline.") or
                    module.startswith("spacy.lang.") and module.endswith(".lemmatizer")):
                return True
            if hasattr(proc, "get_error_handler") and \
                    proc.get_error_handler() is not raise_error:
                return True
        return False

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
                    attributes = None, batch_size = None, n_process = 1,
                    offsets = False):
        # The columns of spacy_parse(), built in one pass over the documents
        # as they are parsed. Token and sentence ids start at 1, and
        # head_token_id is the position of the head in its sentence. start
        # and end are the positions of a token's first and last characters
        # in the input text (see doc_token_offsets()).
        texts, docnames = _as_list(texts, docnames)
        if attributes is None:
            attributes = []
        elif not isinstance(attributes, list):
            attributes = [attributes]
        cols = {"doc_id": [], "sentence_id": [], "token_id": [], "token": []}
        if offsets:
            cols["start"] = []
            cols["end"] = []
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
        if offsets:
            inputs = dict(zip(docnames, texts))
        # the components that these options do not need are left out for the
        # call; the context manager restores them even if parsing fails
        disabled = unneeded_pipes(self.nlp, lemma = lemma, pos = pos, tag = tag,
                                  entity = entity, nounphrase = nounphrase,
                                  attributes = attributes,
                                  dependency = dependency)
        self.disabled = disabled
        with self.nlp.select_pipes(disable = disabled):
            for id_, doc in self.docs(texts, docnames, batch_size, n_process):
                if offsets:
                    starts, ends = doc_token_offsets(doc, inputs[id_], id_)
                for sent_id, sent in enumerate(doc.sents, 1):
                    for token_id, w in enumerate(sent, 1):
                        cols["doc_id"].append(id_)
                        cols["sentence_id"].append(sent_id)
                        cols["token_id"].append(token_id)
                        cols["token"].append(w.text)
                        if offsets:
                            cols["start"].append(starts[w.i])
                            cols["end"].append(ends[w.i])
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
        return {"columns": cols, "attributes": extra, "n_nounphrases": n_nounphrases,
                "disabled": disabled}

    def tokenize(self, texts, docnames, turn_off_pipes = True,
                 remove_punct = False,
                 remove_numbers = False,
                 remove_url = False,
                 remove_separators = True,
                 remove_symbols = False,
                 padding = False,
                 batch_size = None,
                 n_process = 1):
        # The tokens need no component of the pipeline, except with
        # remove_symbols, which reads the part of speech: then only the
        # components that it does not need are left out (see
        # pipes_unneeded_for()). The context manager restores them even if
        # tokenization fails.
        if remove_symbols:
            self.disabled = pipes_unneeded_for(self.nlp, {"tags"})
        elif turn_off_pipes:
            self.disabled = list(self.nlp.pipe_names)
        else:
            self.disabled = []
        texts, docnames = _as_list(texts, docnames)
        if self.disabled:
            pipes_context = self.nlp.select_pipes(disable = self.disabled)
        else:
            pipes_context = contextlib.nullcontext()
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
        # sentences need only the components that set them, or that those
        # may read: the others are left out for the call
        self.disabled = pipes_unneeded_for(self.nlp, set())
        with self.nlp.select_pipes(disable = self.disabled):
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
        # the components that the spans do not need are left out for the
        # call; the context manager restores them even if it fails
        self.disabled = pipes_unneeded_for(self.nlp, spans_use(self.nlp, what))
        with self.nlp.select_pipes(disable = self.disabled):
            for id_, doc in self.docs(texts, docnames, batch_size, n_process):
                items[id_] = doc_span_texts(doc, what, ent_type_category)
        return items

    def extract_nounphrases_dataframe(self, docnames, texts = [], timestamps = [],
                                      batch_size = None, n_process = 1,
                                      offsets = False):
        return self.extract_np_ne_dataframe(docnames, texts, timestamps, what = "noun_chunks",
                                            batch_size = batch_size, n_process = n_process,
                                            offsets = offsets)

    def extract_entity_dataframe(self, docnames, texts = [], timestamps = [],
                                 batch_size = None, n_process = 1,
                                 offsets = False):
        return self.extract_np_ne_dataframe(docnames, texts, timestamps, what = "ents",
                                            batch_size = batch_size, n_process = n_process,
                                            offsets = offsets)

    def extract_np_ne_dataframe(self, docnames, texts = [], timestamps = [], what = "noun_chunks",
                                batch_size = None, n_process = 1, offsets = False):
        # offsets adds the positions of each span's first and last characters
        # in the input text (see doc_token_offsets()). They need the texts,
        # so not the documents already parsed by parse().
        inputs = None
        self.disabled = []
        if timestamps:
            # documents already parsed by parse()
            if isinstance(timestamps, list) == False:
                timestamps = [timestamps]
                docnames = [docnames]
            docs = zip(docnames, (self.documents[ts] for ts in timestamps))
        else:
            texts, docnames = _as_list(texts, docnames)
            docs = self.docs(texts, docnames, batch_size, n_process)
            if offsets:
                inputs = dict(zip(docnames, texts))
            # the components that the spans do not need are left out for
            # the call; the context manager restores them even if it fails
            self.disabled = pipes_unneeded_for(self.nlp, spans_use(self.nlp, what))
        df_all = {}
        # documents already parsed need no pipeline, which their handle
        # does not keep
        if self.disabled:
            pipes_context = self.nlp.select_pipes(disable = self.disabled)
        else:
            pipes_context = contextlib.nullcontext()
        with pipes_context:
            for id_, doc in docs:
                if inputs is None:
                    df_doc = doc_span_table(doc, what)
                else:
                    df_doc = doc_span_table(doc, what,
                                            doc_token_offsets(doc, inputs[id_], id_))
                # documents without spans are left out; R would drop them anyway
                if len(df_doc['text']) == 0:
                    continue
                df_all[id_] = df_doc
        return df_all

    def match_table(self, texts, docnames, labels, patterns, phrases = None,
                    dependency = None, greedy = None, batch_size = None,
                    n_process = 1, offsets = False):
        # The columns of spacy_match(): one row for each match of a sequence
        # of tokens, and one row for each node of each match of a dependency
        # pattern, from one pass over the documents.
        # labels holds every label, in the order that sorts matches; patterns
        # is parallel to it, with the alternative token patterns of each
        # label, which may be none; phrases is a list of dicts with the label,
        # case_insensitive and either the text or the words of each phrase;
        # and dependency a list of
        # dicts with the label and the one dependency pattern of each label
        # that has one.
        # Token patterns are matched by spaCy's Matcher, after merging those
        # of a single regular expression as for the entity ruler. Phrases are
        # matched by its PhraseMatcher, which is far faster for many phrases
        # than token patterns: on the tokens' text (ORTH), or on their lower
        # case form (LOWER) for phrases marked case_insensitive. A phrase
        # given as text is tokenized by the pipeline's own tokenizer; one
        # given as words is a document of those words as its tokens, so that
        # the caller sets the token boundaries. The same span found
        # for a label by more than one pattern or matcher is one match.
        # Overlapping matches of a label are filtered here (greedy "FIRST" or
        # "LONGEST"), over the matches of these matchers together.
        # Dependency patterns are matched by spaCy's DependencyMatcher, which
        # returns a label and one token for each node of the pattern, in the
        # order of the nodes; that would not say which of several patterns of
        # a label had matched, so a label has one. The nodes are named by
        # their RIGHT_ID. A pattern with relations between nodes needs the
        # dependency parse: without it, spaCy gives an error (E155) only when
        # a node asks for an attribute such as DEP, and otherwise finds
        # nothing, as if the document had no match. So a document with tokens
        # and no dependency annotation is an error, whichever component would
        # have set it. greedy does not apply to these matches.
        # The matchers run here, on each document as nlp.pipe() returns it,
        # also when n_process > 1. Labels are read as strings, since match
        # IDs are 64-bit hashes that R cannot hold.
        # spaCy returns matches grouped by label rather than in document
        # order, so each document's matches are sorted by the position of
        # their first row: the first token of a sequence, or the token of the
        # first node of a dependency match. Of those at the same position,
        # sequences come first, by their length and then the order of the
        # labels; then dependency matches, by the positions of their other
        # nodes, in the order of the nodes, and then the order of the labels.
        # match_id numbers them from 1 in that order.
        # start_id counts tokens from 1 in the document; sentence_id and
        # token_id are those of the row's first token, as in spacy_parse(),
        # or 0 when the document has no sentence boundaries. node is "" for a
        # sequence. With offsets, start and end are the positions of the
        # row's first and last characters in the input text (see
        # doc_token_offsets()).
        texts, docnames = _as_list(texts, docnames)
        if not isinstance(labels, list):
            labels = [labels]
            patterns = [patterns]
        vocab = self.nlp.vocab
        matchers = []
        token_patterns = [{"label": label, "pattern": pattern}
                          for label, alternatives in zip(labels, patterns)
                          for pattern in alternatives]
        if token_patterns:
            by_label = {}
            for p in ruler_patterns(self.nlp, token_patterns):
                by_label.setdefault(p["label"], []).append(p["pattern"])
            matcher = Matcher(vocab, validate = True)
            for label, alternatives in by_label.items():
                matcher.add(label, alternatives)
            matchers.append(matcher)
        for lower in (False, True):
            by_label = {}
            for p in phrases or []:
                if bool(p.get("case_insensitive", False)) == lower:
                    if p.get("words") is not None:
                        words = p["words"]
                        if isinstance(words, str):
                            words = [words]
                        phrase = Doc(vocab, words = list(words))
                    else:
                        phrase = self.nlp.make_doc(p["text"])
                    by_label.setdefault(p["label"], []).append(phrase)
            if by_label:
                matcher = PhraseMatcher(vocab, attr = "LOWER" if lower else "ORTH")
                for label, docs in by_label.items():
                    matcher.add(label, docs)
                matchers.append(matcher)
        dependency_matcher = None
        nodes = {}
        for p in dependency or []:
            if dependency_matcher is None:
                dependency_matcher = DependencyMatcher(vocab, validate = True)
            dependency_matcher.add(p["label"], [p["pattern"]])
            nodes[p["label"]] = [node["RIGHT_ID"] for node in p["pattern"]]
        relations = any(len(ids) > 1 for ids in nodes.values())
        order = dict((label, k) for k, label in enumerate(labels))
        strings = vocab.strings
        cols = {"doc_id": [], "match_id": [], "label": [], "node": [],
                "sentence_id": [], "token_id": [], "text": [], "start_id": [],
                "length": []}
        if offsets:
            cols["start"] = []
            cols["end"] = []
            inputs = dict(zip(docnames, texts))
        # the components that the patterns do not need are left out for the
        # call; the context manager restores them even if it fails
        self.disabled = pipes_unneeded_for(
            self.nlp, match_use(patterns, dependency))
        if self.disabled:
            pipes_context = self.nlp.select_pipes(disable = self.disabled)
        else:
            pipes_context = contextlib.nullcontext()
        with pipes_context:
            for id_, doc in self.docs(texts, docnames, batch_size, n_process):
                if offsets:
                    starts, ends = doc_token_offsets(doc, inputs[id_], id_)
                if relations and len(doc) > 0 and not doc.has_annotation("DEP"):
                    raise ValueError(
                        "Document '" + str(id_) + "' has no dependency parse, which "
                        "patterns with relations between nodes need. The pipeline "
                        "needs a parser, or another component that sets dependencies.")
                found = set()
                for matcher in matchers:
                    for key, start, end in matcher(doc):
                        found.add((strings[key], start, end))
                if found and greedy is not None:
                    found = filter_overlaps(found, greedy)
                # (sort key, label, rows), each row the (node, start, end) of a span
                matches = [((start, 0, (end,), order[label]), label, [("", start, end)])
                           for label, start, end in found]
                if dependency_matcher is not None:
                    for key, token_ids in dependency_matcher(doc):
                        label = strings[key]
                        matches.append(((token_ids[0], 1, tuple(token_ids), order[label]),
                                        label,
                                        [(node, i, i + 1)
                                         for node, i in zip(nodes[label], token_ids)]))
                if not matches:
                    continue
                matches.sort(key = lambda m: m[0])
                positions = sentence_positions(doc)
                for match_id, (_, label, rows) in enumerate(matches, 1):
                    for node, start, end in rows:
                        sent_id, token_id = positions[start] if positions else (0, 0)
                        cols["doc_id"].append(id_)
                        cols["match_id"].append(match_id)
                        cols["label"].append(label)
                        cols["node"].append(node)
                        cols["sentence_id"].append(sent_id)
                        cols["token_id"].append(token_id)
                        cols["text"].append(doc[start:end].text)
                        cols["start_id"].append(start + 1)
                        cols["length"].append(end - start)
                        if offsets:
                            cols["start"].append(starts[start])
                            cols["end"].append(ends[end - 1])
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
