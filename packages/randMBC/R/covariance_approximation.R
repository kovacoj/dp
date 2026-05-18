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

    list(
        Q = q,
        B = b,
        covariance = cov_regularized,
        lambda = lambda,
        rank = rank_used,
        sketch = sketch,
        precision = list(mult = mult_prec, orth = orth_prec),
        eigvals = eigvals,
        residual_norm_est = sampled_range_residual(y_for_qr, q),
        condition_est = kappa(cov_regularized),
        runtime = proc.time()[[3L]] - start
    )
}

draw_sketch_matrix <- function(p, ell, sketch) {
    switch(
        sketch,
        gaussian = matrix(stats::rnorm(p * ell), nrow = p, ncol = ell),
        rademacher = matrix(sample(c(-1, 1), p * ell, replace = TRUE), nrow = p, ncol = ell)
    )
}

covariance_action <- function(Z, rhs) {
    crossprod(Z, Z %*% rhs) / nrow(Z)
}

sampled_range_residual <- function(sample_y, q) {
    projected <- q %*% crossprod(q, sample_y)
    norm(sample_y - projected, type = "F")
}
