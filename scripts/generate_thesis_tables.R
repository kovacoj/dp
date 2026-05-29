suppressPackageStartupMessages({
    library(rSketchLS)
})

results_dir <- "/workspace/results"

exp01 <- read.csv(file.path(results_dir, "01_ls_sketch_size_sweep_20260528_222601", "trial_metrics.csv"))
cat("=== LS Sketch-Size Sweep: Selected rows ===\n")
sel <- exp01[exp01$s %in% c(30, 60, 100, 200, 300, 400), ]
agg <- aggregate(cbind(mean_residual_ratio, mean_solution_error, mean_condition_number) ~ s,
                 data = exp01, FUN = function(x) c(mean = mean(x), sd = sd(x)))
agg_df <- do.call(data.frame, agg)
print(agg_df, digits = 3)

exp04 <- read.csv(file.path(results_dir, "04_transport_rank_sweep_20260528_222625", "trial_metrics.csv"))
cat("\n=== CT Rank Sweep (double, lambda=0.01) ===\n")
sub04 <- exp04[exp04$lambda == 0.01 & exp04$mult_prec == "double", ]
agg04 <- aggregate(cbind(cov_error, transport_error, lambda_min_reg, condition_est, runtime) ~ rank,
                   data = sub04,
                   FUN = function(x) c(mean = mean(x), sd = sd(x), median = median(x)))
agg04_df <- do.call(data.frame, agg04)
print(agg04_df, digits = 3)

exp06 <- read.csv(file.path(results_dir, "06_transport_precision_sweep_20260528_225619", "trial_metrics.csv"))
cat("\n=== CT Precision Comparison (rank=20, lambda=0.01) ===\n")
agg06 <- aggregate(cbind(cov_error, transport_error, runtime) ~ mult_prec,
                   data = exp06,
                   FUN = function(x) c(mean = mean(x), sd = sd(x)))
agg06_df <- do.call(data.frame, agg06)
print(agg06_df, digits = 3)

exp07 <- read.csv(file.path(results_dir, "07_transport_basis_mode_20260528_225622", "trial_metrics.csv"))
cat("\n=== CT Basis Mode Comparison ===\n")
agg07 <- aggregate(cbind(pearson_error, covariance_error_x, runtime) ~ basis_mode + rank + lambda,
                   data = exp07,
                   FUN = function(x) c(mean = mean(x), sd = sd(x)))
agg07_df <- do.call(data.frame, agg07)
print(agg07_df, digits = 3)
