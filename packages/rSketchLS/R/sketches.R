#' Generate a Gaussian sketching matrix
#'
#' Creates an \eqn{s \times n} dense Gaussian sketch with entries scaled by
#' \eqn{1 / \sqrt{s}}.
#'
#' @param s Integer number of sketch rows.
#' @param n Integer number of input rows.
#'
#' @return A numeric matrix with `s` rows and `n` columns.
#'
#' @examples
#' set.seed(1)
#' S <- gaussian_sketch(8, 20)
#' dim(S)
#'
#' @export
gaussian_sketch <- function(s, n) {
    stopifnot(length(s) == 1L, length(n) == 1L, s >= 1L, n >= 1L)
    matrix(stats::rnorm(s * n), nrow = s, ncol = n) / sqrt(s)
}

#' Generate a Rademacher sketching matrix
#'
#' Creates an \eqn{s \times n} dense sketch with independent signs scaled by
#' \eqn{1 / \sqrt{s}}.
#'
#' @param s Integer number of sketch rows.
#' @param n Integer number of input rows.
#'
#' @return A numeric matrix with `s` rows and `n` columns.
#'
#' @examples
#' set.seed(1)
#' S <- rademacher_sketch(8, 20)
#' unique(as.vector(S))
#'
#' @export
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

#' Generate an SRHT sketching matrix
#'
#' Creates a subsampled randomized Hadamard transform (SRHT) sketch. The input
#' dimension `n` must be a power of two.
#'
#' @param s Integer number of sampled Hadamard rows.
#' @param n Integer input dimension. Must be a power of two.
#'
#' @return A numeric matrix with `s` rows and `n` columns.
#'
#' @examples
#' set.seed(1)
#' S <- srht_sketch(4, 8)
#' dim(S)
#'
#' @export
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
