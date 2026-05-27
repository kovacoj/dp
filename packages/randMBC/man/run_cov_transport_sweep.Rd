\name{run_cov_transport_sweep}
\alias{run_cov_transport_sweep}
\title{Run a covariance-transport parameter sweep}
\description{Iterates over a grid of rank, lambda, sketch, and precision settings, running multiple trials per grid point and collecting results in a data frame.}
\usage{
run_cov_transport_sweep(
  cov_op,
  ranks = c(5L, 10L, 15L, 20L),
  lambdas = c(1e-6, 1e-4, 1e-2),
  sketches = c("gaussian", "rademacher"),
  precisions = c("double", "single"),
  n_trials = 5L,
  oversampling = 5L,
  base_seed = 1L
)
}
\arguments{
  \item{cov_op}{Covariance operator list from \code{generate_cov_operator} or \code{generate_climate_cov}.}
  \item{ranks}{Integer vector of target ranks.}
  \item{lambdas}{Numeric vector of regularization parameters.}
  \item{sketches}{Character vector of sketch distribution names.}
  \item{precisions}{Character vector of sketch-precision names.}
  \item{n_trials}{Number of independent trials per grid point.}
  \item{oversampling}{Oversampling parameter (fixed across sweep).}
  \item{base_seed}{Starting seed; each trial increments by 1.}
}
\value{A data frame with one row per trial, containing scalar diagnostics and parameter settings.}
\examples{
op <- generate_cov_operator(20, rank = 10, spectrum = "exponential", cond = 100)
df <- run_cov_transport_sweep(op, ranks = c(5, 10), lambdas = 1e-6,
  n_trials = 3, base_seed = 42)
nrow(df)
}
