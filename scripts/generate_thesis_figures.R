suppressPackageStartupMessages({
    library(rSketchLS)
})

results_dir <- "/workspace/results"
fig_dir <- "/workspace/thesis/figures"
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

exp01 <- read.csv(file.path(results_dir, "01_ls_sketch_size_sweep_20260528_222601", "trial_metrics.csv"))

pdf(file.path(fig_dir, "ls_res_ratio_vs_s.pdf"), width = 7, height = 5)
plot(exp01$s, exp01$mean_residual_ratio,
     type = "b", pch = 19, col = "navy",
     xlab = "Sketch size s", ylab = "Mean residual ratio",
     main = "Residual ratio vs sketch size (n=500, d=20, Gaussian)")
abline(h = 1, lty = 2, col = "grey40")
grid()
dev.off()

pdf(file.path(fig_dir, "ls_sol_error_vs_s.pdf"), width = 7, height = 5)
plot(exp01$s, exp01$mean_solution_error,
     type = "b", pch = 19, col = "darkred",
     xlab = "Sketch size s", ylab = "Mean relative solution error",
     main = "Solution error vs sketch size (n=500, d=20, Gaussian)")
grid()
dev.off()

exp02 <- read.csv(file.path(results_dir, "02_ls_conditioning_sweep_20260528_225557", "trial_metrics.csv"))
agg02 <- aggregate(cbind(solution_error, residual_norm, condition_number) ~ cond_num + s,
                   data = exp02, FUN = mean)

pdf(file.path(fig_dir, "ls_cond_error.pdf"), width = 7, height = 5)
colors <- c("50" = "navy", "100" = "darkred", "200" = "darkgreen")
plot(NULL, xlim = range(agg02$cond_num), ylim = range(agg02$solution_error, na.rm = TRUE),
     log = "x", xlab = expression(kappa(A)), ylab = "Mean relative solution error",
     main = "Solution error vs condition number")
for (ss in sort(unique(agg02$s))) {
    sub <- agg02[agg02$s == ss, ]
    col <- if (ss == 50) "navy" else if (ss == 100) "darkred" else "darkgreen"
    lines(sub$cond_num, sub$solution_error, type = "b", pch = 19, col = col)
}
legend("topleft", legend = paste("s =", sort(unique(agg02$s))),
       col = c("navy", "darkred", "darkgreen"), lty = 1, pch = 19)
grid()
dev.off()

exp04 <- read.csv(file.path(results_dir, "04_transport_rank_sweep_20260528_222625", "trial_metrics.csv"))
agg04 <- aggregate(cbind(cov_error, transport_error) ~ rank,
                   data = exp04[exp04$lambda == 0.01, ], FUN = mean)

pdf(file.path(fig_dir, "ct_transport_error_vs_rank.pdf"), width = 7, height = 5)
plot(agg04$rank, agg04$transport_error,
     type = "b", pch = 19, col = "navy",
     xlab = "Approximation rank", ylab = "Mean transport error",
     main = "Covariance transport error vs rank (lambda=0.01, double)")
grid()
dev.off()

cat("Figures written to", fig_dir, "\n")
