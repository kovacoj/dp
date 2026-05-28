MASTER_SEED <- 20260527L

suppressPackageStartupMessages({
    library(rSketchLS)
})

cfg <- list(
    n = 500L,
    d = 20L,
    s_vals = c(50L, 100L, 200L),
    sketch_prec = c("double", "single", "half", "bfloat16"),
    solve_prec = "double",
    trials = 20L
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

writeLinesCfg <- function(path, cfg_list) {
    writeLines(c(
        sprintf("master_seed: %d", MASTER_SEED),
        sprintf("n: %d", cfg_list$n),
        sprintf("d: %d", cfg_list$d),
        sprintf("s_vals: [%s]", paste(cfg_list$s_vals, collapse = ", ")),
        sprintf("sketch_prec: [%s]", paste(cfg_list$sketch_prec, collapse = ", ")),
        sprintf("solve_prec: %s", cfg_list$solve_prec),
        sprintf("trials: %d", cfg_list$trials)
    ), con = path)
}

set.seed(MASTER_SEED)
out_dir <- make_results_dir("03_ls_precision_sweep.R")
writeLinesCfg(file.path(out_dir, "config.yaml"), cfg)
write_git_sha(file.path(out_dir, "git_sha.txt"))
capture.output(utils::sessionInfo(), file = file.path(out_dir, "sessionInfo.txt"))

A <- matrix(stats::rnorm(cfg$n * cfg$d), nrow = cfg$n, ncol = cfg$d)
x_true <- rep(1, cfg$d)
b <- as.vector(A %*% x_true + 0.1 * stats::rnorm(cfg$n))
x_ref <- qr.solve(A, b)
ref_norm <- sqrt(sum(x_ref^2))
ref_resid <- sqrt(sum((A %*% x_ref - b)^2))

rows <- vector("list", length(cfg$s_vals) * length(cfg$sketch_prec) * cfg$trials)
idx <- 1L

for (s in cfg$s_vals) {
    for (prec in cfg$sketch_prec) {
        for (trial in seq_len(cfg$trials)) {
            fit <- rSketchLS::sketch_lstsq_mixed(
                A,
                b,
                s = s,
                method = "gaussian",
                sketch_prec = prec,
                solve_prec = cfg$solve_prec,
                seed = MASTER_SEED + idx
            )
            rows[[idx]] <- data.frame(
                s = s,
                sketch_prec = prec,
                solve_prec = cfg$solve_prec,
                trial = trial,
                residual_ratio = fit$residual_norm / ref_resid,
                solution_error = sqrt(sum((fit$x - x_ref)^2)) / ref_norm,
                condition_number = fit$condition_number,
                stringsAsFactors = FALSE
            )
            idx <- idx + 1L
        }
    }
}

trial_metrics <- do.call(rbind, rows)
summary_df <- stats::aggregate(
    cbind(residual_ratio, solution_error, condition_number) ~ s + sketch_prec + solve_prec,
    data = trial_metrics,
    FUN = mean
)

utils::write.csv(trial_metrics, file.path(out_dir, "trial_metrics.csv"), row.names = FALSE)
utils::write.csv(summary_df, file.path(out_dir, "summary.csv"), row.names = FALSE)

pdf(file.path(out_dir, "figures", "fig_ls_precision_comparison.pdf"), width = 7, height = 5)
cols <- c("black", "navy", "firebrick", "darkgreen")
plot(range(cfg$s_vals), range(summary_df$solution_error, na.rm = TRUE),
     type = "n", xlab = "Sketch size s", ylab = "Mean relative solution error",
     main = "Mixed-precision sketch comparison")
for (j in seq_along(cfg$sketch_prec)) {
    sub <- summary_df[summary_df$sketch_prec == cfg$sketch_prec[[j]], ]
    lines(sub$s, sub$solution_error, type = "b", pch = 19, col = cols[[j]])
}
legend("topright", legend = cfg$sketch_prec, col = cols, pch = 19, lty = 1, bty = "n")
grid()
dev.off()

writeLines(out_dir)
