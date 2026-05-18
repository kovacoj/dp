test_that("fl_round returns input unchanged for double", {
    x <- c(pi, -2.5, 0)
    expect_identical(fl_round(x, "double"), x)
})

test_that("rank restoration preserves the columnwise multiset", {
    values <- matrix(c(3, 1, 2, 9, 7, 8), nrow = 3, ncol = 2)
    scores <- matrix(c(0.2, -1, 0.1, 2, 0.3, 0), nrow = 3, ncol = 2)

    restored <- rank_restore_matrix(values, scores)

    expect_equal(sort(restored[, 1]), sort(values[, 1]))
    expect_equal(sort(restored[, 2]), sort(values[, 2]))
})

test_that("covariance action matches explicit covariance product", {
    set.seed(11)
    z <- matrix(rnorm(40), nrow = 10, ncol = 4)
    rhs <- matrix(rnorm(8), nrow = 4, ncol = 2)

    expect_equal(
        covariance_action(z, rhs),
        (crossprod(z) / nrow(z)) %*% rhs
    )
})

test_that("rand_cov_approx returns regularized covariance metadata", {
    set.seed(1)
    z <- matrix(rnorm(80), nrow = 20, ncol = 4)
    fit <- rand_cov_approx(z, rank = 2, oversampling = 1, mult_prec = "single", lambda = 1e-4)

    expect_equal(dim(fit$Q), c(4L, 2L))
    expect_equal(dim(fit$B), c(2L, 2L))
    expect_equal(dim(fit$covariance_raw), c(4L, 4L))
    expect_equal(dim(fit$covariance), c(4L, 4L))
    expect_true(all(eigen((fit$covariance + t(fit$covariance)) / 2, symmetric = TRUE)$values > 0))
    expect_true(fit$residual_norm_est >= 0)
    expect_true(is.numeric(fit$lambda_min_reg))
    expect_true(fit$lambda_min_reg > 0)
})

test_that("cov_transport is identity for identical inputs", {
    a <- diag(c(2, 3, 4))
    fit <- cov_transport(a, a, lambda = 1e-6)
    expect_equal(fit$transport, diag(3), tolerance = 1e-6)
})

test_that("fit_rand_mbc preserves marginal values columnwise", {
    set.seed(2)
    x_hist <- matrix(rnorm(60), nrow = 20, ncol = 3)
    y_hist <- x_hist + matrix(rnorm(60, sd = 0.1), nrow = 20, ncol = 3)
    x_fut <- matrix(rnorm(45), nrow = 15, ncol = 3)

    fit <- fit_rand_mbc(x_hist, y_hist, x_fut, rank = 2, oversampling = 1, precision = "double")
    expect_equal(dim(fit$corrected), dim(x_fut))
    expect_true(is.numeric(fit$runtime))
    expect_true(fit$runtime >= 0)

    for (j in seq_len(ncol(x_fut))) {
        expect_equal(sort(fit$corrected[, j]), sort(fit$marginals$x_fut[, j]))
    }
})

test_that("fit_rand_mbc reduces calibration dependence error on simple synthetic data", {
    set.seed(7)
    n <- 80
    u <- matrix(rnorm(n * 2), nrow = n, ncol = 2)
    x_hist <- cbind(u[, 1], -0.2 * u[, 1] + 0.98 * u[, 2])
    y_hist <- cbind(u[, 1], 0.85 * u[, 1] + 0.4 * u[, 2])
    x_fut <- x_hist[1:60, , drop = FALSE]

    raw_error <- norm(stats::cor(x_hist) - stats::cor(y_hist), type = "F")
    fit <- fit_rand_mbc(x_hist, y_hist, x_fut, rank = 2, oversampling = 0, precision = "double")
    corrected_error <- norm(stats::cor(fit$historical_corrected) - stats::cor(y_hist), type = "F")

    expect_true(corrected_error < raw_error)
    expect_true(is.numeric(fit$diagnostics$pearson_error))
    expect_true(is.numeric(fit$diagnostics$quantile_error))
})

test_that("ratio-aware marginal adjustment preserves nonnegativity and dry days", {
    y_hist <- matrix(c(0, 0.1, 0.4, 1.2, 0, 0.3, 0.8, 1.5), ncol = 1)
    x_hist <- matrix(c(0, 0.05, 0.2, 0.7, 0, 0.1, 0.5, 1.1), ncol = 1)
    x_fut <- matrix(c(0, 0.02, 0.15, 0.6, 0, 0.05), ncol = 1)

    fit <- qdm_adjust_matrix(y_hist, x_hist, x_fut, ratio_seq = TRUE, trace = 0.05)

    expect_true(all(fit$x_hist >= 0))
    expect_true(all(fit$x_fut >= 0))
    expect_equal(sum(fit$x_fut == 0), 2)
})

test_that("fit_rand_mbc accepts per-column ratio control", {
    set.seed(12)
    x_hist <- cbind(rnorm(20), pmax(0, rnorm(20, mean = 0.2, sd = 0.2)))
    y_hist <- cbind(x_hist[, 1] + 0.1, pmax(0, x_hist[, 2] * 1.2))
    x_fut <- cbind(rnorm(15), pmax(0, rnorm(15, mean = 0.15, sd = 0.2)))

    fit <- fit_rand_mbc(
        x_hist,
        y_hist,
        x_fut,
        rank = 2,
        oversampling = 0,
        ratio_seq = c(FALSE, TRUE),
        trace = c(0.05, 0.05)
    )

    expect_equal(fit$ratio_seq, c(FALSE, TRUE))
    expect_true(all(fit$corrected[, 2] >= 0))
})
