# Saved output

The saved-output tests (`../test-9-saved-output.R`) rerun a fixed set of calls
and require results identical to the ones saved here. The calls are defined
in `../helper-saved-output.R`:
- `spacy_parse()`, `spacy_tokenize()`, `spacy_extract_entity()` and
  `spacy_extract_nounphrases()`, with many option combinations;
- on a fixed set of texts with edge cases: `NA`, empty and whitespace-only
  documents, backslashes, unsorted and missing document names, trailing
  whitespace, non-ASCII text and German;
- the `entity_*()` and `nounphrase_*()` functions applied to the saved parses.

For each case the files store the value, messages, warnings and error message.

## Files

- `saved-output.rds`: the **accepted** output that the tests compare with.
  It starts as the 1.4.0 output. It changes only when a change in output is
  intended, or when spaCy or a language model is updated.
- `saved-output-1.4.0.rds`: the **baseline**, the output of the submitted
  `spacyr_1.4.0.tar.gz` (tag `v1.4`, commit 6a2520a) with spaCy 3.8.18,
  `en_core_web_sm` 3.8.0 and `de_core_news_sm` 3.8.0. It is never re-recorded.
  It is kept as a reference, and is not included in the package build.
- `record-saved-output.R`: records `saved-output.rds`.
- `compare-saved-output.R`: lists the cases where the accepted output differs
  from the baseline, which should match the changes in `NEWS.md`, or from
  another saved-output file given as its argument.

## When the tests run

The cases that call spaCy compare output only when the installed spaCy and
language model versions match the ones recorded in `saved-output.rds`
(`meta$spacy_version` and `meta$models`), since either can change the output.
Otherwise, and on CRAN, they are skipped. The `entity_*()` and
`nounphrase_*()` cases need no Python and always run.

The `saved-output` CI job (`.github/workflows/saved-output.yaml`) reads those
versions from `saved-output.rds`, installs exactly them, and fails if any
saved-output test is skipped. So every case runs on every pull request, while
the main CI matrix keeps testing compatibility with the latest spaCy.

## Recording an intended change

When a pull request changes output on purpose, record only the affected cases
from the pull request's code, and describe the change in `NEWS.md`:

```sh
R CMD INSTALL .
Rscript tests/testthat/fixtures/record-saved-output.R --revision="PR 123" \
  "spacy_tokenize/.*/sentence"
```

Each argument after `--revision` is a case id or a regular expression matching
case ids. The other cases are left as they are. `meta$updates` records which
cases were recorded, from which revision, and with which versions. The script
refuses if spaCy or a model differs from the versions of the saved output.
Once the pull request is merged, its output becomes part of the accepted
output.

## Updating spaCy or a language model

Record all cases again with the new versions, using the code of an
**accepted revision**: the latest commit on `main` whose saved-output tests
pass. Name it with `--revision`. Do not record from 1.4.0 (that would undo the
intended changes accepted since) or from unmerged code:

```sh
cp tests/testthat/fixtures/saved-output.rds /tmp/saved-output-old.rds
git worktree add ../spacyr-accepted <commit on main>
R CMD INSTALL -l /tmp/lib-accepted ../spacyr-accepted
R_LIBS=/tmp/lib-accepted Rscript tests/testthat/fixtures/record-saved-output.R \
  --revision="main@<commit>"
git worktree remove ../spacyr-accepted
Rscript tests/testthat/fixtures/compare-saved-output.R /tmp/saved-output-old.rds
```

Run this from the checkout of the pull request that updates the versions, so
that the case definitions match. Before recording, run the saved-output tests
with the old versions, to confirm that the accepted revision reproduces the
accepted output. The comparison with the old accepted output lists the cases
that the new versions change. Review them in the pull request. The CI job
installs the versions recorded in `saved-output.rds`, so it follows the update
automatically. The previous metadata is kept in `meta$history`.
