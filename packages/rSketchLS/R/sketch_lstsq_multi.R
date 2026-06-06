#' Solve a multivariate least-squares problem with a randomized sketch
#'
#' Solves \eqn{\min_X \|AX - Y\|_F} by forming the sketched problem
#' \eqn{\min_X \|SAX - SY\|_F} and recovering \eqn{X} via QR on \eqn{SA}.
#'
#' @param A Numeric design matrix with more rows than columns.
#' @param Y Numeric right-hand side matrix with `nrow(Y) == nrow(A)`.
#' @param s Integer sketch size.
#' @param method Sketch family. One of `"gaussian"`, `"rademacher"`, or
#'   `"srht"`.
#' @param seed Optional integer seed for reproducibility.
#' @param return_sketch Logical; if `TRUE`, include the sketch matrix `S`
#'   in the output.
#'
#' @return A list with the solution matrix `X`, residual matrix, Frobenius
#'   residual norm, sketched-system condition number, sketch size, method,
#'   and optionally the sketch matrix.
#'
#' @examples
#' set.seed(1)
#' A <- matrix(rnorm(80), nrow = 20)
#' Y <- matrix(rnorm(60), nrow = 20)
#' fit <- sketch_lstsq_multi(A, Y, s = 10, method = "gaussian")
#' fit$residual_norm
#'
#' @export
sketch_lstsq_multi <- function(
    A, Y, s,
    method = c("gaussian", "rademacher", "srht"),
    seed = NULL,
    return_sketch = FALSE
) {
    method <- match.arg(method)

    if (!is.matrix(A)) stop("A must be a matrix")
    if (!is.matrix(Y)) stop("Y must be a matrix")
    n <- nrow(A)
    d <- ncol(A)
    p <- ncol(Y)

    if (nrow(Y) != n) stop("nrow(Y) must equal nrow(A)")
    if (!is.numeric(s) || length(s) != 1L || s < 1L) stop("s must be a positive integer")
    s <- as.integer(s)
    if (s < d) warning("s < ncol(A): the sketched system may be underdetermined")

    if (!is.null(seed)) set.seed(seed)

    S <- switch(
        method,
        gaussian = gaussian_sketch(s, n),
        rademacher = rademacher_sketch(s, n),
        srht = srht_sketch(s, n)
    )

    SA <- S %*% A
    SY <- S %*% Y
    qr_sa <- qr(SA)
    X <- qr.coef(qr_sa, SY)
    residual <- A %*% X - Y
    condition_number <- kappa(SA)

    out <- list(
        X = X,
        residual = residual,
        residual_norm = sqrt(sum(residual^2)),
        condition_number = condition_number,
        sketch_size = s,
        method = method
    )
    if (return_sketch) out$S <- S
    out
}
