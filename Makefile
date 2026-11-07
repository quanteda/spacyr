.PHONY: readme vignette

# Knit README.md and index.md (the pkgdown home page) from their .Rmd sources.
# CI checks that both are up to date (.github/workflows/render-readme.yaml).
readme:
	Rscript -e "rmarkdown::render('README.Rmd', quiet = TRUE)"
	Rscript -e "rmarkdown::render('index.Rmd', quiet = TRUE)"

# Knit the vignette's source into vignettes/using_spacyr.Rmd, with its results
# computed ahead of time, since running its code needs spaCy. Uses this copy of
# spacyr, so run it after changes that affect the vignette's output.
vignette:
	cd vignettes && Rscript -e "pkgload::load_all('..', quiet = TRUE); knitr::knit('using_spacyr.Rmd.orig', output = 'using_spacyr.Rmd', quiet = TRUE)"
