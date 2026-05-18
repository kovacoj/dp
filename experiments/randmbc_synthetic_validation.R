args <- commandArgs(trailingOnly = TRUE)

parse_args <- function(args) {
    out <- list(
        csv = file.path("results", "randmbc_synthetic_validation.csv"),
        rds = file.path("results", "randmbc_synthetic_validation.rds"),
        summary_csv = file.path("results", "randmbc_synthetic_validation_summary.csv"),
        cov_plot = file.path("figures", "randmbc_cov_error_vs_rank.pdf"),
        transport_plot = file.path("figures", "randmbc_transport_error_vs_rank.pdf")
    )

    if (length(args) == 0L) {
        return(out)
    }

    for (arg in args) {
        parts <- strsplit(arg, "=", fixed = TRUE)[[1]]
        if (length(parts) != 2L) {
            next
        }

        key <- parts[[1]]
        value <- parts[[2]]
        if (key == "--csv") {
            out$csv <- value
        } else if (key == "--rds") {
            out$rds <- value
        } else if (key == "--summary-csv") {
            out$summary_csv <- value
        } else if (key == "--cov-plot") {
            out$cov_plot <- value
        } else if (key == "--transport-plot") {
            out$transport_plot <- value
        }
    }

    out
}

cfg <- parse_args(args)

source(file.path("packages", "randMBC", "R", "fl_round.R"))
source(file.path("packages", "randMBC", "R", "covariance_transport.R"))
source(file.path("packages", "randMBC", "R", "covariance_approximation.R"))

symmetrize <- function(x) {
    (x + t(x)) / 2
}

spectral_error <- function(a, b) {
    norm(symmetrize(a - b), type = "2")
}

dependence_error <- function(x, y, method = c("pearson", "spearman")) {
    method <- match.arg(method)
    cor_x <- stats::cor(x, method = method)
    cor_y <- stats::cor(y, method = method)
    norm(cor_x - cor_y, type = "F") / max(norm(cor_y, type = "F"), .Machine$double.eps)
}

decaying_spectrum <- function(p, strength = 1.2, floor = 0.08) {
    floor + (seq_len(p) + 1)^(-strength)
}

exponential_spectrum <- function(p, alpha = 10, floor = 0.02) {
    floor + exp(-seq_len(p) / alpha)
}

flat_spectrum <- function(p, level = 0.35) {
    rep(level, p)
}

low_rank_noise_spectrum <- function(p, rank_signal = 8L, signal = 1, noise = 0.03) {
    c(rep(signal, rank_signal), rep(noise, max(0L, p - rank_signal)))
}

block_mixer <- function(p, block_size = 4L, coupling = 0.22) {
    mixer <- diag(p)
    block_ids <- ((seq_len(p) - 1L) %/% block_size) + 1L

    for (i in seq_len(p)) {
        for (j in seq_len(p)) {
            if (i != j && block_ids[i] == block_ids[j]) {
                mixer[i, j] <- coupling / (abs(i - j) + 1)
            }
        }
    }

    qr.Q(qr(mixer + 0.03 * matrix(stats::rnorm(p * p), nrow = p, ncol = p)))
}

spectral_pair <- function(p, spectrum_case) {
    switch(
        spectrum_case,
        exp_decay = list(
            x = exponential_spectrum(p, alpha = 8, floor = 0.03),
            y = exponential_spectrum(p, alpha = 11, floor = 0.04)
        ),
        poly_decay = list(
            x = decaying_spectrum(p, strength = 1.15, floor = 0.05),
            y = decaying_spectrum(p, strength = 1.35, floor = 0.07)
        ),
        flat = list(
            x = flat_spectrum(p, level = 0.35),
            y = flat_spectrum(p, level = 0.45)
        ),
        low_rank_noise = list(
            x = low_rank_noise_spectrum(p, rank_signal = 6L, signal = 1.2, noise = 0.03),
            y = low_rank_noise_spectrum(p, rank_signal = 8L, signal = 1.0, noise = 0.05)
        ),
        stop(sprintf("Unknown spectrum_case: %s", spectrum_case))
    )
}

simulate_latent_triplet <- function(n = 256L, n_future = 128L, p = 64L, seed = 1L, spectrum_case = "poly_decay") {
    set.seed(seed)

    spectra <- spectral_pair(p, spectrum_case)
    spectrum_x <- spectra$x
    spectrum_y <- spectra$y
    q_x <- block_mixer(p, coupling = 0.20)
    q_y <- block_mixer(p, coupling = 0.28)

    map_x <- q_x %*% diag(sqrt(spectrum_x), nrow = p)
    map_y <- q_y %*% diag(sqrt(spectrum_y), nrow = p)

    z_x <- matrix(stats::rnorm(n * p), nrow = n, ncol = p) %*% t(map_x)
    z_y <- matrix(stats::rnorm(n * p), nrow = n, ncol = p) %*% t(map_y)
    z_f <- matrix(stats::rnorm(n_future * p), nrow = n_future, ncol = p) %*% t(map_x)

    list(
        Z_X = scale(z_x, center = TRUE, scale = FALSE),
        Z_Y = scale(z_y, center = TRUE, scale = FALSE),
        Z_f = scale(z_f, center = TRUE, scale = FALSE)
    )
}

