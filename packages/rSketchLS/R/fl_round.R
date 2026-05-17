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
