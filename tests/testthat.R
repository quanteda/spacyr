Sys.setenv("R_TESTS" = "")

library(testthat)
library(spacyr)

test_check("spacyr")
