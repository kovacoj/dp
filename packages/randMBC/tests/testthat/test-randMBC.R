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

test_that("fit_rand_mbc with basis_mode and seed is deterministic", {
    set.seed(3)
    x_hist <- matrix(rnorm(60), nrow = 20, ncol = 3)
    y_hist <- x_hist + matrix(rnorm(60, sd = 0.1), nrow = 20, ncol = 3)
    x_fut <- matrix(rnorm(30), nrow = 10, ncol = 3)

    fit1 <- fit_rand_mbc(x_hist, y_hist, x_fut, rank = 2, oversampling = 1,
                          basis_mode = "shared", seed = 42)
    fit2 <- fit_rand_mbc(x_hist, y_hist, x_fut, rank = 2, oversampling = 1,
                          basis_mode = "shared", seed = 42)
    expect_identical(fit1$corrected, fit2$corrected)
    expect_equal(fit1$basis_mode, "shared")
})

test_that("fit_rand_mbc independent basis differs from shared", {
    set.seed(4)
    x_hist <- matrix(rnorm(60), nrow = 20, ncol = 3)
    y_hist <- x_hist + matrix(rnorm(60, sd = 0.1), nrow = 20, ncol = 3)
    x_fut <- matrix(rnorm(30), nrow = 10, ncol = 3)

    fit_s <- fit_rand_mbc(x_hist, y_hist, x_fut, rank = 2, oversampling = 1,
                           basis_mode = "shared", seed = 1)
    fit_i <- fit_rand_mbc(x_hist, y_hist, x_fut, rank = 2, oversampling = 1,
                           basis_mode = "independent", seed = 1)
    expect_false(identical(fit_s$corrected, fit_i$corrected))
})

test_that("sketch_forward_bound two-stage is larger than one-stage", {
    pm <- precision_model("single", "double")
    b1 <- sketch_forward_bound(pm, norm_Z = 10, norm_Omega = sqrt(2),
                                n = 100, p = 20, two_stage = FALSE)
    b2 <- sketch_forward_bound(pm, norm_Z = 10, norm_Omega = sqrt(2),
                                n = 100, p = 20, two_stage = TRUE)
    expect_gt(b2, b1)
})

test_that("generate_cov_operator custom spectrum works", {
    op <- generate_cov_operator(20, rank = 3, spectrum = "custom",
                                 custom_eigvals = c(10, 5, 1), seed = 1)
    expect_equal(op$rank, 3)
    expect_equal(op$eigvals[1:3], c(10, 5, 1))
})

test_that("generate_climate_cov returns correct metadata", {
    op <- generate_climate_cov(n_var = 3, n_loc = 10, rank_signal = 5,
                                spatial_rho = 0.9, seed = 1)
    expect_equal(op$n_var, 3)
    expect_equal(op$n_loc, 10)
    expect_equal(dim(op$covariance), c(30, 30))
})

test_that("latent_rank_normalize and restore_marginals_by_rank are inverses", {
    set.seed(5)
    x <- matrix(rnorm(60), nrow = 20, ncol = 3)
    z <- latent_rank_normalize(x)
    y <- restore_marginals_by_rank(x, z)
    for (j in 1:3) {
        expect_equal(sort(x[, j]), sort(y[, j]))
    }
    expect_true(abs(mean(z[, 1])) < 0.3)
})

test_that("fit_rand_mbc return_diagnostics=FALSE omits diagnostics", {
    set.seed(6)
    x_hist <- matrix(rnorm(40), nrow = 20, ncol = 2)
    y_hist <- x_hist + matrix(rnorm(40, sd = 0.1), nrow = 20, ncol = 2)
    x_fut <- matrix(rnorm(20), nrow = 10, ncol = 2)
    fit <- fit_rand_mbc(x_hist, y_hist, x_fut, rank = 2, oversampling = 0,
                         return_diagnostics = FALSE, seed = 1)
    expect_null(fit$diagnostics)
    expect_true(is.numeric(fit$runtime))
})
