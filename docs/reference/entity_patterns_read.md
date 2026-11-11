# Read and write entity patterns

Read entity patterns from a file, or write them to one, for instance to
keep them with a project, edit them by hand, or share them with users of
spaCy in Python.

## Usage

``` r
entity_patterns_read(file, label = NULL, case_insensitive = FALSE)

entity_patterns_write(x, file)
```

## Arguments

- file:

  the path of the file to read or write. Its extension sets the format,
  and must be `.jsonl` for writing:

  - `.jsonl`: spaCy's own format, one pattern per line, each a JSON
    object with the keys `label`, `pattern` and optionally `id`, as
    written by spaCy's `EntityRuler.to_disk()`;

  - `.json`: a JSON array of the same patterns;

  - `.txt` (reading only): one phrase per line, all with the label given
    by `label`. Empty lines are skipped.

- label:

  character; for a `.txt` file, the label of its phrases.

- case_insensitive:

  logical; for phrases, whether they match regardless of case. See
  [`as_entity_patterns()`](https://spacyr.quanteda.io/reference/as_entity_patterns.md).

- x:

  patterns to write: a `spacyr_entity_patterns` object, or anything that
  [`as_entity_patterns()`](https://spacyr.quanteda.io/reference/as_entity_patterns.md)
  accepts.

## Value

`entity_patterns_read()` returns a `spacyr_entity_patterns` object.
`entity_patterns_write()` returns `file`, invisibly.

## Details

Reading and writing JSON needs the **jsonlite** package.

`entity_patterns_write()` writes JSONL only, so `file` must end in
`.jsonl`. It checks the patterns before opening `file`, so an existing
file is left as it was if they are not valid. A phrase that matches
regardless of case is written with the extra key
`"case_insensitive": true`, which `entity_patterns_read()` reads back.
spaCy itself ignores that key, and matches the phrase exactly.

Patterns written and read back are identical to the originals.

## See also

[`as_entity_patterns()`](https://spacyr.quanteda.io/reference/as_entity_patterns.md)

## Examples

``` r
# \donttest{
if (requireNamespace("jsonlite", quietly = TRUE)) {
  pats <- as_entity_patterns(list(
    list(label = "PERSON",
         pattern = list(list(LOWER = list(IN = c("dr", "dr."))),
                        list(ENT_TYPE = "PERSON", ENT_IOB = "B"),
                        list(ENT_TYPE = "PERSON", ENT_IOB = "I", OP = "*"))),
    list(label = "ORG", pattern = "Acme Widgets", id = "acme")
  ))
  file <- tempfile(fileext = ".jsonl")
  entity_patterns_write(pats, file)
  readLines(file)
  identical(entity_patterns_read(file), pats)
}
#> [1] TRUE
# }
```
