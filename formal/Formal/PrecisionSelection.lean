import Mathlib
import Formal.ErrorBudget

set_option linter.style.header false

namespace Formal
namespace PrecisionSelection

variable {Precision : Type*}

/--
Abstract correctness theorem for adaptive precision selection.

If the selected precision `p` has algebraic error proxy within its
allocated budget, and the other error components are also within
budget, then the total error is below the target tolerance.
-/
theorem total_error_with_precision_proxy
    {ε eTotal eDisc eSampling θDisc θSampling θAlg : ℝ}
    {p : Precision} (algErr : Precision → ℝ)
    (hε : 0 ≤ ε)
    (hTotal : eTotal ≤ eDisc + eSampling + algErr p)
    (hDisc : eDisc ≤ θDisc * ε)
    (hSampling : eSampling ≤ θSampling * ε)
    (hAlg : algErr p ≤ θAlg * ε)
    (hθ : θDisc + θSampling + θAlg ≤ 1) :
    eTotal ≤ ε := by
  exact ErrorBudget.total_error_budget_three
    hε hTotal hDisc hSampling hAlg hθ

end PrecisionSelection
end Formal
