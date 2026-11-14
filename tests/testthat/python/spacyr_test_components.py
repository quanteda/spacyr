# A pipeline component for the tests, which records whether spaCy called it
# per document (__call__) or in batches (pipe()). It replaces the document's
# entities with one entity at its start, labelled "VIA_CALL" and one token
# long, or labelled "VIA_PIPE" and two tokens long (so that the path also
# shows in entity text), and sets the first token's norm_ to the label.
from spacy.language import Language
from spacy.tokens import Span

def _mark(doc, label, length):
    if len(doc) > 0:
        doc.ents = [Span(doc, 0, min(length, len(doc)), label = label)]
        doc[0].norm_ = label
    return doc

class PathMarker:
    def __call__(self, doc):
        return _mark(doc, "VIA_CALL", 1)

    def pipe(self, docs, batch_size = 128):
        for doc in docs:
            yield _mark(doc, "VIA_PIPE", 2)

if not Language.has_factory("spacyr_test_path_marker"):
    @Language.factory("spacyr_test_path_marker")
    def make_path_marker(nlp, name):
        return PathMarker()

# A component that fails on documents whose text starts with "Bad". It has no
# pipe() method, so in nlp.pipe() spaCy passes its errors to the pipeline's
# error handler; with skip_errors(nlp), the failing documents are left out of
# the output instead of stopping it.
class FailOnBad:
    def __call__(self, doc):
        if doc.text.startswith("Bad"):
            raise ValueError("spacyr test component: bad document")
        return doc

if not Language.has_factory("spacyr_test_fail_on_bad"):
    @Language.factory("spacyr_test_fail_on_bad")
    def make_fail_on_bad(nlp, name):
        return FailOnBad()

def _ignore_error(proc_name, proc, docs, e):
    pass

def skip_errors(nlp):
    # only the default handler: some built-in components do not accept one
    nlp.default_error_handler = _ignore_error

class ReverseBatch:
    def __call__(self, doc):
        return doc

    def pipe(self, docs, batch_size = 128):
        yield from reversed(list(docs))

if not Language.has_factory("spacyr_test_reverse_batch"):
    @Language.factory("spacyr_test_reverse_batch")
    def make_reverse_batch(nlp, name):
        return ReverseBatch()

# A stand-in for a pipeline that returns one document fewer (change < 0) or
# one more than the texts it is given, though its error handlers raise.
class WrongCount:
    pipeline = []
    max_length = 1000000

    def __init__(self, nlp, change):
        from spacy.util import raise_error
        self.default_error_handler = raise_error
        self.nlp = nlp
        self.change = change

    def make_doc(self, text):
        return self.nlp.make_doc(text)

    def pipe(self, texts, **kwargs):
        texts = list(texts)
        texts = texts[1:] if self.change < 0 else texts + texts[:1]
        return (self.nlp.make_doc(text) for text in texts)

# A tokenizer that, like spaCy's tokenizer for Korean, makes the document
# from the words of the text with single spaces between them, so that
# doc.text is not the input when the input has other whitespace. With
# lower = True it also changes the words themselves, and with
# drop_last = True it leaves out the last word.
from spacy.tokens import Doc

class SingleSpaceTokenizer:
    def __init__(self, vocab, lower = False, drop_last = False):
        self.vocab = vocab
        self.lower = lower
        self.drop_last = drop_last

    def __call__(self, text):
        words = text.split()
        if self.lower:
            words = [word.lower() for word in words]
        if self.drop_last:
            words = words[:-1]
        spaces = [True] * len(words)
        if words:
            spaces[-1] = False
        return Doc(self.vocab, words = words, spaces = spaces)

def set_single_space_tokenizer(nlp, lower = False, drop_last = False):
    nlp.tokenizer = SingleSpaceTokenizer(nlp.vocab, lower, drop_last)

# A pipeline of spaCy's own components in which a later model reads what an
# earlier component sets: an attribute ruler that sets the part of speech of
# one word, and an entity recognizer whose model embeds the part of speech
# as well as the form of each token. It is trained for a few steps on one
# text, so that the entity it finds depends on that part of speech.
def save_pos_ner_pipeline(path):
    import random
    import spacy
    from spacy.training import Example
    from thinc.api import fix_random_seed
    fix_random_seed(0)
    random.seed(0)
    nlp = spacy.blank("en")
    nlp.add_pipe("sentencizer")
    ruler = nlp.add_pipe("attribute_ruler")
    tok2vec = {"@architectures": "spacy.Tok2Vec.v2",
               "embed": {"@architectures": "spacy.MultiHashEmbed.v2",
                         "width": 32, "attrs": ["POS"], "rows": [50],
                         "include_static_vectors": False},
               "encode": {"@architectures": "spacy.MaxoutWindowEncoder.v2",
                          "width": 32, "depth": 1, "window_size": 1,
                          "maxout_pieces": 2}}
    nlp.add_pipe("ner", config = {"model": {
        "@architectures": "spacy.TransitionBasedParser.v2",
        "state_type": "ner", "extra_state_tokens": False, "hidden_width": 32,
        "maxout_pieces": 2, "use_upper": True, "nO": None, "tok2vec": tok2vec}})
    texts = [("We saw alpha today.", [(7, 12, "PERSON")]),
             ("They met alpha again.", [(9, 14, "PERSON")]),
             ("Nothing to see here.", [])]
    def examples():
        out = []
        for text, ents in texts:
            # the part of speech is set as the ruler sets it
            doc = nlp.make_doc(text)
            for token in doc:
                if token.lower_ == "alpha":
                    token.pos_ = "PROPN"
            out.append(Example.from_dict(doc, {"entities": ents}))
        return out
    optimizer = nlp.initialize(examples)
    for _ in range(60):
        nlp.update(examples(), sgd = optimizer, drop = 0.0,
                   exclude = ["sentencizer", "attribute_ruler"])
    # after nlp.initialize(), which removes the rules of an attribute ruler
    ruler.add(patterns = [[{"LOWER": "alpha"}]], attrs = {"POS": "PROPN"})
    nlp.to_disk(path)

