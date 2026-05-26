#' Fit randomized multivariate bias correction
#'
#' Runs the current randMBC backend: columnwise marginal adjustment, latent
#' Gaussianization, randomized covariance approximation, regularized covariance
#' transport, and marginal rank restoration.
#'
#' @param x_hist Historical model matrix.
#' @param y_hist Historical reference matrix with the same dimensions as
#'   `x_hist`.
#' @param x_fut Future model matrix with the same number of columns as
#'   `x_hist`.
#' @param rank Target covariance approximation rank.
#' @param oversampling Oversampling parameter for the randomized range finder.
#' @param sketch Sketch distribution used for covariance approximation.
#' @param precision Simulated precision used in the covariance-action products.
#' @param orth_prec Simulated precision used before orthogonalization.
#' @param lambda Regularization parameter for the covariance approximation.
#' @param ratio_seq Logical vector marking columns that should use ratio-style
#'   QDM handling, for example precipitation-like variables.
#' @param trace Dry-day threshold for ratio columns. Values below this threshold
#'   are zeroed after marginal adjustment.
#' @param trace_calc Internal threshold used to lift zero-like ratio values
#'   before quantile calculations.
#' @param ratio_max Maximum multiplicative change imposed on low-reference
#'   quantiles for ratio columns.
#' @param ratio_max_trace Threshold below which `ratio_max` is enforced.
#'
#' @return A list containing corrected future samples, corrected historical
#'   samples, post-QDM marginals, transport diagnostics, and the fitted
#'   covariance surrogates.
#' @examples
#' set.seed(2)
#' x_hist <- matrix(rnorm(60), nrow = 20, ncol = 3)
#' y_hist <- x_hist + matrix(rnorm(60, sd = 0.1), nrow = 20, ncol = 3)
#' x_fut <- matrix(rnorm(45), nrow = 15, ncol = 3)
#' fit <- fit_rand_mbc(x_hist, y_hist, x_fut, rank = 2, oversampling = 1)
#' dim(fit$corrected)
#' @export
fit_rand_mbc <- function(
    x_hist,
    y_hist,
    x_fut,
    rank = 20L,
    oversampling = 10L,
    sketch = c("gaussian", "rademacher"),
    precision = c("double", "single", "half", "bfloat16"),
    orth_prec = c("double", "single"),
    lambda = 1e-6,
    ratio_seq = rep(FALSE, ncol(x_hist)),
    trace = 0.05,
    trace_calc = 0.5 * trace,
    ratio_max = 2,
    ratio_max_trace = 10 * trace
) {
    sketch <- match.arg(sketch)
    precision <- match.arg(precision)
    orth_prec <- match.arg(orth_prec)

    validate_rand_mbc_inputs(
        x_hist,
        y_hist,
        x_fut,
        rank,
        oversampling,
        lambda,
        ratio_seq,
        trace,
        trace_calc,
        ratio_max,
        ratio_max_trace
    )

    start <- proc.time()[[3L]]

    marginals <- qdm_adjust_matrix(
        y_hist,
        x_hist,
        x_fut,
        ratio_seq = ratio_seq,
        trace = trace,
        trace_calc = trace_calc,
        ratio_max = ratio_max,
        ratio_max_trace = ratio_max_trace
    )

    latent_source <- gaussianize_matrix(marginals$x_hist, marginals$x_hist)
    latent_target <- gaussianize_matrix(y_hist, y_hist)
    latent_future <- gaussianize_matrix(marginals$x_fut, marginals$x_hist)

    source_cov <- rand_cov_approx(
        latent_source,
        rank = rank,
        oversampling = oversampling,
        sketch = sketch,
        mult_prec = precision,
        orth_prec = orth_prec,
        lambda = lambda
    )
    target_cov <- rand_cov_approx(
        latent_target,
        rank = rank,
        oversampling = oversampling,
        sketch = sketch,
        mult_prec = precision,
        orth_prec = orth_prec,
        lambda = lambda
    )

    transport_fit <- cov_transport(source_cov$covariance, target_cov$covariance, lambda = 0)
    latent_hist_corrected <- latent_source %*% transport_fit$transport
    latent_fut_corrected <- latent_future %*% transport_fit$transport

    historical_corrected <- rank_restore_matrix(marginals$x_hist, latent_hist_corrected)
    corrected <- rank_restore_matrix(marginals$x_fut, latent_fut_corrected)

    list(
        corrected = corrected,
        historical_corrected = historical_corrected,
        marginals = marginals,
        diagnostics = rand_mbc_diagnostics(
            historical_corrected,
            y_hist,
            source_cov,
            target_cov
        ),
        transport = transport_fit$transport,
        covariance = list(source = source_cov, target = target_cov),
        latent = list(hist = latent_hist_corrected, fut = latent_fut_corrected),
        precision = list(mult = precision, orth = orth_prec),
        sketch = sketch,
        lambda = lambda,
        rank = min(as.integer(rank), ncol(x_hist)),
        ratio_seq = marginals$controls$ratio_seq,
        runtime = proc.time()[[3L]] - start
    )
}

