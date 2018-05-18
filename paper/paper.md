---
title: 'spacyr: an R wrapper for spaCy'
authors:
- affiliation: 1
  name: Kenneth Benoit
  orcid: 0000-0002-0797-564X
- affiliation: 1
  name: Akitaka Matsuo
  orcid: 0000-0002-3323-6330
date: "8 May 2018"
bibliography: paper.bib
tags:
- text mining
- natural language processing
- part of speech tagging
affiliations:
- index: 1
  name: Department of Methodology, London School of Economics and Political Science
---

# Summary

``spacyr`` package is an R wrapper to the spaCy "industrial strength natural language processing" Python library from http://spacy.io. The ``spacyr`` package sends a large corpus of texts to Python environment and obtains detailed results of parsing, including part of speech tagging, named entity recognition, and dependency parsing, as an R data.frame. This package seamlessly works with ``quanteda``, the main package of quanteda-verse. The package also provides a function to automatically install spaCy in a dedicated virtual (or conda) environment.

# References
