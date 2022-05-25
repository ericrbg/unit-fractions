/-
Copyright (c) 2021 Bhavik Mehta, Thomas Bloom. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Bhavik Mehta, Thomas Bloom
-/

import data.real.basic
import analysis.special_functions.log.basic
import number_theory.arithmetic_function
import algebra.is_prime_pow

open_locale classical big_operators arithmetic_function

open filter finset real
open nat (coprime)

noncomputable theory

theorem card_bUnion_lt_card_mul_real {s : finset ℤ} {f : ℤ → finset ℕ}
 (hs : s.nonempty) (m : ℝ)
  (h : ∀ (a : ℤ), a ∈ s → ((f a).card : ℝ) < m) :
((s.bUnion f).card : ℝ) < s.card * m := sorry

lemma sum_bUnion_le {f : ℕ → ℚ} {s : finset ℕ} {t : ℕ → finset ℕ}
(hf : ∀ (i : ℕ), 0 ≤ f i) :
(s.bUnion t).sum (λ (x : ℕ), f x) ≤ s.sum (λ (x : ℕ), (t x).sum (λ (i : ℕ), f i)) :=
begin
  -- card_bUnion_le is this but worse
  induction s using finset.induction_on with k s hks ih,
  { simp },
  rw [sum_insert hks, bUnion_insert],
  apply le_of_add_le_of_nonneg_left,
  { rw [sum_union_inter],
    exact add_le_add le_rfl ih },
  { exact sum_nonneg' hf }
end

lemma nat_cast_diff_issue {x y : ℤ} : (|x-y|:ℝ) = int.nat_abs (x-y) :=
by rw [←int.cast_sub, int.cast_nat_abs]

lemma two_in_Icc' {a b x y: ℤ} (I : finset ℤ) (hI : I = Icc a b) (hx : x ∈ I) (hy : y ∈ I) :
  (|x-y|:ℝ) ≤ b-a :=
begin
  suffices : ∀ {c d}, c ∈ I → d ∈ I → c ≤ d → (|d - c| : ℝ) ≤ b-a,
  { rcases le_total x y with h | h,
    { convert this hx hy h using 1,
      rw [←abs_neg],
      simp },
    { exact this hy hx h } },
  subst hI,
  clear_except,
  intros c d hc hd hcd,
  rw abs_of_nonneg,
  swap, { norm_cast, rwa sub_nonneg },
  rw mem_Icc at hc hd,
  cases hc,
  cases hd,
  norm_cast,
  linarith,
end

lemma two_in_Icc {a b x y: ℤ} (hx : x ∈ Icc a b) (hy : y ∈ Icc a b) : (|x-y|:ℝ) ≤ b-a :=
two_in_Icc' _ rfl hx hy

lemma omega_div {a b : ℕ} (h: b ∣ a) : (ω a:ℝ) - ω b ≤ ω (a/b) :=
begin
  rcases a.eq_zero_or_pos with rfl | ha,
  { simp },
  rcases b.eq_zero_or_pos with rfl | hb,
  { simp [zero_dvd_iff.mp h] },
  rw sub_le_iff_le_add,
  norm_cast,
  simp only [nat.arithmetic_function.card_distinct_factors_apply],
  rw [add_comm, ←list.length_append],
  apply list.subperm.length_le,
  obtain ⟨k, rfl⟩ := h,
  have hk : 0 < k := pos_of_mul_pos_left ha hb.le,
  rw [k.mul_div_cancel_left hb],
  refine (list.nodup_dedup _).subperm _,
  intros x hx,
  rw [list.mem_dedup, nat.mem_factors_mul hb.ne' hk.ne'] at hx,
  rwa [list.mem_append, list.mem_dedup, list.mem_dedup]
end

-- this isn't true: ω 13 = 1, ω (13 / 2) = 2
lemma omega_div_le {a b : ℕ} : ω (a/b) ≤ ω a := sorry

section list

open list

lemma list.mem_join_repeat {α} {n : ℕ} {a : list α} {t} (hn : n ≠ 0) :
  t ∈ (list.repeat a n).join ↔ t ∈ a :=
begin
  simp_rw [list.mem_join, list.mem_repeat],
  exact ⟨by { rintro ⟨a, ⟨hn, rfl⟩, h⟩, exact h }, λ h, ⟨_, ⟨hn, rfl⟩, h⟩⟩
end

lemma nat.factors_pow_perm (a : ℕ) {n : ℕ} (hn : n ≠ 0) :
  (a ^ n).factors ~ (list.repeat a.factors n).join :=
begin
  rcases eq_or_ne a 0 with rfl | ha,
  { simpa using or.inl hn.bot_lt },
  refine (nat.factors_unique _ $ λ p hp, _).symm,
  { simp [nat.prod_factors ha] },
  rw [list.mem_join_repeat hn, nat.mem_factors ha] at hp,
  exact hp.1
end

lemma nat.factors_pow (a : ℕ) {n : ℕ} (hn : n ≠ 0) :
  (a ^ n).factors = (list.repeat a.factors n).join.merge_sort (≤) :=
eq_of_perm_of_sorted ((a.factors_pow_perm hn).trans (perm_merge_sort _ _).symm)
                     ((a ^ n).factors_sorted) $ sorted_merge_sort _ _

end list

lemma omega_pow {a n : ℕ} (hn : n ≠ 0) : ω a = ω (a ^ n) :=
begin
  simp only [nat.arithmetic_function.card_distinct_factors_apply],
  apply list.perm.length_eq,
  rw [list.perm_ext (list.nodup_dedup _) (list.nodup_dedup _)],
  intro x,
  rw [list.mem_dedup, list.mem_dedup, (a.factors_pow_perm hn).mem_iff, list.mem_join_repeat hn]
end

lemma omega_mul_ppower {a q : ℕ} (hq : is_prime_pow q) : ω (q*a) ≤ 1 + ω a :=
begin
  obtain ⟨p, n, hp, hn, rfl⟩ := hq,
  sorry,
end

lemma sum_add_sum {A B : finset ℕ} {f : ℕ → ℝ} :
A.sum (λ (i : ℕ), f i) + B.sum (λ (i : ℕ), f i) = (A∪B).sum (λ (i : ℕ), f i) +
(A∩B).sum (λ (i : ℕ), f i) :=
by rw sum_union_inter

lemma sum_add_sum_add_sum {A B C : finset ℕ} {f : ℕ → ℝ} :
A.sum (λ (i : ℕ), f i) + B.sum (λ (i : ℕ), f i) + C.sum (λ (i : ℕ), f i) =
(A∪B∪C).sum (λ (i : ℕ), f i) + (A∩B).sum (λ (i : ℕ), f i) + (A∩C).sum (λ (i : ℕ), f i)
+ (B∩C).sum (λ (i : ℕ), f i) - (A∩B∩C).sum (λ (i : ℕ), f i)
 := sorry

lemma sum_le_sum_of_inj {A B : finset ℕ} {f1 f2 : ℕ → ℝ} (g : ℕ → ℕ) (hf2 : ∀ b ∈ B, 0 ≤ f2 b )
(hgB : ∀ a ∈ A, g a ∈ B) (hginj : ∀ a1 a2 ∈ A, (g a1 = g a2) → a1 = a2) (hgf : ∀ a ∈ A, f2 (g a) = f1 a) :
A.sum (λ (i : ℕ), f1 i) ≤ B.sum (λ (i : ℕ), f2 i) :=
sorry

lemma eq_iff_ppowers_dvd (a b  : ℕ) : a = b ↔ (∀ q ∣ a, is_prime_pow q → coprime q (a/q)
 → q ∣ b) ∧ (∀ q ∣ b, is_prime_pow q → coprime q (b/q) → q ∣ a) := sorry

theorem is_prime_pow_dvd_prod {n : ℕ} {D : finset ℕ}
 (hD : ∀ a b ∈ D, a ≠ b → coprime a b) (hn : is_prime_pow n) :
n ∣ ∏ d in D, d ↔ ∃ d ∈ D, n ∣ d := sorry

lemma prime_pow_not_coprime_iff {a b : ℕ} (ha : is_prime_pow a) (hb : is_prime_pow b) :
 ¬ coprime a b ↔ ∃ (p : ℕ) (ka kb : ℕ), p.prime ∧ ka ≠ 0 ∧ kb ≠ 0 ∧
 p ^ ka = a ∧ p ^ kb = b := sorry

lemma prime_pow_not_coprime_prod_iff {a : ℕ} {D : finset ℕ} (ha : is_prime_pow a)
(hD : ∀ d ∈ D, is_prime_pow d) :
 ¬ coprime a (∏ d in D, d) ↔ ∃ (p : ℕ) (ka kd : ℕ) (d ∈ D), p.prime ∧ ka ≠ 0 ∧ kd ≠ 0 ∧
 p ^ ka = a ∧ p ^ kd = d := sorry

 lemma prime_pow_dvd_prod_prime_pow {a : ℕ} {D : finset ℕ} (ha : is_prime_pow a)
(hD : ∀ d ∈ D, is_prime_pow d) :
a ∣ (∏ d in D, d) → coprime a ((∏ d in D, d)/a) → a ∈ D := sorry

lemma prime_pow_prods_coprime {A B : finset ℕ} (hA : ∀ a ∈ A, is_prime_pow a)
 (hB : ∀ b ∈ B, is_prime_pow b) : coprime (∏ a in A, a) (∏ b in B, b) ↔
 ∀ a ∈ A, ∀ b ∈ B, coprime a b := sorry

lemma prod_le_max_size {ι N : Type*} [ordered_comm_semiring N]
  {s : finset ι} {f : ι → N} (hs : ∀ i ∈ s, 0 ≤ f i) (M : N) (hf : ∀ i ∈ s, f i ≤ M) :
  ∏ i in s, f i ≤ M^s.card :=
sorry

lemma omega_count_eq_ppowers {n : ℕ} :
  (filter (λ (r : ℕ), is_prime_pow r ∧ r.coprime (n / r)) n.divisors).card = ω n := sorry

lemma prod_of_subset_le_prod_of_ge_one {ι N : Type*} [ordered_comm_semiring N]
  {s t : finset ι} {f : ι → N} (h : t ⊆ s) (hs : ∀ i ∈ t, 0 ≤ f i) (hf : ∀ i ∈ s, i ∉ t → 1 ≤ f i) :
  ∏ i in t, f i ≤ ∏ i in s, f i :=
sorry

theorem sum_bUnion_le_sum_of_nonneg
{f : ℕ → ℚ} {s : finset ℕ} {t : ℕ → finset ℕ}
 (hf : ∀ x ∈ s.bUnion t, 0 ≤ f x) :
(s.bUnion t).sum (λ (x : ℕ), f x) ≤ s.sum (λ (x : ℕ), (t x).sum (λ (i : ℕ), f i)) :=
sorry

theorem weighted_ph {α M: Type*} {s : finset α}
{f : α → M} {w : α → M} {b : M} [ordered_comm_semiring M]
(hw : ∀ (a : α), a ∈ s → 0 ≤ w a) (hf : ∀ (a : α), a ∈ s → 0 ≤ f a)
(hb : b ≤ s.sum (λ (x : α), ((w x) * (f x)))) :
∃ (y : α) (H : y ∈ s), b ≤ (s.sum (λ (x : α), w x))*f y
:= sorry