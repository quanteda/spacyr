#' Copy variable from R to Python
#' 
#' @param name variable name in python
#' @param x R data, numeric and character vectors and numeric matrices are currently supported.
#'
#' @examples
#' pyvar("x", 1:10)
#' pyprint(x)
#' pyvar("s", c("Hello", "R!")) 
#' pyprint(s)
#' df <- data.frame(x = rnorm(10), y = 1:10)
#' pyvar(df)
#' pyprint(df)
#' pyvar("l", list(a=3, b=1:10, z="a"))
#' pyprint(l)
#' @export
pyvar <- function(name, x)
{
  if (missing(x)){
    x <- name
    name <- deparse(substitute(name))
  }
  topy(x, name)
}

# Generic method to copy data to Python
# 
# Some of the methods are defined in C++
# 
topy <- function(x, name) UseMethod("topy")

topy.matrix <- function(z, name)
{
  #Array moved to Python as list and converted to 
  #NumPy array
  nr = nrow(z)
  nc = ncol(z)
  topy.numeric(z, name)
  
  #numvec_to_python(paste(name,"z_size", sep=""), c(nr, nc))
  pyrun("import numpy as np")
  pyrun(sprintf("%s = (np.reshape(%s, [%i, %i], order='F'))", name, name, nr, nc))  
}


topy.list <- function(l, name)
{
  keys <- names(l)
  for (key in keys)
  {
    pydict(l[[key]], key, name)     
  }
}

topy.data.frame <- topy.list


#' Copy variables to a Python dictionary in __main__
#' 
#' @param x R object to copy
#' @param key Key of the object as string 
#' @param name of the dictionary
#'
#'  
#' @export
pydict <- function(x, key, dictname) UseMethod("pydict") #Some of the methods defined in pylab.cpp

pydict.factor <- function(x, key, dictname)
{
  pydict(as.character(x), key, dictname)
}


# Copy variables to _pvars dictionary for plotting
plotvar <- function(name, x, dictname="_pvars")
{
  if (missing(x)){
    x <- name
    name <- deparse(substitute(name))
  }
  
  pydict(x, name, dictname)
}


#' Print python object
#' 
#' @param name name of the python object
#' 
#' @examples
#' pyvar("x", 1:10)
#' pyprint(x)
#' pyprint("dir()") #You can quote Python commands
#' @export
pyprint <- function(x)
{
  cmd <- substitute(x)
  if (is.character(cmd))
  {
    pyrun(paste("print(", cmd, ")")) 
  }
  else
  {
    pyrun(paste("print(", deparse(cmd), ")")) 
  }
}

#' Get the type of Python variable
#' 
#' var name of the Pytho variable
#' 
#' @examples
#' pyvar("x", 1:10)
#' pytype(x)
#' pytype(x[1])
#' @importFrom utils capture.output
#' @export
pytype <- function(var){
  cmd <- substitute(var)
  if (!is.character(cmd))
    var = deparse(cmd) 
  capture.output(pyrun(sprintf("print(type(%s).__name__)", var)))
}

#Type without substitution
pytype_str <- function(var){
  capture.output(pyrun(sprintf("print(type(%s).__name__)", var)))
}


#' Copy a variable from Python to R
#' 
#' @param var Python variable name
#' 
#' @examples
#' pyvar("x", 1:10)
#' Rvar("x")
#' pyrun("f = 3")
#' Rvar("f")
#' pyrun("s = ['a', 'b', 'c']")
#' Rvar("s")
#' pyrun("s2 = 'a'")
#' Rvar("s2")
#' @export
Rvar <- function(var)
{
  cmd <- substitute(var)
  if (!is.character(cmd))
    var = deparse(cmd)
  
  type <- pytype_str(var)
  if (type=="str" || type=="unicode")
    return(char_to_R(var))
  if (type=="float" || type=="int")
    return(num_to_R(var))
  if (type == "list")
    return(Rvar_list(var))
  if (type == "dict")
    return(Rvar_dict(var))
  stop("Unsupported type")
}

#Python dict to R
Rvar_dict <- function(var)
{
  pyrun(sprintf("_pyr_keys = list(%s.keys())", var))
  keys <- Rvar("_pyr_keys")
  res <- list()
  for (key in keys)
  {
    pyrun(sprintf("_pyr_temp =  %s['%s']", var, key)) #Key need to be strings
    res[[key]] = Rvar("_pyr_temp") 
  }
  
  return(res)
}

#Python list to R
Rvar_list <- function(var)
{
  ltype = pytype_str(paste(var, "[0]", sep="")) #Get the type of list, based on first element
  if (ltype=="float" || ltype=="int")
    return(numvec_to_R(var))
  if (ltype=="str" || ltype=="unicode")
    return(charvec_to_R(var))
  stop("Unsupported type")
}