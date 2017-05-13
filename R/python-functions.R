spacyr_pyassign <- function(pyvarname, values) {
    main <- reticulate::import_main()
    eval(parse(text = sprintf("main$%s <- reticulate::r_to_py(values)", pyvarname)))
}

spacyr_pyget <- function(pyvarname) {
    main <- reticulate::import_main()
    return(eval(parse(text = sprintf("main$%s", pyvarname))))
}

spacyr_pyexec <- function(pystring = NULL, pyfile = NULL) {
    if(!is.null(pystring)) {
        reticulate::py_run_string(pystring)
    }
    if(!is.null(pyfile)) {
        reticulate::py_run_file(pyfile)
    }
}

