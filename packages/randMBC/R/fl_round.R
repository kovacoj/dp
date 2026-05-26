#' Round values to a simulated floating-point format
#'
#' Simulates coarser floating-point arithmetic by rounding numeric values to the
#' significand width of a selected format.
#'
#' @param x Numeric vector, matrix, or array to round.
#' @param prec Target floating-point format. `"double"` leaves the input
#'   unchanged.
#'
#' @return An object with the same shape as `x`, rounded to the requested
#'   simulated precision.
#' @examples
#' fl_round(c(pi, 1e-3), "single")
#' @export
fl_round <- function(x, prec = c("double", "single", "half", "bfloat16")) {
    prec <- match.arg(prec)

    if (prec == "double") {
        return(x)
    }

    sig_bits <- switch(
        prec,
        single = 24L,
        half = 11L,
        bfloat16 = 8L
    )

    y <- x
    idx <- which(x != 0)
    if (length(idx) == 0L) {
        return(y)
    }

    abs_x <- abs(x[idx])
    e <- floor(log2(abs_x))
    scale <- 2^(sig_bits - 1L - e)
    rounded <- round(abs_x * scale) / scale

    y[idx] <- sign(x[idx]) * rounded
    y
}
