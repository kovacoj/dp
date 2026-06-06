#' Run repeated multivariate sketched least-squares experiments
#'
#' Generates a synthetic overdetermined problem \eqn{\min_X \|AX - Y\|_F}
#' and evaluates a randomized sketching method over a grid of sketch sizes.
#'
#' @param n Integer number of rows.
#' @param d Integer number of columns.
#' @param p Integer number of right-hand-side columns.
#' @param s_vals Integer vector of sketch sizes.
#' @param trials Integer number of randomized trials per sketch size.
#' @param noise_level Numeric standard deviation of additive noise.
#' @param cond_num Optional target condition number for `A`.
#' @param method Sketch family.
#' @param seed Integer seed for reproducibility.
#' @param outdir Optional directory path. If provided, saves `trial_metrics.csv`,
#'   `summary.csv`, and `config.yaml` into `outdir`.
#'
#' @return A list with `history` (data frame), reference solution, true
#'   coefficient matrix, generated data, and settings.
#'
#' @examples
#' out <- sketch_lstsq_experiment_multi(
#'   n = 30, d = 5, p = 3, s_vals = c(10, 15), trials = 2, seed = 1
#' )
#' out$history
#'
#' @export
sketch_lstsq_experiment_multi <- function(
    n = 100L,
    d = 10L,
    p = 5L,
    s_vals = seq(2L * d, n - 1L, by = 4L),
    trials = 20L,
    noise_level = 0,
    cond_num = NULL,
    method = c("gaussian", "rademacher", "srht"),
    seed = 1L,
    outdir = NULL
) {
    method <- match.arg(method)
    MASTER_SEED <- 20260527L
    base_seed <- if (!is.null(seed)) as.integer(seed) else MASTER_SEED

    if (!is.null(cond_num)) {
        A <- generate_conditional(n, d, kappa = cond_num)
    } else {
        set.seed(base_seed)
        A <- matrix(stats::rnorm(n * d), nrow = n, ncol = d)
    }

    set.seed(base_seed + 1L)
    X_true <- matrix(stats::rnorm(d * p), nrow = d, ncol = p)
    Y <- A %*% X_true + noise_level * matrix(stats::rnorm(n * p), nrow = n, ncol = p)

    X_ref <- qr.solve(A, Y)
    ref_residual <- A %*% X_ref - Y
    ref_res_norm <- sqrt(sum(ref_residual^2))
    ref_norm <- sqrt(sum(X_ref^2))

    rows <- list()
    for (s in s_vals) {
        for (trial in seq_len(trials)) {
            trial_seed <- base_seed + 1000L * as.integer(s) + trial
            fit <- sketch_lstsq_multi(A, Y, s = s, method = method, seed = trial_seed)
            res_ratio <- if (ref_res_norm > 1e-12) fit$residual_norm / ref_res_norm else NA_real_
            sol_error <- sqrt(sum((fit$X - X_ref)^2)) / max(ref_norm, 1e-12)
            rows[[length(rows) + 1L]] <- data.frame(
                s = s, trial = trial,
                residual_norm = fit$residual_norm,
                res_ratio = res_ratio,
                solution_error = sol_error,
                condition_number = fit$condition_number,
                stringsAsFactors = FALSE
            )
        }
    }
    history <- do.call(rbind, rows)
    rownames(history) <- NULL

    metrics <- c("residual_norm", "res_ratio", "solution_error", "condition_number")
    groups <- split(history, history$s)
    summary_rows <- lapply(groups, function(sub) {
        row <- data.frame(s = sub$s[1L], n_trials = nrow(sub), stringsAsFactors = FALSE)
        for (m in metrics) {
            vals <- sub[[m]]
            vals <- vals[!is.na(vals)]
            row[[paste0(m, "_mean")]] <- if (length(vals) > 0) mean(vals) else NA_real_
            row[[paste0(m, "_sd")]] <- if (length(vals) > 1) stats::sd(vals) else NA_real_
            row[[paste0(m, "_median")]] <- if (length(vals) > 0) stats::median(vals) else NA_real_
        }
        row
    })
    summary_df <- do.call(rbind, summary_rows)
    rownames(summary_df) <- NULL

    out <- list(
        history = history,
        summary = summary_df,
        X_ref = X_ref,
        X_true = X_true,
        A = A,
        Y = Y,
        noise_level = noise_level,
        cond_num = cond_num,
        trials = trials,
        method = method,
        seed = base_seed
    )

    if (!is.null(outdir)) {
        dir.create(outdir, recursive = TRUE, showWarnings = FALSE)
        utils::write.csv(history, file.path(outdir, "trial_metrics.csv"), row.names = FALSE)
        utils::write.csv(summary_df, file.path(outdir, "summary.csv"), row.names = FALSE)
        yaml_path <- file.path(outdir, "config.yaml")
        config_lines <- c(
            sprintf("n: %d", n),
            sprintf("d: %d", d),
            sprintf("p: %d", p),
            sprintf("method: %s", method),
            sprintf("trials: %d", trials),
            sprintf("noise_level: %g", noise_level),
            sprintf("cond_num: %s", if (is.null(cond_num)) "NULL" else as.character(cond_num)),
            sprintf("seed: %d", base_seed),
            sprintf("s_vals: [%s]", paste(s_vals, collapse = ", "))
        )
        writeLines(config_lines, yaml_path)
    }

    out
}
