\name{generate_cov_operator}
\alias{generate_cov_operator}
\alias{generate_climate_cov}
\title{Generate synthetic covariance operators for thesis experiments}
\description{Creates symmetric positive semidefinite matrices with controllable spectrum, rank, and condition number. \code{generate_climate_cov} adds block structure mimicking spatially correlated climate fields.}
\usage{
generate_cov_operator(
  p,
  rank = p,
  spectrum = c("exponential", "linear", "flat", "gap"),
  cond = NULL,
  seed = NULL
)

generate_climate_cov(
  n_var = 3,
  n_loc = 10,
  rank_signal = 5,
  noise_level = 1e-3,
  seed = NULL
)
}
\arguments{
  \item{p}{Column dimension of the covariance operator.}
  \item{rank}{Exact rank (number of nonzero eigenvalues). Use \code{p} for full rank.}
  \item{spectrum}{Eigenvalue profile: \code{"exponential"} (geometric decay), \code{"linear"} (arithmetic decay), \code{"flat"} (all equal), or \code{"gap"} (one large + cluster of small).}
  \item{cond}{Target condition number of the nonzero part. Ignored when \code{spectrum = "flat"}.}
  \item{seed}{Optional integer seed for the random rotation.}
  \item{n_var}{Number of physical variables (for climate-shaped generator).}
  \item{n_loc}{Number of spatial locations per variable.}
  \item{rank_signal}{Rank of the dominant shared atmospheric-mode component.}
  \item{noise_level}{Relative magnitude of the noise floor eigenvalues.}
}
\value{A named list with components \code{covariance}, \code{eigvals}, \code{rank}, \code{spectrum}, and \code{cond}.}
\examples{
op <- generate_cov_operator(20, rank = 10, spectrum = "exponential", cond = 100)
op$rank
op$cond

clim <- generate_climate_cov(n_var = 3, n_loc = 10, rank_signal = 5)
clim$rank
}
