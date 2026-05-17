gaussian_sketch <- function(s, n) {
    stopifnot(length(s) == 1L, length(n) == 1L, s >= 1L, n >= 1L)
    matrix(stats::rnorm(s * n), nrow = s, ncol = n) / sqrt(s)
}

rademacher_sketch <- function(s, n) {
    stopifnot(length(s) == 1L, length(n) == 1L, s >= 1L, n >= 1L)
    matrix(sample(c(-1, 1), s * n, replace = TRUE), nrow = s, ncol = n) / sqrt(s)
}

hadamard_matrix <- function(n) {
    stopifnot(length(n) == 1L, n >= 1L, n == as.integer(n))

    if (bitwAnd(n, n - 1L) != 0L) {
        stop("n must be a power of 2")
    }

    H <- matrix(1, nrow = 1L, ncol = 1L)
    while (nrow(H) < n) {
        H <- rbind(
            cbind(H, H),
            cbind(H, -H)
        )
    }
    H
}

srht_sketch <- function(s, n) {
    stopifnot(length(s) == 1L, length(n) == 1L, s >= 1L, n >= 1L)
    if (s > n) {
        stop("s must not exceed n")
    }

    H <- hadamard_matrix(as.integer(n))
    idx <- sample.int(n, size = s, replace = FALSE)
    signs <- sample(c(-1, 1), n, replace = TRUE)

    (H[idx, , drop = FALSE] * rep(signs, each = s)) / sqrt(s)
}
