#' Solve a sketched least-squares problem with simulated mixed precision
#'
#' Builds a randomized sketch, rounds selected intermediate quantities to
#' simulated lower precision, and solves the resulting sketched least-squares
#' problem.
#'
#' @param A Numeric design matrix.
#' @param b Numeric response vector with length equal to `nrow(A)`.
#' @param s Integer sketch size. If `NULL`, defaults to `min(nrow(A), 2 *
#'   (ncol(A) + 1))`.
#' @param method Sketch family. One of `"gaussian"`, `"rademacher"`, or
#'   `"srht"`.
#' @param sketch_prec Precision used for the sketch and sketched products.
#'   Passed to [fl_round()].
#' @param solve_prec Precision used before solving the sketched system. Passed
#'   to [fl_round()].
#'
#' @return A list with the coefficient vector `x`, residual diagnostics,
#'   sketched-system condition number, sketch settings, and precision settings.
#'
#' @examples
#' set.seed(1)
#' A <- matrix(rnorm(80), nrow = 20)
#' b <- rnorm(20)
#' fit <- sketch_lstsq_mixed(A, b, s = 10, sketch_prec = "single")
#' fit$residual_norm
#'
#' @export
sketch_lstsq_mixed <- function(
    A,
    b,
    s = NULL,
    method = c("gaussian", "rademacher", "srht"),
    sketch_prec = "double",
    solve_prec = "double"
) {
    method <- match.arg(method)

    if (is.null(dim(A))) {
        stop("A must be a matrix")
    }

    n <- nrow(A)
    d <- ncol(A)

    if (length(b) != n) {
        stop("length(b) must equal nrow(A)")
    }

    if (is.null(s)) {
        s <- min(n, 2L * (d + 1L))
    }

    S <- switch(
        method,
        gaussian = gaussian_sketch(s, n),
        rademacher = rademacher_sketch(s, n),
        srht = srht_sketch(s, n)
    )

    S <- fl_round(S, sketch_prec)
    SA <- fl_round(S %*% A, sketch_prec)
    Sb <- fl_round(S %*% b, sketch_prec)

    if (solve_prec != "double") {
        SA <- fl_round(SA, solve_prec)
        Sb <- fl_round(Sb, solve_prec)
    }

    fit <- qr.solve(SA, Sb)
    residual <- as.vector(A %*% fit - b)
    condition_number <- kappa(SA)

    list(
        x = fit,
        residual = residual,
        residual_norm = sqrt(sum(residual^2)),
        condition_number = condition_number,
        sketch_size = s,
        method = method,
        sketch_prec = sketch_prec,
        solve_prec = solve_prec
    )
}

#' Refine a mixed-precision sketched least-squares solution
#'
#' Computes an initial mixed-precision sketched solution and applies residual
#' correction steps using the same sketch.
#'
#' @inheritParams sketch_lstsq_mixed
#' @param ref_prec Precision used when forming residuals during refinement.
#'   Passed to [fl_round()].
#' @param ref_steps Integer number of refinement steps.
#'
#' @return A list with the refined coefficient vector, residual diagnostics,
#'   sketch and precision settings, and `ref_history`, a matrix recording the
#'   refinement step, residual norm, and solution norm.
#'
#' @examples
#' set.seed(1)
#' A <- matrix(rnorm(80), nrow = 20)
#' b <- rnorm(20)
#' fit <- sketch_refine(A, b, s = 10, sketch_prec = "single", ref_steps = 2)
#' fit$ref_history
#'
#' @export
sketch_refine <- function(
    A,
    b,
    s = NULL,
    method = c("gaussian", "rademacher", "srht"),
    sketch_prec = "double",
    solve_prec = "double",
    ref_prec = "double",
    ref_steps = 3L
) {
    method <- match.arg(method)

    if (is.null(dim(A))) {
        stop("A must be a matrix")
    }

    n <- nrow(A)
    d <- ncol(A)

    if (length(b) != n) {
        stop("length(b) must equal nrow(A)")
    }

    if (is.null(s)) {
        s <- min(n, 2L * (d + 1L))
    }

    S <- switch(
        method,
        gaussian = gaussian_sketch(s, n),
        rademacher = rademacher_sketch(s, n),
        srht = srht_sketch(s, n)
    )
    S <- fl_round(S, sketch_prec)

    SA <- fl_round(S %*% A, sketch_prec)
    Sb <- fl_round(S %*% b, sketch_prec)

    if (solve_prec != "double") {
        SA_s <- fl_round(SA, solve_prec)
        Sb_s <- fl_round(Sb, solve_prec)
    } else {
        SA_s <- SA
        Sb_s <- Sb
    }

    xhat <- qr.solve(SA_s, Sb_s)

    ref_history <- matrix(0, nrow = ref_steps + 1L, ncol = 3L)
    r0 <- as.vector(A %*% xhat - b)
    ref_history[1L, ] <- c(0, sqrt(sum(r0^2)), sqrt(sum(xhat^2)))

    for (k in seq_len(ref_steps)) {
        r <- fl_round(as.vector(A %*% xhat - b), ref_prec)
        Sr <- fl_round(S %*% r, sketch_prec)

        dx <- qr.solve(SA_s, Sr)
        xhat <- xhat - dx

        r_new <- as.vector(A %*% xhat - b)
        ref_history[k + 1L, ] <- c(k, sqrt(sum(r_new^2)), sqrt(sum(xhat^2)))
    }

    residual <- as.vector(A %*% xhat - b)

    list(
        x = xhat,
        residual = residual,
        residual_norm = sqrt(sum(residual^2)),
        condition_number = kappa(SA),
        sketch_size = s,
        method = method,
        sketch_prec = sketch_prec,
        solve_prec = solve_prec,
        ref_prec = ref_prec,
        ref_steps = ref_steps,
        ref_history = ref_history
    )
}
