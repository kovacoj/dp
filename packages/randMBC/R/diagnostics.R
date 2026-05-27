#' Summarize experiment results across trials
#'
#' Aggregates a results data frame from
#' \code{\link{run_cov_transport_sweep}} into summary statistics per
#' parameter combination.
#'
#' @param df Data frame of trial results.
#' @param fun Summary function to apply to each metric column.
#'   Default \code{mean}.
#'
#' @return A data frame with one row per (rank, lambda, sketch, mult_prec)
#'   combination and columns for the aggregated metrics.
#' @examples
#' op <- generate_cov_operator(20, rank = 10, spectrum = "exponential", cond = 100)
#' df <- run_cov_transport_sweep(op, ranks = c(5, 10), lambdas = 1e-6,
#'   n_trials = 3, base_seed = 1)
#' summary <- summarize_results(df)
#' nrow(summary)
#' @export
summarize_results <- function(df, fun = mean) {
    metrics <- c("cov_error", "transport_error", "lambda_min_reg",
                 "condition_est", "runtime")

    grouped <- split(df, paste(df$rank, df$lambda, df$sketch, df$mult_prec, sep = "|"))

    rows <- lapply(grouped, function(sub) {
        out <- data.frame(
            rank = sub$rank[1],
            lambda = sub$lambda[1],
            sketch = sub$sketch[1],
            mult_prec = sub$mult_prec[1],
            n_trials = nrow(sub),
            stringsAsFactors = FALSE
        )
        for (m in metrics) {
            vals <- sub[[m]]
            vals <- vals[!is.na(vals)]
            out[[paste0(m, "_mean")]] <- if (length(vals) > 0) fun(vals) else NA_real_
            out[[paste0(m, "_sd")]] <- if (length(vals) > 1) stats::sd(vals) else NA_real_
        }
        out
    })

    do.call(rbind, rows)
}

#' Check whether floating-point error is hidden by randomized error
#'
#' Given a summarized results data frame, marks each parameter combination
#' according to whether the mean transport error in single precision is
#' within a tolerance factor of the double-precision transport error at the
#' same rank, lambda, and sketch.
#'
#' @param summary_df Summarized results from \code{\link{summarize_results}}.
#' @param tol Relative tolerance.  Default 1.5.
#'
#' @return The input data frame with an additional logical column
#'   \code{fp_hidden}.
#' @examples
#' op <- generate_cov_operator(20, rank = 10, spectrum = "exponential", cond = 100)
#' df <- run_cov_transport_sweep(op, ranks = c(5, 10), lambdas = 1e-6,
#'   precisions = c("double", "single"), n_trials = 3, base_seed = 1)
#' s <- summarize_results(df)
#' s <- check_fp_hidden(s)
#' "fp_hidden" %in% names(s)
#' @export
check_fp_hidden <- function(summary_df, tol = 1.5) {
    double_rows <- summary_df[summary_df$mult_prec == "double", ]
    fp_hidden <- logical(nrow(summary_df))

    for (i in seq_len(nrow(summary_df))) {
        row <- summary_df[i, ]
        match_idx <- which(
            double_rows$rank == row$rank &
            double_rows$lambda == row$lambda &
            double_rows$sketch == row$sketch
        )
        if (length(match_idx) >= 1 && row$mult_prec != "double") {
            ref_error <- double_rows$transport_error_mean[match_idx[1]]
            if (!is.na(ref_error) && ref_error > 0 && !is.na(row$transport_error_mean)) {
                fp_hidden[i] <- row$transport_error_mean <= tol * ref_error
            } else {
                fp_hidden[i] <- NA
            }
        } else if (row$mult_prec == "double") {
            fp_hidden[i] <- TRUE
        } else {
            fp_hidden[i] <- NA
        }
    }

    summary_df$fp_hidden <- fp_hidden
    summary_df
}

#' Write results to CSV
#'
#' A thin wrapper around \code{write.csv} with consistent defaults for
#' thesis experiment outputs.
#'
#' @param df Data frame to write.
#' @param path Output file path.
#' @param row.names Logical; passed to \code{write.csv}.
#' @export
write_results <- function(df, path, row.names = FALSE) {
    utils::write.csv(df, path, row.names = row.names)
}

#' Read results from CSV
#'
#' @param path File path.
#' @return A data frame.
#' @export
read_results <- function(path) {
    utils::read.csv(path, stringsAsFactors = FALSE)
}
