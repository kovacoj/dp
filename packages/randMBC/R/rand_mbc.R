fit_rand_mbc <- function(
    x_hist,
    y_hist,
    x_fut,
    rank = 20L,
    oversampling = 10L,
    sketch = c("gaussian", "rademacher"),
    precision = c("double", "single", "half", "bfloat16"),
    orth_prec = c("double", "single"),
    lambda = 1e-6
) {
    sketch <- match.arg(sketch)
    precision <- match.arg(precision)
    orth_prec <- match.arg(orth_prec)

    validate_rand_mbc_inputs(x_hist, y_hist, x_fut, rank, oversampling, lambda)

    marginals <- qdm_adjust_matrix(y_hist, x_hist, x_fut)
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
        rank = min(as.integer(rank), ncol(x_hist))
    )
}

validate_rand_mbc_inputs <- function(x_hist, y_hist, x_fut, rank, oversampling, lambda) {
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
}

rand_mbc_diagnostics <- function(historical_corrected, y_hist, source_cov, target_cov) {
    list(
        pearson_error = dependence_error(historical_corrected, y_hist, method = "pearson"),
        spearman_error = dependence_error(historical_corrected, y_hist, method = "spearman"),
        quantile_error = marginal_quantile_error(historical_corrected, y_hist),
        covariance_error_x = source_cov$residual_norm_est,
        covariance_error_y = target_cov$residual_norm_est
    )
}

dependence_error <- function(x, y, method = c("pearson", "spearman")) {
    method <- match.arg(method)
    cor_x <- stats::cor(x, method = method)
    cor_y <- stats::cor(y, method = method)
    norm(cor_x - cor_y, type = "F") / max(norm(cor_y, type = "F"), .Machine$double.eps)
}

marginal_quantile_error <- function(x, y, probs = c(0.05, 0.5, 0.95)) {
    errs <- vapply(seq_len(ncol(x)), function(j) {
        qx <- stats::quantile(x[, j], probs = probs, type = 7, names = FALSE)
        qy <- stats::quantile(y[, j], probs = probs, type = 7, names = FALSE)
        mean(abs(qx - qy))
    }, numeric(1))
    mean(errs)
}
