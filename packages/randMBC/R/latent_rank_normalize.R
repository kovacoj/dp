#' Rank-normalize and inverse-normal transform a data matrix
#'
#' Applies plotting-position ranking, then transforms to a standard-normal
#' scale via the inverse-normal CDF. Columns are centered after the transform.
#'
#' @param values Numeric matrix to transform.
#' @param reference Numeric matrix used to define the empirical CDF for each
#'   column. If `NULL`, `values` is used as its own reference.
#' @param ties_method Character. `"average"` or `"first"`, controlling how
#'   ties are broken during ranking. Default `"average"`.
#'
#' @return A numeric matrix of the same dimensions as `values`, on the
#'   latent Gaussian scale.
#' @examples
#' set.seed(1)
#' x <- matrix(rnorm(60), nrow = 20, ncol = 3)
#' z <- latent_rank_normalize(x)
#' all(abs(colMeans(z)) < 0.3)
#' @export
latent_rank_normalize <- function(values, reference = NULL, ties_method = "average") {
    if (!is.matrix(values)) stop("values must be a matrix")
    if (is.null(reference)) reference <- values
    if (!is.matrix(reference)) stop("reference must be a matrix")
    if (ncol(values) != ncol(reference)) stop("values and reference must have the same number of columns")

    out <- matrix(0, nrow = nrow(values), ncol = ncol(values))
    for (j in seq_len(ncol(values))) {
        n_tau <- max(nrow(reference), 32L)
        tau <- seq(0, 1, length.out = n_tau)
        q_ref <- stats::quantile(reference[, j], probs = tau, type = 7, names = FALSE)
        u <- stats::approx(q_ref, tau, xout = values[, j], rule = 2, ties = "ordered")$y
        u <- pmin(pmax(u, 1e-6), 1 - 1e-6)
        z <- stats::qnorm(u)
        out[, j] <- z - mean(z)
    }
    colnames(out) <- colnames(values)
    out
}

#' Restore marginal distributions from a latent-score matrix
#'
#' Replaces the marginal distributions of `target_values` with those from
#' `marginals`, rearranged according to the columnwise ranks of `scores`.
#' This is the inverse step of [latent_rank_normalize()].
#'
#' @param marginals Numeric matrix whose sorted columns supply the target
#'   marginal values.
#' @param scores Numeric matrix whose columnwise ranks determine the
#'   rearrangement.
#' @param ties_method Character. `"average"` or `"first"`. Default `"average"`.
#'
#' @return A numeric matrix with the marginals of `marginals` and the
#'   dependence structure induced by `scores`.
#' @examples
#' set.seed(1)
#' x <- matrix(rnorm(60), nrow = 20, ncol = 3)
#' z <- latent_rank_normalize(x)
#' y <- restore_marginals_by_rank(x, z)
#' max(abs(sort(x[, 1]) - sort(y[, 1])))
#' @export
restore_marginals_by_rank <- function(marginals, scores, ties_method = "average") {
    if (!is.matrix(marginals)) stop("marginals must be a matrix")
    if (!is.matrix(scores)) stop("scores must be a matrix")
    if (!all(dim(marginals) == dim(scores))) stop("marginals and scores must have the same dimensions")

    out <- matrix(0, nrow = nrow(marginals), ncol = ncol(marginals))
    for (j in seq_len(ncol(marginals))) {
        if (ties_method == "first") {
            rnk <- rank(scores[, j], ties.method = "first", na.last = TRUE)
            ord <- sort.list(rnk)
        } else {
            ord <- order(scores[, j], na.last = TRUE)
        }
        out[ord, j] <- sort(marginals[, j], na.last = TRUE)
    }
    colnames(out) <- colnames(marginals)
    out
}