build_cov_fit_from_basis <- function(Z, q, lambda, sketch, mult_prec, orth_prec, sample_y) {
    cov_q <- covariance_action(Z, q)
    b <- crossprod(q, cov_q)
    cov_approx <- q %*% b %*% t(q)
    cov_regularized <- cov_approx + diag(lambda, ncol(Z))
    reg_eigvals <- eigen(symmetrize(cov_regularized), symmetric = TRUE, only.values = TRUE)$values

    list(
        Q = q,
        B = b,
        covariance_raw = cov_approx,
        covariance = cov_regularized,
        lambda = lambda,
        rank = ncol(q),
        sketch = sketch,
        precision = list(mult = mult_prec, orth = orth_prec),
        residual_norm_est = sampled_range_residual(sample_y, q),
        lambda_min_reg = min(reg_eigvals),
        condition_est = kappa(cov_regularized)
    )
}

full_transport_row <- function(latent, seed, lambda, spectrum_case) {
    source_cov <- covariance_action(latent$Z_X, diag(ncol(latent$Z_X)))
    target_cov <- covariance_action(latent$Z_Y, diag(ncol(latent$Z_Y)))
    start <- proc.time()[[3L]]
    full_fit <- cov_transport(source_cov, target_cov, lambda = lambda)
    future_full <- latent$Z_f %*% full_fit$transport
    runtime <- proc.time()[[3L]] - start

    source_reg <- full_fit$source
    target_reg <- full_fit$target
    source_eigs <- eigen(symmetrize(source_reg), symmetric = TRUE, only.values = TRUE)$values
    target_eigs <- eigen(symmetrize(target_reg), symmetric = TRUE, only.values = TRUE)$values

    list(
        row = data.frame(
            method = "full_cov_transport",
            backend = "baseline",
            basis_mode = "full",
            spectrum_case = spectrum_case,
            rank = ncol(latent$Z_X),
            oversampling = 0L,
            lambda = lambda,
            precision = "double",
            rounding = "nearest",
            seed = seed,
            n = nrow(latent$Z_X),
            p = ncol(latent$Z_X),
            runtime_sec = runtime,
            cov_error = 0,
            cov_error_x = 0,
            cov_error_y = 0,
            transport_error = 0,
            future_error = 0,
            cond_reg_cov = max(kappa(source_reg), kappa(target_reg)),
            cond_reg_cov_x = kappa(source_reg),
            cond_reg_cov_y = kappa(target_reg),
            lambda_min_reg_cov = min(source_eigs, target_eigs),
            lambda_min_reg_cov_x = min(source_eigs),
            lambda_min_reg_cov_y = min(target_eigs),
            pearson_error = 0,
            spearman_error = 0,
            status = "ok",
            failure_reason = NA_character_,
            stringsAsFactors = FALSE
        ),
        source_cov = source_cov,
        target_cov = target_cov,
        transport = full_fit$transport,
        future = future_full
    )
}

