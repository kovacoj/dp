import Mathlib

set_option linter.style.header false

namespace Formal
namespace ErrorBudget

/--
Two-component deterministic error-budget lemma.

This is useful when the analysis only separates, for example,
approximation error and algebraic error.

Given a tolerance ε ≥ 0, error components e₁, e₂ bounded by
allocated fractions θ₁, θ₂ of ε, with θ₁ + θ₂ ≤ 1,
the total error e₁ + e₂ does not exceed ε.
-/
theorem two_error_budget
    {ε e₁ e₂ θ₁ θ₂ : ℝ}
    (hε : 0 ≤ ε)
    (h₁ : e₁ ≤ θ₁ * ε)
    (h₂ : e₂ ≤ θ₂ * ε)
    (hθ : θ₁ + θ₂ ≤ 1) :
    e₁ + e₂ ≤ ε := by
  nlinarith

/--
Two-component total-error budget lemma.

If `eTotal ≤ e₁ + e₂` and the two-component budget holds, then
`eTotal ≤ ε`.
-/
theorem total_error_budget_two
    {ε eTotal e₁ e₂ θ₁ θ₂ : ℝ}
    (hε : 0 ≤ ε)
    (hTotal : eTotal ≤ e₁ + e₂)
    (h₁ : e₁ ≤ θ₁ * ε)
    (h₂ : e₂ ≤ θ₂ * ε)
    (hθ : θ₁ + θ₂ ≤ 1) :
    eTotal ≤ ε := by
  exact le_trans hTotal (two_error_budget hε h₁ h₂ hθ)

/--
Three-component deterministic error-budget lemma.

This corresponds to the thesis decomposition:
discretization error + sampling error + algebraic/rounding error.

Given a tolerance ε ≥ 0, error components e₁, e₂, e₃ bounded by
allocated fractions θ₁, θ₂, θ₃ of ε, with θ₁ + θ₂ + θ₃ ≤ 1,
the total error e₁ + e₂ + e₃ does not exceed ε.
-/
theorem three_error_budget
    {ε e₁ e₂ e₃ θ₁ θ₂ θ₃ : ℝ}
    (hε : 0 ≤ ε)
    (h₁ : e₁ ≤ θ₁ * ε)
    (h₂ : e₂ ≤ θ₂ * ε)
    (h₃ : e₃ ≤ θ₃ * ε)
    (hθ : θ₁ + θ₂ + θ₃ ≤ 1) :
    e₁ + e₂ + e₃ ≤ ε := by
  nlinarith

/--
Three-component total-error budget lemma.

If `eTotal ≤ e₁ + e₂ + e₃` and the three-component budget holds,
then `eTotal ≤ ε`.
-/
theorem total_error_budget_three
    {ε eTotal e₁ e₂ e₃ θ₁ θ₂ θ₃ : ℝ}
    (hε : 0 ≤ ε)
    (hTotal : eTotal ≤ e₁ + e₂ + e₃)
    (h₁ : e₁ ≤ θ₁ * ε)
    (h₂ : e₂ ≤ θ₂ * ε)
    (h₃ : e₃ ≤ θ₃ * ε)
    (hθ : θ₁ + θ₂ + θ₃ ≤ 1) :
    eTotal ≤ ε := by
  exact le_trans hTotal (three_error_budget hε h₁ h₂ h₃ hθ)

end ErrorBudget
end Formal
