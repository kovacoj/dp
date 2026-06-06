#' Refine a mixed-precision sketched least-squares solution
#'
#' Computes an initial mixed-precision sketched solution and applies residual
#' correction steps using the same sketch. Supports both vector and matrix
#' right-hand sides.
#'
#' @param A Numeric design matrix.
#' @param b_or_Y Numeric response vector or matrix.
#' @param s Integer sketch size.
#' @param method Sketch family.
#' @param sketch_prec Precision for sketch and sketched products.
#' @param solve_prec Precision applied before solving.
#' @param ref_prec Precision used when forming residuals during refinement.
#' @param ref_steps Integer number of refinement steps.
#' @param seed Optional integer seed.
#'
#' @return A list with the refined coefficient vector/matrix, residual
#'   diagnostics, settings, and `ref_history`, a matrix recording the
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
    b_or_Y,
    s = NULL,
    method = c("gaussian", "rademacher", "srht"),
    sketch_prec = "double",
    solve_prec = "double",
    ref_prec = "double",
    ref_steps = 3L,
    seed = NULL
) {
    method <- match.arg(method)

    if (!is.matrix(A)) stop("A must be a matrix")
    n <- nrow(A)
    d <- ncol(A)
    multi <- is.matrix(b_or_Y)

    if (multi) {
        if (nrow(b_or_Y) != n) stop("nrow(b_or_Y) must equal nrow(A)")
    } else {
        if (length(b_or_Y) != n) stop("length(b_or_Y) must equal nrow(A)")
    }

    if (is.null(s)) s <- min(n, 2L * (d + 1L))
    s <- as.integer(s)

    if (!is.null(seed)) set.seed(seed)

    S <- switch(
        method,
        gaussian = gaussian_sketch(s, n),
        rademacher = rademacher_sketch(s, n),
        srht = srht_sketch(s, n)
    )
    S <- fl_round(S, sketch_prec)

    SA <- fl_round(S %*% A, sketch_prec)
    SY <- fl_round(if (multi) S %*% b_or_Y else S %*% b_or_Y, sketch_prec)

    if (solve_prec != "double") {
        SA_s <- fl_round(SA, solve_prec)
        SY_s <- fl_round(SY, solve_prec)
    } else {
        SA_s <- SA
        SY_s <- SY
    }

    xhat <- qr.solve(SA_s, SY_s)

    ref_history <- matrix(0, nrow = ref_steps + 1L, ncol = 3L)
    r0 <- if (multi) A %*% xhat - b_or_Y else as.vector(A %*% xhat - b_or_Y)
    ref_history[1L, ] <- c(0, sqrt(sum(r0^2)), sqrt(sum(xhat^2)))

    for (k in seq_len(ref_steps)) {
        r <- fl_round(if (multi) as.matrix(A %*% xhat - b_or_Y) else as.vector(A %*% xhat - b_or_Y), ref_prec)
        Sr <- fl_round(S %*% r, sketch_prec)

        dx <- qr.solve(SA_s, Sr)
        xhat <- xhat - dx

        r_new <- if (multi) A %*% xhat - b_or_Y else as.vector(A %*% xhat - b_or_Y)
        ref_history[k + 1L, ] <- c(k, sqrt(sum(r_new^2)), sqrt(sum(xhat^2)))
    }

    residual <- if (multi) A %*% xhat - b_or_Y else as.vector(A %*% xhat - b_or_Y)

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
        ref_history = ref_history,
        multi = multi
    )
}
