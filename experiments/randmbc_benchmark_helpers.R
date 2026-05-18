source(file.path("packages", "randMBC", "R", "marginal_adjustment.R"))
source(file.path("packages", "randMBC", "R", "latent_dependence.R"))
source(file.path("packages", "randMBC", "R", "covariance_transport.R"))

null_coalesce <- function(x, default) {
    if (is.null(x)) {
        return(default)
    }
    x
}

simulate_climate_data <- function(
    n_hist = 240L,
    n_fut = 120L,
    p = 4L,
    seed = 1L,
    ratio_idx = integer()
) {
    set.seed(seed)

    time_hist <- seq_len(n_hist)
    time_fut <- seq_len(n_fut)
    seasonal_hist <- cbind(
        sin(2 * pi * time_hist / 12),
        cos(2 * pi * time_hist / 12)
    )
    seasonal_fut <- cbind(
        sin(2 * pi * time_fut / 12),
        cos(2 * pi * time_fut / 12)
    )

    loadings <- matrix(stats::rnorm(2 * p, sd = 0.7), nrow = 2, ncol = p)
    latent_hist <- seasonal_hist %*% loadings + matrix(stats::rnorm(n_hist * p, sd = 0.5), ncol = p)
    latent_fut <- seasonal_fut %*% loadings + matrix(stats::rnorm(n_fut * p, sd = 0.55), ncol = p)

    mix <- diag(p)
    if (p > 1L) {
        mix[lower.tri(mix)] <- 0.2
    }

    y_hist <- latent_hist %*% mix
    x_hist <- sweep(latent_hist %*% (0.7 * mix), 2, seq(0.1, 0.3, length.out = p), "+")
    x_fut <- sweep(latent_fut %*% (0.75 * mix), 2, seq(0.15, 0.4, length.out = p), "+")

    if (length(ratio_idx) > 0L) {
        for (j in ratio_idx) {
            y_hist[, j] <- pmax(0, exp(y_hist[, j] / 3) - 1)
            x_hist[, j] <- pmax(0, exp(x_hist[, j] / 3) - 1)
            x_fut[, j] <- pmax(0, exp(x_fut[, j] / 3) - 1)
        }
    }

    list(
        x_hist = x_hist,
        y_hist = y_hist,
        x_fut = x_fut
    )
}

fit_full_cov_transport <- function(
    x_hist,
    y_hist,
    x_fut,
    lambda = 1e-6,
    ratio_seq = rep(FALSE, ncol(x_hist)),
    trace = 0.05,
    trace_calc = 0.5 * trace,
    ratio_max = 2,
    ratio_max_trace = 10 * trace
) {
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

    source_cov <- stats::cov(latent_source)
    target_cov <- stats::cov(latent_target)
    transport_fit <- cov_transport(source_cov, target_cov, lambda = lambda)

    latent_hist_corrected <- latent_source %*% transport_fit$transport
    latent_fut_corrected <- latent_future %*% transport_fit$transport

    historical_corrected <- rank_restore_matrix(marginals$x_hist, latent_hist_corrected)
    corrected <- rank_restore_matrix(marginals$x_fut, latent_fut_corrected)

    list(
        corrected = corrected,
        historical_corrected = historical_corrected,
        marginals = marginals,
        transport = transport_fit$transport,
        covariance = list(source = source_cov, target = target_cov),
        latent = list(hist = latent_hist_corrected, fut = latent_fut_corrected),
        runtime = proc.time()[[3L]] - start,
        lambda = lambda,
        ratio_seq = marginals$controls$ratio_seq
    )
}

matrix_memory_mb <- function(x) {
    as.numeric(object.size(x)) / 1024^2
}

extract_covariance_matrix <- function(x) {
    if (is.list(x) && !is.null(x$covariance)) {
        return(x$covariance)
    }
    x
}

dependence_error_metric <- function(x, y, method = c("pearson", "spearman")) {
    method <- match.arg(method)
    cor_x <- stats::cor(x, method = method)
    cor_y <- stats::cor(y, method = method)
    norm(cor_x - cor_y, type = "F") / max(norm(cor_y, type = "F"), .Machine$double.eps)
}

marginal_quantile_error_metric <- function(x, y, probs = c(0.05, 0.5, 0.95)) {
    errs <- vapply(seq_len(ncol(x)), function(j) {
        qx <- stats::quantile(x[, j], probs = probs, type = 7, names = FALSE)
        qy <- stats::quantile(y[, j], probs = probs, type = 7, names = FALSE)
        mean(abs(qx - qy))
    }, numeric(1))
    mean(errs)
}

