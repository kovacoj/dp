# Formal verification sandbox

This directory contains a small Lean 4 / mathlib formalization layer for selected proof components used in the thesis.

The goal is not to formalize the full PDE/FEM/MLMC theory. Instead, we verify small deterministic lemmas that support the thesis error-budget mechanism:

- tolerance splitting for total error control,
- residual-to-error bounds for algebraic solves,
- abstract precision-selection logic.

## Build

```bash
lake build
```

Requires Lean 4 (v4.30.0) and mathlib. The `lean-toolchain` file pins the exact version. Use [elan](https://github.com/leanprover/elan) to manage the toolchain.

## Mapping to thesis

| Module                      | Thesis component                                                                                     |
| --------------------------- | ---------------------------------------------------------------------------------------------------- |
| `Formal.ErrorBudget`        | Deterministic tolerance splitting: balancing discretization, sampling, and algebraic/rounding errors |
| `Formal.ResidualBounds`     | Residual identity and norm bound for approximate linear solves                                       |
| `Formal.PrecisionSelection` | Abstract correctness of adaptive precision selection under an error proxy                            |

## Current theorem inventory

- `Formal.ErrorBudget.two_error_budget`
- `Formal.ErrorBudget.total_error_budget_two`
- `Formal.ErrorBudget.three_error_budget`
- `Formal.ErrorBudget.total_error_budget_three`
- `Formal.ResidualBounds.error_eq_inverse_residual`
- `Formal.ResidualBounds.norm_error_le_inverse_norm_mul_residual`
- `Formal.ResidualBounds.norm_error_eq_norm_inverse_residual`
- `Formal.PrecisionSelection.total_error_with_precision_proxy`

## Non-goals

This directory does not formalize Sobolev spaces, weak PDE formulations, FEM convergence, stochastic PDEs, full MLMC complexity, or IEEE floating-point semantics.

## Thesis-facing documentation

See `thesis-note.md` for a short explanation of how this formalization can be described in the written thesis.
