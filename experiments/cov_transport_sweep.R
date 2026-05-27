args <- commandArgs(trailingOnly = TRUE)

parse_args <- function(args) {
    out <- list(
        output_dir = file.path("experiments", "output"),
        n_trials = 5L,
        base_seed = 100L
    )
    if (length(args) == 0L) return(out)
    for (arg in args) {
        parts <- strsplit(arg, "=", fixed = TRUE)[[1]]
        if (length(parts) == 2L) {
            key <- sub("^--", "", parts[[1]])
            if (key == "output_dir") out$output_dir <- parts[[2]]
            if (key == "n_trials") out$n_trials <- as.integer(parts[[2]])
            if (key == "base_seed") out$base_seed <- as.integer(parts[[2]])
        }
    }
    out
}

cfg <- parse_args(args)

suppressPackageStartupMessages({
    library(randMBC)
})

dir.create(cfg$output_dir, recursive = TRUE, showWarnings = FALSE)

cat("=== Covariance-transport experiment sweep ===\n")
cat(sprintf("  output_dir: %s\n", cfg$output_dir))
cat(sprintf("  n_trials:   %d\n", cfg$n_trials))
cat(sprintf("  base_seed:  %d\n", cfg$base_seed))

spectrum_types <- c("exponential", "linear", "gap")
p <- 30L

cat("\n--- Phase 1: Synthetic covariance operators ---\n")

for (spec in spectrum_types) {
    cat(sprintf("  Spectrum: %s\n", spec))
    op <- generate_cov_operator(
        p = p,
        rank = p,
        spectrum = spec,
        cond = 100,
        seed = cfg$base_seed
    )

    df <- run_cov_transport_sweep(
        cov_op = op,
        ranks = c(5L, 10L, 15L, 20L, 25L),
        lambdas = c(1e-6, 1e-4, 1e-2),
        sketches = c("gaussian", "rademacher"),
        precisions = c("double", "single"),
        n_trials = cfg$n_trials,
        oversampling = 5L,
        base_seed = cfg$base_seed
    )

    out_path <- file.path(cfg$output_dir, paste0("cov_transport_", spec, ".csv"))
    write_results(df, out_path)
    cat(sprintf("    -> %s (%d rows)\n", out_path, nrow(df)))

    summary <- summarize_results(df)
    summary <- check_fp_hidden(summary)
    sum_path <- file.path(cfg$output_dir, paste0("cov_transport_", spec, "_summary.csv"))
    write_results(summary, sum_path)
    cat(sprintf("    -> %s (%d rows)\n", sum_path, nrow(summary)))
}

cat("\n--- Phase 2: Climate-shaped covariance ---\n")

clim_op <- generate_climate_cov(
    n_var = 3,
    n_loc = 10,
    rank_signal = 5,
    noise_level = 1e-3,
    seed = cfg$base_seed
)

clim_df <- run_cov_transport_sweep(
    cov_op = clim_op,
    ranks = c(5L, 10L, 15L, 20L),
    lambdas = c(1e-6, 1e-4, 1e-2),
    sketches = c("gaussian"),
    precisions = c("double", "single"),
    n_trials = cfg$n_trials,
    oversampling = 5L,
    base_seed = cfg$base_seed + 1000L
)

clim_path <- file.path(cfg$output_dir, "cov_transport_climate.csv")
write_results(clim_df, clim_path)
cat(sprintf("  -> %s (%d rows)\n", clim_path, nrow(clim_df)))

clim_summary <- summarize_results(clim_df)
clim_summary <- check_fp_hidden(clim_summary)
clim_sum_path <- file.path(cfg$output_dir, "cov_transport_climate_summary.csv")
write_results(clim_summary, clim_sum_path)
cat(sprintf("  -> %s (%d rows)\n", clim_sum_path, nrow(clim_summary)))

cat("\n=== Done ===\n")
