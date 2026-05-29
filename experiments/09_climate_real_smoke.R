MASTER_SEED <- 20260527L

suppressPackageStartupMessages({
    library(randMBC)
})

cfg <- list(
    dataset = "cccma",
    rank = 2L,
    oversampling = 1L,
    precision = "double",
    orth_prec = "double",
    lambda = 1e-6
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

out_dir <- make_results_dir("09_climate_real_smoke.R")
writeLines(c(
    sprintf("master_seed: %d", MASTER_SEED),
    sprintf("dataset: %s", cfg$dataset),
    sprintf("rank: %d", cfg$rank),
    sprintf("oversampling: %d", cfg$oversampling),
    sprintf("precision: %s", cfg$precision),
    sprintf("orth_prec: %s", cfg$orth_prec),
    sprintf("lambda: %.16g", cfg$lambda)
), con = file.path(out_dir, "config.yaml"))
write_git_sha(file.path(out_dir, "git_sha.txt"))
capture.output(utils::sessionInfo(), file = file.path(out_dir, "sessionInfo.txt"))

if (!requireNamespace("MBC", quietly = TRUE)) {
    trial_metrics <- data.frame(status = "skipped", reason = "MBC package not installed", stringsAsFactors = FALSE)
    summary_df <- data.frame(status = "skipped", reason = "MBC package not installed", stringsAsFactors = FALSE)
    utils::write.csv(trial_metrics, file.path(out_dir, "trial_metrics.csv"), row.names = FALSE)
    utils::write.csv(summary_df, file.path(out_dir, "summary.csv"), row.names = FALSE)
    message("MBC is not installed; skipping smoke test.")
    quit(save = "no", status = 0L)
}

data_ok <- tryCatch({
    data("cccma", package = "MBC", envir = environment())
    TRUE
}, error = function(e) FALSE)

if (!data_ok || !exists("cccma", inherits = FALSE)) {
    trial_metrics <- data.frame(status = "skipped", reason = "cccma dataset unavailable", stringsAsFactors = FALSE)
    summary_df <- data.frame(status = "skipped", reason = "cccma dataset unavailable", stringsAsFactors = FALSE)
    utils::write.csv(trial_metrics, file.path(out_dir, "trial_metrics.csv"), row.names = FALSE)
    utils::write.csv(summary_df, file.path(out_dir, "summary.csv"), row.names = FALSE)
    message("cccma dataset could not be loaded; skipping smoke test.")
    quit(save = "no", status = 0L)
}

cccma_obj <- get("cccma", inherits = FALSE)
matrices <- Filter(is.matrix, unclass(cccma_obj))

if (length(matrices) < 3L) {
    trial_metrics <- data.frame(status = "skipped", reason = "cccma data shape not recognized", stringsAsFactors = FALSE)
    summary_df <- data.frame(status = "skipped", reason = "cccma data shape not recognized", stringsAsFactors = FALSE)
    utils::write.csv(trial_metrics, file.path(out_dir, "trial_metrics.csv"), row.names = FALSE)
    utils::write.csv(summary_df, file.path(out_dir, "summary.csv"), row.names = FALSE)
    message("cccma dataset layout is not recognized; skipping smoke test.")
    quit(save = "no", status = 0L)
}

x_hist <- matrices[[1L]]
y_hist <- matrices[[2L]]
x_fut <- matrices[[3L]]
common_cols <- min(ncol(x_hist), ncol(y_hist), ncol(x_fut))
x_hist <- x_hist[, seq_len(common_cols), drop = FALSE]
y_hist <- y_hist[, seq_len(common_cols), drop = FALSE]
x_fut <- x_fut[, seq_len(common_cols), drop = FALSE]
common_rows_hist <- min(nrow(x_hist), nrow(y_hist))
x_hist <- x_hist[seq_len(common_rows_hist), , drop = FALSE]
y_hist <- y_hist[seq_len(common_rows_hist), , drop = FALSE]

fit <- randMBC::fit_rand_mbc(
    x_hist = x_hist,
    y_hist = y_hist,
    x_fut = x_fut,
    rank = cfg$rank,
    oversampling = cfg$oversampling,
    sketch = "gaussian",
    precision = cfg$precision,
    orth_prec = cfg$orth_prec,
    lambda = cfg$lambda,
    seed = MASTER_SEED
)

trial_metrics <- data.frame(
    status = "ok",
    n_hist = nrow(x_hist),
    n_fut = nrow(x_fut),
    p = ncol(x_hist),
    rank = fit$rank,
    runtime = fit$runtime,
    pearson_error = fit$diagnostics$pearson_error,
    spearman_error = fit$diagnostics$spearman_error,
    quantile_error = fit$diagnostics$quantile_error,
    covariance_error_x = fit$diagnostics$covariance_error_x,
    covariance_error_y = fit$diagnostics$covariance_error_y,
    stringsAsFactors = FALSE
)

summary_df <- data.frame(
    metric = names(trial_metrics),
    value = vapply(trial_metrics[1, , drop = FALSE], function(x) as.character(x[[1L]]), character(1)),
    stringsAsFactors = FALSE
)

utils::write.csv(trial_metrics, file.path(out_dir, "trial_metrics.csv"), row.names = FALSE)
utils::write.csv(summary_df, file.path(out_dir, "summary.csv"), row.names = FALSE)

writeLines(out_dir)
