\name{fl_round}
\alias{fl_round}
\title{Round values to a simulated floating-point format}
\description{Simulates coarser floating-point arithmetic by rounding numeric values to the significand width of a selected format.}
\usage{
fl_round(x, prec = c("double", "single", "half", "bfloat16"))
}
\arguments{
  \item{x}{Numeric vector, matrix, or array to round.}
  \item{prec}{Target floating-point format. \code{"double"} leaves the input unchanged.}
}
\value{An object with the same shape as \code{x}, rounded to the requested simulated precision.}
\examples{
fl_round(c(pi, 1e-3), "single")
}
