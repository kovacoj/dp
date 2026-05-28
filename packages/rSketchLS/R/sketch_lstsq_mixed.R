#' Solve a sketched least-squares problem with simulated mixed precision
#'
#' Builds a randomized sketch, rounds selected intermediate quantities to
#' simulated lower precision, and solves the resulting sketched least-squares
#' problem. Supports both vector (`b`) and matrix (`Y`) right-hand sides.
#'
#' @param A Numeric design matrix.
#' @param b_or_Y Numeric response vector or matrix.
#' @param s Integer sketch size.
#' @param method Sketch family.
#' @param sketch_prec Precision for sketch and sketched products.
#' @param solve_prec Precision applied before solving the sketched system.
#' @param seed Optional integer seed for reproducibility.
#'
#' @return A list with the coefficient vector/matrix `x`, residual diagnostics,
#'   sketched-system condition number, sketch settings, and precision settings.
#'
#' @examples
#' set.seed(1)
#' A <- matrix(rnorm(80), nrow = 20)
#' b <- rnorm(20)
#' fit <- sketch_lstsq_mixed(A, b, s = 10, sketch_prec = "single")
#' fit$residual_norm
#'
#' Y <- matrix(rnorm(60), nrow = 20)
#' fit2 <- sketch_lstsq_mixed(A, Y, s = 10, sketch_prec = "single")
#' fit2$residual_norm
#'
#' @export
sketch_lstsq_mixed <- function(
    A,
    b_or_Y,
    s = NULL,
    method = c("gaussian", "rademacher", "srht"),
    sketch_prec = c("double", "single", "half", "bfloat16"),
    solve_prec = c("double", "single", "half", "bfloat16"),
    seed = NULL
) {
    method <- match.arg(method)
    sketch_prec <- match.arg(sketch_prec)
    solve_prec <- match.arg(solve_prec)

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
        SA <- fl_round(SA, solve_prec)
        SY <- fl_round(SY, solve_prec)
    }

    xhat <- qr.solve(SA, SY)
    residual <- if (multi) A %*% xhat - b_or_Y else as.vector(A %*% xhat - b_or_Y)
    condition_number <- kappa(SA)

    list(
        x = xhat,
        residual = residual,
        residual_norm = sqrt(sum(residual^2)),
        condition_number = condition_number,
        sketch_size = s,
        method = method,
        sketch_prec = sketch_prec,
        solve_prec = solve_prec,
        multi = multi
    )
}
