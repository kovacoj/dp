gaussianize_matrix <- function(values, reference) {
    out <- matrix(0, nrow = nrow(values), ncol = ncol(values))

    for (j in seq_len(ncol(values))) {
        out[, j] <- gaussianize_column(values[, j], reference[, j])
    }

    colnames(out) <- colnames(values)
    out
}

gaussianize_column <- function(values, reference) {
    n_tau <- max(length(reference), 32L)
    tau <- seq(0, 1, length.out = n_tau)
    q_ref <- stats::quantile(reference, probs = tau, type = 7, names = FALSE)
    u <- stats::approx(q_ref, tau, xout = values, rule = 2, ties = "ordered")$y
    u <- pmin(pmax(u, 1e-6), 1 - 1e-6)
    stats::qnorm(u)
}

rank_restore_matrix <- function(values, scores) {
    out <- matrix(0, nrow = nrow(values), ncol = ncol(values))

    for (j in seq_len(ncol(values))) {
        ord <- order(scores[, j], na.last = TRUE)
        out[ord, j] <- sort(values[, j], na.last = TRUE)
    }

    colnames(out) <- colnames(values)
    out
}
