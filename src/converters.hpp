//Converters borrowed from https://github.com/mpastell/Rpyplot 

#ifndef __CONVERT__
#define __CONVERT__
#include <Rcpp.h>
#include <Python.h>

//Converters from R to Python
using namespace Rcpp;

//Convert NumericVector to Python List
PyObject* to_list(NumericVector x){
  int n = x.length();
  PyObject *xpy = PyList_New(n);
  PyObject *f;
  
  for (int i=0; i<n; i++)
  {
    f = PyFloat_FromDouble(x[i]);
    PyList_SetItem(xpy, i, f);
  }
  
  return(xpy);
}

//Convert CharacterVector to Python List
PyObject* to_list(std::vector<std::string> strings){
  int n = strings.size();
  PyObject *xpy = PyList_New(n);
  PyObject *s;
  
  for (int i=0; i<n; i++)
  {
    s = PyUnicode_FromString(strings[i].c_str());
    PyList_SetItem(xpy, i, s);
  }
  return(xpy);
}

//Push data to python __main__ namespace
void to_main(std::string name, PyObject *pyobj)
{
  PyObject *main = PyModule_GetDict(PyImport_AddModule("__main__"));
  PyDict_SetItemString(main, name.c_str(), pyobj);
  //Py_CLEAR(pyobj);
}

//Get data from __main__ namespace
PyObject* from_main(std::string name){
  PyObject *main = PyModule_GetDict(PyImport_AddModule("__main__"));
  return PyDict_GetItemString(main, name.c_str());
}

//Add data to dict in main. Create the dict if it doesn't exist
void add_to_dict(std::string name, std::string dictname, PyObject *pyobj)
{
  PyObject *dict = from_main(dictname);
  if (dict==NULL || !PyDict_Check(dict))// !PyDict_Check(dict)) //Create new if dict doesn't exist
  {
    dict = PyDict_New();
  }
  PyDict_SetItemString(dict, name.c_str(), pyobj);  
  to_main(dictname, dict);
}

//' Get numeric vector from python __main__ namespace.
//' 
//' The data retrieved from Python has to be a list of numbers.
//' 
//' @param name Python variable name
//' 
//' @export
//[[Rcpp::export]]
NumericVector numvec_to_R(std::string name){
  PyObject *list = from_main(name);
  
  if (list == NULL)
  {
    Rcout << "Error: Unknown Python variable\n";
    return NumericVector(0);
  }
  
  int n = (int)PyList_Size(list);
  NumericVector x(n);
  
  for (int i=0; i<n; i++)
  {
    x(i) = PyFloat_AsDouble(PyList_GetItem(list, i));
    //Rcout << x(i) << std::endl;
  }
  
  return x;
}

//' Copy list of strings from Python to R character vector
//' 
//' @examples
//'
//'pyrun("l = ['a', 'b']")
//'pyrun("print(l)")
//'charvec_to_R("l")
//'pyrun("l2 = [u'a', u'b']")
//'charvec_to_R("l2")
//' @param name Python variable name
//' 
//' @export
//[[Rcpp::export]]
std::vector<std::string> charvec_to_R(std::string name){
  PyObject *list = from_main(name);
  
  if (list == NULL)
  {
    Rcout << "Error: Unknown Python variable\n";
    std::vector< std::string > x(0);
    return x;
  }
  
  int n = (int)PyList_Size(list);
  std::vector< std::string > x(n);
  PyObject *item;
  
  for (int i=0; i<n; i++)
  {
    
    item = PyList_GetItem(list, i);
#if PY_MAJOR_VERSION >= 3
    x[i] = PyBytes_AsString(PyUnicode_AsUTF8String(item));
#else
    if (PyString_Check(item)){
      x[i] = PyString_AsString(item);
    } else
    {
      x[i] = PyBytes_AsString(PyUnicode_AsUTF8String(item));
    }
#endif
  }
  //Rcout << x[i] << std::endl;
  return x;
}

//[[Rcpp::export]]
std::string char_to_R(std::string name){
  PyObject *var = from_main(name);
  std::string x;
  
  if (var == NULL)
  {
    Rcout << "Error: Unknown Python variable\n";
    return "";
  }
  
#if PY_MAJOR_VERSION >= 3
  x = PyBytes_AsString(PyUnicode_AsUTF8String(var));
#else
  if (PyString_Check(var)){
    x = PyString_AsString(var);
  } else
  {
    x = PyBytes_AsString(PyUnicode_AsUTF8String(var));
  }
#endif
  
  return x;
}

//[[Rcpp::export]]
double num_to_R(std::string name){
  PyObject *var = from_main(name);
  
  if (var == NULL)
  {
    Rcout << "Error: Unknown Python variable\n";
    return NA_REAL;
  }
  
  return PyFloat_AsDouble(var);
}

#endif