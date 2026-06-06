import Mathlib

set_option linter.style.header false

namespace Formal
namespace ResidualBounds

/--
Residual identity for an invertible continuous linear map on real normed spaces.

If `x` solves `A x = b` and `r = A xhat - b`, then the error
`xhat - x` is exactly the inverse image of the residual.

This is the formal analogue of the standard numerical linear algebra
identity `xhat - x = A⁻¹ r`.
-/
theorem error_eq_inverse_residual
    {E F : Type*}
    [NormedAddCommGroup E] [NormedSpace ℝ E] [CompleteSpace E]
    [NormedAddCommGroup F] [NormedSpace ℝ F]
    (A : E ≃L[ℝ] F) (x xhat : E) (b r : F)
    (hx : A x = b)
    (hr : r = A xhat - b) :
    xhat - x = A.symm r := by
  calc xhat - x = A.symm (A (xhat - x)) := by simp
    _ = A.symm (A xhat - A x) := by rw [A.map_sub]
    _ = A.symm (A xhat - b) := by rw [hx]
    _ = A.symm r := by rw [hr]

/--
Residual norm bound on real normed spaces.

This is the formal analogue of the standard numerical linear algebra
estimate `‖xhat - x‖ ≤ ‖A⁻¹‖ ‖r‖`.

It justifies controlling algebraic error by controlling the residual.
-/
theorem norm_error_le_inverse_norm_mul_residual
    {E F : Type*}
    [NormedAddCommGroup E] [NormedSpace ℝ E] [CompleteSpace E]
    [NormedAddCommGroup F] [NormedSpace ℝ F] [CompleteSpace F]
    (A : E ≃L[ℝ] F) (x xhat : E) (b r : F)
    (hx : A x = b)
    (hr : r = A xhat - b) :
    ‖xhat - x‖ ≤ ‖(A.symm : F →L[ℝ] E)‖ * ‖r‖ := by
  rw [error_eq_inverse_residual A x xhat b r hx hr]
  exact ContinuousLinearMap.le_opNorm (A.symm : F →L[ℝ] E) r

/--
Weaker but still useful equality: the norm of the error equals
the norm of the inverse image of the residual.
-/
theorem norm_error_eq_norm_inverse_residual
    {E F : Type*}
    [NormedAddCommGroup E] [NormedSpace ℝ E] [CompleteSpace E]
    [NormedAddCommGroup F] [NormedSpace ℝ F] [CompleteSpace F]
    (A : E ≃L[ℝ] F) (x xhat : E) (b r : F)
    (hx : A x = b)
    (hr : r = A xhat - b) :
    ‖xhat - x‖ = ‖A.symm r‖ := by
  rw [error_eq_inverse_residual A x xhat b r hx hr]

end ResidualBounds
end Formal
