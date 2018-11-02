# from __future__ import unicode_literals 

## Parser for version strings
try:
    from packaging.version import parse as VersionParser
except ImportError:
    from distutils.version import LooseVersion as VersionParser

spacy_version = spacy.about.__version__

if 'spacy_entity' in locals() and spacy_entity == False and VersionParser(spacy_version) >= VersionParser("2"):
    nlp = spacy.load(model, disable=['ner'])
else:
    nlp = spacy.load(model)

import re
