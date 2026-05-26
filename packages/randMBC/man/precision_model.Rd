\name{precision_model}
\alias{precision_model}
\title{Create a precision model for a randMBC experiment}
\description{A precision model encapsulates the arithmetic assumptions used in a randomized covariance-transport experiment. It stores the working formats for each computational stage, the rounding mode, and provides accessor methods that apply stage-appropriate rounding without the caller needing to know format details.}
\usage{
precision_model(
  sketch_prec = c("double", "single", "half", "bfloat16"),
  orth_prec = c("double", "single"),
  core_prec = "double",
  rounding_mode = c("nearest")
)
}
\arguments{
  \item{sketch_prec}{Simulated precision used in the bulk sketch products \code{Z Omega} and \code{Z' (Z Omega)}.}
  \item{orth_prec}{Simulated precision used before QR orthogonalization.}
  \item{core_prec}{Simulated precision used inside the small core eigenproblems and matrix-function evaluations. Typically \code{"double"}.}
  \item{rounding_mode}{Character string. Currently only \code{"nearest"} is supported; this is a seam for future stochastic-rounding adapters.}
}
\value{An object of class \code{randMBC_precision} containing the stage formats, the rounding mode, and derived unit-roundoff values.}
\examples{
pm <- precision_model("single", "double")
pm$unit_roundoff("sketch")
pm$round_to_stage(matrix(rnorm(6), 3, 2), "sketch")
}