randomized_transport_row <- function(latent, baseline, seed, rank, oversampling, lambda, precision, spectrum_case, basis_mode = c("independent", "joint")) {
    basis_mode <- match.arg(basis_mode)
    start <- proc.time()[[3L]]

    if (basis_mode == "independent") {
        source_fit <- rand_cov_approx(
            latent$Z_X,
            rank = rank,
            oversampling = oversampling,
            sketch = "gaussian",
            mult_prec = precision,
            orth_prec = "double",
            lambda = lambda
        )
        target_fit <- rand_cov_approx(
            latent$Z_Y,
            rank = rank,
            oversampling = oversampling,
            sketch = "gaussian",
            mult_prec = precision,
            orth_prec = "double",
            lambda = lambda
        )
    } else {
        p <- ncol(latent$Z_X)
        ell <- min(p, as.integer(rank + oversampling))
        rank_used <- min(as.integer(rank), ell)
        omega <- draw_sketch_matrix(p, ell, "gaussian")
        omega_low <- fl_round(omega, precision)
        z_x_low <- fl_round(latent$Z_X, precision)
        z_y_low <- fl_round(latent$Z_Y, precision)
        y_x <- fl_round(covariance_action(z_x_low, omega_low), precision)
        y_y <- fl_round(covariance_action(z_y_low, omega_low), precision)
        y_joint <- cbind(y_x, y_y)
        y_for_qr <- fl_round(y_joint, "double")
        q_full <- qr.Q(qr(y_for_qr))
        q <- q_full[, seq_len(rank_used), drop = FALSE]
        source_fit <- build_cov_fit_from_basis(latent$Z_X, q, lambda, "gaussian", precision, "double", y_x)
        target_fit <- build_cov_fit_from_basis(latent$Z_Y, q, lambda, "gaussian", precision, "double", y_y)
    }
    transport_fit <- cov_transport(source_fit$covariance, target_fit$covariance, lambda = 0)
    future_hat <- latent$Z_f %*% transport_fit$transport
    runtime <- proc.time()[[3L]] - start

    cov_error_x <- spectral_error(baseline$source_cov, source_fit$covariance_raw)
    cov_error_y <- spectral_error(baseline$target_cov, target_fit$covariance_raw)

    data.frame(
        method = "randomized_cov_transport",
        backend = "randMBC",
        basis_mode = basis_mode,
        spectrum_case = spectrum_case,
        rank = rank,
        oversampling = oversampling,
        lambda = lambda,
        precision = precision,
        rounding = "nearest",
        seed = seed,
        n = nrow(latent$Z_X),
        p = ncol(latent$Z_X),
        runtime_sec = runtime,
        cov_error = max(cov_error_x, cov_error_y),
        cov_error_x = cov_error_x,
        cov_error_y = cov_error_y,
        transport_error = spectral_error(baseline$transport, transport_fit$transport),
        future_error = norm(baseline$future - future_hat, type = "F"),
        cond_reg_cov = max(source_fit$condition_est, target_fit$condition_est),
        cond_reg_cov_x = source_fit$condition_est,
        cond_reg_cov_y = target_fit$condition_est,
        lambda_min_reg_cov = min(source_fit$lambda_min_reg, target_fit$lambda_min_reg),
        lambda_min_reg_cov_x = source_fit$lambda_min_reg,
        lambda_min_reg_cov_y = target_fit$lambda_min_reg,
        pearson_error = dependence_error(future_hat, baseline$future, method = "pearson"),
        spearman_error = dependence_error(future_hat, baseline$future, method = "spearman"),
        status = "ok",
        failure_reason = NA_character_,
        stringsAsFactors = FALSE
    )
}

failure_row <- function(seed, n, p, rank, oversampling, lambda, precision, spectrum_case, basis_mode, message) {
    data.frame(
        method = "randomized_cov_transport",
        backend = "randMBC",
        basis_mode = basis_mode,
        spectrum_case = spectrum_case,
        rank = rank,
        oversampling = oversampling,
        lambda = lambda,
        precision = precision,
        rounding = "nearest",
        seed = seed,
        n = n,
        p = p,
        runtime_sec = NA_real_,
        cov_error = NA_real_,
        cov_error_x = NA_real_,
        cov_error_y = NA_real_,
        transport_error = NA_real_,
        future_error = NA_real_,
        cond_reg_cov = NA_real_,
        cond_reg_cov_x = NA_real_,
        cond_reg_cov_y = NA_real_,
        lambda_min_reg_cov = NA_real_,
        lambda_min_reg_cov_x = NA_real_,
        lambda_min_reg_cov_y = NA_real_,
        pearson_error = NA_real_,
        spearman_error = NA_real_,
        status = "failed",
        failure_reason = as.character(message),
        stringsAsFactors = FALSE
    )
}

plot_metric_by_rank <- function(results, metric, ylabel, output_path) {
    randomized <- results[results$method == "randomized_cov_transport" & results$status == "ok", , drop = FALSE]
    if (nrow(randomized) == 0L) {
        return(invisible(NULL))
    }

    summary <- stats::aggregate(
        randomized[[metric]],
        by = list(
            rank = randomized$rank,
            precision = randomized$precision,
            lambda = randomized$lambda,
            spectrum_case = randomized$spectrum_case,
            basis_mode = randomized$basis_mode
        ),
        FUN = mean
    )
    colnames(summary)[6L] <- metric
    lambdas <- sort(unique(summary$lambda))
    spectrum_cases <- unique(summary$spectrum_case)
    colors <- c(double = "steelblue", single = "firebrick")
    line_types <- c(independent = 1, joint = 2)
    pdf(output_path, width = 8, height = 3 * length(lambdas))
    op <- par(mfrow = c(length(lambdas), 1L), mar = c(4, 4, 3, 1))
    on.exit({
        par(op)
        dev.off()
    }, add = TRUE)

    for (case in spectrum_cases) {
        for (lam in lambdas) {
            panel <- summary[summary$lambda == lam & summary$spectrum_case == case, , drop = FALSE]
            y_vals <- panel[[metric]][is.finite(panel[[metric]]) & panel[[metric]] > 0]
            y_lim <- if (length(y_vals) > 0L) range(y_vals) else c(1e-12, 1)
            plot(NA,
                xlim = range(panel$rank),
                ylim = y_lim,
                log = "y",
                xlab = "rank",
                ylab = ylabel,
                main = paste0(case, ": ", ylabel, " vs rank (lambda = ", format(lam, scientific = TRUE), ")")
            )

            for (basis_mode in c("independent", "joint")) {
                for (precision in c("double", "single")) {
                    curve <- panel[panel$precision == precision & panel$basis_mode == basis_mode, , drop = FALSE]
                    if (nrow(curve) == 0L) {
                        next
                    }
                    curve <- curve[order(curve$rank), , drop = FALSE]
                    lines(curve$rank, curve[[metric]], type = "b", lwd = 2, pch = 16, lty = line_types[[basis_mode]], col = colors[[precision]])
                }
            }
            legend(
                "topright",
                legend = c("double + independent", "single + independent", "double + joint", "single + joint"),
                col = c(colors[["double"]], colors[["single"]], colors[["double"]], colors[["single"]]),
                lty = c(1, 1, 2, 2),
                pch = 16,
                bty = "n"
            )
        }
    }
}

