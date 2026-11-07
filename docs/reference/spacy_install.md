# Install spaCy in a virtual environment

Install spaCy in a self-contained environment, including specified
language models.

## Usage

``` r
spacy_install(
  version = "latest",
  lang_models = "en_core_web_sm",
  ask = interactive(),
  force = FALSE,
  ...
)
```

## Arguments

- version:

  character; spaCy version to install (see details).

- lang_models:

  character; language models to be installed. Defaults `en_core_web_sm`
  (English model). A vector of multiple model names can be used (e.g.
  `c("en_core_web_sm", "de_core_news_sm")`). A list of available
  language models and their names is available from the [spaCy language
  models](https://spacy.io/usage/models) page.

- ask:

  logical; ask whether to proceed during the installation. By default,
  questions are only asked in interactive sessions.

- force:

  ignore if spaCy/the lang_models is already present and install it
  anyway.

- ...:

  not used.

## Details

The function checks whether a suitable installation of Python is present
on the system and installs one via
[`reticulate::install_python()`](https://rstudio.github.io/reticulate/reference/install_python.html)
otherwise. "Suitable" means a version of Python supported by the spaCy
release being installed, as declared on PyPI (if PyPI cannot be reached,
any Python found is used). It then creates a virtual environment with
the necessary packages in the default location chosen by
[`reticulate::virtualenv_root()`](https://rstudio.github.io/reticulate/reference/virtualenv-tools.html).
For a spaCy version range, pip selects a release compatible with the
environment's Python.

An existing environment keeps the Python version it was created with. If
that version is not supported by the spaCy release being installed,
`spacy_install()` stops with an error; run
[`spacy_uninstall()`](https://spacyr.quanteda.io/reference/spacy_uninstall.md)
and then `spacy_install()` to recreate the environment with a suitable
Python.

If you want to install a different version of Python than the default,
you should call
[`reticulate::install_python()`](https://rstudio.github.io/reticulate/reference/install_python.html)
directly. If you want to create or use a different virtual environment,
you can use, e.g., `Sys.setenv(SPACY_PYTHON = "path/to/directory")`.

## See also

[`spacy_download_langmodel()`](https://spacyr.quanteda.io/reference/spacy_download_langmodel.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# install the latest version of spaCy
spacy_install()

# update spaCy
spacy_install(force = TRUE)

# install an older version
spacy_install(version = "3.1.0")

# install with GPU enabled
spacy_install(version = "cuda-autodetect")

# install on Apple ARM processors
spacy_install(version = "apple")

# install an old custom version
spacy_install(version = "[cuda-autodetect]==3.2.0")

# install several models with spaCy
spacy_install(lang_models = c("en_core_web_sm", "de_core_news_sm"))


# install spaCy to an existing virtual environment
Sys.setenv(RETICULATE_PYTHON = "path/to/python")
spacy_install()
} # }
```
