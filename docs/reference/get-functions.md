# Get results from documents processed by spaCy (deprecated)

These functions are deprecated, and will be removed in a future version
of spacyr. They give a warning on every call.
[`spacy_parse()`](https://spacyr.quanteda.io/reference/spacy_parse.md)
returns all of their results in one data.frame, one row per token:

- `get_tokens()`: the `token` column;

- `get_tags()`: the `pos` column, or `tag` with
  `spacy_parse(x, tag = TRUE)`;

- `get_attrs()`: `spacy_parse(x, additional_attributes = attr_name)`;

- `get_named_entities()`: the `entity` column;

- `get_dependency()`: the `head_token_id` and `dep_rel` columns of
  `spacy_parse(x, dependency = TRUE)`. Note that `head_token_id` numbers
  the tokens within each sentence, while the `head_id` of
  `get_dependency()` numbers them within each document. To number the
  head tokens within each document, add the number of tokens in the
  document's earlier sentences:

      parsed <- spacy_parse(x, dependency = TRUE)
      head_id <- parsed$head_token_id +
        ave(seq_len(nrow(parsed)), parsed$doc_id, FUN = seq_along) -
        parsed$token_id

- `get_ntokens()` and `get_ntokens_by_sent()`: count the rows by
  `doc_id`, and by `doc_id` and `sentence_id`;

- `get_noun_phrases()`:
  [`spacy_extract_nounphrases()`](https://spacyr.quanteda.io/reference/spacy_extract_nounphrases.md).

Each reads the documents held by the result of
[`process_document()`](https://spacyr.quanteda.io/reference/process_document.md),
which are not affected by later calls to other spacyr functions.

## Usage

``` r
get_tokens(spacy_out)

get_tags(spacy_out, tagset = c("google", "detailed"))

get_attrs(spacy_out, attr_name, deal_utf8 = FALSE)

get_named_entities(spacy_out)

get_dependency(spacy_out)

get_noun_phrases(spacy_out)

get_ntokens(spacy_out)

get_ntokens_by_sent(spacy_out)
```

## Arguments

- spacy_out:

  the result of
  [`process_document()`](https://spacyr.quanteda.io/reference/process_document.md)

- tagset:

  character label for the tagset to use, either `"google"` or
  `"detailed"` to use the simplified Google tagset, or the more detailed
  scheme from the Penn Treebank (or the German Text Archive in case of
  German language model).

- attr_name:

  name of spaCy token attributes to extract

- deal_utf8:

  not used; kept for compatibility

## Value

`get_tokens()` returns a character vector of the tokens of all the
documents.

`get_tags()` returns a character vector of the part-of-speech tags of
all the tokens.

`get_attrs()` returns the values of the attribute for all the tokens.

`get_named_entities()` returns a character vector of the entity tags of
all the tokens.

`get_dependency()` returns a list of the head token IDs (`head_id`) and
the dependency relations (`dep_rel`) of all the tokens.

`get_noun_phrases()` returns a data.frame of noun phrases.

`get_ntokens()` returns the number of tokens in each document.

`get_ntokens_by_sent()` returns a list of the number of tokens in each
sentence, for each document.
