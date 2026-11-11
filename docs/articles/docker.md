# Using spacyr with Docker

A Docker image can contain R, **spacyr**, Python, spaCy and the language
model. Installing them at build time lets you start a container and
parse text straight away. The Dockerfile below uses the
[Rocker](https://rocker-project.org/images/versioned/r-ver.html) image
for R and offers two build targets. The `manual` target installs a
specific spaCy version and model with pip. The `managed` target uses
[`spacy_install()`](https://spacyr.quanteda.io/reference/spacy_install.md)
to create the Python environment and install the default English model.

## Prepare the build directory

With Docker running, open a terminal in a Git checkout of **spacyr**.
Create a build directory and export the checked-out revision into it:

``` sh
build_dir=$(mktemp -d)
git archive --output="$build_dir/spacyr-src.tar" HEAD
cd "$build_dir"
```

Save the following as `Dockerfile` in that directory, next to
`spacyr-src.tar`:

``` dockerfile
FROM rocker/r-ver:4.5.1 AS base

RUN apt-get update \
    && apt-get install -y --no-install-recommends libpng-dev libpython3-dev python3-venv \
    && rm -rf /var/lib/apt/lists/*

RUN Rscript --vanilla -e \
    'install.packages(c("data.table", "reticulate"), repos = "https://cloud.r-project.org", Ncpus = 2L)'
ADD spacyr-src.tar /tmp/spacyr/
RUN R CMD INSTALL /tmp/spacyr && rm -rf /tmp/spacyr

FROM base AS manual

RUN python3 -m venv /opt/spacy \
    && /opt/spacy/bin/python -m pip install --no-cache-dir \
        'spacy==3.8.18' \
        'https://github.com/explosion/spacy-models/releases/download/en_core_web_sm-3.8.0/en_core_web_sm-3.8.0-py3-none-any.whl'
ENV RETICULATE_PYTHON=/opt/spacy/bin/python

FROM base AS managed

RUN apt-get update \
    && apt-get install -y --no-install-recommends python3-pip \
    && rm -rf /var/lib/apt/lists/*

ENV SPACY_PYTHON=/opt/spacy
RUN Rscript --vanilla -e 'spacyr::spacy_install(ask = FALSE)'
```

## Build with pinned spaCy and model versions

``` sh
docker build --target manual --tag spacyr:manual .
```

The `manual` target installs spaCy 3.8.18 and the English pipeline
`en_core_web_sm` 3.8.0 in `/opt/spacy`. The model wheel is installed
from its [release on
GitHub](https://github.com/explosion/spacy-models/releases/tag/en_core_web_sm-3.8.0).
Set `RETICULATE_PYTHON` to the Python executable in the virtual
environment so **reticulate** uses it when
[`spacy_initialize()`](https://spacyr.quanteda.io/reference/spacy_initialize.md)
starts Python.

## Build with `spacy_install()`

``` sh
docker build --target managed --tag spacyr:managed .
```

The `managed` target installs spaCy and the default English model during
the build. Use `ask = FALSE` to make the installation non-interactive.
This is already the default under `Rscript`. On this Rocker image,
**reticulate** needs both `python3-venv` and `python3-pip` to create the
virtual environment from system Python.

Set `SPACY_PYTHON` to the environment directory so the build and
subsequent R sessions use the same location, even under different user
accounts. Leave `RETICULATE_PYTHON` unset for this target. To choose a
spaCy release or add other models, pass `version` or `lang_models` to
[`spacy_install()`](https://spacyr.quanteda.io/reference/spacy_install.md).

## Check the finished image

Run a parse as an unprivileged user with networking disabled. To check
the managed installation, use `spacyr:managed` in the same command.

``` sh
docker run --rm -i --network none --user 10001:10001 --env HOME=/tmp \
    spacyr:manual Rscript --vanilla - <<'RSCRIPT'
spacyr::spacy_initialize(model = "en_core_web_sm")
parsed <- spacyr::spacy_parse("Docker works.")
stopifnot(identical(as.character(parsed$token), c("Docker", "works", ".")))
print(parsed)
RSCRIPT
```

Both targets were tested with Docker Desktop on Apple silicon (Linux
ARM64).