# A component that does nothing. Since it is not one of spaCy's, no function
# leaves any component out of a pipeline that has it, which gives the output
# of the whole pipeline to compare with.
class NoOp:
    def __call__(self, doc):
        return doc

if not Language.has_factory("spacyr_test_noop"):
    @Language.factory("spacyr_test_noop")
    def make_noop(nlp, name):
        return NoOp()

# A noun chunk iterator that is not spaCy's: the language's own, keeping the
# noun chunks that have a token with this lemma. spaCy lets a pipeline have
# its own iterator in Vocab.get_noun_chunks, which may read any annotation.
def set_lemma_noun_chunks(nlp, lemma = "dog"):
    own = nlp.vocab.get_noun_chunks
    def lemma_noun_chunks(doclike):
        doc = doclike.doc
        for start, end, label in own(doclike):
            if any(token.lemma_ == lemma for token in doc[start:end]):
                yield start, end, label
    nlp.vocab.get_noun_chunks = lemma_noun_chunks

# A tokenizer that is not spaCy's, which wraps the pipeline's own and gives
# each document a function for its sentences (Doc.user_hooks["sents"]): a
# sentence starts at each coordinating conjunction, so the function reads
# the part of speech, which the pipeline's components set afterwards.
def _sents_at_conjunctions(doc):
    start = 0
    for token in doc:
        if token.i > start and token.pos_ == "CCONJ":
            yield doc[start:token.i]
            start = token.i
    if start < len(doc):
        yield doc[start:len(doc)]

class SentenceHookTokenizer:
    def __init__(self, tokenizer):
        self.tokenizer = tokenizer
        self.vocab = tokenizer.vocab

    def __call__(self, text):
        doc = self.tokenizer(text)
        doc.user_hooks["sents"] = _sents_at_conjunctions
        return doc

def set_sentence_hook_tokenizer(nlp):
    nlp.tokenizer = SentenceHookTokenizer(nlp.tokenizer)

# A second attribute ruler, after the lemmatizer, with a rule on an extension
# attribute that reads the lemma: it sets the part of speech INTJ for the
# tokens whose lemma is this one.
def add_lemma_extension_ruler(nlp, lemma = "dog"):
    from spacy.tokens import Token
    Token.set_extension("spacyr_test_has_lemma",
                        getter = lambda token: token.lemma_ == lemma, force = True)
    ruler = nlp.add_pipe("attribute_ruler", name = "spacyr_test_late_ruler",
                         after = "lemmatizer")
    ruler.add(patterns = [[{"_": {"spacyr_test_has_lemma": True}}]],
              attrs = {"POS": "INTJ"})

# A second attribute ruler, after the lemmatizer, with a rule that sets an
# extension attribute, whose setter reads the lemma and sets the part of
# speech: INTJ for "dogs" when its lemma is this one.
def add_lemma_setter_ruler(nlp, lemma = "dog"):
    from spacy.tokens import Token
    def setter(token, value):
        if token.lemma_ == lemma:
            token.pos_ = "INTJ"
    Token.set_extension("spacyr_test_mark", getter = lambda token: False,
                        setter = setter, force = True)
    ruler = nlp.add_pipe("attribute_ruler", name = "spacyr_test_setter_ruler",
                         after = "lemmatizer")
    ruler.add(patterns = [[{"LOWER": "dogs"}]],
              attrs = {"_": {"spacyr_test_mark": True}})

# A small pipeline with word vectors, saved for spacy_initialize(model = ):
# a blank English pipeline with a sentencizer, and vectors of three
# dimensions for a few types. "Cat" has the vector of "cat", as spellings
# share vectors in spaCy's models; no other type has one.
def save_vectors_pipeline(path):
    import numpy
    import spacy
    nlp = spacy.blank("en")
    nlp.add_pipe("sentencizer")
    vectors = {"cat": [1, 0, 0], "Cat": [1, 0, 0], "dog": [0, 1, 0],
               "sat": [0, 0, 1], "the": [0.5, 0.5, 0], ".": [0, 0, 0.25]}
    for text, vector in vectors.items():
        nlp.vocab.set_vector(text, numpy.asarray(vector, dtype = "float32"))
    nlp.meta["name"] = "spacyr_test_vectors"
    nlp.meta["version"] = "0.0.1"
    nlp.to_disk(path)

