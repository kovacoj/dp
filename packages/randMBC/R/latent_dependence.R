#' Gaussianize a multivariate sample columnwise
#'
#' @param values Matrix of values to transform.
#' @param reference Matrix used to define the marginal rank-to-Gaussian map.
#'
#' @return A matrix with the same dimensions as `values`, transformed to a
#'   latent Gaussian scale.
#' @noRd
gaussianize_matrix <- function(values, reference) {
    out <- matrix(0, nrow = nrow(values), ncol = ncol(values))

    for (j in seq_len(ncol(values))) {
        out[, j] <- gaussianize_column(values[, j], reference[, j])
    }

    colnames(out) <- colnames(values)
    out
}

#' Gaussianize one column against a reference sample
#'
#' @param values Numeric vector to transform.
#' @param reference Numeric reference vector used to build the empirical map.
#'
#' @return A numeric vector on the standard-normal scale.
#' @noRd
gaussianize_column <- function(values, reference) {
    n_tau <- max(length(reference), 32L)
    tau <- seq(0, 1, length.out = n_tau)
    q_ref <- stats::quantile(reference, probs = tau, type = 7, names = FALSE)
    u <- stats::approx(q_ref, tau, xout = values, rule = 2, ties = "ordered")$y
    u <- pmin(pmax(u, 1e-6), 1 - 1e-6)
    stats::qnorm(u)
}

#' Restore marginal values according to latent scores
#'
#' @param values Matrix containing the target marginal values.
#' @param scores Matrix whose columnwise ranks determine the rearrangement.
#'
#' @return A matrix with the marginals of `values` and the ordering induced by
#'   `scores`.
#' @noRd
rank_restore_matrix <- function(values, scores) {
    out <- matrix(0, nrow = nrow(values), ncol = ncol(values))

    for (j in seq_len(ncol(values))) {
        ord <- order(scores[, j], na.last = TRUE)
        out[ord, j] <- sort(values[, j], na.last = TRUE)
    }

    colnames(out) <- colnames(values)
    out
}
