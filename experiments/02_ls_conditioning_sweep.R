MASTER_SEED <- 20260527L

suppressPackageStartupMessages({
    library(rSketchLS)
})

cfg <- list(
    n = 500L,
    d = 20L,
    cond_nums = c(1e1, 1e2, 1e3, 1e4, 1e6),
    s_vals = c(50L, 100L, 200L),
    trials = 20L,
    method = "gaussian"
)

make_results_dir <- function(script_name) {
    args_all <- commandArgs(trailingOnly = FALSE)
    script_path <- sys.frame(1)$ofile
    if (is.null(script_path) || length(script_path) == 0L || is.na(script_path)) {
        file_arg <- args_all[grep("^--file=", args_all)]
        script_path <- sub("^--file=", "", file_arg[[1L]])
    }
    script_dir <- dirname(normalizePath(script_path))
    results_root <- file.path(script_dir, "results")
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
        sprintf("n: %d", cfg_list$n),
        sprintf("d: %d", cfg_list$d),
        sprintf("cond_nums: [%s]", paste(format(cfg_list$cond_nums, scientific = TRUE), collapse = ", ")),
        sprintf("s_vals: [%s]", paste(cfg_list$s_vals, collapse = ", ")),
        sprintf("trials: %d", cfg_list$trials),
        sprintf("method: %s", cfg_list$method)
    ), con = path)
}

write_git_sha <- function(path) {
    sha <- tryCatch(system2("git", c("rev-parse", "HEAD"), stdout = TRUE), error = function(e) "NA")
    writeLines(sha[[1L]], con = path)
}

set.seed(MASTER_SEED)
out_dir <- make_results_dir("02_ls_conditioning_sweep.R")
write_config(file.path(out_dir, "config.yaml"), cfg)
write_git_sha(file.path(out_dir, "git_sha.txt"))
capture.output(utils::sessionInfo(), file = file.path(out_dir, "sessionInfo.txt"))

rows <- vector("list", length(cfg$cond_nums) * length(cfg$s_vals) * cfg$trials)
idx <- 1L

for (cond_num in cfg$cond_nums) {
    A <- rSketchLS::generate_conditional(cfg$n, cfg$d, kappa = cond_num)
    x_true <- rep(1, cfg$d)
    b <- as.vector(A %*% x_true)
    x_ref <- qr.solve(A, b)
    ref_norm <- sqrt(sum(x_ref^2))

    for (s in cfg$s_vals) {
        for (trial in seq_len(cfg$trials)) {
            set.seed(MASTER_SEED + idx)
            fit <- rSketchLS::sketch_lstsq(A, b, s = s, method = cfg$method)
            rows[[idx]] <- data.frame(
                cond_num = cond_num,
                s = s,
                trial = trial,
                solution_error = sqrt(sum((fit$x - x_ref)^2)) / ref_norm,
                residual_norm = fit$residual_norm,
                condition_number = fit$condition_number,
                stringsAsFactors = FALSE
            )
            idx <- idx + 1L
        }
    }
}

trial_metrics <- do.call(rbind, rows)
summary_df <- stats::aggregate(
    cbind(solution_error, residual_norm, condition_number) ~ cond_num + s,
    data = trial_metrics,
    FUN = mean
)

utils::write.csv(trial_metrics, file.path(out_dir, "trial_metrics.csv"), row.names = FALSE)
utils::write.csv(summary_df, file.path(out_dir, "summary.csv"), row.names = FALSE)

pdf(file.path(out_dir, "figures", "fig_ls_cond_error.pdf"), width = 7, height = 5)
cols <- c("navy", "firebrick", "darkgreen")
plot(range(cfg$cond_nums), range(summary_df$solution_error, na.rm = TRUE),
     log = "x", type = "n", xlab = "Condition number", ylab = "Mean relative solution error",
     main = "Least-squares sketch error vs conditioning")
for (j in seq_along(cfg$s_vals)) {
    sub <- summary_df[summary_df$s == cfg$s_vals[[j]], ]
    lines(sub$cond_num, sub$solution_error, type = "b", pch = 19, col = cols[[j]])
}
legend("topleft", legend = paste("s =", cfg$s_vals), col = cols, pch = 19, lty = 1, bty = "n")
grid()
dev.off()

writeLines(out_dir)
