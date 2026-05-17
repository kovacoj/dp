test_that("Gaussian sketch has expected dimensions", {
    S <- gaussian_sketch(8, 16)
    expect_equal(dim(S), c(8, 16))
})

test_that("Rademacher sketch has expected dimensions", {
    S <- rademacher_sketch(8, 16)
    expect_equal(dim(S), c(8, 16))
})

test_that("SRHT sketch has expected dimensions", {
    S <- srht_sketch(8, 16)
    expect_equal(dim(S), c(8, 16))
})

test_that("sketch_lstsq returns a solution vector with expected length", {
    set.seed(1)
    A <- matrix(rnorm(100 * 10), nrow = 100, ncol = 10)
    x_true <- rep(1, 10)
    b <- as.vector(A %*% x_true)

    fit <- sketch_lstsq(A, b, s = 24, method = "gaussian")

    expect_length(fit$x, 10)
    expect_true(is.numeric(fit$residual_norm))
    expect_true(is.numeric(fit$condition_number))
})

test_that("gaussian_lstsq_experiment returns the expected metric columns", {
    result <- gaussian_lstsq_experiment(n = 20, d = 5, s_values = 5:8, trials = 3, seed = 1)

    expect_equal(
        colnames(result$history),
        c("s", "mean_abs_error", "mean_residual_ratio", "mean_solution_error", "mean_condition_number")
    )
    expect_equal(nrow(result$history), 4)
})
