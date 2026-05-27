test_that("fl_round returns input unchanged for double", {
    x <- c(pi, 1e-10, -0.00123456789012345)
    expect_identical(fl_round(x, "double"), x)
})

test_that("fl_round single precision reduces precision", {
    x <- pi
    r <- fl_round(x, "single")
    expect_true(abs(r - x) < 1e-6)
    expect_true(abs(r - x) > 0)
})

test_that("fl_round half precision is coarser than single", {
    x <- pi
    r_h <- fl_round(x, "half")
    r_s <- fl_round(x, "single")
    expect_true(abs(r_h - x) >= abs(r_s - x))
})

test_that("fl_round handles zeros correctly", {
    x <- c(0, 0, 0)
    expect_equal(fl_round(x, "half"), x)
})

test_that("generate_conditional produces correct dimensions", {
    A <- generate_conditional(64, 8, 1e4, "logspace")
    expect_equal(dim(A), c(64L, 8L))
})

test_that("generate_conditional achieves target condition number", {
    A <- generate_conditional(64, 8, 1e4, "logspace")
    k <- kappa(A, exact = TRUE)
    expect_true(abs(k - 1e4) / 1e4 < 0.1)
})

test_that("generate_conditional twocluster is near target kappa", {
    A <- generate_conditional(64, 8, 1e6, "twocluster")
    k <- kappa(A, exact = TRUE)
    expect_true(k / 1e6 > 0.5)
    expect_true(k / 1e6 < 2)
})

test_that("generate_conditional random mode is near target", {
    set.seed(42)
    A <- generate_conditional(64, 8, 1e3, "random")
    expect_true(kappa(A) >= 1)
    expect_true(kappa(A) <= 1e3 * 2)
})

test_that("sketch_lstsq_mixed returns solution and metadata", {
    set.seed(1)
    A <- matrix(rnorm(100 * 10), nrow = 100, ncol = 10)
    b <- as.vector(A %*% rep(1, 10))
    fit <- sketch_lstsq_mixed(A, b, s = 24, method = "gaussian",
                              sketch_prec = "single", solve_prec = "double")
    expect_length(fit$x, 10)
    expect_true(is.numeric(fit$residual_norm))
    expect_equal(fit$sketch_prec, "single")
    expect_equal(fit$solve_prec, "double")
})

test_that("sketch_lstsq_mixed double/double matches sketch_lstsq", {
    set.seed(1)
    A <- matrix(rnorm(100 * 10), nrow = 100, ncol = 10)
    b <- as.vector(A %*% rep(1, 10))
    fit1 <- sketch_lstsq(A, b, s = 24, method = "gaussian")
    set.seed(1)
    fit2 <- sketch_lstsq_mixed(A, b, s = 24, method = "gaussian",
                               sketch_prec = "double", solve_prec = "double")
    expect_equal(fit1$x, fit2$x)
})

test_that("sketch_refine returns refinement history", {
    set.seed(1)
    A <- matrix(rnorm(64 * 8), nrow = 64, ncol = 8)
    b <- as.vector(A %*% rep(1, 8))
    fit <- sketch_refine(A, b, s = 20, method = "gaussian",
                         sketch_prec = "half", ref_prec = "double",
                         ref_steps = 3)
    expect_equal(nrow(fit$ref_history), 4)
    expect_true(fit$ref_history[4, 2] < fit$ref_history[1, 2])
})

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

test_that("sketch_precond_lstsq matches full QR residual on small problems", {
    set.seed(1)
    A <- matrix(rnorm(160), nrow = 40, ncol = 4)
    b <- rnorm(40)
    ref <- qr.solve(A, b)
    ref_residual <- sqrt(sum((A %*% ref - b)^2))

    fit <- sketch_precond_lstsq(A, b, s = 16, method = "gaussian")

    expect_length(fit$x, 4)
    expect_true(is.numeric(fit$preconditioned_condition_number))
    expect_equal(fit$residual_norm, ref_residual, tolerance = 1e-8)
})

test_that("sketch_precond_lstsq works with all sketch methods", {
    for (m in c("gaussian", "rademacher", "srht")) {
        set.seed(1)
        n_val <- if (m == "srht") 32L else 40L
        A <- matrix(rnorm(n_val * 4), nrow = n_val, ncol = 4)
        b <- rnorm(n_val)
        fit <- sketch_precond_lstsq(A, b, s = 16, method = m)

        expect_length(fit$x, 4)
        expect_equal(fit$method, m)
        expect_equal(fit$qr_rank, 4)
        expect_true(is.finite(fit$preconditioned_condition_number))
    }
})

test_that("sketch_precond_lstsq improves conditioning for a well-conditioned matrix", {
    set.seed(1)
    A <- qr.Q(qr(matrix(rnorm(80), nrow = 20, ncol = 4)))
    b <- rnorm(20)
    fit <- sketch_precond_lstsq(A, b, s = 12, method = "gaussian")

    expect_lt(fit$preconditioned_condition_number, 5)
})

test_that("gaussian_lstsq_experiment returns the expected metric columns", {
    result <- gaussian_lstsq_experiment(n = 20, d = 5, s_values = 5:8, trials = 3, seed = 1)

    expect_equal(
        colnames(result$history),
        c("s", "mean_abs_error", "mean_residual_ratio", "mean_solution_error", "mean_condition_number")
    )
    expect_equal(nrow(result$history), 4)
    expect_equal(result$method, "gaussian")
})

test_that("srht_lstsq_experiment returns the expected metric columns", {
    result <- srht_lstsq_experiment(n = 16, d = 4, s_values = 8:12, trials = 3, seed = 1)

    expect_equal(
        colnames(result$history),
        c("s", "mean_abs_error", "mean_residual_ratio", "mean_solution_error", "mean_condition_number")
    )
    expect_equal(nrow(result$history), 5)
    expect_equal(result$method, "srht")
})

test_that("sketch_lstsq_experiment works with all methods", {
    for (m in c("gaussian", "rademacher", "srht")) {
        n_val <- if (m == "srht") 16L else 20L
        result <- sketch_lstsq_experiment(n = n_val, d = 4, s_values = 8:10, trials = 2, method = m, seed = 1)
        expect_equal(result$method, m)
        expect_equal(nrow(result$history), 3)
    }
})
