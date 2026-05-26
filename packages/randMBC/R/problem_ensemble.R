#' Generate a synthetic covariance operator for thesis experiments
#'
#' Creates a \(p \times p\) symmetric positive semidefinite matrix with a
#' controllable spectrum.  The spectrum is constructed explicitly, so that the
#' rank, the spectral decay profile, and the target condition number are all
#' exact by construction.
#'
#' @param p Column dimension of the covariance operator.
#' @param rank Exact rank (number of nonzero eigenvalues).  Use `p` for
#'   full-rank operators.
#' @param spectrum Character string controlling the eigenvalue profile.
#'   \describe{
#'     \item{`"exponential"`}{Eigenvalues decay geometrically:
#'       \eqn{\mu_j = \mu_1 \rho^{j-1}}, where \eqn{\rho} is chosen to hit
#'       the target condition number.}
#'     \item{`"linear"`}{Eigenvalues decay linearly from \eqn{\mu_1} to
#'       \eqn{\mu_r}.}
#'     \item{`"flat"`}{All nonzero eigenvalues equal (well-conditioned
#'       low-rank operator).}
#'     \item{`"gap"`}{One large eigenvalue, a gap, then a cluster of small
#'       eigenvalues.  Useful for testing rank-selection behaviour.}
#'   }
#' @param cond Target condition number of the nonzero part.  Ignored when
#'   `spectrum = "flat"`.
#' @param seed Optional integer seed for the random rotation.
#'
#' @return A named list with components:
#'   \describe{
#'     \item{`covariance`}{The generated \(p \times p\) SPD matrix.}
#'     \item{`eigvals`}{The exact eigenvalues in nonincreasing order.}
#'     \item{`rank`}{The exact rank.}
#'     \item{`spectrum`}{The spectrum type used.}
#'     \item{`cond`}{The exact condition number.}
#'   }
#' @examples
#' op <- generate_cov_operator(20, rank = 10, spectrum = "exponential", cond = 100)
#' op$rank
#' op$cond
#' @export
generate_cov_operator <- function(
    p,
    rank = p,
    spectrum = c("exponential", "linear", "flat", "gap"),
    cond = NULL,
    seed = NULL
) {
    spectrum <- match.arg(spectrum)
    if (!is.numeric(p) || length(p) != 1L || p < 1L) {
        stop("p must be a positive integer")
    }
    if (!is.numeric(rank) || length(rank) != 1L || rank < 1L || rank > p) {
        stop("rank must be a positive integer <= p")
    }
    rank <- as.integer(rank)

    if (!is.null(seed)) {
        set.seed(seed)
    }

    eigvals <- .build_spectrum(rank, spectrum, cond)
    full_eigvals <- c(eigvals, rep(0, p - rank))
    Q <- .random_rotation(p)

    covariance <- Q %*% diag(full_eigvals, nrow = p) %*% t(Q)
    covariance <- (covariance + t(covariance)) / 2

    list(
        covariance = covariance,
        eigvals = full_eigvals,
        rank = rank,
        spectrum = spectrum,
        cond = if (spectrum == "flat") 1 else cond
    )
}

#' Generate a climate-shaped synthetic covariance operator
#'
#' Constructs a \(p \times p\) covariance matrix whose spectrum and block
#' structure mimic those observed in spatially correlated climate fields.  The
#' operator consists of a low-rank dominant component (shared atmospheric
#' modes), a block-diagonal component (local variable interactions), and a
#' noise floor.
#'
#' @param n_var Number of physical variables.
#' @param n_loc Number of spatial locations per variable.
#' @param rank_signal Rank of the dominant shared component.
#' @param noise_level Relative magnitude of the noise floor eigenvalues.
#' @param seed Optional integer seed.
#'
#' @return Same structure as \code{\link{generate_cov_operator}}.
#' @examples
#' op <- generate_climate_cov(n_var = 3, n_loc = 10, rank_signal = 5)
#' op$rank
#' @export
generate_climate_cov <- function(
    n_var = 3,
    n_loc = 10,
    rank_signal = 5,
    noise_level = 1e-3,
    seed = NULL
) {
    p <- n_var * n_loc
    if (!is.null(seed)) {
        set.seed(seed)
    }

    signal <- .random_rotation(p)[, seq_len(min(rank_signal, p)), drop = FALSE]
    signal_cov <- tcrossprod(signal) * n_loc

    block_cov <- matrix(0, p, p)
    for (v in seq_len(n_var)) {
        idx <- ((v - 1L) * n_loc + 1L):(v * n_loc)
        rho <- 0.8
        block_cov[idx, idx] <- rho^abs(outer(seq_len(n_loc), seq_len(n_loc), "-"))
    }

    covariance <- signal_cov + block_cov + diag(noise_level, p)
    covariance <- (covariance + t(covariance)) / 2

    eigvals <- eigen(covariance, symmetric = TRUE, only.values = TRUE)$values

    list(
        covariance = covariance,
        eigvals = eigvals,
        rank = p,
        spectrum = "climate-shaped",
        cond = eigvals[1] / max(eigvals[p], .Machine$double.eps)
    )
}

.build_spectrum <- function(rank, spectrum, cond) {
    if (rank == 1L) {
        return(1)
    }

    switch(
        spectrum,
        exponential = {
            rho <- cond^(-1 / (rank - 1))
            rho^seq(0, rank - 1)
        },
        linear = {
            seq(1, 1 / cond, length.out = rank)
        },
        flat = {
            rep(1, rank)
        },
        gap = {
            c(1, rep(1 / cond, rank - 1))
        }
    )
}

.random_rotation <- function(p) {
    Z <- matrix(stats::rnorm(p^2), nrow = p, ncol = p)
    qr.Q(qr(Z))
}
