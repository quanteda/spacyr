## Submission notes

### Purpose

This is a major release. It adds rule-based matching (`spacy_match()`) and rule-based named entities (`as_entity_patterns()`, and new arguments of `spacy_initialize()`), with functions that connect their results to the quanteda package (`as_index()`, and a method of `quanteda::as.dictionary()`). It also adds the arguments `n_process` and `batch_size` for parallel processing, and deprecates `multithread`, `process_document()` and the `get_*()` functions.

The version is 2.0.0 because the S3 methods for the output of `spacy_parse()` on quanteda's generics (`as.tokens()`, `docnames()`, `ndoc()`, `ntoken()`, `ntype()` and `nsentence()`) are now part of this package. They were part of quanteda, which will remove its copies in a later release that requires this version. The methods are registered with delayed S3 registration (`S3method(quanteda::as.tokens, spacyr_parsed)`), so quanteda remains in `Suggests`; this is why the package now requires R (>= 3.6.0). While both packages have the methods, calls by users reach this package's methods in either order of loading.

## R CMD check results

### ERRORs or WARNINGs

None.

### NOTES

None.

Checked locally on macOS (R 4.6.1) with `R CMD check --as-cran`, with spaCy installed so that the full test suite runs.

## Downstream dependencies

We checked all 14 reverse dependencies with `R CMD check`, once with the current CRAN version of spacyr (1.4.0) and once with this version, using the revdepcheck package, with spaCy installed so that their spaCy-dependent examples and vignettes ran: the 11 that import or suggest spacyr (ACEP, idiolect, LBDiscover, leadeR, minorparties, poldis, politeness, sentixr, sentopics, textrecipes, warmthcompetence) and the 3 that list it under `Enhances` (NLP, quanteda, rsyntax).

The results were identical for every package: no new problems were introduced. Four packages had problems with both versions, none caused by spacyr: a snapshot test of printed output in idiolect, an error in a vignette of leadeR and of textrecipes, and a NOTE for warmthcompetence from a missing Java runtime in our local setup.
