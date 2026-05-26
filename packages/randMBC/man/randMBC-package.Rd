\name{randMBC-package}
\alias{randMBC-package}
\alias{randMBC}
\title{randMBC: Randomized Multivariate Bias Correction Backend}
\description{Experimental thesis package for randomized low-rank covariance transport in multivariate bias correction. The current package exports a simulated floating-point rounding helper, a precision model abstraction, randomized covariance approximation, a regularized covariance transport map, and a top-level prototype for dependence correction after marginal adjustment.}
\details{The package is intentionally narrow at this stage. It focuses on the numerical backend needed for thesis experiments rather than a full climate-facing user interface. The precision model (\code{precision_model}) encapsulates stage-specific rounding and unit-roundoff values so that experiment code does not need to track format strings manually.}
