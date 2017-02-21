AC_INIT([spacyr], [0.1.4])
AC_CONFIG_SRCDIR([src])

# find R home and set CC/CFLAGS
: ${R_HOME=`R RHOME`}
if test -z "${R_HOME}"; then
  echo "Could not determine R_HOME"
  exit 1
fi
RBIN="${R_HOME}/bin/R"
CC=`"${RBIN}" CMD config CC`;
CFLAGS=`"${RBIN}" CMD config CFLAGS`

# find spacy target python binary
if test -z "${SPACY_PYTHON}"
then
  echo "Using python binary from PATH"
  USE_PYTHON=python
else
  echo "Using python binary at ${SPACY_PYTHON}"
  USE_PYTHON=${SPACY_PYTHON}
fi

# find python
PYTHON_BIN=`which ${USE_PYTHON}`
if test -z "${PYTHON_BIN}"; then
  echo "Could not locate ${PYTHON_BIN}"
  exit 1
fi

# determine path to python-config
USE_PYTHON_CONFIG=${USE_PYTHON}-config

# Extract the linker and include flags for python
: ${PYTHONCONFIG=`which ${USE_PYTHON_CONFIG}`}
if test -z "${PYTHONCONFIG}"; then
  echo "Could not locate ${USE_PYTHON_CONFIG}"
  exit 1
fi

PKG_LIBS=`$PYTHONCONFIG --ldflags`
PKG_CPPFLAGS=`$PYTHONCONFIG --includes`

# Find the .so library for python
PYTHONLIBFILE=libpython`$PYTHON_BIN -c "import sys; print(sys.version[[:3]])"`.so
PKG_CPPFLAGS="$PKG_CPPFLAGS -D PYTHONLIBFILE=$PYTHONLIBFILE"

AC_SUBST(PYTHON_BIN)
AC_SUBST(PKG_LIBS)
AC_SUBST(PKG_CPPFLAGS)

# Check autoconf version
#AC_PREREQ

# Specify a compiler to use
#AC_PROG_CC

AC_CONFIG_FILES([src/Makevars R/config.R])
AC_OUTPUT