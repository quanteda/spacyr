.PHONY: readme vignette

# Knit README.md and index.md (the pkgdown home page) from their .Rmd sources.
# CI checks that both are up to date (.github/workflows/render-readme.yaml).
readme:
	Rscript -e "rmarkdown::render('README.Rmd', quiet = TRUE)"
	Rscript -e "rmarkdown::render('index.Rmd', quiet = TRUE)"

# Knit the source of each vignette and pkgdown article, vignettes/*.Rmd.orig
# and vignettes/articles/*.Rmd.orig, into the .Rmd of the same name, with its
# results computed ahead of time, since running its code needs spaCy. Uses this
# copy of spacyr, so run it after changes that affect their output.
vignette:
	cd vignettes && Rscript -e "pkgload::load_all('..', quiet = TRUE); for (f in list.files(c('.', 'articles'), pattern = '[.]Rmd[.]orig$$', full.names = TRUE)) knitr::knit(f, output = sub('[.]orig$$', '', f), quiet = TRUE)"
