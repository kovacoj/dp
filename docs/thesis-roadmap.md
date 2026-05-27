# Diploma Thesis Roadmap

## Working Title

Randomized Numerical Linear Algebra in Mixed Precision, with an Application to Climate Models

## Thesis Questions

1. How do randomized low-rank covariance approximations perturb a regularized covariance-transport map?
2. How do finite-precision perturbations interact with randomized approximation error in this transport map?
3. Which regimes satisfy the balancing principle that floating-point error is hidden by randomized or statistical tolerance?
4. How do least-squares sketching and sketch-and-precondition solvers serve as model problems for the covariance-transport analysis?
5. How does the method compare with relevant climate post-processing R packages in an application workflow?

## Current Framing (2026-05-27)

The thesis is mathematical first. The central object is the regularized covariance transport map

```text
T_lambda = (C_X + lambda I)^(-1/2) (C_Y + lambda I)^(1/2),
```

where `C_X = Z_X^T Z_X / n` and `C_Y = Z_Y^T Z_Y / n` are empirical covariance
operators in a latent dependence space.

The computed randomized mixed-precision approximation is modeled as

```text
C_hat = C + E_rand + E_fp
```

and the main theorem chain should explain how this perturbation affects

```text
||T_lambda - T_hat_lambda||_2
||Z_f T_lambda - Z_f T_hat_lambda||_F.
```

The R packages, backend contracts, and benchmarks support this mathematical
story. They are validation layers, not replacements for the theory. `MBC` is the
first reference package for comparison, but the broader benchmark ecosystem is
tracked in `docs/r-package-ecosystem-survey.md`.

## Current Status (2026-05-18)

### Code (operational)

| Component                             | Location                                                        | Status                                              |
| ------------------------------------- | --------------------------------------------------------------- | --------------------------------------------------- |
| Gaussian sketch + LS experiment       | `src/octave/randLS_experiment.m`, `src/octave/randLS.m`         | Done, driver + reusable function                    |
| SRHT sketch + LS experiment           | `src/octave/srht_experiment.m`, `src/octave/srht.m`             | Done                                                |
| Rademacher sketch + LS experiment     | `src/octave/rademacher_experiment.m`, `src/octave/rademacher.m` | Done                                                |
| Unified sketch experiment (3 methods) | `src/octave/sketch_experiment.m`                                | Done                                                |
| Mixed-precision LS experiment         | `src/octave/mixedprec_experiment.m`, `src/octave/mixedprec.m`   | Done                                                |
| Simulated low-precision rounding      | `src/octave/fl_round.m`                                         | Done (double/single/half/bfloat16)                  |
| 3-method comparison driver            | `src/octave/compare_sketches.m`                                 | Done                                                |
| R package rSketchLS                   | `packages/rSketchLS/`                                           | Done: sketches, sketch_lstsq, experiments, 18 tests |

### Thesis text (partially written)

| Chapter                  | Status                                     | Gaps                                                                 |
| ------------------------ | ------------------------------------------ | -------------------------------------------------------------------- |
| Introduction             | Written                                    | Author/department/supervisor placeholders                            |
| Notation                 | Written                                    | Minor                                                                |
| Mathematical Background  | Thin — 21 lines, mostly forward references | Needs SVD, QR vs normal eqns, perturbation theory, condition numbers |
| Mixed Precision          | Written (6 sections)                       | Good                                                                 |
| Randomized Least Squares | Written with 6 formal propositions         | Reasonably complete                                                  |
| Numerical Experiments    | Framing written, no actual results         | Needs experiment specs, figures, tables                              |
| Climate Application      | Stub (9 lines)                             | Needs everything                                                     |
| Conclusion               | Written                                    | May need adjustment after experiments                                |

### Research literature

Three research runs completed in `research/runs/`. Key references already cited in `thesis/preamble/bibliography.bib`. Core surveys: Martinsson & Tropp (2020), Woodruff (2014), Higham & Mary (2022), Abdelfattah et al. (2021). Critical recent papers: Meier, Nakatsukasa & Townsend (2023) on stability of sketch-and-precondition, Epperly (2024) on forward-stable randomized LS, Carson & Higham & Pranesh (2020) on three-precision GMRES-LSIR, Gao & Ma & Shao (2025) on mixed-precision LS with constraints.

---

## Roadmap: Phase-by-Phase

### Phase 1 — Close the Theory Gap (MathematicalBackground + remaining theory)

**Goal**: The theory chapters must be self-contained and citable before the experiments chapter can reference them.

**Tasks**:

1. **Expand MathematicalBackground.tex** (currently 21 lines → target ~4–6 pages)
   - SVD, pseudoinverse, operator norm, condition number as amplification factor
   - Least-squares solution methods: normal equations vs QR vs SVD; their differing conditioning
   - Perturbation theory for LS: classical Wedin/Stewart results on how perturbations in A and b propagate; role of κ₂(A) and the residual size
   - Decision: should OSE definition and JL lemma live here (with ch:randls consuming them) or stay in ch:randls? Current placement is ch:randls (§4.2–4.3); recommend keeping them there since the OSE is a sketching-specific concept
   - Brief floating-point model recap specialized for the LS perturbation setting