# An array that stands in for one on a GPU, as CuPy's: NumPy cannot convert
# it by itself, and its get() returns a copy on the host.
class DeviceArray:
    def __init__(self, values):
        import numpy
        self._values = numpy.asarray(values, dtype = "float32")

    def __array__(self, *args, **kwargs):
        raise TypeError("Implicit conversion to a NumPy array is not allowed.")

    def get(self):
        return self._values.copy()

# The same pipeline's vocabulary, returning its vectors as such arrays
def use_device_vectors(nlp):
    vocab = nlp.vocab
    class DeviceVocab:
        vectors = vocab.vectors
        def has_vector(self, text):
            return vocab.has_vector(text)
        def get_vector(self, text):
            return DeviceArray(vocab.get_vector(text))
    class DeviceNlp:
        pass
    stand_in = DeviceNlp()
    stand_in.vocab = DeviceVocab()
    stand_in.meta = nlp.meta
    return stand_in

# A small pipeline whose vectors are those of subwords (floret), saved for
# spacy_initialize(model = ): such a table has a vector for any string, made
# from the vectors of its character n-grams.
def save_floret_pipeline(path):
    import numpy
    import spacy
    from spacy.vectors import Vectors
    nlp = spacy.blank("en")
    nlp.add_pipe("sentencizer")
    data = numpy.arange(1, 31, dtype = "float32").reshape((10, 3)) / 10
    nlp.vocab.vectors = Vectors(data = data, mode = "floret", hash_count = 1,
                                minn = 2, maxn = 3)
    nlp.meta["name"] = "spacyr_test_floret"
    nlp.meta["version"] = "0.0.1"
    nlp.to_disk(path)

# A tokenizer that is not spaCy's, which wraps the pipeline's own and gives
# each document a function for its vector (Doc.user_hooks["vector"]): a
# vector of sevens, of the width of the table.
class VectorHookTokenizer:
    def __init__(self, tokenizer, width = None):
        self.tokenizer = tokenizer
        self.vocab = tokenizer.vocab
        self.width = width

    def __call__(self, text):
        doc = self.tokenizer(text)
        doc.user_hooks["vector"] = _sevens(self.width or self.vocab.vectors.shape[1])
        return doc

class _sevens:
    # a function that can be sent to another process
    def __init__(self, width):
        self.width = width

    def __call__(self, doc):
        import numpy
        return numpy.full(self.width, 7, dtype = "float32")

# width: of the vector of the hook, when not that of the table
def set_vector_hook_tokenizer(nlp, width = None):
    own = getattr(nlp.tokenizer, "tokenizer", nlp.tokenizer)
    nlp.tokenizer = VectorHookTokenizer(own, width)

# The pipeline of save_vectors_pipeline() with a dependency parser that is
# set to merge subtokens (learn_tokens), which changes the tokens of a
# document, and so its vector. The parser is initialized and not trained:
# what it predicts does not matter here.
def save_vectors_parser_pipeline(path):
    import numpy
    import spacy
    from spacy.training import Example
    nlp = spacy.blank("en")
    vectors = {"cat": [1, 0, 0], "dog": [0, 1, 0], "sat": [0, 0, 1]}
    for text, vector in vectors.items():
        nlp.vocab.set_vector(text, numpy.asarray(vector, dtype = "float32"))
    nlp.add_pipe("parser", config = {"learn_tokens": True})
    def examples():
        doc = nlp.make_doc("the cat sat")
        return [Example.from_dict(doc, {"heads": [1, 2, 2],
                                        "deps": ["det", "nsubj", "ROOT"]})]
    nlp.initialize(examples)
    nlp.meta["name"] = "spacyr_test_vectors_parser"
    nlp.to_disk(path)

# Remove the extension attributes that the functions above set. They belong
# to the Python process, not to a pipeline, and spaCy sends them to the
# other processes of nlp.pipe(), which their local functions do not survive.
def remove_test_extensions():
    from spacy.tokens import Token
    for name in ("spacyr_test_has_lemma", "spacyr_test_mark",
                 "spacyr_test_vector_hook"):
        if Token.has_extension(name):
            Token.remove_extension(name)

# An attribute ruler, of spaCy's, with a rule that sets an extension
# attribute whose setter gives the document a function for its vector: a
# vector of sevens, for the documents with this word.
def add_vector_hook_ruler(nlp, word = "cat"):
    from spacy.tokens import Token
    width = nlp.vocab.vectors.shape[1]
    def setter(token, value):
        token.doc.user_hooks["vector"] = _sevens(width)
    Token.set_extension("spacyr_test_vector_hook", getter = lambda token: False,
                        setter = setter, force = True)
    ruler = nlp.add_pipe("attribute_ruler", name = "spacyr_test_hook_ruler")
    ruler.add(patterns = [[{"LOWER": word}]],
              attrs = {"_": {"spacyr_test_vector_hook": True}})
