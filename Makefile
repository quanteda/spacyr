.PHONY: readme vignette

# Knit README.md and index.md (the pkgdown home page) from their .Rmd sources.
# CI checks that both are up to date (.github/workflows/render-readme.yaml).
readme:
	Rscript -e "rmarkdown::render('README.Rmd', quiet = TRUE)"
	Rscript -e "rmarkdown::render('index.Rmd', quiet = TRUE)"

# Knit each vignette's source, vignettes/*.Rmd.orig, into the .Rmd of the same
# name, with its results computed ahead of time, since running its code needs
# spaCy. Uses this copy of spacyr, so run it after changes that affect the
# vignettes' output.
vignette:
	cd vignettes && Rscript -e "pkgload::load_all('..', quiet = TRUE); for (f in list.files(pattern = '[.]Rmd[.]orig$$')) knitr::knit(f, output = sub('[.]orig$$', '', f), quiet = TRUE)"
