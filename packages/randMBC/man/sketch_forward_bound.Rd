\name{sketch_forward_bound}
\alias{sketch_forward_bound}
\title{Estimate the forward-error bound for a sketch product}
\description{Under the standard matrix-product rounding model, the computed product \code{fl(Z' Z Omega)} satisfies \eqn{\|\Delta Y\|_2 \lesssim \gamma_n^{(u)} \|Z\|_2^2 / n \|\Omega\|_2}, where \eqn{u} is the unit roundoff of the working precision. This function evaluates that bound for a given precision model and data norms.}
\usage{
sketch_forward_bound(pm, norm_Z, norm_Omega, n, stage = c("sketch", "orth", "core"))
}
\arguments{
  \item{pm}{A \code{randMBC_precision} object.}
  \item{norm_Z}{Spectral norm of the data matrix \code{Z}.}
  \item{norm_Omega}{Spectral norm of the sketching matrix \code{Omega}.}
  \item{n}{Number of rows in \code{Z} (accumulation length).}
  \item{stage}{The computational stage whose precision governs the bound.}
}
\value{A scalar upper bound on \eqn{\|\Delta Y\|_2}.}
\examples{
pm <- precision_model("single", "double")
sketch_forward_bound(pm, norm_Z = 10, norm_Omega = sqrt(2), n = 100)
}