energy_score_metric <- function(x, y) {
    dx <- as.matrix(stats::dist(x))
    dy <- as.matrix(stats::dist(y))
    dxy <- as.matrix(stats::dist(rbind(x, y)))
    n_x <- nrow(x)
    n_y <- nrow(y)
    cross <- dxy[seq_len(n_x), n_x + seq_len(n_y), drop = FALSE]
    2 * mean(cross) - mean(dx) - mean(dy)
}

raw_covariance_gap_metric <- function(x, y) {
    cov_x <- stats::cov(x)
    cov_y <- stats::cov(y)
    norm(cov_x - cov_y, type = "F") / max(norm(cov_y, type = "F"), .Machine$double.eps)
}

load_mbc_reference_env <- local({
    mbc_env <- NULL

    function() {
        if (!is.null(mbc_env)) {
            return(mbc_env)
        }

        if (!requireNamespace("Matrix", quietly = TRUE)) {
            stop("Matrix is required for src/MBC reference comparisons")
        }

        library(Matrix)

        mbc_path <- file.path("src", "MBC", "R", "MBC-QDM.R")
        lines <- readLines(mbc_path)
        lines <- lines[!grepl("^library\\(", trimws(lines))]

        mbc_env <- new.env(parent = globalenv())
        con <- textConnection(lines)
        on.exit(close(con), add = TRUE)
        source(con, local = mbc_env)
        mbc_env
    }
})

fit_mbc_reference <- function(
    method,
    x_hist,
    y_hist,
    x_fut,
    ratio_seq = rep(FALSE, ncol(x_hist)),
    trace = 0.05,
    trace_calc = 0.5 * trace,
    ratio_max = 2,
    ratio_max_trace = 10 * trace,
    iter = 12L,
    cor_thresh = 1e-4
) {
    mbc_env <- load_mbc_reference_env()
    mbc_fun <- get(method, envir = mbc_env, inherits = FALSE)

    start <- proc.time()[[3L]]
    fit <- mbc_fun(
        o.c = y_hist,
        m.c = x_hist,
        m.p = x_fut,
        iter = iter,
        cor.thresh = cor_thresh,
        ratio.seq = ratio_seq,
        trace = trace,
        trace.calc = trace_calc,
        ratio.max = ratio_max,
        ratio.max.trace = ratio_max_trace,
        silent = TRUE
    )

    list(
        corrected = fit$mhat.p,
        historical_corrected = fit$mhat.c,
        runtime = proc.time()[[3L]] - start,
        method = method
    )
}

benchmark_row <- function(method, backend, seed, dataset, fit, baseline_fit, params) {
    source_cov_full <- baseline_fit$covariance$source
    target_cov_full <- baseline_fit$covariance$target
    future_baseline <- baseline_fit$corrected
    source_cov_error <- NA_real_
    target_cov_error <- NA_real_
    covariance_error <- NA_real_
    transport_error <- NA_real_

    if (!is.null(fit$covariance) && !is.null(fit$transport)) {
        fit_source_cov <- extract_covariance_matrix(fit$covariance$source)
        fit_target_cov <- extract_covariance_matrix(fit$covariance$target)
        source_cov_error <- norm(fit_source_cov - source_cov_full, type = "F")
        target_cov_error <- norm(fit_target_cov - target_cov_full, type = "F")
        covariance_error <- (source_cov_error + target_cov_error) / 2
        transport_error <- norm(fit$transport - baseline_fit$transport, type = "F")
    }

    data.frame(
        method = method,
        backend = backend,
        rank = params$rank,
        oversampling = params$oversampling,
        lambda = params$lambda,
        precision = params$precision,
        rounding = null_coalesce(params$rounding, "nearest"),
        orth_prec = params$orth_prec,
        sketch = params$sketch,
        seed = seed,
        n_hist = nrow(dataset$x_hist),
        n_fut = nrow(dataset$x_fut),
        p = ncol(dataset$x_hist),
        runtime_sec = unname(params$runtime),
        memory_mb = matrix_memory_mb(fit$corrected),
        pearson_error = dependence_error_metric(fit$historical_corrected, dataset$y_hist, method = "pearson"),
        spearman_error = dependence_error_metric(fit$historical_corrected, dataset$y_hist, method = "spearman"),
        quantile_error = marginal_quantile_error_metric(fit$historical_corrected, dataset$y_hist),
        energy_score = energy_score_metric(fit$historical_corrected, dataset$y_hist),
        historical_covariance_gap = raw_covariance_gap_metric(fit$historical_corrected, dataset$y_hist),
        source_cov_error = source_cov_error,
        target_cov_error = target_cov_error,
        covariance_error = covariance_error,
        transport_error = transport_error,
        future_error = norm(fit$corrected - future_baseline, type = "F") / max(norm(future_baseline, type = "F"), .Machine$double.eps),
        source_condition = kappa(source_cov_full + diag(params$lambda, ncol(source_cov_full))),
        target_condition = kappa(target_cov_full + diag(params$lambda, ncol(target_cov_full))),
        status = "ok",
        stringsAsFactors = FALSE
    )
}

