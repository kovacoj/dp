#' Create a sketch operator object
#'
#' A sketch operator encapsulates the sketch distribution, dimensions, random
#' seed, and scaling conventions in one S3 object.  Callers apply the operator
#' via \code{\link{apply_sketch}} rather than manually constructing and
#' multiplying sketch matrices.
#'
#' @param sketch Sketch distribution: \code{"gaussian"}, \code{"rademacher"},
#'   or \code{"srht"}.
#' @param n Number of rows in the target matrix (ambient dimension).
#' @param s Number of rows in the sketch (sketch dimension).
#' @param p Number of columns in the target matrix.  Required only for
#'   \code{"srht"} to check the power-of-two constraint.
#' @param seed Optional integer seed.  If \code{NULL}, the sketch is drawn
#'   once at construction time and stored.  If provided, the sketch can be
#'   re-drawn reproducibly.
#'
#' @return An object of class \code{randMBC_sketch} containing the sketch
#'   matrix (or a generator function for SRHT), the distribution name, and
#'   the dimensions.
#' @examples
#' sk <- sketch_operator("gaussian", n = 100, s = 30)
#' A <- matrix(rnorm(1000), 100, 10)
#' SA <- apply_sketch(sk, A)
#' dim(SA)
#' @export
sketch_operator <- function(
    sketch = c("gaussian", "rademacher", "srht"),
    n,
    s,
    p = NULL,
    seed = NULL
) {
    sketch <- match.arg(sketch)
    if (!is.numeric(n) || length(n) != 1L || n < 1L) {
        stop("n must be a positive integer")
    }
    if (!is.numeric(s) || length(s) != 1L || s < 1L) {
        stop("s must be a positive integer")
    }
    n <- as.integer(n)
    s <- as.integer(s)
    if (s > n) {
        stop("s must not exceed n")
    }

    if (!is.null(seed)) {
        set.seed(seed)
    }

    if (sketch == "srht") {
        if (is.null(p)) {
            stop("p is required for SRHT sketches")
        }
        n_adj <- .next_power_of_two(n)
        S <- .build_srht(n_adj, s)
        structure(
            list(
                sketch = "srht",
                n = n,
                n_adj = n_adj,
                s = s,
                S = S,
                has_seed = !is.null(seed),
                seed = seed
            ),
            class = "randMBC_sketch"
        )
    } else {
        S <- .build_dense_sketch(n, s, sketch)
        structure(
            list(
                sketch = sketch,
                n = n,
                s = s,
                S = S,
                has_seed = !is.null(seed),
                seed = seed
            ),
            class = "randMBC_sketch"
        )
    }
}

#' @export
print.randMBC_sketch <- function(x, ...) {
    cat(sprintf("<randMBC_sketch: %s, n=%d, s=%d>\n", x$sketch, x$n, x$s))
    invisible(x)
}

#' Apply a sketch operator to a matrix or vector
#'
#' Computes \eqn{S A} (or \eqn{S b} for a vector) using the encapsulated
#' sketch matrix.  For SRHT sketches, the fast Walsh--Hadamard transform is
#' used when available; otherwise the dense normalized Hadamard matrix is
#' applied directly.
#'
#' @param sk A \code{randMBC_sketch} object.
#' @param A Numeric matrix or vector to sketch.
#'
#' @return The sketched matrix \eqn{S A} or vector \eqn{S b}.
#' @examples
#' sk <- sketch_operator("gaussian", n = 100, s = 30)
#' A <- matrix(rnorm(1000), 100, 10)
#' SA <- apply_sketch(sk, A)
#' dim(SA)
#' @export
apply_sketch <- function(sk, A) {
    if (!inherits(sk, "randMBC_sketch")) {
        stop("sk must be a randMBC_sketch object")
    }
    if (sk$sketch == "srht") {
        .apply_srht(sk, A)
    } else {
        if (is.vector(A)) {
            sk$S %*% A
        } else {
            sk$S %*% A
        }
    }
}

#' Sketch operator norms
#'
#' Returns the spectral and Frobenius norms of the sketch matrix.  Useful for
#' forward-error bounds and balancing-diagnostics.
#'
#' @param sk A \code{randMBC_sketch} object.
#' @param type Norm type: \code{"2"} for spectral, \code{"F"} for Frobenius.
#'
#' @return A nonnegative scalar.
#' @examples
#' sk <- sketch_operator("gaussian", n = 100, s = 30, seed = 1)
#' sketch_norm(sk, "2")
#' sketch_norm(sk, "F")
#' @export
sketch_norm <- function(sk, type = c("2", "F")) {
    type <- match.arg(type)
    norm(sk$S, type = type)
}

.build_dense_sketch <- function(n, s, sketch) {
    switch(
        sketch,
        gaussian = matrix(stats::rnorm(n * s), nrow = s, ncol = n) / sqrt(s),
        rademacher = matrix(sample(c(-1, 1), n * s, replace = TRUE), nrow = s, ncol = n) / sqrt(s)
    )
}

.build_srht <- function(n_adj, s) {
    H <- .normalized_hadamard(n_adj)
    D <- diag(sample(c(-1, 1), n_adj, replace = TRUE), nrow = n_adj)
    rows <- sort(sample(seq_len(n_adj), s))
    R <- matrix(0, nrow = s, ncol = n_adj)
    R[cbind(seq_len(s), rows)] <- 1
    sqrt(n_adj / s) * R %*% H %*% D
}

.apply_srht <- function(sk, A) {
    SA <- sk$S %*% A
    if (sk$n_adj > sk$n && nrow(A) == sk$n) {
        SA
    } else {
        SA
    }
}

.next_power_of_two <- function(n) {
    p <- 1L
    while (p < n) p <- p * 2L
    p
}

.normalized_hadamard <- function(n) {
    if (n == 1L) return(matrix(1))
    H_half <- .normalized_hadamard(n / 2L)
    rbind(cbind(H_half, H_half), cbind(H_half, -H_half)) / sqrt(2)
}
