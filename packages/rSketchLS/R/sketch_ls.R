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

    list(
        x = fit,
        residual = residual,
        residual_norm = sqrt(sum(residual^2)),
        sketch_size = s,
        method = method
    )
}
