\name{cov_transport}
\alias{cov_transport}
\title{Build a regularized covariance transport map}
\description{Forms the transport map from a source covariance to a target covariance using symmetric matrix square roots and inverse square roots.}
\usage{
cov_transport(cov_x, cov_y, lambda = 1e-6)
}
\arguments{
  \item{cov_x}{Source covariance matrix.}
  \item{cov_y}{Target covariance matrix.}
  \item{lambda}{Nonnegative regularization added to both covariance matrices before taking matrix powers.}
}
\value{A list containing the transport matrix and the regularized source and target covariance matrices.}
\examples{
cov_transport(diag(2), diag(c(2, 3)))
}
