cov_transport <- function(cov_x, cov_y, lambda = 1e-6) {
    if (!is.matrix(cov_x) || !is.matrix(cov_y)) {
        stop("cov_x and cov_y must be matrices")
    }
    if (!all(dim(cov_x) == dim(cov_y))) {
        stop("cov_x and cov_y must have matching dimensions")
    }
    if (!is.numeric(lambda) || length(lambda) != 1L || lambda < 0) {
        stop("lambda must be a nonnegative scalar")
    }

    p <- ncol(cov_x)
    source <- (cov_x + t(cov_x)) / 2 + diag(lambda, p)
    target <- (cov_y + t(cov_y)) / 2 + diag(lambda, p)
    transport <- sym_matrix_power(source, -0.5) %*% sym_matrix_power(target, 0.5)

    list(
        transport = transport,
        source = source,
        target = target
    )
}

sym_matrix_power <- function(a, power) {
    eig <- eigen((a + t(a)) / 2, symmetric = TRUE)
    vals <- pmax(eig$values, .Machine$double.eps)
    eig$vectors %*% diag(vals^power, nrow = length(vals)) %*% t(eig$vectors)
}
