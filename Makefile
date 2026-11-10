.PHONY: readme vignette

# Knit README.md and index.md (the pkgdown home page) from their .Rmd sources.
# CI checks that both are up to date (.github/workflows/render-readme.yaml).
readme:
	Rscript -e "rmarkdown::render('README.Rmd', quiet = TRUE)"
	Rscript -e "rmarkdown::render('index.Rmd', quiet = TRUE)"

# Knit the source of each vignette and pkgdown article, vignettes/*.Rmd.orig
# and vignettes/articles/*.Rmd.orig, into the .Rmd of the same name, with its
# results computed ahead of time, since running its code needs spaCy. Uses this
# copy of spacyr and starts a fresh R session for each source.
vignette:
	cd vignettes && for input in ./*.Rmd.orig articles/*.Rmd.orig; do \
		[ -f "$$input" ] || continue; \
		Rscript -e 'pkgload::load_all("..", quiet = TRUE)' \
			-e 'knitr::opts_chunk$$set(error = FALSE)' \
			-e 'input <- commandArgs(trailingOnly = TRUE)[[1L]]' \
			-e 'knitr::knit(input, output = sub("[.]orig$$", "", input), quiet = TRUE)' \
			"$$input" || exit $$?; \
	done
