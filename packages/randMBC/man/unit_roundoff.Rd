\name{unit_roundoff}
\alias{unit_roundoff}
\title{Return the unit roundoff for a computational stage}
\description{Dispatches on the precision model class and returns the unit roundoff \eqn{u} for the requested computational stage.}
\usage{
unit_roundoff(pm, stage = c("sketch", "orth", "core"))
}
\arguments{
  \item{pm}{A \code{randMBC_precision} object.}
  \item{stage}{One of \code{"sketch"}, \code{"orth"}, or \code{"core"}.}
}
\value{A scalar giving the unit roundoff for the requested stage.}
\examples{
pm <- precision_model("single", "double")
unit_roundoff(pm, "sketch")
}
