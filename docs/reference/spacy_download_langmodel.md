# Download spaCy language models

Download spaCy language models

## Usage

``` r
spacy_download_langmodel(lang_models = "en_core_web_sm", force = FALSE)
```

## Arguments

- lang_models:

  character; language models to be installed. Defaults `en_core_web_sm`
  (English model). A vector of multiple model names can be used (e.g.
  `c("en_core_web_sm", "de_core_news_sm")`). A list of available
  language models and their names is available from the [spaCy language
  models](https://spacy.io/usage/models) page.

- force:

  ignore if spaCy/the lang_models is already present and install it
  anyway.

## Value

Invisibly returns the installation log.

## Details

Models are downloaded from GitHub. If a download fails, for instance
because of a temporary server error, it is tried twice more, after 10
and 30 seconds, and a warning is given if all three attempts fail.

## Examples

``` r
if (FALSE) { # \dontrun{
# install medium sized model
spacy_download_langmodel("en_core_web_md")

#' # install several models with spaCy
spacy_install(lang_models = c("en_core_web_sm", "de_core_news_sm"))

# install transformer based model
spacy_download_langmodel("en_core_web_trf")
} # }
```
