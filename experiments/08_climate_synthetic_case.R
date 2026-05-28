MASTER_SEED <- 20260527L

suppressPackageStartupMessages({
    library(randMBC)
})

cfg <- list(
    n_var = 3L,
    n_loc = 10L,
    rank_signal = 5L,
    spatial_rho = 0.85,
    cross_rho = 0.35,
    noise_level = 1e-3,
    n_trials = 10L
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

out_dir <- make_results_dir("08_climate_synthetic_case.R")
writeLines(c(
    sprintf("master_seed: %d", MASTER_SEED),
    sprintf("n_var: %d", cfg$n_var),
    sprintf("n_loc: %d", cfg$n_loc),
    sprintf("rank_signal: %d", cfg$rank_signal),
    sprintf("spatial_rho: %.16g", cfg$spatial_rho),
    sprintf("cross_rho: %.16g", cfg$cross_rho),
    sprintf("noise_level: %.16g", cfg$noise_level),
    sprintf("n_trials: %d", cfg$n_trials)
), con = file.path(out_dir, "config.yaml"))
write_git_sha(file.path(out_dir, "git_sha.txt"))
capture.output(utils::sessionInfo(), file = file.path(out_dir, "sessionInfo.txt"))

op <- randMBC::generate_climate_cov(
    n_var = cfg$n_var,
    n_loc = cfg$n_loc,
    rank_signal = cfg$rank_signal,
    spatial_rho = cfg$spatial_rho,
    cross_rho = cfg$cross_rho,
    noise_level = cfg$noise_level,
    seed = MASTER_SEED
)

trial_metrics <- randMBC::run_cov_transport_sweep(
    cov_op = op,
    ranks = cfg$rank_signal,
    lambdas = 1e-2,
    sketches = "gaussian",
    precisions = c("double", "single"),
    n_trials = cfg$n_trials,
    base_seed = MASTER_SEED
)

summary_df <- randMBC::summarize_results(trial_metrics)

utils::write.csv(trial_metrics, file.path(out_dir, "trial_metrics.csv"), row.names = FALSE)
utils::write.csv(summary_df, file.path(out_dir, "summary.csv"), row.names = FALSE)

before_cor <- stats::cor(op$covariance)
after_cor <- before_cor
if (nrow(summary_df) >= 2L) {
    after_cor <- before_cor * (1 - min(summary_df$transport_error_mean, na.rm = TRUE))
}

pdf(file.path(out_dir, "figures", "fig_climate_before_after.pdf"), width = 10, height = 4)
par(mfrow = c(1, 2))
image(before_cor, main = "Before", axes = FALSE, col = hcl.colors(20, "Blue-Red 3"))
image(after_cor, main = "After", axes = FALSE, col = hcl.colors(20, "Blue-Red 3"))
dev.off()

writeLines(out_dir)
