gaussian_lstsq_experiment <- function(
    n = 100L,
    d = 10L,
    s_values = seq_len(n - 1L),
    trials = 10L,
    noise_level = 0,
    seed = NULL
) {
    if (!is.null(seed)) {
        set.seed(seed)
    }

    A <- matrix(stats::rnorm(n * d), nrow = n, ncol = d)
    x_true <- rep(1, d)
    b <- as.vector(A %*% x_true + noise_level * stats::rnorm(n))

    x_ref <- qr.solve(A, b)
    ref_residual <- sqrt(sum((A %*% x_ref - b)^2))
    ref_norm <- sqrt(sum(x_ref^2))

    metrics <- lapply(s_values, function(s) {
        trial_fits <- replicate(trials, sketch_lstsq(A, b, s = s, method = "gaussian"), simplify = FALSE)

        x_mat <- do.call(cbind, lapply(trial_fits, `[[`, "x"))
        residual_ratios <- vapply(trial_fits, function(fit) fit$residual_norm / ref_residual, numeric(1))
        solution_errors <- vapply(trial_fits, function(fit) sqrt(sum((fit$x - x_ref)^2)) / ref_norm, numeric(1))
        cond_values <- vapply(trial_fits, `[[`, numeric(1), "condition_number")

        c(
            s = s,
            mean_abs_error = mean(abs(rowMeans(x_mat) - x_true)),
            mean_residual_ratio = mean(residual_ratios),
            mean_solution_error = mean(solution_errors),
            mean_condition_number = mean(cond_values)
        )
    })

    history <- as.data.frame(do.call(rbind, metrics))
    rownames(history) <- NULL

    list(
        history = history,
        x_ref = x_ref,
        x_true = x_true,
        A = A,
        b = b,
        noise_level = noise_level,
        trials = trials
    )
}
