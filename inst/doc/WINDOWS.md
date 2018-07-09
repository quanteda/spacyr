Tips for Windows Users
----------------------

### Installing spaCy and **spacyr** in Microsoft Windows

Installing spaCy in Windows is a bit complicated, but followings are the
steps which we have been successful most of times.

#### Setup C++ compiler

Before you start, a C++ compiler must be installed on your system. For
Python 3 in windows, Visual Studio Community 2017 and its C++ compiler
environment should be installed. An installer for Visual Studio
Community 2017 is available
[here](https://visualstudio.microsoft.com/downloads/). After
installation, start Visual Studio Installer and install an additional
component, **Desktop development with C++** (see the screenshot below).

![vs\_installer\_screenshot](VS_Installer_screenshot.png)

#### Install **spacyr**

1.  Install the [Rtools](https://cran.r-project.org/bin/windows/Rtools/)
    software available from CRAN.

2.  Installing the **spacyr** R package:

    To install the package from source, you can simply run the
    following.

    ``` r
    devtools::install_github("quanteda/spacyr", build_vignettes = FALSE)
    ```

#### Install spaCy with miniconda and `spacyr::spacy_install()`

The easiest way to install spaCy is to use `spacy_install()` function in
`spacyr` package. This function generates a conda environment
(`spacy_condaenv`) and install spaCy and language models in the
environment. You can run this command if you have Anaconda/Miniconda.

If you do not have Miniconda, the installer can be found
[here](https://conda.io/miniconda.html) (we recommend Python 3.6,
64-bit). After installing Miniconda, open R console, then enter:

``` r
library(spacyr)
spacy_install()
```

This will install spaCy and its English language model.

#### An alternative way: Install spaCy through pip

You can also install spaCy through normal `pip` method.

1.  Install python 3.\*. Although spaCy is supposed to work with 2.7.\*,
    there seems to be numerous problems installing the language modules
    with this setup. Consequently, we strongly recommend using **Python
    3** (currently 3.6.6). A Python 3 installer is available at the
    [Python Official
    Page](https://www.python.org/downloads/release/python-361/). The
    64-bit version is recommended (“Windows x86-64 executable
    installer”).
    -   During the installation process, be sure to scroll down in the
        installation option window and find the “Add Python.exe to
        Path”, and click on the small red “x.”
2.  Install spaCy with the **Administrator Command Line**.
    1.  The installation of spaCy requires administrator privileges, as
        it generates symbolic links outside the user folder. In order to
        start it you need to do:
        -   (Windows 7)
            <https://technet.microsoft.com/en-gb/library/cc947813(v=ws.10).aspx>
            1.  Click **Start**, click **All Programs**, and then
                **click Accessories**.
            2.  Right-click **Command prompt**, and then click **Run as
                administrator**.
            3.  If the User Account Control dialog box appears, confirm
                that the action it displays is what you want, and then
                click Continue.
        -   (Windows 8 and 10) See
            <https://www.howtogeek.com/194041/how-to-open-the-command-prompt-as-administrator-in-windows-8.1/>.

            1.  Right-click on the Start button in the lower-left corner
                of the screen
            2.  Select the **Command Prompt (Admin)** option from the
                Power User menu.

    2.  Install spaCy. In the administrator command prompt, enter

        ``` bash
        pip3 install spacy
        ```

    3.  Install the English language model using these commands

        ``` bash
        python -m spacy download en
        ```

    4.  Test your installation at the command line using:

        ``` bash
        python -c "import spacy; spacy.load('en'); print('OK')"
        ```

        There are alternative methods of installing spaCy, especially if
        you have installed a different Python (e.g. through Anaconda).
        Full installation instructions are available from the [spaCy
        page](https://spacy.io/docs/usage/#source-windows).

### When you have more than one python in your system

Things can go wrong in many ways if you have more than one Python
executable. To check type

    where python

If this returns more than one line of output, you have more than one.
**spacyr** will attempt to find the version in which you have installed
spaCy, but you can always override this as an explicit argument to
`spacy_initialize()`.

#### Specify the Python path in **spacyr**

The python path is set when `spacy_initialize()` is called for the first
time after `spacyr` package is attached. Here is the example to specify
the path:

``` r
library(spacyr)
spacy_initialize(python_executable = "C:\Users\***\AppData\Local\Programs\Python\Python36\python.exe")
```

(where `***` is replaced by your user name, as indicated from
`where python`.)

The value of `python_executable` has to be set to one of the python
executables returned from `where python`, in which you have also
installed spaCy and a language model.
