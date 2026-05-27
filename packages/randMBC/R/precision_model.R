#' Create a precision model for a randMBC experiment
#'
#' A precision model encapsulates the arithmetic assumptions used in a
#' randomized covariance-transport experiment.  It stores the working formats
#' for each computational stage, the rounding mode, and provides accessor
#' methods that apply stage-appropriate rounding without the caller needing to
#' know format details.
#'
#' @param sketch_prec Simulated precision used in the bulk sketch products.
#' @param orth_prec Simulated precision used before QR orthogonalization.
#' @param core_prec Simulated precision used inside the small core eigenproblems
#'   and matrix-function evaluations.  This is typically \code{"double"}.
#' @param rounding_mode Character string.  Currently only \code{"nearest"} is
#'   supported; this is a seam for future stochastic-rounding adapters.
#'
#' @return An object of class \code{randMBC_precision} containing the stage
#'   formats, the rounding mode, and derived unit-roundoff values.
#' @examples
#' pm <- precision_model("single", "double")
#' unit_roundoff(pm, "sketch")
#' @export
precision_model <- function(
    sketch_prec = c("double", "single", "half", "bfloat16"),
    orth_prec = c("double", "single"),
    core_prec = "double",
    rounding_mode = c("nearest")
) {
    sketch_prec <- match.arg(sketch_prec)
    orth_prec <- match.arg(orth_prec)
    core_prec <- match.arg(core_prec, c("double", "single", "half", "bfloat16"))
    rounding_mode <- match.arg(rounding_mode)

    if (rounding_mode != "nearest") {
        stop("Only 'nearest' rounding mode is currently supported")
    }

    uro <- .unit_roundoff_table()

    structure(
        list(
            sketch_prec = sketch_prec,
            orth_prec = orth_prec,
            core_prec = core_prec,
            rounding_mode = rounding_mode,
            .uro = uro
        ),
        class = "randMBC_precision"
    )
}

#' @export
print.randMBC_precision <- function(x, ...) {
    cat("<randMBC_precision>\n")
    cat(sprintf("  sketch products : %s  (u = %.2e)\n", x$sketch_prec, x$unit_roundoff("sketch")))
    cat(sprintf("  orthogonalization: %s  (u = %.2e)\n", x$orth_prec, x$unit_roundoff("orth")))
    cat(sprintf("  core eigen/sqrt  : %s  (u = %.2e)\n", x$core_prec, x$unit_roundoff("core")))
    cat(sprintf("  rounding mode    : %s\n", x$rounding_mode))
    invisible(x)
}

#' Return the unit roundoff for a computational stage
#'
#' @param pm A \code{randMBC_precision} object.
#' @param stage One of \code{"sketch"}, \code{"orth"}, or \code{"core"}.
#'
#' @return A scalar giving the unit roundoff \(u\) for the requested stage.
#' Return the unit roundoff for a computational stage
#'
#' @param pm A \code{randMBC_precision} object.
#' @param stage One of \code{"sketch"}, \code{"orth"}, or \code{"core"}.
#'
#' @return A scalar giving the unit roundoff \(u\) for the requested stage.
#' @export
unit_roundoff <- function(pm, stage = c("sketch", "orth", "core")) {
    UseMethod("unit_roundoff")
}

#' @export
unit_roundoff.randMBC_precision <- function(pm, stage = c("sketch", "orth", "core")) {
    stage <- match.arg(stage)
    prec <- switch(stage, sketch = pm$sketch_prec, orth = pm$orth_prec, core = pm$core_prec)
    pm$.uro[[prec]]
}

#' Apply stage-appropriate rounding
#'
#' @param pm A \code{randMBC_precision} object.
#' @param x Numeric vector, matrix, or array.
#' @param stage One of \code{"sketch"}, \code{"orth"}, or \code{"core"}.
#'
#' @return \code{x} rounded to the precision associated with \code{stage}.
#' @noRd
round_to_stage <- function(pm, x, stage = c("sketch", "orth", "core")) {
    UseMethod("round_to_stage")
}

#' @exportS3Method randMBC::round_to_stage
#' @noRd
round_to_stage.randMBC_precision <- function(pm, x, stage = c("sketch", "orth", "core")) {
    stage <- match.arg(stage)
    prec <- switch(stage, sketch = pm$sketch_prec, orth = pm$orth_prec, core = pm$core_prec)
    if (pm$rounding_mode == "nearest") {
        fl_round(x, prec)
    } else {
        stop(sprintf("Rounding mode '%s' not yet implemented", pm$rounding_mode))
    }
}

.unit_roundoff_table <- function() {
    list(
        double = 2^-53,
        single = 2^-24,
        half = 2^-11,
        bfloat16 = 2^-8
    )
}

#' Estimate the forward-error bound for a sketch product
#'
#' Under the standard matrix-product rounding model, the computed sketch
#' product satisfies an error bound proportional to the unit roundoff,
#' the squared spectral norm of the data, the norm of the sketching
#' operator, and the reciprocal of the sample size.
#'
#' @param pm A \code{randMBC_precision} object.
#' @param norm_Z Spectral norm of the data matrix \code{Z}.
#' @param norm_Omega Spectral norm of the sketching matrix \code{Omega}.
#' @param n Number of rows in \code{Z} (accumulation length).
#' @param stage The computational stage whose precision governs the bound.
#'
#' @return A scalar upper bound on the forward error.
#' @examples
#' pm <- precision_model("single", "double")
#' sketch_forward_bound(pm, norm_Z = 10, norm_Omega = sqrt(2), n = 100)
#' @export
sketch_forward_bound <- function(
    pm,
    norm_Z,
    norm_Omega,
    n,
    stage = c("sketch", "orth", "core")
) {
    stage <- match.arg(stage)
    u <- unit_roundoff(pm, stage)
    gamma_n <- (n * u) / (1 - n * u)
    gamma_n * (norm_Z^2 / n) * norm_Omega
}

#' Check whether floating-point error is dominated by randomized truncation
#'
#' Returns \code{TRUE} when the estimated forward-error bound for the sketch
#' product is smaller than the randomized truncation-error estimate, meaning
#' that reduced precision is likely safe at the current rank and spectrum.
#'
#' @param pm A \code{randMBC_precision} object.
#' @param rand_err Estimated randomized truncation error
#'   (e.g.\ from a range-finder residual).
#' @param norm_Z Spectral norm of \code{Z}.
#' @param norm_Omega Spectral norm of \code{Omega}.
#' @param n Number of rows in \code{Z}.
#'
#' @return A logical scalar.
#' @examples
#' pm <- precision_model("single", "double")
#' is_fp_hidden(pm, rand_err = 0.5, norm_Z = 10, norm_Omega = sqrt(2), n = 100)
#' @export
is_fp_hidden <- function(pm, rand_err, norm_Z, norm_Omega, n) {
    fp_bound <- sketch_forward_bound(pm, norm_Z, norm_Omega, n, stage = "sketch")
    fp_bound <= rand_err
}
