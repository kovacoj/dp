test_that("sketch_lstsq_multi returns correct dimensions for matrix RHS", {
    set.seed(1)
    A <- matrix(rnorm(80), nrow = 20, ncol = 4)
    Y <- matrix(rnorm(60), nrow = 20, ncol = 3)
    fit <- sketch_lstsq_multi(A, Y, s = 10, method = "gaussian")
    expect_equal(dim(fit$X), c(4, 3))
    expect_equal(dim(fit$residual), c(20, 3))
    expect_true(is.numeric(fit$residual_norm))
    expect_true(is.numeric(fit$condition_number))
    expect_equal(fit$sketch_size, 10)
    expect_equal(fit$method, "gaussian")
})

test_that("sketch_lstsq_multi returns sketch matrix when requested", {
    set.seed(2)
    A <- matrix(rnorm(40), nrow = 10, ncol = 4)
    Y <- matrix(rnorm(20), nrow = 10, ncol = 2)
    fit <- sketch_lstsq_multi(A, Y, s = 6, method = "gaussian", return_sketch = TRUE)
    expect_equal(dim(fit$S), c(6, 10))
})

test_that("sketch_lstsq_multi seed is reproducible", {
    A <- matrix(rnorm(80), nrow = 20, ncol = 4)
    Y <- matrix(rnorm(60), nrow = 20, ncol = 3)
    fit1 <- sketch_lstsq_multi(A, Y, s = 10, method = "gaussian", seed = 42)
    fit2 <- sketch_lstsq_multi(A, Y, s = 10, method = "gaussian", seed = 42)
    expect_identical(fit1$X, fit2$X)
    expect_identical(fit1$residual_norm, fit2$residual_norm)
})

test_that("sketch_lstsq_mixed works with vector RHS", {
    set.seed(1)
    A <- matrix(rnorm(100), nrow = 20, ncol = 5)
    b <- rnorm(20)
    fit <- sketch_lstsq_mixed(A, b, s = 10, sketch_prec = "single", solve_prec = "double")
    expect_length(fit$x, 5)
    expect_true(is.numeric(fit$residual_norm))
    expect_equal(fit$sketch_prec, "single")
    expect_equal(fit$solve_prec, "double")
    expect_false(fit$multi)
})

test_that("sketch_lstsq_mixed works with matrix RHS", {
    set.seed(1)
    A <- matrix(rnorm(100), nrow = 20, ncol = 5)
    Y <- matrix(rnorm(40), nrow = 20, ncol = 2)
    fit <- sketch_lstsq_mixed(A, Y, s = 10, sketch_prec = "single")
    expect_equal(dim(fit$x), c(5, 2))
    expect_true(fit$multi)
    expect_true(is.numeric(fit$residual_norm))
})

test_that("sketch_lstsq_mixed seed is reproducible", {
    A <- matrix(rnorm(80), nrow = 20, ncol = 4)
    b <- rnorm(20)
    fit1 <- sketch_lstsq_mixed(A, b, s = 8, seed = 99)
    fit2 <- sketch_lstsq_mixed(A, b, s = 8, seed = 99)
    expect_identical(fit1$x, fit2$x)
})

test_that("sketch_lstsq_mixed lower precision does not catastrophically diverge on small well-conditioned case", {
    set.seed(3)
    A <- matrix(rnorm(40), nrow = 10, ncol = 4)
    b <- rnorm(10)
    fit_d <- sketch_lstsq_mixed(A, b, s = 6, sketch_prec = "double", solve_prec = "double", seed = 1)
    fit_s <- sketch_lstsq_mixed(A, b, s = 6, sketch_prec = "single", solve_prec = "double", seed = 1)
    expect_lt(sqrt(sum((fit_d$x - fit_s$x)^2)), 1.0)
})

test_that("sketch_lstsq_experiment_multi returns history and summary", {
    out <- sketch_lstsq_experiment_multi(
        n = 20, d = 4, p = 3, s_vals = c(8, 12), trials = 2, seed = 1
    )
    expect_equal(nrow(out$history), 4)
    expect_true("s" %in% names(out$history))
    expect_true("s" %in% names(out$summary))
    expect_true(all(c("residual_norm_mean", "solution_error_mean") %in% names(out$summary)))
})

test_that("sketch_refine works with matrix RHS", {
    set.seed(1)
    A <- matrix(rnorm(64), nrow = 16, ncol = 4)
    Y <- matrix(rnorm(32), nrow = 16, ncol = 2)
    fit <- sketch_refine(A, Y, s = 8, sketch_prec = "single", ref_steps = 2)
    expect_equal(dim(fit$x), c(4, 2))
    expect_true(fit$multi)
    expect_equal(nrow(fit$ref_history), 3)
    expect_equal(nrow(fit$ref_history), 3)
    expect_true(is.numeric(fit$ref_history[3, 2]))
})
