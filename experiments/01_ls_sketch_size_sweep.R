MASTER_SEED <- 20260527L

suppressPackageStartupMessages({
    library(rSketchLS)
})

cfg <- list(
    n = 500L,
    d = 20L,
    s_vals = seq(30L, 400L, by = 10L),
    trials = 20L,
    noise_level = 0.1,
    method = "gaussian",
    seed = 1L
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
    lines <- c(
        sprintf("master_seed: %d", MASTER_SEED),
        sprintf("n: %d", cfg_list$n),
        sprintf("d: %d", cfg_list$d),
        sprintf("s_vals: [%s]", paste(cfg_list$s_vals, collapse = ", ")),
        sprintf("trials: %d", cfg_list$trials),
        sprintf("noise_level: %.16g", cfg_list$noise_level),
        sprintf("method: %s", cfg_list$method),
        sprintf("seed: %d", cfg_list$seed)
    )
    writeLines(lines, con = path)
}

write_git_sha <- function(path) {
    sha <- tryCatch(
        system2("git", c("rev-parse", "HEAD"), stdout = TRUE, stderr = FALSE),
        error = function(e) NA_character_
    )
    writeLines(if (length(sha) >= 1L) sha[[1L]] else "NA", con = path)
}

plot_metric <- function(df, y, ylab, path) {
    pdf(path, width = 7, height = 5)
    on.exit(dev.off(), add = TRUE)
    plot(df$s, df[[y]], type = "b", pch = 19, col = "navy",
         xlab = "Sketch size s", ylab = ylab,
         main = sprintf("%s vs sketch size", ylab))
    grid()
}

set.seed(MASTER_SEED)
out_dir <- make_results_dir("01_ls_sketch_size_sweep.R")

write_config(file.path(out_dir, "config.yaml"), cfg)
write_git_sha(file.path(out_dir, "git_sha.txt"))
capture.output(utils::sessionInfo(), file = file.path(out_dir, "sessionInfo.txt"))

result <- rSketchLS::sketch_lstsq_experiment(
    n = cfg$n,
    d = cfg$d,
    s_values = cfg$s_vals,
    trials = cfg$trials,
    noise_level = cfg$noise_level,
    method = cfg$method,
    seed = cfg$seed
)

trial_metrics <- result$history
summary_df <- data.frame(
    metric = c("min_residual_ratio", "min_solution_error", "mean_condition_number"),
    value = c(
        min(trial_metrics$mean_residual_ratio, na.rm = TRUE),
        min(trial_metrics$mean_solution_error, na.rm = TRUE),
        mean(trial_metrics$mean_condition_number, na.rm = TRUE)
    ),
    stringsAsFactors = FALSE
)

utils::write.csv(trial_metrics, file.path(out_dir, "trial_metrics.csv"), row.names = FALSE)
utils::write.csv(summary_df, file.path(out_dir, "summary.csv"), row.names = FALSE)

plot_metric(
    trial_metrics,
    y = "mean_residual_ratio",
    ylab = "Mean residual ratio",
    path = file.path(out_dir, "figures", "fig_ls_residual.pdf")
)

plot_metric(
    trial_metrics,
    y = "mean_solution_error",
    ylab = "Mean relative solution error",
    path = file.path(out_dir, "figures", "fig_ls_solution.pdf")
)

writeLines(out_dir)
