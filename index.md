# spacyr: an R wrapper for spaCy

[![CRAN
Version](https://www.r-pkg.org/badges/version/spacyr)](https://CRAN.R-project.org/package=spacyr)
[![R-CMD-check](https://github.com/quanteda/spacyr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/quanteda/spacyr/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/quanteda/spacyr/branch/main/graph/badge.svg)](https://app.codecov.io/gh/quanteda/spacyr?branch=main)
[![Downloads](https://cranlogs.r-pkg.org/badges/spacyr)](https://CRAN.R-project.org/package=spacyr)
[![Total
Downloads](https://cranlogs.r-pkg.org/badges/grand-total/spacyr?color=orange)](https://CRAN.R-project.org/package=spacyr)

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

    You can check whether spaCy and a model are ready to use, without
    starting Python, with:

    ``` r
    spacy_installed("en_core_web_sm")
    ```

`spacy_install()` creates its environment with a version of Python
supported by the spaCy release being installed, and offers to install
one through `reticulate::install_python()` if none is found. On Windows,
`install_python()` requires [git](https://git-scm.com/downloads/) to be
installed and on your `PATH`.

If you run into any problems, you can try the manual installation path
described below.

### Changing the Python version

An existing environment keeps the version of Python it was created with.
If that version is too old or too new for the spaCy release you want,
`spacy_install()` stops with an error. To recreate the environment with
a suitable Python, remove it and install again:

``` r
spacy_uninstall()
spacy_install()
```

To use a particular Python, create the environment yourself first (see
step 2 of the manual installation below), then run `spacy_install()`.

### Using an existing Python or conda environment

If you already have a Python environment with spaCy installed, for
instance a conda environment, point **spacyr** to its Python executable
through the `RETICULATE_PYTHON` environment variable before calling
`spacy_initialize()`:

``` r
Sys.setenv(RETICULATE_PYTHON = reticulate::conda_python("my-spacy-env"))
spacy_initialize(model = "en_core_web_sm")
```

You can also set `RETICULATE_PYTHON` in your `.Renviron` file. When it
is set, **spacyr** uses that Python instead of its own environment.

### Using local or custom language models

Besides the names of installed models, `spacy_initialize()` accepts the
path to a model directory, for instance a model you have trained or
downloaded yourself:

``` r
spacy_initialize(model = "path/to/my_model")
```

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

    The language models are not available through `pip` by name, so they
    are installed with spaCy’s own download command, which
    `spacy_download_langmodel()` runs for you:

    ``` r
    spacyr::spacy_download_langmodel("en_core_web_sm")
    ```

If any of those steps fail, please file an
[issue](https://github.com/quanteda/spacyr/issues) (after checking if
one already exists for your error). You can also use the individual
commands to customise your setup.
