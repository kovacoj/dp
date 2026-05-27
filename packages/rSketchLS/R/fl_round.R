#' Round numeric values to a simulated floating-point precision
#'
#' Applies a simple significand-bit rounding model to approximate lower
#' precision arithmetic for experiment design.
#'
#' @param x Numeric vector, matrix, or array to round.
#' @param prec Target precision. One of `"double"`, `"single"`, `"half"`, or
#'   `"bfloat16"`.
#'
#' @return `x` rounded to the requested simulated precision, with the same
#'   shape as the input.
#'
#' @examples
#' fl_round(c(1, pi, 1000), "half")
#'
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