#' Validate top-level randMBC inputs
#'
#' @param x_hist Historical model matrix.
#' @param y_hist Historical reference matrix.
#' @param x_fut Future model matrix.
#' @param rank Target covariance approximation rank.
#' @param oversampling Oversampling parameter.
#' @param lambda Regularization level.
#' @param ratio_seq Ratio-style QDM indicator.
#' @param trace Dry-day threshold.
#' @param trace_calc Internal threshold used during QDM interpolation.
#' @param ratio_max Maximum multiplicative change for ratio columns.
#' @param ratio_max_trace Threshold below which `ratio_max` is enforced.
#'
#' @return Called for its validation side effects; returns `NULL` invisibly on
#'   success.
#' @noRd
validate_rand_mbc_inputs <- function(
    x_hist,
    y_hist,
    x_fut,
    rank,
    oversampling,
    lambda,
    ratio_seq,
    trace,
    trace_calc,
    ratio_max,
    ratio_max_trace
) {
    if (!is.matrix(x_hist) || !is.matrix(y_hist) || !is.matrix(x_fut)) {
        stop("x_hist, y_hist, and x_fut must be matrices")
    }
    if (!all(dim(x_hist) == dim(y_hist))) {
        stop("x_hist and y_hist must have the same dimensions")
    }
    if (ncol(x_hist) != ncol(x_fut)) {
        stop("x_hist and x_fut must have the same number of columns")
    }
    if (!is.numeric(rank) || length(rank) != 1L || rank < 1L) {
        stop("rank must be a positive scalar")
    }
    if (!is.numeric(oversampling) || length(oversampling) != 1L || oversampling < 0L) {
        stop("oversampling must be a nonnegative scalar")
    }
    if (!is.numeric(lambda) || length(lambda) != 1L || lambda < 0) {
        stop("lambda must be a nonnegative scalar")
    }
    expand_qdm_arg(ratio_seq, ncol(x_hist), "ratio_seq")
    expand_qdm_arg(trace, ncol(x_hist), "trace")
    expand_qdm_arg(trace_calc, ncol(x_hist), "trace_calc")
    expand_qdm_arg(ratio_max, ncol(x_hist), "ratio_max")
    expand_qdm_arg(ratio_max_trace, ncol(x_hist), "ratio_max_trace")
}

#' Summarize post-fit dependence and covariance diagnostics
#'
#' @param historical_corrected Bias-corrected historical sample.
#' @param y_hist Historical reference sample.
#' @param source_cov Source covariance fit returned by `rand_cov_approx()`.
#' @param target_cov Target covariance fit returned by `rand_cov_approx()`.
#'
#' @return A named list of scalar diagnostics.
#' @noRd
rand_mbc_diagnostics <- function(historical_corrected, y_hist, source_cov, target_cov) {
    list(
        pearson_error = dependence_error(historical_corrected, y_hist, method = "pearson"),
        spearman_error = dependence_error(historical_corrected, y_hist, method = "spearman"),
        quantile_error = marginal_quantile_error(historical_corrected, y_hist),
        covariance_error_x = source_cov$residual_norm_est,
        covariance_error_y = target_cov$residual_norm_est
    )
}

#' Measure relative dependence error between two multivariate samples
#'
#' @param x First data matrix.
#' @param y Second data matrix.
#' @param method Correlation type passed to `stats::cor()`.
#'
#' @return Relative Frobenius-norm error between the correlation matrices.
#' @noRd
dependence_error <- function(x, y, method = c("pearson", "spearman")) {
    method <- match.arg(method)
    cor_x <- stats::cor(x, method = method)
    cor_y <- stats::cor(y, method = method)
    norm(cor_x - cor_y, type = "F") / max(norm(cor_y, type = "F"), .Machine$double.eps)
}

#' Measure marginal quantile discrepancy between two samples
#'
#' @param x First data matrix.
#' @param y Second data matrix.
#' @param probs Quantile levels used in the comparison.
#'
#' @return Mean absolute quantile difference across columns.
#' @noRd
marginal_quantile_error <- function(x, y, probs = c(0.05, 0.5, 0.95)) {
    errs <- vapply(seq_len(ncol(x)), function(j) {
        qx <- stats::quantile(x[, j], probs = probs, type = 7, names = FALSE)
        qy <- stats::quantile(y[, j], probs = probs, type = 7, names = FALSE)
        mean(abs(qx - qy))
    }, numeric(1))
    mean(errs)
}
