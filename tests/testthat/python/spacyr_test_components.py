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
# lower = True it also changes the words themselves.
from spacy.tokens import Doc

class SingleSpaceTokenizer:
    def __init__(self, vocab, lower = False):
        self.vocab = vocab
        self.lower = lower

    def __call__(self, text):
        words = text.split()
        if self.lower:
            words = [word.lower() for word in words]
        spaces = [True] * len(words)
        if words:
            spaces[-1] = False
        return Doc(self.vocab, words = words, spaces = spaces)

def set_single_space_tokenizer(nlp, lower = False):
    nlp.tokenizer = SingleSpaceTokenizer(nlp.vocab, lower)