write_outputs <- function(results, cfg) {
    dir.create(dirname(cfg$csv), recursive = TRUE, showWarnings = FALSE)
    dir.create(dirname(cfg$rds), recursive = TRUE, showWarnings = FALSE)
    dir.create(dirname(cfg$summary_csv), recursive = TRUE, showWarnings = FALSE)
    dir.create(dirname(cfg$cov_plot), recursive = TRUE, showWarnings = FALSE)
    dir.create(dirname(cfg$transport_plot), recursive = TRUE, showWarnings = FALSE)

    randomized <- results[results$method == "randomized_cov_transport" & results$status == "ok", , drop = FALSE]
    summary <- stats::aggregate(
        randomized[c("cov_error", "transport_error", "future_error", "pearson_error", "spearman_error", "runtime_sec")],
        by = randomized[c("spectrum_case", "basis_mode", "rank", "oversampling", "lambda", "precision")],
        FUN = mean
    )

    utils::write.csv(results, cfg$csv, row.names = FALSE)
    saveRDS(results, cfg$rds)
    utils::write.csv(summary, cfg$summary_csv, row.names = FALSE)
    plot_metric_by_rank(results, "cov_error", "covariance error", cfg$cov_plot)
    plot_metric_by_rank(results, "transport_error", "transport error", cfg$transport_plot)
}

grid <- expand.grid(
    spectrum_case = c("exp_decay", "poly_decay", "flat", "low_rank_noise"),
    seed = c(1L, 2L, 3L),
    rank = c(5L, 10L, 20L, 40L),
    oversampling = c(5L, 10L),
    lambda = c(1e-6, 1e-4, 1e-2),
    precision = c("double", "single"),
    basis_mode = c("independent", "joint"),
    stringsAsFactors = FALSE
)

results <- vector("list", length = nrow(grid) + length(unique(interaction(grid$spectrum_case, grid$seed, grid$lambda))))
idx <- 1L
baseline_cache <- new.env(parent = emptyenv())

for (i in seq_len(nrow(grid))) {
    params <- grid[i, ]
    key <- paste(params$spectrum_case, params$seed, params$lambda, sep = "::")

    if (!exists(key, envir = baseline_cache, inherits = FALSE)) {
        latent <- simulate_latent_triplet(seed = params$seed, spectrum_case = params$spectrum_case)
        baseline <- full_transport_row(latent, seed = params$seed, lambda = params$lambda, spectrum_case = params$spectrum_case)
        assign(key, list(latent = latent, baseline = baseline), envir = baseline_cache)
        results[[idx]] <- baseline$row
        idx <- idx + 1L
    }

    entry <- get(key, envir = baseline_cache, inherits = FALSE)
    row <- tryCatch(
        randomized_transport_row(
            entry$latent,
            entry$baseline,
            seed = params$seed,
            rank = params$rank,
            oversampling = params$oversampling,
            lambda = params$lambda,
            precision = params$precision,
            spectrum_case = params$spectrum_case,
            basis_mode = params$basis_mode
        ),
        error = function(err) {
            failure_row(
                seed = params$seed,
                n = nrow(entry$latent$Z_X),
                p = ncol(entry$latent$Z_X),
                rank = params$rank,
                oversampling = params$oversampling,
                lambda = params$lambda,
                precision = params$precision,
                spectrum_case = params$spectrum_case,
                basis_mode = params$basis_mode,
                message = conditionMessage(err)
            )
        }
    )

    results[[idx]] <- row
    idx <- idx + 1L
}

results <- do.call(rbind, results[seq_len(idx - 1L)])
write_outputs(results, cfg)
print(results)
