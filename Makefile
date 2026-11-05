.PHONY: readme

# Knit README.md and index.md (the pkgdown home page) from their .Rmd sources.
# CI checks that both are up to date (.github/workflows/render-readme.yaml).
readme:
	Rscript -e "rmarkdown::render('README.Rmd', quiet = TRUE)"
	Rscript -e "rmarkdown::render('index.Rmd', quiet = TRUE)"
