Tips for Mac OS X Users
-----------------------

### Before install spaCy

You need to have a C++ complier, Xtools. Either get the full Xcode from the App Store, or install the command-line Xtools using this command from the Terminal:

``` bash
xcode-select --install
```

### Install spaCy and spacyr on Mac OSX

This document describes three methods to install spaCy and spacyr in the system. 1. use Python 2 from the homebrew package manager 2. use Python 3 from the homebrew package manager 3. use system default python.

#### Install spaCy using homebrew python 2

Homebrew is a package manager for Mac OS X. You can install spaCy on it.

1.  Install homebrew

    ``` bash
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    ```

2.  Install Python 2

    ``` bash
    brew install python
    ```

3.  Check if the default python is changed

    ``` bash
    which python
    ```

    The output should be now `/usr/local/bin/python`
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
    devtools::install_github("kbenoit/spacyr")
    ```

If you are using a brew Python 2, the `spacy_initialize` is

``` r
library(spacyr)
spacy_initialize(use_python = "/usr/local/bin/python")
```

#### Install spaCy using homebrew python 3

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

    The output should be now `/usr/local/bin/python3`
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

7.  Check if the installation succeeded

    ``` bash
    python3 -c "import spacy; spacy.load('en'); print('OK')"
    ```

8.  Install spacyr

    ``` r
    devtools::install_github("kbenoit/spacyr")
    ```

If you are using a brew Python 2, the `spacy_initialize` is

``` r
library(spacyr)
spacy_initialize(use_python = "/usr/local/bin/python3")
```

#### Install spaCy on default Python (not really recommend)

Mac OS X comes with Python. In order to install spacy in that python, follow the steps below:

1.  Install `pip`

    ``` bash
    sudo easy_install pip
    ```

2.  Install `spacy`

    ``` bash
    sudo pip install spacy
    ```

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
    devtools::install_github("kbenoit/spacyr")
    ```

If the default Python is used the initializaiton is simply:

``` r
library(spacyr)
spacy_initialize()
```
