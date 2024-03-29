% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/spacy_langmodel_functions.R
\name{spacy_download_langmodel}
\alias{spacy_download_langmodel}
\title{Download spaCy language models}
\usage{
spacy_download_langmodel(lang_models = "en_core_web_sm", force = FALSE)
}
\arguments{
\item{lang_models}{character; language models to be installed. Defaults
\code{en_core_web_sm} (English model). A vector of multiple model names can
be used (e.g. \code{c("en_core_web_sm", "de_core_news_sm")}). A list of
available language models and their
names is available from the \href{https://spacy.io/usage/models}{spaCy language models} page.}

\item{force}{ignore if spaCy/the lang_models is already present and install
it anyway.}
}
\value{
Invisibly returns the installation log.
}
\description{
Download spaCy language models
}
\examples{
\dontrun{
# install medium sized model
spacy_download_langmodel("en_core_web_md")

#' # install several models with spaCy
spacy_install(lang_models = c("en_core_web_sm", "de_core_news_sm"))

# install transformer based model
spacy_download_langmodel("en_core_web_trf")
}
}
