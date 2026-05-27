#' Run a single covariance-transport experiment
#'
#' Executes one experiment on a synthetic covariance operator: applies
#' randomized low-rank approximation with the given parameters, builds the
#' regularized transport map, and collects all numerical and timing
#' diagnostics.
#'
#' @param cov_op A covariance operator list from
#'   \code{\link{generate_cov_operator}} or \code{\link{generate_climate_cov}}.
#' @param rank Target approximation rank.
#' @param oversampling Oversampling parameter.
#' @param sketch Sketch distribution name.
#' @param lambda Regularization parameter.
#' @param pm A \code{randMBC_precision} object (optional; uses double if
#'   missing).
#' @param seed Integer seed for this trial.
#'
#' @return A named list of scalar diagnostics and the fitted objects.
#' @noRd
run_cov_transport_trial <- function(
    cov_op,
    rank,
    oversampling = 5L,
    sketch = "gaussian",
    lambda = 1e-6,
    pm = NULL,
    seed = NULL
) {
    if (!is.null(seed)) {
        set.seed(seed)
    }

    C <- cov_op$covariance
    p <- ncol(C)

    if (is.null(pm)) {
        pm <- precision_model("double", "double")
    }

    start <- proc.time()[[3L]]

    source_approx <- rand_cov_approx_pm(
        Z = .matrix_from_cov(C),
        rank = rank,
        oversampling = oversampling,
        sketch = sketch,
        pm = pm,
        lambda = lambda
    )

    target_approx <- rand_cov_approx_pm(
        Z = .matrix_from_cov(C),
        rank = rank,
        oversampling = oversampling,
        sketch = sketch,
        pm = pm,
        lambda = lambda
    )

    transport_fit <- cov_transport(
        source_approx$covariance,
        target_approx$covariance,
        lambda = 0
    )

    elapsed <- proc.time()[[3L]] - start

    T_exact <- cov_transport(C, C, lambda = lambda)$transport
    T_approx <- transport_fit$transport

    list(
        cov_error_source = norm(C - source_approx$covariance_raw, type = "F") / norm(C, type = "F"),
        cov_error_target = norm(C - target_approx$covariance_raw, type = "F") / norm(C, type = "F"),
        transport_error = norm(T_exact - T_approx, type = "F") / max(norm(T_exact, type = "F"), .Machine$double.eps),
        lambda_min_reg = source_approx$lambda_min_reg,
        condition_est = source_approx$condition_est,
        rank = source_approx$rank,
        lambda = lambda,
        sketch = sketch,
        precision = list(mult = pm$sketch_prec, orth = pm$orth_prec),
        seed = seed,
        runtime = elapsed,
        source_fit = source_approx,
        target_fit = target_approx,
        transport_fit = transport_fit
    )
}

#' Run a parameter-sweep experiment
#'
#' Iterates over a grid of rank, lambda, sketch, and precision settings,
#' running multiple trials per grid point and collecting results in a
#' data frame.
#'
#' @param cov_op Covariance operator list.
#' @param ranks Integer vector of target ranks.
#' @param lambdas Numeric vector of regularization parameters.
#' @param sketches Character vector of sketch distribution names.
#' @param precisions Character vector of sketch-precision names.
#' @param n_trials Number of independent trials per grid point.
#' @param oversampling Oversampling parameter (fixed across sweep).
#' @param base_seed Starting seed; each trial increments by 1.
#'
#' @return A data frame with one row per trial, containing all scalar
#'   diagnostics and parameter settings.
#' @examples
#' op <- generate_cov_operator(20, rank = 10, spectrum = "exponential", cond = 100)
#' df <- run_cov_transport_sweep(op, ranks = c(5, 10), lambdas = c(1e-6, 1e-2),
#'   n_trials = 3, base_seed = 42)
#' nrow(df)
#' @export
run_cov_transport_sweep <- function(
    cov_op,
    ranks = c(5L, 10L, 15L, 20L),
    lambdas = c(1e-6, 1e-4, 1e-2),
    sketches = c("gaussian", "rademacher"),
    precisions = c("double", "single"),
    n_trials = 5L,
    oversampling = 5L,
    base_seed = 1L
) {
    rows <- list()
    counter <- 0L

    for (r in ranks) {
        for (lam in lambdas) {
            for (sk in sketches) {
                for (pr in precisions) {
                    pm <- precision_model(pr, "double")
                    for (t in seq_len(n_trials)) {
                        counter <- counter + 1L
                        seed <- base_seed + counter
                        result <- tryCatch(
                            run_cov_transport_trial(
                                cov_op = cov_op,
                                rank = r,
                                oversampling = oversampling,
                                sketch = sk,
                                lambda = lam,
                                pm = pm,
                                seed = seed
                            ),
                            error = function(e) {
                                list(
                                    cov_error_source = NA_real_,
                                    cov_error_target = NA_real_,
                                    transport_error = NA_real_,
                                    lambda_min_reg = NA_real_,
                                    condition_est = NA_real_,
                                    rank = r,
                                    lambda = lam,
                                    sketch = sk,
                                    precision = list(mult = pr, orth = "double"),
                                    seed = seed,
                                    runtime = NA_real_
                                )
                            }
                        )
                        rows[[counter]] <- data.frame(
                            trial = t,
                            rank = result$rank,
                            lambda = result$lambda,
                            sketch = result$sketch,
                            mult_prec = result$precision$mult,
                            orth_prec = result$precision$orth,
                            cov_error = result$cov_error_source,
                            transport_error = result$transport_error,
                            lambda_min_reg = result$lambda_min_reg,
                            condition_est = result$condition_est,
                            runtime = result$runtime,
                            seed = result$seed,
                            stringsAsFactors = FALSE
                        )
                    }
                }
            }
        }
    }

    do.call(rbind, rows)
}

.matrix_from_cov <- function(C) {
    eig <- eigen(C, symmetric = TRUE)
    eigvals <- pmax(eig$values, 0)
    Z_root <- eig$vectors %*% diag(sqrt(eigvals), nrow = length(eigvals))
    n <- nrow(C)
    Z <- matrix(stats::rnorm(n * ncol(Z_root)), nrow = n, ncol = ncol(Z_root))
    Z %*% t(Z_root)
}
