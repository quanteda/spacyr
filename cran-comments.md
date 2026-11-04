## Submission notes

### Purpose

This release fixes two bugs that affected results: input text was altered before being passed to spaCy (backslashes were removed), and an error during tokenization could leave the spaCy pipeline disabled for the rest of the session. It also makes installation more robust, by creating the Python environment with a version of Python supported by the spaCy release being installed, and adds a small function, `spacy_installed()`, that other packages can use to skip examples and tests when spaCy is not available.

## R CMD check results

### ERRORs or WARNINGs

None.

### NOTES

None.

Checked locally on macOS (R 4.6.1), and on GitHub Actions on macOS, Windows and Ubuntu (R release, devel and oldrel-1), with spaCy installed so that the full test suite runs.

## Downstream dependencies

We checked all 11 reverse dependencies (idiolect, leadeR, minorparties, poldis, politeness, warmthcompetence, ACEP, LBDiscover, sentixr, sentopics, textrecipes) with `R CMD check --as-cran`, once with the current CRAN version of spacyr (1.3.0) and once with this version, with spaCy installed so that their spaCy-dependent examples and vignettes ran. The results were identical for every package: no new problems were introduced. The only failures, which occurred with both versions, were caused by our local setup (a missing Java runtime for warmthcompetence, and a vignette dependency of poldis not installed), not by spacyr.
