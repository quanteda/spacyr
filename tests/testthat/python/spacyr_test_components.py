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
