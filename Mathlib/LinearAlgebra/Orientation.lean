/-
Copyright (c) 2021 Joseph Myers. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Joseph Myers
-/
import Mathlib.LinearAlgebra.Ray
import Mathlib.LinearAlgebra.Determinant

/-!
# Orientations of modules

This file defines orientations of modules.

## Main definitions

* `Orientation` is a type synonym for `Module.Ray` for the case where the module is that of
  alternating maps from a module to its underlying ring.  An orientation may be associated with an
  alternating map or with a basis.

* `Module.Oriented` is a type class for a choice of orientation of a module that is considered
  the positive orientation.

## Implementation notes

`Orientation` is defined for an arbitrary index type, but the main intended use case is when
that index type is a `Fintype` and there exists a basis of the same cardinality.

## References

* https://en.wikipedia.org/wiki/Orientation_(vector_space)

-/

noncomputable section

open Module

section OrderedCommSemiring

variable (R : Type*) [CommSemiring R] [PartialOrder R] [IsStrictOrderedRing R]
variable (M : Type*) [AddCommMonoid M] [Module R M]
variable {N : Type*} [AddCommMonoid N] [Module R N]
variable (ι ι' : Type*)

/-- An orientation of a module, intended to be used when `ι` is a `Fintype` with the same
cardinality as a basis. -/
abbrev Orientation := Module.Ray R (M [⋀^ι]→ₗ[R] R)

/-- A type class fixing an orientation of a module. -/
class Module.Oriented where
  /-- Fix a positive orientation. -/
  positiveOrientation : Orientation R M ι

export Module.Oriented (positiveOrientation)

variable {R M}

/-- An equivalence between modules implies an equivalence between orientations. -/
def Orientation.map (e : M ≃ₗ[R] N) : Orientation R M ι ≃ Orientation R N ι :=
  Module.Ray.map <| AlternatingMap.domLCongr R R ι R e

@[simp]
theorem Orientation.map_apply (e : M ≃ₗ[R] N) (v : M [⋀^ι]→ₗ[R] R) (hv : v ≠ 0) :
    Orientation.map ι e (rayOfNeZero _ v hv) =
      rayOfNeZero _ (v.compLinearMap e.symm) (mt (v.compLinearEquiv_eq_zero_iff e.symm).mp hv) :=
  rfl

@[simp]
theorem Orientation.map_refl : (Orientation.map ι <| LinearEquiv.refl R M) = Equiv.refl _ := by
  rw [Orientation.map, AlternatingMap.domLCongr_refl, Module.Ray.map_refl]

@[simp]
theorem Orientation.map_symm (e : M ≃ₗ[R] N) :
    (Orientation.map ι e).symm = Orientation.map ι e.symm := rfl

section Reindex

variable (R M) {ι ι'}

/-- An equivalence between indices implies an equivalence between orientations. -/
def Orientation.reindex (e : ι ≃ ι') : Orientation R M ι ≃ Orientation R M ι' :=
  Module.Ray.map <| AlternatingMap.domDomCongrₗ R e

@[simp]
theorem Orientation.reindex_apply (e : ι ≃ ι') (v : M [⋀^ι]→ₗ[R] R) (hv : v ≠ 0) :
    Orientation.reindex R M e (rayOfNeZero _ v hv) =
      rayOfNeZero _ (v.domDomCongr e) (mt (v.domDomCongr_eq_zero_iff e).mp hv) :=
  rfl

@[simp]
theorem Orientation.reindex_refl : (Orientation.reindex R M <| Equiv.refl ι) = Equiv.refl _ := by
  rw [Orientation.reindex, AlternatingMap.domDomCongrₗ_refl, Module.Ray.map_refl]

@[simp]
theorem Orientation.reindex_symm (e : ι ≃ ι') :
    (Orientation.reindex R M e).symm = Orientation.reindex R M e.symm :=
  rfl

end Reindex

/-- A module is canonically oriented with respect to an empty index type. -/
instance (priority := 100) IsEmpty.oriented [IsEmpty ι] : Module.Oriented R M ι where
  positiveOrientation :=
    rayOfNeZero R (AlternatingMap.constLinearEquivOfIsEmpty 1) <|
      AlternatingMap.constLinearEquivOfIsEmpty.injective.ne (by exact one_ne_zero)

@[simp]
theorem Orientation.map_positiveOrientation_of_isEmpty [IsEmpty ι] (f : M ≃ₗ[R] N) :
    Orientation.map ι f positiveOrientation = positiveOrientation := rfl

@[simp]
theorem Orientation.map_of_isEmpty [IsEmpty ι] (x : Orientation R M ι) (f : M ≃ₗ[R] M) :
    Orientation.map ι f x = x := by
  induction x using Module.Ray.ind with | h g hg =>
  rw [Orientation.map_apply]
  congr
  ext i
  rw [AlternatingMap.compLinearMap_apply]
  congr
  simp only [LinearEquiv.coe_coe, eq_iff_true_of_subsingleton]

end OrderedCommSemiring

section OrderedCommRing

variable {R : Type*} [CommRing R] [PartialOrder R] [IsStrictOrderedRing R]
variable {M N : Type*} [AddCommGroup M] [AddCommGroup N] [Module R M] [Module R N]

@[simp]
protected theorem Orientation.map_neg {ι : Type*} (f : M ≃ₗ[R] N) (x : Orientation R M ι) :
    Orientation.map ι f (-x) = -Orientation.map ι f x :=
  Module.Ray.map_neg _ x

@[simp]
protected theorem Orientation.reindex_neg {ι ι' : Type*} (e : ι ≃ ι') (x : Orientation R M ι) :
    Orientation.reindex R M e (-x) = -Orientation.reindex R M e x :=
  Module.Ray.map_neg _ x

namespace Module.Basis

variable {ι ι' : Type*}

/-- The value of `Orientation.map` when the index type has the cardinality of a basis, in terms
of `f.det`. -/
theorem map_orientation_eq_det_inv_smul [Finite ι] (e : Basis ι R M) (x : Orientation R M ι)
    (f : M ≃ₗ[R] M) : Orientation.map ι f x = (LinearEquiv.det f)⁻¹ • x := by
  cases nonempty_fintype ι
  letI := Classical.decEq ι
  induction x using Module.Ray.ind with | h g hg =>
  rw [Orientation.map_apply, smul_rayOfNeZero, ray_eq_iff, Units.smul_def,
    (g.compLinearMap f.symm).eq_smul_basis_det e, g.eq_smul_basis_det e,
    AlternatingMap.compLinearMap_apply, AlternatingMap.smul_apply,
    show (fun i ↦ (LinearEquiv.symm f).toLinearMap (e i)) = (LinearEquiv.symm f).toLinearMap ∘ e
    by rfl, Basis.det_comp, Basis.det_self, mul_one, smul_eq_mul, mul_comm, mul_smul,
    LinearEquiv.coe_inv_det]

variable [Fintype ι] [DecidableEq ι] [Fintype ι'] [DecidableEq ι']

/-- The orientation given by a basis. -/
protected def orientation (e : Basis ι R M) : Orientation R M ι :=
  rayOfNeZero R _ e.det_ne_zero

theorem orientation_map (e : Basis ι R M) (f : M ≃ₗ[R] N) :
    (e.map f).orientation = Orientation.map ι f e.orientation := by
  simp_rw [Basis.orientation, Orientation.map_apply, Basis.det_map']

theorem orientation_reindex (e : Basis ι R M) (eι : ι ≃ ι') :
    (e.reindex eι).orientation = Orientation.reindex R M eι e.orientation := by
  simp_rw [Basis.orientation, Orientation.reindex_apply, Basis.det_reindex']

/-- The orientation given by a basis derived using `units_smul`, in terms of the product of those
units. -/
theorem orientation_unitsSMul (e : Basis ι R M) (w : ι → Units R) :
    (e.unitsSMul w).orientation = (∏ i, w i)⁻¹ • e.orientation := by
  rw [Basis.orientation, Basis.orientation, smul_rayOfNeZero, ray_eq_iff,
    e.det.eq_smul_basis_det (e.unitsSMul w), det_unitsSMul_self, Units.smul_def, smul_smul]
  norm_cast
  simp only [inv_mul_cancel, Units.val_one, one_smul]
  exact SameRay.rfl

@[simp]
theorem orientation_isEmpty [IsEmpty ι] (b : Basis ι R M) :
    b.orientation = positiveOrientation := by
  rw [Basis.orientation]
  congr
  exact b.det_isEmpty

end Module.Basis

end OrderedCommRing

section LinearOrderedCommRing

variable {R : Type*} [CommRing R] [LinearOrder R] [IsStrictOrderedRing R]
variable {M : Type*} [AddCommGroup M] [Module R M]
variable {ι : Type*}

namespace Orientation

/-- A module `M` over a linearly ordered commutative ring has precisely two "orientations" with
respect to an empty index type. (Note that these are only orientations of `M` of in the conventional
mathematical sense if `M` is zero-dimensional.) -/
theorem eq_or_eq_neg_of_isEmpty [IsEmpty ι] (o : Orientation R M ι) :
    o = positiveOrientation ∨ o = -positiveOrientation := by
  induction o using Module.Ray.ind with | h x hx =>
  dsimp [positiveOrientation]
  simp only [ray_eq_iff]
  rw [sameRay_or_sameRay_neg_iff_not_linearIndependent]
  intro h
  set f : (M [⋀^ι]→ₗ[R] R) ≃ₗ[R] R := AlternatingMap.constLinearEquivOfIsEmpty.symm
  have H : LinearIndependent R ![f x, 1] := by
    convert h.map' f.toLinearMap f.ker
    ext i
    fin_cases i <;> simp [f]
  rw [linearIndependent_iff'] at H
  simpa using H Finset.univ ![1, -f x] (by simp [Fin.sum_univ_succ]) 0 (by simp)

end Orientation

namespace Module.Basis

variable [Fintype ι] [DecidableEq ι]

/-- The orientations given by two bases are equal if and only if the determinant of one basis
with respect to the other is positive. -/
theorem orientation_eq_iff_det_pos (e₁ e₂ : Basis ι R M) :
    e₁.orientation = e₂.orientation ↔ 0 < e₁.det e₂ :=
  calc
    e₁.orientation = e₂.orientation ↔ SameRay R e₁.det e₂.det := ray_eq_iff _ _
    _ ↔ SameRay R (e₁.det e₂ • e₂.det) e₂.det := by rw [← e₁.det.eq_smul_basis_det e₂]
    _ ↔ 0 < e₁.det e₂ := sameRay_smul_left_iff_of_ne e₂.det_ne_zero (e₁.isUnit_det e₂).ne_zero

/-- Given a basis, any orientation equals the orientation given by that basis or its negation. -/
theorem orientation_eq_or_eq_neg (e : Basis ι R M) (x : Orientation R M ι) :
    x = e.orientation ∨ x = -e.orientation := by
  induction x using Module.Ray.ind with | h x hx =>
  rw [← x.map_basis_ne_zero_iff e] at hx
  rwa [Basis.orientation, ray_eq_iff, neg_rayOfNeZero, ray_eq_iff, x.eq_smul_basis_det e,
    sameRay_neg_smul_left_iff_of_ne e.det_ne_zero hx, sameRay_smul_left_iff_of_ne e.det_ne_zero hx,
    lt_or_lt_iff_ne, ne_comm]

/-- Given a basis, an orientation equals the negation of that given by that basis if and only
if it does not equal that given by that basis. -/
theorem orientation_ne_iff_eq_neg (e : Basis ι R M) (x : Orientation R M ι) :
    x ≠ e.orientation ↔ x = -e.orientation :=
  ⟨fun h => (e.orientation_eq_or_eq_neg x).resolve_left h, fun h =>
    h.symm ▸ (Module.Ray.ne_neg_self e.orientation).symm⟩

/-- Composing a basis with a linear equiv gives the same orientation if and only if the
determinant is positive. -/
theorem orientation_comp_linearEquiv_eq_iff_det_pos (e : Basis ι R M) (f : M ≃ₗ[R] M) :
    (e.map f).orientation = e.orientation ↔ 0 < LinearMap.det (f : M →ₗ[R] M) := by
  rw [orientation_map, e.map_orientation_eq_det_inv_smul, units_inv_smul, units_smul_eq_self_iff,
    LinearEquiv.coe_det]

/-- Composing a basis with a linear equiv gives the negation of that orientation if and only if
the determinant is negative. -/
theorem orientation_comp_linearEquiv_eq_neg_iff_det_neg (e : Basis ι R M) (f : M ≃ₗ[R] M) :
    (e.map f).orientation = -e.orientation ↔ LinearMap.det (f : M →ₗ[R] M) < 0 := by
  rw [orientation_map, e.map_orientation_eq_det_inv_smul, units_inv_smul, units_smul_eq_neg_iff,
    LinearEquiv.coe_det]

/-- Negating a single basis vector (represented using `units_smul`) negates the corresponding
orientation. -/
@[simp]
theorem orientation_neg_single (e : Basis ι R M) (i : ι) :
    (e.unitsSMul (Function.update 1 i (-1))).orientation = -e.orientation := by
  rw [orientation_unitsSMul, Finset.prod_update_of_mem (Finset.mem_univ _)]
  simp

/-- Given a basis and an orientation, return a basis giving that orientation: either the original
basis, or one constructed by negating a single (arbitrary) basis vector. -/
def adjustToOrientation [Nonempty ι] (e : Basis ι R M) (x : Orientation R M ι) :
    Basis ι R M :=
  haveI := Classical.decEq (Orientation R M ι)
  if e.orientation = x then e else e.unitsSMul (Function.update 1 (Classical.arbitrary ι) (-1))

/-- `adjust_to_orientation` gives a basis with the required orientation. -/
@[simp]
theorem orientation_adjustToOrientation [Nonempty ι] (e : Basis ι R M)
    (x : Orientation R M ι) : (e.adjustToOrientation x).orientation = x := by
  rw [adjustToOrientation]
  split_ifs with h
  · exact h
  · rw [orientation_neg_single, eq_comm, ← orientation_ne_iff_eq_neg, ne_comm]
    exact h

/-- Every basis vector from `adjust_to_orientation` is either that from the original basis or its
negation. -/
theorem adjustToOrientation_apply_eq_or_eq_neg [Nonempty ι] (e : Basis ι R M)
    (x : Orientation R M ι) (i : ι) :
    e.adjustToOrientation x i = e i ∨ e.adjustToOrientation x i = -e i := by
  rw [adjustToOrientation]
  split_ifs with h
  · simp
  · by_cases hi : i = Classical.arbitrary ι <;> simp [unitsSMul_apply, hi]

theorem det_adjustToOrientation [Nonempty ι] (e : Basis ι R M)
    (x : Orientation R M ι) :
    (e.adjustToOrientation x).det = e.det ∨ (e.adjustToOrientation x).det = -e.det := by
  dsimp [Basis.adjustToOrientation]
  split_ifs
  · left
    rfl
  · right
    simp only [e.det_unitsSMul, Finset.mem_univ, Finset.prod_update_of_mem,
      Pi.one_apply, Finset.prod_const_one, mul_one, inv_neg, inv_one, Units.val_neg, Units.val_one]
    ext
    simp

@[simp]
theorem abs_det_adjustToOrientation [Nonempty ι] (e : Basis ι R M)
    (x : Orientation R M ι) (v : ι → M) : |(e.adjustToOrientation x).det v| = |e.det v| := by
  rcases e.det_adjustToOrientation x with h | h <;> simp [h]

end Module.Basis

end LinearOrderedCommRing

section LinearOrderedField

variable {R : Type*} [Field R] [LinearOrder R] [IsStrictOrderedRing R]
variable {M : Type*} [AddCommGroup M] [Module R M]
variable {ι : Type*}

namespace Orientation

variable [Fintype ι]

open FiniteDimensional Module

/-- If the index type has cardinality equal to the finite dimension, any two orientations are
equal or negations. -/
theorem eq_or_eq_neg [FiniteDimensional R M] (x₁ x₂ : Orientation R M ι)
    (h : Fintype.card ι = finrank R M) : x₁ = x₂ ∨ x₁ = -x₂ := by
  have e := (finBasis R M).reindex (Fintype.equivFinOfCardEq h).symm
  letI := Classical.decEq ι
  rcases e.orientation_eq_or_eq_neg x₁ with (h₁ | h₁) <;>
    rcases e.orientation_eq_or_eq_neg x₂ with (h₂ | h₂) <;> simp [h₁, h₂]

/-- If the index type has cardinality equal to the finite dimension, an orientation equals the
negation of another orientation if and only if they are not equal. -/
theorem ne_iff_eq_neg [FiniteDimensional R M] (x₁ x₂ : Orientation R M ι)
    (h : Fintype.card ι = finrank R M) : x₁ ≠ x₂ ↔ x₁ = -x₂ :=
  ⟨fun hn => (eq_or_eq_neg x₁ x₂ h).resolve_left hn, fun he =>
    he.symm ▸ (Module.Ray.ne_neg_self x₂).symm⟩

/-- The value of `Orientation.map` when the index type has cardinality equal to the finite
dimension, in terms of `f.det`. -/
theorem map_eq_det_inv_smul [FiniteDimensional R M] (x : Orientation R M ι) (f : M ≃ₗ[R] M)
    (h : Fintype.card ι = finrank R M) : Orientation.map ι f x = (LinearEquiv.det f)⁻¹ • x :=
  haveI e := (finBasis R M).reindex (Fintype.equivFinOfCardEq h).symm
  e.map_orientation_eq_det_inv_smul x f

/-- If the index type has cardinality equal to the finite dimension, composing an alternating
map with the same linear equiv on each argument gives the same orientation if and only if the
determinant is positive. -/
theorem map_eq_iff_det_pos [FiniteDimensional R M] (x : Orientation R M ι) (f : M ≃ₗ[R] M)
    (h : Fintype.card ι = finrank R M) :
    Orientation.map ι f x = x ↔ 0 < LinearMap.det (f : M →ₗ[R] M) := by
  cases isEmpty_or_nonempty ι
  · have H : finrank R M = 0 := h.symm.trans Fintype.card_eq_zero
    simp [LinearMap.det_eq_one_of_finrank_eq_zero H]
  rw [map_eq_det_inv_smul _ _ h, units_inv_smul, units_smul_eq_self_iff, LinearEquiv.coe_det]

/-- If the index type has cardinality equal to the finite dimension, composing an alternating
map with the same linear equiv on each argument gives the negation of that orientation if and
only if the determinant is negative. -/
theorem map_eq_neg_iff_det_neg (x : Orientation R M ι) (f : M ≃ₗ[R] M)
    (h : Fintype.card ι = finrank R M) :
    Orientation.map ι f x = -x ↔ LinearMap.det (f : M →ₗ[R] M) < 0 := by
  cases isEmpty_or_nonempty ι
  · have H : finrank R M = 0 := h.symm.trans Fintype.card_eq_zero
    simp [LinearMap.det_eq_one_of_finrank_eq_zero H, Module.Ray.ne_neg_self x]
  have H : 0 < finrank R M := by
    rw [← h]
    exact Fintype.card_pos
  haveI : FiniteDimensional R M := of_finrank_pos H
  rw [map_eq_det_inv_smul _ _ h, units_inv_smul, units_smul_eq_neg_iff, LinearEquiv.coe_det]

/-- If the index type has cardinality equal to the finite dimension, a basis with the given
orientation. -/
def someBasis [Nonempty ι] [DecidableEq ι] [FiniteDimensional R M] (x : Orientation R M ι)
    (h : Fintype.card ι = finrank R M) : Basis ι R M :=
  ((finBasis R M).reindex (Fintype.equivFinOfCardEq h).symm).adjustToOrientation x

/-- `some_basis` gives a basis with the required orientation. -/
@[simp]
theorem someBasis_orientation [Nonempty ι] [DecidableEq ι] [FiniteDimensional R M]
    (x : Orientation R M ι) (h : Fintype.card ι = finrank R M) : (x.someBasis h).orientation = x :=
  Basis.orientation_adjustToOrientation _ _

end Orientation

end LinearOrderedField
