#' Solve least squares with a sketching preconditioner
#'
#' Computes a sketch of the design matrix, factors the sketched matrix, and
#' uses the triangular factor as a right preconditioner for the original
#' least-squares problem. This is a direct reference implementation of the
#' sketch-and-precondition strategy.
#'
#' @param A Numeric design matrix with full column rank.
#' @param b Numeric response vector with length equal to `nrow(A)`.
#' @param s Integer sketch size. If `NULL`, defaults to `min(nrow(A), 2 *
#'   (ncol(A) + 1))`.
#' @param method Sketch family. One of `"gaussian"`, `"rademacher"`, or
#'   `"srht"`.
#'
#' @return A list with the coefficient vector `x`, residual vector, residual
#'   norm, condition number of the right-preconditioned system, sketch size,
#'   method, and QR rank of the sketched system.
#'
#' @examples
#' set.seed(1)
#' A <- matrix(rnorm(160), nrow = 40)
#' b <- rnorm(40)
#' fit <- sketch_precond_lstsq(A, b, s = 20, method = "gaussian")
#' fit$preconditioned_condition_number
#'
#' @export
sketch_precond_lstsq <- function(A, b, s = NULL, method = c("gaussian", "rademacher", "srht")) {
    method <- match.arg(method)

    if (is.null(dim(A))) {
        stop("A must be a matrix")
    }

    n <- nrow(A)
    d <- ncol(A)

    if (length(b) != n) {
        stop("length(b) must equal nrow(A)")
    }

    if (is.null(s)) {
        s <- min(n, 2L * (d + 1L))
    }

    if (s < d) {
        stop("s must be at least ncol(A) for sketch-and-precondition")
    }

    S <- switch(
        method,
        gaussian = gaussian_sketch(s, n),
        rademacher = rademacher_sketch(s, n),
        srht = srht_sketch(s, n)
    )

    SA <- S %*% A
    qr_sa <- qr(SA)
    if (qr_sa$rank < d) {
        stop("sketched matrix is rank deficient")
    }

    R <- qr.R(qr_sa)[seq_len(d), , drop = FALSE]

    # A %*% solve(R) is formed by solving t(R) X^T = A^T.
    A_precond <- t(backsolve(R, t(A), transpose = TRUE))
    y <- qr.solve(A_precond, b)
    x <- backsolve(R, y)

    residual <- as.vector(A %*% x - b)

    list(
        x = x,
        residual = residual,
        residual_norm = sqrt(sum(residual^2)),
        preconditioned_condition_number = kappa(A_precond),
        sketch_size = s,
        method = method,
        qr_rank = qr_sa$rank
    )
}
