MASTER_SEED <- 20260527L

suppressPackageStartupMessages({
    library(randMBC)
})

cfg <- list(
    p = 30L,
    rank_vals = c(5L, 10L, 15L, 20L, 25L, 30L),
    lambda = 1e-2,
    spectrum = "exponential",
    cond = 100,
    basis_mode = "shared",
    precision = "double",
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

write_config <- function(path, cfg_list) {
    writeLines(c(
        sprintf("master_seed: %d", MASTER_SEED),
        sprintf("p: %d", cfg_list$p),
        sprintf("rank_vals: [%s]", paste(cfg_list$rank_vals, collapse = ", ")),
        sprintf("lambda: %.16g", cfg_list$lambda),
        sprintf("spectrum: %s", cfg_list$spectrum),
        sprintf("cond: %.16g", cfg_list$cond),
        sprintf("basis_mode: %s", cfg_list$basis_mode),
        sprintf("precision: %s", cfg_list$precision),
        sprintf("n_trials: %d", cfg_list$n_trials)
    ), con = path)
}

write_git_sha <- function(path) {
    sha <- tryCatch(system2("git", c("rev-parse", "HEAD"), stdout = TRUE), error = function(e) "NA")
    writeLines(sha[[1L]], con = path)
}

set.seed(MASTER_SEED)
out_dir <- make_results_dir("04_transport_rank_sweep.R")
write_config(file.path(out_dir, "config.yaml"), cfg)
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
    ranks = cfg$rank_vals,
    lambdas = cfg$lambda,
    sketches = "gaussian",
    precisions = cfg$precision,
    n_trials = cfg$n_trials,
    base_seed = MASTER_SEED
)
trial_metrics$basis_mode <- cfg$basis_mode

summary_df <- randMBC::summarize_results(trial_metrics)
summary_df$basis_mode <- cfg$basis_mode

utils::write.csv(trial_metrics, file.path(out_dir, "trial_metrics.csv"), row.names = FALSE)
utils::write.csv(summary_df, file.path(out_dir, "summary.csv"), row.names = FALSE)

pdf(file.path(out_dir, "figures", "fig_ct_rank_sweep.pdf"), width = 7, height = 5)
plot(summary_df$rank, summary_df$transport_error_mean, type = "b", pch = 19,
     col = "navy", xlab = "Rank", ylab = "Mean transport error",
     main = "Covariance transport rank sweep")
grid()
dev.off()

writeLines(out_dir)