2. **Complete RandomizedLeastSquares.tex** (already has 6 propositions)
   - §4.7 (From Embedding to Solver): currently prose only. Add formal statements for sketch-and-precondition paradigm, possibly as a remark linking to Blendenpik and Epperly (2024)
   - Add a remark on the gap between sketch-and-solve guarantees (Props 4.6–4.7) and what iterative refinement or preconditioning can achieve (forward/backward stability)
   - Add cross-references from the conditioning proposition (Prop 4.8) to the mixed-precision analysis in ch:mixedprecision

3. **Add mixed-precision + sketching coupled analysis**
   - Currently the thesis has mixed precision and sketching as separate chapters with only prose-level connection. Need at least one formal result that couples them:
     - Proposition: If S is a (d,ε,δ)-OSE and sketch formation is done in precision u_s, then the effective embedding distortion becomes ε + O(κ₂(A)·u_s·n)
     - This is the thesis's main theoretical contribution; even a conservative bound is valuable

**Research needed**:

- Wedin/Stewart perturbation bounds for LS (standard references: Stewart 1977, Wedin 1973, or the summary in Björck 1996)
- Existing coupled sketching+precision bounds: check if Carson/Oktay (2024) or Meier et al. (2023) already have something directly usable, or if the thesis needs to derive its own

**Deliverable**: Theory chapters in near-final draft form.

---

### Phase 2 — Systematic Numerical Experiments

**Goal**: Replace the current framing-only NumericalExperiments chapter with actual experimental results, figures, and interpretation.

**Experiment families** (ordered by thesis relevance):

#### Experiment 1 — Sketch-size sweep (Gaussian / Rademacher / SRHT)

- **Code**: `src/octave/compare_sketches.m`, `packages/rSketchLS/R/experiments.R`
- **Setup**: n=1024, d=20, s ∈ {30, 40, ..., 500}, trials=20, noise=0
- **Metrics**: residual ratio, solution error, κ₂(SA)
- **Question**: At what s does each sketch family achieve (1+ε) residual? How much larger must s be for SRHT vs Gaussian?
- **Expected**: Gaussian and Rademacher converge at similar rates; SRHT needs slightly larger s due to log n factor but is cheaper per sketch
- **Thesis section**: §6.2

#### Experiment 2 — Mixed-precision sketch formation

- **Code**: `src/octave/mixedprec_experiment.m` with `sketch_prec` ∈ {double, single, half, bfloat16}
- **Setup**: Same as Exp 1 but fix method=gaussian, s ∈ {40, 60, ..., 200}, solve_prec=double
- **Question**: At what precision does SA formation start to degrade the solution? Is single always safe? When does half fail?
- **Expected**: single is safe for well-conditioned A; half fails when κ₂(A) is large or s/d is small
- **Thesis section**: §6.3

#### Experiment 3 — Mixed-precision solve

- **Code**: `src/octave/mixedprec_experiment.m` with `solve_prec` ∈ {double, single}
- **Setup**: Same as Exp 2 but sketch_prec=double
- **Question**: Does solving the reduced system in single precision degrade the solution? Correlation with κ₂(SA)?
- **Expected**: Single-precision solve is safe when κ₂(SA) ≪ 1/u_single ≈ 10⁷; fails otherwise
- **Thesis section**: §6.4

#### Experiment 4 — Ill-conditioned problems

- **Code**: Generate A with prescribed κ₂ by SVD manipulation (set σ_min = σ_max / κ_target)
- **Setup**: κ_target ∈ {10², 10⁴, 10⁶, 10⁸}, n=1024, d=20, s=100, method=gaussian
- **Question**: How does conditioning interact with sketch quality and precision? Identify the regime where mixed precision is no longer safe.
- **Expected**: Phase transition — the method works well until κ₂(A)·u_s ≈ ε, after which both residual and solution error blow up
- **Thesis section**: §6.5

#### Experiment 5 — Iterative refinement after sketch-and-solve

- **Code**: New function `src/octave/iterative_refine.m` — compute high-precision residual, apply one correction step
- **Setup**: Same as Exp 2, but follow sketch-and-solve with 1–3 refinement steps
- **Question**: Can one or two refinement steps recover from half-precision sketch formation?
- **Expected**: Yes, if κ₂(A) is moderate; refinement dramatically reduces the residual gap
- **Thesis section**: §6.6

**New code needed**:

- `src/octave/generate_conditional.m` — generate A with prescribed κ₂
- `src/octave/iterative_refine.m` — sketch-and-solve + LSQR/refinement loop
- R equivalents in rSketchLS if time permits

**Deliverable**: NumericalExperiments chapter with figures, tables, and interpretation tied back to Props 4.6–4.8.

---

### Phase 3 — Climate-Model Application

**Goal**: Test whether the methods from Phases 1–2 survive in a realistic workflow.

**Approach**:

1. Use `src/MBC/` (multivariate bias correction) as the application anchor
2. Identify the linear-algebra bottleneck in MBC: typically a large least-squares or regression step
3. Replace that step with a sketched solve using rSketchLS or the Octave prototypes
4. Compare: accuracy of bias correction, runtime, memory

