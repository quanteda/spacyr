if (requireNamespace("spelling", quietly = TRUE)) {
    error <- TRUE
    additional_files <- c("index.Rmd", "README.Rmd", "installation.Rmd")

    # regular package check
    spelling::spell_check_test(vignettes = TRUE, error = error,
                               skip_on_cran = TRUE)

    # check additional files
    # results <- spelling::spell_check_files(
    #     path = additional_files,
    #     ignore = spelling::get_wordlist(),
    #     lang = "en_GB"
    # )
    # if (nrow(results)) {
    #     if (error) {
    #         output <- sprintf("Potential spelling errors: %s\n", paste(results$word, collapse = ", "))
    #         stop(output, call. = FALSE)
    #     } else {
    #         cat("Potential spelling errors:\n")
    #         print(results)
    #     }
    # }
}
