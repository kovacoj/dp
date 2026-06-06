MASTER_SEED <- 20260527L

suppressPackageStartupMessages({
    library(randMBC)
})

cfg <- list(
    p = 30L,
    rank = 20L,
    lambda_vals = c(1e-6, 1e-4, 1e-2, 1e-1),
    spectrum = "exponential",
    cond = 100,
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

out_dir <- make_results_dir("05_transport_lambda_sweep.R")
writeLines(c(
    sprintf("master_seed: %d", MASTER_SEED),
    sprintf("p: %d", cfg$p),
    sprintf("rank: %d", cfg$rank),
    sprintf("lambda_vals: [%s]", paste(format(cfg$lambda_vals, scientific = TRUE), collapse = ", ")),
    sprintf("spectrum: %s", cfg$spectrum),
    sprintf("cond: %.16g", cfg$cond),
    sprintf("n_trials: %d", cfg$n_trials)
), con = file.path(out_dir, "config.yaml"))
write_git_sha(file.path(out_dir, "git_sha.txt"))
capture.output(utils::sessionInfo(), file = file.path(out_dir, "sessionInfo.txt"))

op <- randMBC::generate_cov_operator(
    p = cfg$p,
    rank = cfg$p,
    spectrum = cfg$spectrum,
    cond = cfg$cond,
    seed = MASTER_SEED
)

trial_metrics <- randMBC::run_cov_transport_sweep(
    cov_op = op,
    ranks = cfg$rank,
    lambdas = cfg$lambda_vals,
    sketches = "gaussian",
    precisions = "double",
    n_trials = cfg$n_trials,
    base_seed = MASTER_SEED
)

summary_df <- randMBC::summarize_results(trial_metrics)

utils::write.csv(trial_metrics, file.path(out_dir, "trial_metrics.csv"), row.names = FALSE)
utils::write.csv(summary_df, file.path(out_dir, "summary.csv"), row.names = FALSE)

pdf(file.path(out_dir, "figures", "fig_ct_lambda_sweep.pdf"), width = 7, height = 5)
plot(summary_df$lambda, summary_df$transport_error_mean, type = "b", pch = 19,
     col = "firebrick", log = "x", xlab = expression(lambda), ylab = "Mean transport error",
     main = "Covariance transport lambda sweep")
grid()
dev.off()

writeLines(out_dir)
