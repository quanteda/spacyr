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