**Questions**:

- Does the sketched solver preserve the statistical quality of the bias correction?
- Is there a measurable computational gain for realistic climate-data sizes?
- Where does reduced precision fail in this workflow?

**Practical constraints**:

- Climate data is often moderate-sized (n ~ 10⁴–10⁵, d ~ 10–100), so the absolute speedup from sketching may be modest; the value may lie more in reduced memory or in demonstrating safe precision reduction
- Need real or realistic climate data — check if MBC package includes example datasets

**New code needed**:

- `src/octave/climate_sketch_demo.m` or an R script using rSketchLS + MBC
- Possible second R package `climateRandNLA` (optional, per roadmap)

**Deliverable**: ClimateApplication chapter (5–8 pages) with one focused case study.

---

### Phase 4 — Package Polish and Reproducibility

**Goal**: Make rSketchLS publication-quality and ensure all experiments are reproducible.

**Tasks**:

1. Add roxygen2 documentation to all rSketchLS functions
2. Add vignette demonstrating the main experiment families
3. Add `README.md` to rSketchLS
4. Ensure all Octave experiments run cleanly in the container (`make octave-test`)
5. Add `make r-test`, `make python-test` Makefile targets
6. Build and test Python + LaTeX containers
7. Save all experiment outputs (figures, tables) in a reproducible way
8. Update thesis `data.tex` with real author info

**Deliverable**: Clean, reproducible, documented codebase.

---

### Phase 5 — Thesis Write-Up and Submission

**Goal**: Complete manuscript.

**Tasks**:

1. Write/finalize all chapter text
2. Insert experiment figures and tables
3. Write climate application chapter
4. Write conclusion (adjust based on actual findings)
5. Fill in `data.tex` placeholders (author, department, study programme)
6. Full LaTeX build and proofread
7. Supervisor review and revision

**Deliverable**: Complete thesis manuscript.

---

## Timeline (Suggested)

Assuming a 2026 submission deadline:

| Phase                   | Duration  | Target completion |
| ----------------------- | --------- | ----------------- |
| Phase 1: Theory         | 2–3 weeks | Early June 2026   |
| Phase 2: Experiments    | 3–4 weeks | Late June 2026    |
| Phase 3: Climate app    | 1–2 weeks | Mid July 2026     |
| Phase 4: Package polish | 1 week    | Late July 2026    |
| Phase 5: Write-up       | 2–3 weeks | Mid August 2026   |

---

## Research To-Do

### Must-read papers (not yet fully digested)

1. **Meier, Nakatsukasa, Townsend (2023)** — "Are sketch-and-precondition least squares solvers numerically stable?" — Critical for Phase 1 §4.7 and Phase 2 Exp 5
2. **Epperly (2024)** — "Fast and forward stable randomized algorithms for linear least-squares problems" — Forward stability of iterative sketching; may supersede some of the sketch-and-solve analysis
3. **Carson, Oktay (2024)** — "Mixed precision FGMRES-based iterative refinement for weighted least squares" — Directly relevant to mixed-precision LSIR
4. **Carson, Higham, Pranesh (2020)** — "Three-precision GMRES-based iterative refinement for least squares problems" — Already cited but needs deeper reading for Phase 1 coupled analysis
5. **Gao, Ma, Shao (2025)** — "Mixed precision iterative refinement for least squares with constraints" — Newest; check for relevant bounds

### Must-derive / must-present

1. **Coupled sketching+precision proposition** (Phase 1 task 3) — The thesis's main theoretical contribution. Need to bound the effective distortion when sketch formation is inexact.
2. **Conditioning of SA under precision perturbation** — Extension of Prop 4.8 to the case where SA = fl(S·A) ≠ S·A. This connects ch:randls to ch:mixedprecision formally.

### Should-scan literature

- Sparse Johnson–Lindenstrauss transforms (Kane & Nelson 2014) — if thesis wants to mention sparse sketches
- CountSketch for LS (Clarkson & Woodruff 2013) — foundational for OSE theory with sparse matrices
- Randomized QR factorization (Martinsson et al.) — alternative to sketch-and-solve for low-rank structure
- Low-rank + sketch interaction — if climate data turns out to have approximate low-rank structure

---

## Open Decisions

1. **Where to put OSE/JL definitions**: Currently in ch:randls. Could move to ch:background. Recommend keeping in ch:randls since they are sketching-specific, but add a forward reference in ch:background.
2. **Second R package (climateRandNLA)**: Optional. May not be worth the packaging overhead if the application chapter stays focused. Decide after Phase 3.
3. **Python notebook status**: `notebooks/rNLA.ipynb` has early exploratory work using PyTorch. Should this be kept, migrated to R/Octave, or frozen as-is? Recommend freezing — the thesis implementations are in R and Octave.
4. **Scope of iterative refinement in experiments**: Exp 5 could range from a single correction step to full LSQR-based refinement. Start simple (one step), expand if time allows.
5. **Climate data source**: Need to identify whether MBC package ships example data, or if we need external data. This affects Phase 3 feasibility.
