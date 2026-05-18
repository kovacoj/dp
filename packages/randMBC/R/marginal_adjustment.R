qdm_adjust_matrix <- function(y_hist, x_hist, x_fut) {
    p <- ncol(x_hist)
    x_hist_out <- matrix(0, nrow = nrow(x_hist), ncol = p)
    x_fut_out <- matrix(0, nrow = nrow(x_fut), ncol = p)

    for (j in seq_len(p)) {
        fit <- qdm_adjust_column(y_hist[, j], x_hist[, j], x_fut[, j])
        x_hist_out[, j] <- fit$x_hist
        x_fut_out[, j] <- fit$x_fut
    }

    colnames(x_hist_out) <- colnames(x_hist)
    colnames(x_fut_out) <- colnames(x_fut)

    list(x_hist = x_hist_out, x_fut = x_fut_out)
}

qdm_adjust_column <- function(y_hist, x_hist, x_fut) {
    tau <- seq(0, 1, length.out = max(length(x_hist), length(x_fut), 32L))
    q_y <- stats::quantile(y_hist, probs = tau, type = 7, names = FALSE)
    q_x_hist <- stats::quantile(x_hist, probs = tau, type = 7, names = FALSE)
    q_x_fut <- stats::quantile(x_fut, probs = tau, type = 7, names = FALSE)

    tau_fut <- stats::approx(q_x_fut, tau, xout = x_fut, rule = 2, ties = "ordered")$y
    x_hist_corr <- stats::approx(q_x_hist, q_y, xout = x_hist, rule = 2, ties = "ordered")$y
    delta_fut <- x_fut - stats::approx(tau, q_x_hist, xout = tau_fut, rule = 2, ties = "ordered")$y
    x_fut_corr <- stats::approx(tau, q_y, xout = tau_fut, rule = 2, ties = "ordered")$y + delta_fut

    list(x_hist = x_hist_corr, x_fut = x_fut_corr)
}
