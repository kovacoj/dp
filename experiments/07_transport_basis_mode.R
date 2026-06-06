MASTER_SEED <- 20260527L

suppressPackageStartupMessages({
    library(randMBC)
})

cfg <- list(
    p = 30L,
    rank_vals = c(10L, 20L),
    lambdas = c(1e-6, 1e-2),
    basis_modes = c("shared", "independent"),
    n_trials = 20L
)

make_results_dir <- function(script_name) {
    results_root <- file.path("/workspace", "results")
    dir.create(results_root, recursive = TRUE, showWarnings = FALSE)
    stamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
    out_dir <- file.path(results_root, paste0(tools::file_path_sans_ext(script_name), "_", stamp))
    dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
    dir.create(file.path(out_dir, "figures"), recursive = TRUE, showWarnings = FALSE)
    out_dir
}

write_git_sha <- function(path) {
    sha <- tryCatch(system2("git", c("rev-parse", "HEAD"), stdout = TRUE), error = function(e) "NA")
    writeLines(sha[[1L]], con = path)
}

out_dir <- make_results_dir("07_transport_basis_mode.R")
writeLines(c(
    sprintf("master_seed: %d", MASTER_SEED),
    sprintf("p: %d", cfg$p),
    sprintf("rank_vals: [%s]", paste(cfg$rank_vals, collapse = ", ")),
    sprintf("lambdas: [%s]", paste(format(cfg$lambdas, scientific = TRUE), collapse = ", ")),
    sprintf("basis_modes: [%s]", paste(cfg$basis_modes, collapse = ", ")),
    sprintf("n_trials: %d", cfg$n_trials)
), con = file.path(out_dir, "config.yaml"))
write_git_sha(file.path(out_dir, "git_sha.txt"))
capture.output(utils::sessionInfo(), file = file.path(out_dir, "sessionInfo.txt"))

op <- randMBC::generate_cov_operator(
    p = cfg$p,
    rank = cfg$p,
    spectrum = "exponential",
    cond = 100,
    seed = MASTER_SEED
)

eig <- eigen(op$covariance, symmetric = TRUE)
X_hist <- matrix(stats::rnorm(200L * cfg$p), nrow = 200L, ncol = cfg$p)
X_hist <- X_hist %*% eig$vectors %*% diag(sqrt(pmax(eig$values, 0)), nrow = cfg$p)
Y_hist <- X_hist + 0.05 * matrix(stats::rnorm(length(X_hist)), nrow = nrow(X_hist), ncol = ncol(X_hist))
X_fut <- X_hist[1:100, , drop = FALSE] + 0.05 * matrix(stats::rnorm(100L * cfg$p), nrow = 100L, ncol = cfg$p)

rows <- vector("list", length(cfg$rank_vals) * length(cfg$lambdas) * length(cfg$basis_modes) * cfg$n_trials)
idx <- 1L

for (rank in cfg$rank_vals) {
    for (lambda in cfg$lambdas) {
        sweep_stub <- randMBC::run_cov_transport_sweep(
            cov_op = op,
            ranks = rank,
            lambdas = lambda,
            sketches = "gaussian",
            precisions = "double",
            n_trials = 1L,
            base_seed = MASTER_SEED + idx
        )
        for (basis_mode in cfg$basis_modes) {
            for (trial in seq_len(cfg$n_trials)) {
                fit <- randMBC::fit_rand_mbc(
                    x_hist = X_hist,
                    y_hist = Y_hist,
                    x_fut = X_fut,
                    rank = rank,
                    oversampling = 5L,
                    sketch = "gaussian",
                    precision = "double",
                    orth_prec = "double",
                    lambda = lambda,
                    basis_mode = basis_mode,
                    seed = MASTER_SEED + idx
                )
                rows[[idx]] <- data.frame(
                    trial = trial,
                    rank = rank,
                    lambda = lambda,
                    basis_mode = basis_mode,
                    pearson_error = fit$diagnostics$pearson_error,
                    spearman_error = fit$diagnostics$spearman_error,
                    quantile_error = fit$diagnostics$quantile_error,
                    covariance_error_x = fit$diagnostics$covariance_error_x,
                    covariance_error_y = fit$diagnostics$covariance_error_y,
                    runtime = fit$runtime,
                    transport_error_proxy = sweep_stub$transport_error[[1L]],
                    stringsAsFactors = FALSE
                )
                idx <- idx + 1L
            }
        }
    }
}

trial_metrics <- do.call(rbind, rows)
summary_df <- stats::aggregate(
    cbind(pearson_error, spearman_error, quantile_error, covariance_error_x, covariance_error_y, runtime, transport_error_proxy) ~ rank + lambda + basis_mode,
    data = trial_metrics,
    FUN = mean
)

utils::write.csv(trial_metrics, file.path(out_dir, "trial_metrics.csv"), row.names = FALSE)
utils::write.csv(summary_df, file.path(out_dir, "summary.csv"), row.names = FALSE)

pdf(file.path(out_dir, "figures", "fig_ct_basis_comparison.pdf"), width = 7, height = 5)
plot(seq_len(nrow(summary_df)), summary_df$pearson_error, type = "n", xaxt = "n",
     xlab = "Configuration", ylab = "Mean Pearson dependence error",
     main = "Basis-mode comparison")
axis(1, at = seq_len(nrow(summary_df)),
     labels = paste(summary_df$basis_mode, "r=", summary_df$rank, " lambda=", format(summary_df$lambda, scientific = TRUE)))
points(seq_len(nrow(summary_df)), summary_df$pearson_error, pch = 19, col = ifelse(summary_df$basis_mode == "shared", "navy", "firebrick"))
grid()
dev.off()

writeLines(out_dir)
