# Saved output

`saved-output.rds` holds the output of spacyr 1.4.0 for the cases defined in
`../helper-saved-output.R`: `spacy_parse()`, `spacy_tokenize()`,
`spacy_extract_entity()` and `spacy_extract_nounphrases()` with many option
combinations, on a fixed set of texts that includes edge cases (`NA`, empty
and whitespace-only documents, backslashes, unsorted and missing document
names, trailing whitespace, non-ASCII text and German), and the
`entity_*()` and `nounphrase_*()` functions applied to the saved parses.
For each case it stores the value, messages, warnings and error message.

`../test-9-saved-output.R` reruns each case and requires identical results.
The cases that call spaCy are skipped on CRAN, and when the installed language
model's version differs from the one used to record (stored in `meta$models`),
since a retrained model changes the output. The `entity_*()` and
`nounphrase_*()` cases need no Python and run everywhere.

## Recording

The output was recorded with the submitted 1.4.0 tarball, spaCy 3.8.18,
`en_core_web_sm` 3.8.0 and `de_core_news_sm` 3.8.0:

```sh
R CMD INSTALL -l /tmp/lib140 spacyr_1.4.0.tar.gz
R_LIBS=/tmp/lib140 Rscript tests/testthat/fixtures/record-saved-output.R
```

When a change in the output is intended, record only the affected cases with
the new version installed, and describe the change in `NEWS.md`:

```sh
R CMD INSTALL .
Rscript tests/testthat/fixtures/record-saved-output.R "spacy_tokenize/.*/sentence"
```

Each argument is a case id or a regular expression matching case ids. The other
cases keep their 1.4.0 output, and `meta$updates` records which cases were
re-recorded, with which versions. When a new language model version is
released, record all cases again with 1.4.0 to update the saved output.
