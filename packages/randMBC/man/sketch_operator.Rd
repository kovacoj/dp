\name{sketch_operator}
\alias{sketch_operator}
\alias{apply_sketch}
\alias{sketch_norm}
\title{Create and apply sketch operators}
\description{Encapsulates a sketch distribution, dimensions, random seed, and scaling in one S3 object. Apply via \code{apply_sketch}; query norms via \code{sketch_norm}.}
\usage{
sketch_operator(
  sketch = c("gaussian", "rademacher", "srht"),
  n,
  s,
  p = NULL,
  seed = NULL
)

apply_sketch(sk, A)

sketch_norm(sk, type = c("2", "F"))
}
\arguments{
  \item{sketch}{Sketch distribution: \code{"gaussian"}, \code{"rademacher"}, or \code{"srht"}.}
  \item{n}{Number of rows in the target matrix (ambient dimension).}
  \item{s}{Number of rows in the sketch (sketch dimension).}
  \item{p}{Number of columns in the target matrix. Required only for \code{"srht"}.}
  \item{seed}{Optional integer seed.}
  \item{sk}{A \code{randMBC_sketch} object.}
  \item{A}{Numeric matrix or vector to sketch.}
  \item{type}{Norm type: \code{"2"} for spectral, \code{"F"} for Frobenius.}
}
\value{\code{sketch_operator} returns an object of class \code{randMBC_sketch}. \code{apply_sketch} returns the sketched matrix or vector. \code{sketch_norm} returns a nonnegative scalar.}
\examples{
sk <- sketch_operator("gaussian", n = 100, s = 30)
A <- matrix(rnorm(400), 40, 10)
SA <- apply_sketch(sk, A)
dim(SA)
sketch_norm(sk, "2")
}
