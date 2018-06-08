# from __future__ import unicode_literals 

## set py_version here
## 
import sys
py_version = sys.version_info.major

## following lines are necessary for showing the version of spacy
## Dealing with pip 10.* api chagnes
## The solution is from:
## https://github.com/naiquevin/pipdeptree/blob/master/pipdeptree.py
try:
    from pip._internal import get_installed_distributions
except ImportError:
    from pip import get_installed_distributions

installed_packages = get_installed_distributions()
versions = {package.key: package.version for package in installed_packages}
spacy_version = int(versions['spacy'][:1])

if 'spacy_entity' in locals() and spacy_entity == False and spacy_version >= 2:
    nlp = spacy.load(model, disable=['ner'])
else:
    nlp = spacy.load(model)
