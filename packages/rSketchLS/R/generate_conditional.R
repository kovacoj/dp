generate_conditional <- function(
    n,
    d,
    kappa,
    mode = c("logspace", "twocluster", "linspace", "random")
) {
    mode <- match.arg(mode)
    r <- min(n, d)

    sv <- switch(
        mode,
        logspace = if (r == 1L) kappa else exp(seq(0, log(kappa), length.out = r)),
        twocluster = c(rep(1, r - 1L), kappa),
        linspace = if (r == 1L) kappa else seq(1, kappa, length.out = r),
        random = {
            s <- sort(10^(log10(kappa) * runif(r)), decreasing = FALSE)
            s[1L] <- 1
            s[r] <- kappa
            s
        }
    )

    U <- qr.Q(qr(matrix(stats::rnorm(n * r), nrow = n, ncol = r)))
    V <- qr.Q(qr(matrix(stats::rnorm(d * r), nrow = d, ncol = r)))

    U %*% diag(sv, nrow = r) %*% t(V)
}
