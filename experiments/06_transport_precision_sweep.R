MASTER_SEED <- 20260527L

suppressPackageStartupMessages({
    library(randMBC)
})

cfg <- list(
    p = 30L,
    rank = 20L,
    lambda = 1e-2,
    precisions = c("double", "single"),
    basis_mode = "shared",
    n_trials = 20L
)

make_results_dir <- function(script_name) {
    args_all <- commandArgs(trailingOnly = FALSE)
    file_arg <- args_all[grep("^--file=", args_all)]
    script_path <- if (!is.null(sys.frame(1)$ofile)) sys.frame(1)$ofile else sub("^--file=", "", file_arg[[1L]])
    script_dir <- dirname(normalizePath(script_path))
    results_root <- file.path(script_dir, "results")
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

out_dir <- make_results_dir("06_transport_precision_sweep.R")
writeLines(c(
    sprintf("master_seed: %d", MASTER_SEED),
    sprintf("p: %d", cfg$p),
    sprintf("rank: %d", cfg$rank),
    sprintf("lambda: %.16g", cfg$lambda),
    sprintf("precisions: [%s]", paste(cfg$precisions, collapse = ", ")),
    sprintf("basis_mode: %s", cfg$basis_mode),
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

trial_metrics <- randMBC::run_cov_transport_sweep(
    cov_op = op,
    ranks = cfg$rank,
    lambdas = cfg$lambda,
    sketches = "gaussian",
    precisions = cfg$precisions,
    n_trials = cfg$n_trials,
    base_seed = MASTER_SEED
)

norm_Z <- sqrt(max(eigen(op$covariance, symmetric = TRUE, only.values = TRUE)$values))
norm_Omega <- sqrt(cfg$rank)
trial_metrics$forward_bound <- vapply(trial_metrics$mult_prec, function(pr) {
    pm <- randMBC::precision_model(pr, "double")
    randMBC::sketch_forward_bound(pm, norm_Z = norm_Z, norm_Omega = norm_Omega, n = cfg$p, p = cfg$p)
}, numeric(1))
trial_metrics$basis_mode <- cfg$basis_mode

summary_df <- randMBC::summarize_results(trial_metrics)
summary_df$forward_bound <- vapply(summary_df$mult_prec, function(pr) {
    pm <- randMBC::precision_model(pr, "double")
    randMBC::sketch_forward_bound(pm, norm_Z = norm_Z, norm_Omega = norm_Omega, n = cfg$p, p = cfg$p)
}, numeric(1))
summary_df$basis_mode <- cfg$basis_mode

utils::write.csv(trial_metrics, file.path(out_dir, "trial_metrics.csv"), row.names = FALSE)
utils::write.csv(summary_df, file.path(out_dir, "summary.csv"), row.names = FALSE)

pdf(file.path(out_dir, "figures", "fig_ct_precision_comparison.pdf"), width = 7, height = 5)
cols <- c("black", "navy")
plot(seq_len(nrow(summary_df)), summary_df$transport_error_mean, type = "n",
     xaxt = "n", xlab = "Precision", ylab = "Mean transport error",
     main = "Transport precision comparison")
axis(1, at = seq_len(nrow(summary_df)), labels = summary_df$mult_prec)
points(seq_len(nrow(summary_df)), summary_df$transport_error_mean, pch = 19, col = cols[seq_len(nrow(summary_df))])
lines(seq_len(nrow(summary_df)), summary_df$transport_error_mean, col = "grey40")
grid()
dev.off()

writeLines(out_dir)
