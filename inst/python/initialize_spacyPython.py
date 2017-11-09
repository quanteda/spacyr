# from __future__ import unicode_literals 

## following lines are necessary for showing the version of spacy
import pip
installed_packages = pip.get_installed_distributions()
versions = {package.key: package.version for package in installed_packages}

nlp = spacy.load(model)
