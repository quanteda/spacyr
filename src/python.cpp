#include <Rcpp.h>
#include <Python.h>
#include "redirect.hpp"
#include "converters.hpp"

#include <dlfcn.h>

// Based on:
// http://gallery.rcpp.org/articles/matplotlib-from-R/
// http://gallery.rcpp.org/articles/rcpp-python/

using namespace Rcpp;

//' Run python code
//'
//' Runs Python code in namespace __main__ . 
//' 
//' @param command Python code to execute as string
//' @examples
//' pyrun("print(range(5))")
//' @export
//[[Rcpp::export]]
void pyrun(std::string command) {
  PyRun_SimpleString(command.c_str());
}

//[[Rcpp::export]]
void py_initialize(const std::string& pythonSharedLibrary) {
  
#ifndef __APPLE__
  // force RTLD_GLOBAL for importing python libraries on Linux
  // http://stackoverflow.com/questions/29880931/
  // https://mail.python.org/pipermail/new-bugs-announce/2008-November/003322.html
  void *lib = dlopen(pythonSharedLibrary.c_str(), RTLD_NOW|RTLD_GLOBAL);
  if (lib == NULL) {
    const char* err = dlerror();
    stop(err);
  }
#endif
  
  Py_Initialize();
  PyObject *m = PyImport_AddModule("__main__");
  PyObject *main = PyModule_GetDict(m);
  PyObject *f = PyCFunction_New(redirect_pystdout, (PyObject*)NULL);
  PyObject *f2 = PyCFunction_New(redirect_pystderr, (PyObject*)NULL);
  PyDict_SetItemString(main, "_Rcout",  f);
  PyDict_SetItemString(main, "_Rcerr",  f2);
  pyrun("class _StdoutCatcher:\n  def write(self, out):\n    _Rcout(out)");
  pyrun("class _StderrCatcher:\n  def write(self, out):\n    _Rcerr(out)");
  pyrun("import sys\nsys.stdout = _StdoutCatcher()");
  pyrun("import sys\nsys.stderr = _StderrCatcher()");
}

//[[Rcpp::export]]
void finalize_python() {
  Py_Finalize();
}

//' Push data to python __main__ namespace
//' 
//' @param name Python variable name as string
//' @param x Numeric vector to copy to Python
//[[Rcpp::export(name="topy.numeric")]]
void numvec_to_python(NumericVector x, std::string name){
  to_main(name, to_list(x));
}

//[[Rcpp::export(name="topy.character")]]
void charvec_to_python(std::vector<std::string> strings, std::string name){
  to_main(name, to_list(strings));
}

//Add NumericVector to dict in Python
//Used to "hide" variables for plotting
//[[Rcpp::export(name="pydict.numeric")]]
void num_to_dict(NumericVector x, std::string name, std::string dictname){
  add_to_dict(name, dictname, to_list(x));
}

//Add character vector to dict in Python
//Used to "hide" variables for plotting
//[[Rcpp::export(name="pydict.character")]]
void char_to_dict(std::vector<std::string>  x, std::string name, std::string dictname){
  add_to_dict(name, dictname, to_list(x));
}