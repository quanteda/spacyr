Tips for macOS Users
--------------------

### Before install spaCy

You need to have a C++ complier, Xtools. Either get the full Xcode from
the App Store, or install the command-line Xtools using this command
from the Terminal:

``` bash
xcode-select --install
```

### Installing spaCy and **spacyr** on macOS

This document describes three methods for installing spaCy and
**spacyr** on macOS. 1. Using Python 2 from the homebrew package
manager. 2. Using Python 3 from the homebrew package manager. 3. Using
the system default Python.

#### Install spaCy using `homebrew` and Python 2.7.x

Homebrew is a package manager for macOS, which you can use to install
Python and spaCy.

1.  Install homebrew

    ``` bash
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    ```

2.  Install Python 2

    ``` bash
    brew install python
    ```

3.  Check that the default python has changed

    ``` bash
    which python
    ```

    The output should now be `/usr/local/bin/python`.
4.  Setup pip

    ``` bash
    pip install --upgrade setuptools
    pip install --upgrade pip
    ```

5.  Install spaCy

    ``` bash
    pip install -U spacy
    ```

6.  Install the English language model

    ``` bash
    python -m spacy download en
    ```

7.  Check if the installation succeeded

    ``` bash
    python -c "import spacy; spacy.load('en'); print('OK')"
    ```

8.  Install spacyr

    ``` r
    devtools::install_github("quanteda/spacyr", build_vignettes = FALSE)
    ```

#### Install spaCy using `homebrew` and Python &gt;= 3.6

1.  Install homebrew

    ``` bash
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    ```

2.  Install Python 3

    ``` bash
    brew install python3
    ```

3.  Check the path for Python 3

    ``` bash
    which python3
    ```

    The output should be `/usr/local/bin/python3`.
4.  Setup pip3

    ``` bash
    pip3 install --upgrade setuptools
    pip3 install --upgrade pip3
    ```

5.  Install spaCy

    ``` bash
    pip3 install -U spacy
    ```

6.  Install the English language model

    ``` bash
    python3 -m spacy download en
    ```

7.  Check that the installation succeeded

    ``` bash
    python3 -c "import spacy; spacy.load('en'); print('OK')"
    ```

8.  Install spacyr

    ``` r
    devtools::install_github("quanteda/spacyr", build_vignettes = FALSE)
    ```

If you are using a homebrew Python 2, the `spacy_initialize` is

``` r
library(spacyr)
spacy_initialize(python_executable = "/usr/local/bin/python3")
```

#### Install spaCy on the default Python (not really recommended)

Mac OS X comes with Python. In order to install spacy in that python,
follow the steps below:

1.  Install `pip`

    ``` bash
    sudo easy_install pip
    ```

2.  Install `spacy`

    ``` bash
    sudo pip install spacy
    ```

    You will need to enter a password for a user account with
    Administrator privileges.
3.  Install the English language model

    ``` bash
    python -m spacy download en
    ```

4.  Check if the installation succeeded

    ``` bash
    python -c "import spacy; spacy.load('en'); print('OK')"
    ```

5.  Install spacyr

    ``` r
    devtools::install_github("quanteda/spacyr", build_vignettes = FALSE)
    ```

If the default Python is used, the initialization is simply:

``` r
library(spacyr)
spacy_initialize()
```
