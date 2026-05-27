\name{summarize_results}
\alias{summarize_results}
\alias{check_fp_hidden}
\alias{write_results}
\alias{read_results}
\title{Summarize, check, and persist experiment results}
\description{Aggregates trial results into per-parameter summaries, checks whether floating-point error is hidden by randomized error, and reads/writes CSV.}
\usage{
summarize_results(df, fun = mean)

check_fp_hidden(summary_df, tol = 1.5)

write_results(df, path, row.names = FALSE)

read_results(path)
}
\arguments{
  \item{df}{Data frame of trial results from \code{run_cov_transport_sweep}.}
  \item{fun}{Summary function. Default \code{mean}.}
  \item{summary_df}{Summarized results from \code{summarize_results}.}
  \item{tol}{Relative tolerance for FP-hidden check. Default 1.5.}
  \item{path}{File path for CSV I/O.}
  \item{row.names}{Logical; passed to \code{write.csv}.}
}
\value{\code{summarize_results} and \code{check_fp_hidden} return data frames. \code{write_results} is called for its side effect. \code{read_results} returns a data frame.}
\examples{
op <- generate_cov_operator(20, rank = 10, spectrum = "exponential", cond = 100)
df <- run_cov_transport_sweep(op, ranks = c(5, 10), lambdas = 1e-6,
  precisions = c("double", "single"), n_trials = 3, base_seed = 1)
s <- summarize_results(df)
s <- check_fp_hidden(s)
"fp_hidden" \%in\% names(s)
}
