#' Apply QDM-style marginal adjustment columnwise
#'
#' @param y_hist Historical reference matrix.
#' @param x_hist Historical model matrix.
#' @param x_fut Future model matrix.
#' @param ratio_seq Logical scalar or vector marking ratio-style columns.
#' @param trace Dry-day threshold applied after ratio-style correction.
#' @param trace_calc Internal threshold used to lift zero-like values before
#'   quantile calculations.
#' @param ratio_max Maximum multiplicative change allowed in low-reference
#'   ratio-style tails.
#' @param ratio_max_trace Threshold below which `ratio_max` is enforced.
#'
#' @return A list with corrected historical and future matrices plus expanded
#'   control arguments.
#' @noRd
qdm_adjust_matrix <- function(
    y_hist,
    x_hist,
    x_fut,
    ratio_seq = rep(FALSE, ncol(x_hist)),
    trace = 0.05,
    trace_calc = 0.5 * trace,
    ratio_max = 2,
    ratio_max_trace = 10 * trace
) {
    p <- ncol(x_hist)
    x_hist_out <- matrix(0, nrow = nrow(x_hist), ncol = p)
    x_fut_out <- matrix(0, nrow = nrow(x_fut), ncol = p)
    ratio_seq <- expand_qdm_arg(ratio_seq, p, "ratio_seq")
    trace <- expand_qdm_arg(trace, p, "trace")
    trace_calc <- expand_qdm_arg(trace_calc, p, "trace_calc")
    ratio_max <- expand_qdm_arg(ratio_max, p, "ratio_max")
    ratio_max_trace <- expand_qdm_arg(ratio_max_trace, p, "ratio_max_trace")

    for (j in seq_len(p)) {
        fit <- qdm_adjust_column(
            y_hist[, j],
            x_hist[, j],
            x_fut[, j],
            ratio = ratio_seq[j],
            trace = trace[j],
            trace_calc = trace_calc[j],
            ratio_max = ratio_max[j],
            ratio_max_trace = ratio_max_trace[j]
        )
        x_hist_out[, j] <- fit$x_hist
        x_fut_out[, j] <- fit$x_fut
    }

    colnames(x_hist_out) <- colnames(x_hist)
    colnames(x_fut_out) <- colnames(x_fut)

    list(
        x_hist = x_hist_out,
        x_fut = x_fut_out,
        controls = list(
            ratio_seq = ratio_seq,
            trace = trace,
            trace_calc = trace_calc,
            ratio_max = ratio_max,
            ratio_max_trace = ratio_max_trace
        )
    )
}

#' Apply QDM-style marginal adjustment to one variable
#'
#' @param y_hist Historical reference vector.
#' @param x_hist Historical model vector.
#' @param x_fut Future model vector.
#' @param ratio Whether to use ratio-style handling.
#' @param trace Dry-day threshold applied after ratio-style correction.
#' @param trace_calc Internal threshold used to lift zero-like values before
#'   quantile calculations.
#' @param ratio_max Maximum multiplicative change allowed in low-reference
#'   ratio-style tails.
#' @param ratio_max_trace Threshold below which `ratio_max` is enforced.
#'
#' @return A list with corrected `x_hist` and `x_fut` vectors.
#' @noRd
qdm_adjust_column <- function(
    y_hist,
    x_hist,
    x_fut,
    ratio = FALSE,
    trace = 0.05,
    trace_calc = 0.5 * trace,
    ratio_max = 2,
    ratio_max_trace = 10 * trace
) {
    y_hist_work <- y_hist
    x_hist_work <- x_hist
    x_fut_work <- x_fut

    if (ratio) {
        y_hist_work <- lift_trace_values(y_hist_work, trace_calc)
        x_hist_work <- lift_trace_values(x_hist_work, trace_calc)
        x_fut_work <- lift_trace_values(x_fut_work, trace_calc)
    }

    tau <- seq(0, 1, length.out = max(length(x_hist), length(x_fut), 32L))
    q_y <- stats::quantile(y_hist_work, probs = tau, type = 7, names = FALSE)
    q_x_hist <- stats::quantile(x_hist_work, probs = tau, type = 7, names = FALSE)
    q_x_fut <- stats::quantile(x_fut_work, probs = tau, type = 7, names = FALSE)

    x_hist_corr <- stats::approx(q_x_hist, q_y, xout = x_hist_work, rule = 2, ties = "ordered")$y

    tau_fut <- stats::approx(q_x_fut, tau, xout = x_fut_work, rule = 2, ties = "ordered")$y
    hist_at_tau <- stats::approx(tau, q_x_hist, xout = tau_fut, rule = 2, ties = "ordered")$y

    if (ratio) {
        delta_fut <- x_fut_work / pmax(hist_at_tau, .Machine$double.eps)
        limited <- hist_at_tau < ratio_max_trace
        delta_fut[limited] <- pmin(delta_fut[limited], ratio_max)
        x_fut_corr <- stats::approx(tau, q_y, xout = tau_fut, rule = 2, ties = "ordered")$y * delta_fut
        x_hist_corr[x_hist_corr < trace] <- 0
        x_fut_corr[x_fut_corr < trace] <- 0
    } else {
        delta_fut <- x_fut_work - hist_at_tau
        x_fut_corr <- stats::approx(tau, q_y, xout = tau_fut, rule = 2, ties = "ordered")$y + delta_fut
    }

    list(x_hist = x_hist_corr, x_fut = x_fut_corr)
}

#' Expand a scalar QDM control to one value per column
#'
#' @param x Scalar or vector control input.
#' @param p Required output length.
#' @param name Name used in validation errors.
#'
#' @return A vector of length `p`.
#' @noRd
expand_qdm_arg <- function(x, p, name) {
    if (length(x) == 1L) {
        return(rep(x, p))
    }
    if (length(x) != p) {
        stop(sprintf("%s must have length 1 or ncol(x_hist)", name))
    }
    x
}

#' Lift trace-like values away from zero before quantile interpolation
#'
#' @param x Numeric vector to modify.
#' @param trace_calc Internal lifting threshold.
#'
#' @return A numeric vector with very small entries replaced by positive values.
#' @noRd
lift_trace_values <- function(x, trace_calc) {
    idx <- which(x < trace_calc)
    if (length(idx) == 0L) {
        return(x)
    }

    lifted <- x
    span <- seq_len(length(idx)) / (length(idx) + 1)
    lifted[idx] <- pmax(.Machine$double.eps, trace_calc * span)
    lifted
}
