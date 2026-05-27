#' Solve a least-squares problem with a randomized sketch
#'
#' Forms a sketching matrix, solves the compressed least-squares problem
#' \eqn{\min_x \|SAx - Sb\|_2}, and reports diagnostics on the residual in
#' the original problem.
#'
#' @param A Numeric design matrix with more rows than columns.
#' @param b Numeric response vector with length equal to `nrow(A)`.
#' @param s Integer sketch size. If `NULL`, defaults to `min(nrow(A), 2 *
#'   (ncol(A) + 1))`.
#' @param method Sketch family. One of `"gaussian"`, `"rademacher"`, or
#'   `"srht"`.
#'
#' @return A list with the coefficient vector `x`, residual vector,
#'   residual norm, sketched-system condition number, sketch size, and method.
#'
#' @examples
#' set.seed(1)
#' A <- matrix(rnorm(80), nrow = 20)
#' b <- rnorm(20)
#' fit <- sketch_lstsq(A, b, s = 10, method = "gaussian")
#' fit$residual_norm
#'
#' @export
sketch_lstsq <- function(A, b, s = NULL, method = c("gaussian", "rademacher", "srht")) {
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
        warning("s < ncol(A): the sketched system may be underdetermined")
    }

    S <- switch(
        method,
        gaussian = gaussian_sketch(s, n),
        rademacher = rademacher_sketch(s, n),
        srht = srht_sketch(s, n)
    )

    SA <- S %*% A
    Sb <- S %*% b
    fit <- qr.solve(SA, Sb)
    residual <- as.vector(A %*% fit - b)
    condition_number <- kappa(SA)

    list(
        x = fit,
        residual = residual,
        residual_norm = sqrt(sum(residual^2)),
        condition_number = condition_number,
        sketch_size = s,
        method = method
    )
}