summarize_benchmark_results <- function(results) {
    key_df <- data.frame(
        method = results$method,
        backend = results$backend,
        precision = results$precision,
        rounding = results$rounding,
        rank = ifelse(is.na(results$rank), "NA", as.character(results$rank)),
        oversampling = ifelse(is.na(results$oversampling), "NA", as.character(results$oversampling)),
        stringsAsFactors = FALSE
    )

    metric_cols <- c(
        "runtime_sec",
        "memory_mb",
        "pearson_error",
        "spearman_error",
        "quantile_error",
        "energy_score",
        "historical_covariance_gap",
        "source_cov_error",
        "target_cov_error",
        "covariance_error",
        "transport_error",
        "future_error"
    )

    summary <- stats::aggregate(results[metric_cols], key_df, function(x) mean(x, na.rm = TRUE))
    counts <- stats::aggregate(list(n_runs = rep(1L, nrow(results))), key_df, sum)
    merge(summary, counts, by = names(key_df), sort = FALSE)
}

plot_metric_tradeoff <- function(results, metric, ylab, main) {
    ref_rows <- results[results$backend != "randMBC", , drop = FALSE]
    rand_rows <- results[results$backend == "randMBC", , drop = FALSE]

    plot(
        rand_rows$runtime_sec,
        rand_rows[[metric]],
        col = ifelse(rand_rows$precision == "double", "steelblue", "firebrick"),
        pch = ifelse(rand_rows$oversampling == 0, 16, 17),
        xlab = "runtime (sec)",
        ylab = ylab,
        main = main
    )
    text(rand_rows$runtime_sec, rand_rows[[metric]], labels = paste0("r", rand_rows$rank, "/o", rand_rows$oversampling), pos = 3, cex = 0.7)

    if (nrow(ref_rows) > 0L) {
        points(ref_rows$runtime_sec, ref_rows[[metric]], pch = 15, col = "black")
        text(ref_rows$runtime_sec, ref_rows[[metric]], labels = ref_rows$method, pos = 4, cex = 0.7)
    }

    legend(
        "topright",
        legend = c("randMBC double", "randMBC single", "oversampling 0", "oversampling 2", "references"),
        col = c("steelblue", "firebrick", "black", "black", "black"),
        pch = c(16, 16, 16, 17, 15),
        bty = "n"
    )
}

write_benchmark_outputs <- function(results, csv_path) {
    summary_path <- sub("\\.csv$", "-summary.csv", csv_path)
    plot_path <- sub("\\.csv$", "-plots.pdf", csv_path)

    summary <- summarize_benchmark_results(results)
    utils::write.csv(summary, summary_path, row.names = FALSE)

    grDevices::pdf(plot_path, width = 8, height = 6)
    on.exit(grDevices::dev.off(), add = TRUE)

    plot_metric_tradeoff(results, "pearson_error", "Pearson error", "Pearson Error vs Runtime")
    plot_metric_tradeoff(results, "spearman_error", "Spearman error", "Spearman Error vs Runtime")
    plot_metric_tradeoff(results, "transport_error", "Transport error", "Transport Error vs Runtime")

    rand_rows <- results[results$backend == "randMBC", , drop = FALSE]
    plot(
        rand_rows$source_cov_error,
        rand_rows$target_cov_error,
        col = ifelse(rand_rows$precision == "double", "steelblue", "firebrick"),
        pch = ifelse(rand_rows$oversampling == 0, 16, 17),
        xlab = "source covariance error",
        ylab = "target covariance error",
        main = "Covariance Error Decomposition"
    )
    text(rand_rows$source_cov_error, rand_rows$target_cov_error, labels = paste0("r", rand_rows$rank), pos = 3, cex = 0.7)

    invisible(summary)
}
