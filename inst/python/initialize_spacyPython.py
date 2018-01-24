# from __future__ import unicode_literals 

## following lines are necessary for showing the version of spacy
import pip
installed_packages = pip.get_installed_distributions()
versions = {package.key: package.version for package in installed_packages}

if 'omit_entity' in locals() and omit_entity == True and versions['spacy'][:1] == '2':
    nlp = spacy.load(model, disable=['ner'])
else:
    nlp = spacy.load(model)
