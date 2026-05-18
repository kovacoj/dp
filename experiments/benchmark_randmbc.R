args <- commandArgs(trailingOnly = TRUE)

parse_args <- function(args) {
    out <- list(output = file.path("experiments", "output", "randmbc-benchmark.csv"))
    if (length(args) == 0L) {
        return(out)
    }

    for (arg in args) {
        parts <- strsplit(arg, "=", fixed = TRUE)[[1]]
        if (length(parts) == 2L && parts[[1]] == "--output") {
            out$output <- parts[[2]]
        }
    }
    out
}

cfg <- parse_args(args)

suppressPackageStartupMessages({
    library(randMBC)
})

source(file.path("experiments", "randmbc_benchmark_helpers.R"))

dir.create(dirname(cfg$output), recursive = TRUE, showWarnings = FALSE)

grid <- expand.grid(
    seed = c(1L, 2L),
    rank = c(2L, 3L),
    oversampling = c(0L, 2L),
    precision = c("double", "single"),
    stringsAsFactors = FALSE
)

rows <- vector("list", 4L * nrow(grid))
idx <- 1L

for (i in seq_len(nrow(grid))) {
    params <- grid[i, ]
    dataset <- simulate_climate_data(seed = params$seed, ratio_idx = 4L)
    ratio_seq <- c(FALSE, FALSE, FALSE, TRUE)
    lambda <- 1e-4

    baseline <- fit_full_cov_transport(
        dataset$x_hist,
        dataset$y_hist,
        dataset$x_fut,
        lambda = lambda,
        ratio_seq = ratio_seq
    )

    if (!any(vapply(rows[seq_len(idx - 1L)], function(x) {
        !is.null(x) && identical(x$method[[1]], "full_cov_transport") && identical(x$seed[[1]], params$seed)
    }, logical(1)))) {
        rows[[idx]] <- benchmark_row(
            method = "full_cov_transport",
            backend = "randMBC-baseline",
            seed = params$seed,
            dataset = dataset,
            fit = baseline,
            baseline_fit = baseline,
            params = list(
                rank = ncol(dataset$x_hist),
                oversampling = 0L,
                lambda = lambda,
                precision = "double",
                rounding = "nearest",
                orth_prec = "double",
                sketch = "none",
                runtime = baseline$runtime
            )
        )
        idx <- idx + 1L

        for (method in c("MBCp", "MBCr")) {
            ref_fit <- fit_mbc_reference(
                method,
                dataset$x_hist,
                dataset$y_hist,
                dataset$x_fut,
                ratio_seq = ratio_seq
            )
            rows[[idx]] <- benchmark_row(
                method = paste0("reference_", method),
                backend = "src/MBC",
                seed = params$seed,
                dataset = dataset,
                fit = ref_fit,
                baseline_fit = baseline,
                params = list(
                    rank = NA_integer_,
                    oversampling = NA_integer_,
                    lambda = lambda,
                    precision = "double",
                    rounding = "nearest",
                    orth_prec = "double",
                    sketch = "none",
                    runtime = ref_fit$runtime
                )
            )
            idx <- idx + 1L
        }
    }

    start <- proc.time()[[3L]]
    fit <- fit_rand_mbc(
        dataset$x_hist,
        dataset$y_hist,
        dataset$x_fut,
        rank = params$rank,
        oversampling = params$oversampling,
        sketch = "gaussian",
        precision = params$precision,
        orth_prec = "double",
        lambda = lambda,
        ratio_seq = ratio_seq
    )
    runtime <- proc.time()[[3L]] - start

    rows[[idx]] <- benchmark_row(
        method = "randomized_cov_transport",
        backend = "randMBC",
        seed = params$seed,
        dataset = dataset,
        fit = fit,
        baseline_fit = baseline,
        params = list(
            rank = params$rank,
            oversampling = params$oversampling,
            lambda = lambda,
            precision = params$precision,
            rounding = "nearest",
            orth_prec = "double",
            sketch = "gaussian",
            runtime = runtime
        )
    )
    idx <- idx + 1L
}

results <- do.call(rbind, rows[seq_len(idx - 1L)])
utils::write.csv(results, cfg$output, row.names = FALSE)
write_benchmark_outputs(results, cfg$output)
print(results)
