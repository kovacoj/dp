#' Randomized low-rank covariance approximation
#'
#' Approximates the covariance of a latent data matrix with a randomized range
#' finder and returns a regularized low-rank surrogate.
#'
#' @param Z Numeric matrix whose rows are samples and whose columns are latent
#'   features.
#' @param rank Target approximation rank.
#' @param oversampling Oversampling parameter added to the target rank before
#'   range finding.
#' @param sketch Sketch distribution used to draw the sampling matrix.
#' @param mult_prec Simulated precision used in the covariance-action products.
#' @param orth_prec Simulated precision used before orthogonalization.
#' @param lambda Nonnegative ridge parameter added to the returned covariance
#'   surrogate.
#'
#' @return A list containing the sampled range basis `Q`, the projected core
#'   matrix `B`, the regularized covariance approximation, and basic
#'   diagnostics.
#' @examples
#' set.seed(1)
#' z <- matrix(rnorm(80), nrow = 20, ncol = 4)
#' fit <- rand_cov_approx(z, rank = 2, oversampling = 1)
#' fit$rank
#' @export
rand_cov_approx <- function(
    Z,
    rank = 20L,
    oversampling = 10L,
    sketch = c("gaussian", "rademacher"),
    mult_prec = c("double", "single", "half", "bfloat16"),
    orth_prec = c("double", "single"),
    lambda = 1e-6
) {
    sketch <- match.arg(sketch)
    mult_prec <- match.arg(mult_prec)
    orth_prec <- match.arg(orth_prec)

    if (!is.matrix(Z)) {
        stop("Z must be a matrix")
    }
    if (!is.numeric(rank) || length(rank) != 1L || rank < 1L) {
        stop("rank must be a positive scalar")
    }
    if (!is.numeric(oversampling) || length(oversampling) != 1L || oversampling < 0L) {
        stop("oversampling must be a nonnegative scalar")
    }
    if (!is.numeric(lambda) || length(lambda) != 1L || lambda < 0) {
        stop("lambda must be a nonnegative scalar")
    }

    n <- nrow(Z)
    p <- ncol(Z)
    ell <- min(p, as.integer(rank + oversampling))
    rank_used <- min(as.integer(rank), ell)

    start <- proc.time()[[3L]]

    omega <- draw_sketch_matrix(p, ell, sketch)
    z_low <- fl_round(Z, mult_prec)
    omega_low <- fl_round(omega, mult_prec)
    sample_y <- fl_round(covariance_action(z_low, omega_low), mult_prec)
    y_for_qr <- fl_round(sample_y, orth_prec)

    q_full <- qr.Q(qr(y_for_qr))
    q <- q_full[, seq_len(rank_used), drop = FALSE]
    cov_q <- covariance_action(Z, q)
    b <- crossprod(q, cov_q)
    cov_approx <- q %*% b %*% t(q)
    cov_regularized <- cov_approx + diag(lambda, p)
    eigvals <- eigen((b + t(b)) / 2, symmetric = TRUE, only.values = TRUE)$values
    reg_eigvals <- eigen((cov_regularized + t(cov_regularized)) / 2, symmetric = TRUE, only.values = TRUE)$values

    list(
        Q = q,
        B = b,
        covariance_raw = cov_approx,
        covariance = cov_regularized,
        lambda = lambda,
        rank = rank_used,
        sketch = sketch,
        precision = list(mult = mult_prec, orth = orth_prec),
        eigvals = eigvals,
        reg_eigvals = reg_eigvals,
        residual_norm_est = sampled_range_residual(y_for_qr, q),
        lambda_min_reg = min(reg_eigvals),
        condition_est = kappa(cov_regularized),
        runtime = proc.time()[[3L]] - start
    )
}

#' Draw a randomized sketch matrix
#'
#' @param p Number of rows in the sketching operator.
#' @param ell Number of columns in the sketching operator.
#' @param sketch Sketch distribution name.
#'
#' @return A numeric matrix of dimension `p x ell`.
#' @noRd
draw_sketch_matrix <- function(p, ell, sketch) {
    switch(
        sketch,
        gaussian = matrix(stats::rnorm(p * ell), nrow = p, ncol = ell),
        rademacher = matrix(sample(c(-1, 1), p * ell, replace = TRUE), nrow = p, ncol = ell)
    )
}

#' Apply a covariance operator without materializing it
#'
#' @param Z Data matrix whose empirical covariance defines the operator.
#' @param rhs Right-hand side matrix or vector.
#'
#' @return The product `(Z' Z / n) rhs`.
#' @noRd
covariance_action <- function(Z, rhs) {
    crossprod(Z, Z %*% rhs) / nrow(Z)
}

#' Estimate the residual left outside a sampled range
#'
#' @param sample_y Sampled range matrix.
#' @param q Orthonormal basis used to project `sample_y`.
#'
#' @return Frobenius norm of the projection residual.
#' @noRd
sampled_range_residual <- function(sample_y, q) {
    projected <- q %*% crossprod(q, sample_y)
    norm(sample_y - projected, type = "F")
}
