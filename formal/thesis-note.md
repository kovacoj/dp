# Lean proof kernel: thesis integration note

This note explains how the Lean formalization in this directory can be described in the thesis.

## Purpose

The Lean files formalize a small deterministic proof kernel underlying the adaptive error-budget mechanism. They do not formalize the whole numerical method.

## Formalized components

### Error-budget splitting

The file `Formal/ErrorBudget.lean` verifies that if the individual error components are each bounded by allocated fractions of the tolerance, then the total error is below the prescribed tolerance.

In thesis notation, this corresponds to:

$$
e_{\mathrm{tot}}
\leq e_{\mathrm{disc}} + e_{\mathrm{sampling}} + e_{\mathrm{alg}},
$$

with

$$
e_{\mathrm{disc}} \leq \theta_{\mathrm{disc}}\varepsilon,\quad
e_{\mathrm{sampling}} \leq \theta_{\mathrm{sampling}}\varepsilon,\quad
e_{\mathrm{alg}} \leq \theta_{\mathrm{alg}}\varepsilon,
$$

and

$$
\theta_{\mathrm{disc}}+\theta_{\mathrm{sampling}}+\theta_{\mathrm{alg}}\leq 1.
$$

### Residual-based algebraic error

The file `Formal/ResidualBounds.lean` formalizes the standard residual relationship for an invertible linear operator:

$$
\hat{x} - x = A^{-1}r.
$$

It also formalizes the norm bound:

$$
\|\hat{x} - x\|
\leq
\|A^{-1}\|\,\|r\|.
$$

This is the mathematical justification for using residual-based stopping criteria when controlling algebraic error.

### Precision-selection logic

The file `Formal/PrecisionSelection.lean` formalizes the abstract decision rule: if the chosen precision has an algebraic error proxy below its allocated tolerance, then the total error budget remains valid.

## Non-goals

The Lean layer does not formalize:

- finite element convergence,
- Sobolev spaces,
- stochastic PDEs,
- MLMC complexity,
- IEEE floating-point arithmetic,
- hardware-specific mixed precision behavior.

These remain part of the conventional mathematical and experimental thesis sections.

## Possible thesis wording

> To increase confidence in the adaptive error-budget mechanism, selected deterministic proof obligations were formalized in Lean 4. The formalized component verifies the tolerance-splitting argument, the residual-to-error relationship for algebraic solves, and the abstract correctness of precision selection under an error proxy. The full PDE, FEM, and MLMC analysis remains in conventional mathematical form.
