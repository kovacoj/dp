sketch_lstsq_experiment <- function(
    n = 100L,
    d = 10L,
    s_values = seq_len(n - 1L),
    trials = 10L,
    noise_level = 0,
    method = "gaussian",
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
        trial_fits <- replicate(trials, sketch_lstsq(A, b, s = s, method = method), simplify = FALSE)

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
        trials = trials,
        method = method
    )
}

gaussian_lstsq_experiment <- function(
    n = 100L,
    d = 10L,
    s_values = seq_len(n - 1L),
    trials = 10L,
    noise_level = 0,
    seed = NULL
) {
    sketch_lstsq_experiment(
        n = n, d = d, s_values = s_values, trials = trials,
        noise_level = noise_level, method = "gaussian", seed = seed
    )
}

srht_lstsq_experiment <- function(
    n = 128L,
    d = 10L,
    s_values = seq(2 * d, n - 1L, by = 4L),
    trials = 10L,
    noise_level = 0,
    seed = NULL
) {
    if (!is.null(seed)) {
        set.seed(seed)
    }
    n_pow2 <- 2L^ceiling(log2(n))
    if (n_pow2 != n) {
        warning(sprintf("SRHT requires n = power of 2; rounding n = %d up to %d", n, n_pow2))
        n <- n_pow2
    }
    sketch_lstsq_experiment(
        n = n, d = d, s_values = s_values, trials = trials,
        noise_level = noise_level, method = "srht", seed = seed
    )
}
