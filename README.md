# [![spacyr: an R wrapper for spaCy](https://cdn.rawgit.com/quanteda/spacyr/master/images/spacyr_logo_small.svg)](https://spacyr.quanteda.io)

<!-- badges: start -->

[![CRAN
Version](https://www.r-pkg.org/badges/version/spacyr)](https://CRAN.R-project.org/package=spacyr)
[![](https://img.shields.io/badge/devel%20version-1.3.0-royalblue.svg)](https://github.com/quanteda/spacyr)
[![R-CMD-check](https://github.com/quanteda/spacyr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/quanteda/spacyr/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/quanteda/spacyr/branch/master/graph/badge.svg)](https://app.codecov.io/gh/quanteda/spacyr?branch=master)
[![Downloads](https://cranlogs.r-pkg.org/badges/spacyr)](https://CRAN.R-project.org/package=spacyr)
[![Total
Downloads](https://cranlogs.r-pkg.org/badges/grand-total/spacyr?color=orange)](https://CRAN.R-project.org/package=spacyr)
<!-- badges: end -->

An R wrapper to the spaCy “industrial strength natural language
processing” Python library from <https://spacy.io>.

## Installing the package

1.  Install the **spacyr** R package:

    - From CRAN:

    ``` r
    install.packages("spacyr")
    ```

    - From GitHub:

      To install the latest package from source, you can simply run the
      following.

    ``` r
    remotes::install_github("quanteda/spacyr")
    ```

2.  Install spaCy and requirements

    Simply run:

    ``` r
    library(spacyr)
    spacy_install()
    ```

    If you want to install a specific version, simply add it to the
    install command:

    ``` r
    library(spacyr)
    spacy_install(version = "apple")
    ```

    Check the helpful version tool on <https://spacy.io/usage> and to
    see what is available.

3.  (optional) Add more language models

    If left unchanged, `spacy_install()` adds the default
    “en_core_web_sm” model. You can add more language models with
    `spacy_download_langmodel()`. For instance, to install a small and
    efficient German language model:

    ``` r
    spacy_download_langmodel("de_core_news_sm")
    ```

    Check out available models at <https://spacy.io/usage/models>.

If you run into any problems, you can try the manual installation path
described below.

### Manual installation and troubleshooting

`spacy_install()` performs a number of tasks to set up a virtual
environment in which spaCy is installed. Virtual environments are the
recommended way to install Python applications, as the lack of central
dependency conflict control (which is performed by CRAN in the
`R`-world) means that conflicts between packages are a lot more common.
Hence each Python package and its dependencies are usually installed in
their own folder.

Usually, none of this should concern you. However, experience shows that
some systems run into problems during installation that are hard to
foresee by developers. Below, we therefore explain how you can perform
the steps in `spacy_install()` manually, to debug any problems that
might occur. Please only file a GitHub issue after you have tried to
manually run through the steps, so we can provide you with more targeted
help.

1.  Install Python

    You can use your own installation of Python for the steps below. By
    default, `spacy_install()` downloads and installs a minimal Python
    version in the default directory used by the `reticulate` package
    for simplicity. This can be done with a single command:

    ``` r
    python_exe <- reticulate::install_python()
    ```

    The function returns the path to the Python executable file. You can
    run this again at any time to get that path (the installation is
    skipped if the files are already present). If you prefer to use a
    specific version of Python, you can use this function to install it
    and it will be picked up by `spacyr`.

2.  Set up a virtual environment

    By default, `spacyr` uses an environment called “r-spacyr”, which is
    located in a directory managed by `reticulate`. We can create it
    with:

    ``` r
    reticulate::virtualenv_create("r-spacyr", python = python_exe)
    ```

    If this causes trouble for some reason, you can install the
    environment in any location that is convenient for you like so:

    ``` r
    reticulate::virtualenv_create("path/to/directory", python = python_exe)
    ```

    Note, that `spacyr` does not know of the existence of this
    environment unless you tell it through the environment variable
    `SPACY_PYTHON`. You can do that either in each session with:

    ``` r
    Sys.setenv(SPACY_PYTHON = "path/to/directory")
    ```

    or you put it into your `.Renviron` file. You can use this little
    helper function to make the change permanent:

    ``` r
    usethis::edit_r_environ(scope = "user")
    ```

    We also need to tell `reticulate` that it should use this
    environment from now on.

    ``` r
    reticulate::use_virtualenv(Sys.getenv("SPACY_PYTHON", unset = "r-spacyr"))
    ```

    We use `Sys.getenv("SPACY_PYTHON", unset = "r-spacyr")` to check if
    `SPACY_PYTHON` is set and use the default otherwise.

3.  Install spaCy

    Installing `spaCy` and its dependencies is again done through
    `reticulate`. We check again if SPACY_PYTHON is set, in case you
    chose a non-default folder.

    ``` r
    reticulate::py_install("spacy", envname = Sys.getenv("SPACY_PYTHON", unset = "r-spacyr"))
    ```

4.  Install spaCy language models

    The language models are installed in the same way.

    ``` r
    reticulate::py_install("en_core_web_sm", envname = Sys.getenv("SPACY_PYTHON", unset = "r-spacyr"))
    ```

If any of those steps fail, please file an
[issue](https://github.com/quanteda/spacyr/issues) (after checking if
one already exists for your error). You can also use the individual
commands to customise your setup.

## Comments and feedback

We welcome your comments and feedback. Please file issues on the
[issues](https://github.com/quanteda/spacyr/issues) page, and/or send us
comments at <kbenoit@lse.ac.uk> and <A.Matsuo@lse.ac.uk>.
