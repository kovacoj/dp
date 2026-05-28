# Repository Map

This repository is the working workspace for the diploma thesis
_Randomized Numerical Linear Algebra in Mixed Precision, with an Application to Climate Models_.
The main conceptual center is randomized least squares, randomized covariance operators,
and mixed-precision error analysis; climate-model post-processing is the downstream
application layer.

## Status Legend

- `[done]` implemented and already used in the thesis or experiments
- `[wip]` implemented in part, but still being hardened or integrated
- `[todo]` planned but not yet fully realized in code or manuscript

## Packages

### `packages/rSketchLS/` `[done]`

Original thesis R package for randomized least-squares experiments.

| File                                       | Role                                                                                                 | Status   |
| ------------------------------------------ | ---------------------------------------------------------------------------------------------------- | -------- |
| `R/sketches.R`                             | Dense Gaussian and Rademacher sketches plus SRHT construction helpers.                               | `[done]` |
| `R/sketch_ls.R`                            | Core sketch-and-solve least-squares routine for vector right-hand sides.                             | `[done]` |
| `R/experiments.R`                          | Repeated synthetic LS experiment driver over sketch-size sweeps.                                     | `[done]` |
| `R/fl_round.R`                             | Simulated floating-point rounding for double, single, half, and bfloat16.                            | `[done]` |
| `R/generate_conditional.R`                 | Synthetic matrix generator with controlled singular spectrum and condition number.                   | `[done]` |
| `R/iterative_refine.R`                     | Sketch-and-solve with residual correction / iterative refinement.                                    | `[done]` |
| `R/sketch_lstsq_mixed.R`                   | Mixed-precision sketch-and-solve for vector or matrix right-hand sides.                              | `[done]` |
| `R/sketch_lstsq_multi.R`                   | Matrix-RHS sketched least-squares solver.                                                            | `[done]` |
| `R/sketch_lstsq_experiment_multi.R`        | Repeated matrix-RHS experiment driver; writes `config.yaml`, `trial_metrics.csv`, and `summary.csv`. | `[done]` |
| `tests/testthat/test-sketches.R`           | Unit tests for sketch generators.                                                                    | `[done]` |
| `tests/testthat/test-sketch_lstsq_multi.R` | Tests for matrix-RHS and experiment output contract.                                                 | `[done]` |

### `packages/randMBC/` `[wip]`

Original thesis R package for randomized covariance transport in multivariate bias correction.

| File                            | Role                                                                                                                                                 | Status   |
| ------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | -------- |
| `R/rand_mbc.R`                  | Top-level `fit_rand_mbc()` pipeline: QDM marginals, latent transform, randomized covariance approximation, transport, rank restoration, diagnostics. | `[wip]`  |
| `R/precision_model.R`           | Precision-model abstraction, unit roundoff table, sketch-product forward-error bounds, and hidden-floating-point checks.                             | `[done]` |
| `R/problem_ensemble.R`          | Synthetic covariance generators: analytic spectra and climate-shaped covariance ensembles.                                                           | `[done]` |
| `R/sketch_operator.R`           | Sketch-operator abstraction for Gaussian, Rademacher, and SRHT application.                                                                          | `[done]` |
| `R/covariance_approximation.R`  | Randomized low-rank covariance approximation and covariance-action helpers.                                                                          | `[done]` |
| `R/covariance_transport.R`      | Regularized covariance transport map and symmetric matrix-function helper.                                                                           | `[done]` |
| `R/latent_dependence.R`         | Latent Gaussianization and rank restoration utilities.                                                                                               | `[done]` |
| `R/marginal_adjustment.R`       | QDM-style marginal adjustment for additive and ratio-style variables.                                                                                | `[done]` |
| `R/latent_rank_normalize.R`     | Exported latent rank-normalization and marginal restoration utilities.                                                                               | `[done]` |
| `R/diagnostics.R`               | Result summarization, floating-point hiding checks, CSV IO helpers.                                                                                  | `[done]` |
| `R/experiment_runner.R`         | Trial and sweep drivers for covariance-transport parameter studies.                                                                                  | `[done]` |
| `R/fl_round.R`                  | Simulated lower-precision rounding model used across experiments.                                                                                    | `[done]` |
| `tests/testthat/test-randMBC.R` | Package-level tests for the current randomized bias-correction backend.                                                                              | `[wip]`  |

## Key Directories

| Directory      | Purpose                                                                                                                 | Status   |
| -------------- | ----------------------------------------------------------------------------------------------------------------------- | -------- |
| `notebooks/`   | Early exploratory Python work; `rNLA.ipynb` is a frozen exploratory record rather than the main implementation surface. | `[done]` |
| `src/octave/`  | Thesis-owned Octave prototypes for sketching, conditioning, mixed precision, and timing studies.                        | `[done]` |
| `literature/`  | Local paper library and human-readable literature index.                                                                | `[wip]`  |
| `thesis/`      | LaTeX manuscript, chapter files, bibliography, and thesis metadata.                                                     | `[wip]`  |
| `containers/`  | Docker-based Python, R, Octave, and LaTeX environments.                                                                 | `[done]` |
| `experiments/` | Runnable benchmark and validation scripts connecting code to thesis-ready outputs.                                      | `[wip]`  |
| `results/`     | Reproducible result tables from focused validation runs.                                                                | `[wip]`  |

## Octave Prototype Surface

| File                      | Role                                            | Status   |
| ------------------------- | ----------------------------------------------- | -------- |
| `randLS.m`                | Gaussian sketched LS helper.                    | `[done]` |
| `randLS_experiment.m`     | Gaussian LS prototype experiment.               | `[done]` |
| `srht.m`                  | SRHT sketch helper.                             | `[done]` |
| `srht_experiment.m`       | SRHT least-squares prototype.                   | `[done]` |
| `rademacher.m`            | Rademacher sketch helper.                       | `[done]` |
| `rademacher_experiment.m` | Rademacher LS prototype.                        | `[done]` |
| `sketch_experiment.m`     | Unified sketch experiment scaffold.             | `[done]` |
| `compare_sketches.m`      | Three-method comparison over sketch sizes.      | `[done]` |
| `mixedprec.m`             | Mixed-precision least-squares helper.           | `[done]` |
| `mixedprec_experiment.m`  | Mixed-precision sketch-formation / solve study. | `[done]` |
| `generate_conditional.m`  | Controlled-conditioning generator.              | `[done]` |
| `exp4_conditioning.m`     | Ill-conditioned synthetic LS experiment.        | `[done]` |
| `iterative_refine.m`      | Refinement helper.                              | `[done]` |
| `exp5_refinement.m`       | Refinement experiment after sketch-and-solve.   | `[done]` |
| `bench_sketch.m`          | Sketch-cost benchmarking helper.                | `[done]` |
| `bench_timing.m`          | Timing benchmark driver.                        | `[done]` |
| `fl_round.m`              | Simulated reduced-precision rounding.           | `[done]` |

## Existing Experiment Scripts

| Script                                       | Role                                                                                                               | Status   |
| -------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ | -------- |
| `experiments/cov_transport_sweep.R`          | Synthetic covariance-transport sweeps over spectrum type, rank, lambda, sketch, and precision.                     | `[done]` |
| `experiments/randmbc_synthetic_validation.R` | Focused validation of randomized covariance transport against full transport in synthetic latent regimes.          | `[done]` |
| `experiments/benchmark_randmbc.R`            | First benchmark slice against deterministic full transport and vendored `MBC` references.                          | `[wip]`  |
| `experiments/randmbc_benchmark_helpers.R`    | Synthetic climate data generator, deterministic baseline, vendored `MBC` adapters, metrics, plots, summary output. | `[done]` |

## Chapter to Script Mapping

| Thesis chapter                      | Main code / scripts feeding it                                                                                                                                                                                            | Status   |
| ----------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- |
| `MathematicalBackground.tex`        | No direct experiment feed; supported indirectly by `rSketchLS` and Octave conditioning prototypes.                                                                                                                        | `[todo]` |
| `MixedPrecision.tex`                | `src/octave/mixedprec_experiment.m`, `src/octave/exp5_refinement.m`, `packages/rSketchLS/R/sketch_lstsq_mixed.R`, `packages/rSketchLS/R/iterative_refine.R`, `packages/randMBC/R/precision_model.R`.                      | `[wip]`  |
| `RandomizedLeastSquares.tex`        | `src/octave/compare_sketches.m`, `src/octave/sketch_experiment.m`, `packages/rSketchLS/R/experiments.R`, `packages/rSketchLS/R/sketch_lstsq_experiment_multi.R`.                                                          | `[done]` |
| `NumericalExperiments.tex`          | `experiments/cov_transport_sweep.R`, `experiments/randmbc_synthetic_validation.R`, `experiments/benchmark_randmbc.R`, plus LS drivers from `rSketchLS` and `src/octave/`.                                                 | `[wip]`  |
| `RandomizedCovarianceTransport.tex` | `packages/randMBC/R/covariance_approximation.R`, `packages/randMBC/R/covariance_transport.R`, `packages/randMBC/R/problem_ensemble.R`, `experiments/cov_transport_sweep.R`, `experiments/randmbc_synthetic_validation.R`. | `[wip]`  |
| `ClimateApplication.tex`            | `packages/randMBC/R/rand_mbc.R`, `experiments/benchmark_randmbc.R`, vendored `src/MBC/` baselines, planned real-data smoke test under `data/raw/central_europe/`.                                                         | `[wip]`  |
| `Conclusion.tex`                    | Draws from all experiment families once results stabilize.                                                                                                                                                                | `[todo]` |

## Reconstructed Experiment Program (01-09)

The roadmap and current code imply the following thesis experiment progression.

| Script                            | Purpose                                                                               | Main implementation anchors                                                            | Status   |
| --------------------------------- | ------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------- | -------- |
| `01_freeze_baseline`              | Freeze repo/package/thesis baseline and record reproducibility metadata.              | `git`, package checks, thesis build, output contract.                                  | `[todo]` |
| `02_ls_sketch_sweep`              | Gaussian/Rademacher/SRHT sketch-size sweep for synthetic least squares.               | `packages/rSketchLS/R/experiments.R`, `src/octave/compare_sketches.m`.                 | `[done]` |
| `03_ls_mixed_sketch_precision`    | Mixed-precision sketch-formation sweep.                                               | `packages/rSketchLS/R/sketch_lstsq_mixed.R`, `src/octave/mixedprec_experiment.m`.      | `[done]` |
| `04_ls_mixed_solve_precision`     | Reduced-system solve precision sweep.                                                 | `packages/rSketchLS/R/sketch_lstsq_mixed.R`, `src/octave/mixedprec_experiment.m`.      | `[done]` |
| `05_ls_conditioning_sweep`        | Controlled-condition-number LS study.                                                 | `packages/rSketchLS/R/generate_conditional.R`, `src/octave/exp4_conditioning.m`.       | `[done]` |
| `06_ls_refinement`                | Iterative refinement after sketch-and-solve.                                          | `packages/rSketchLS/R/iterative_refine.R`, `src/octave/exp5_refinement.m`.             | `[done]` |
| `07_cov_transport_synthetic`      | Synthetic covariance-transport sweeps over spectrum, rank, lambda, sketch, precision. | `experiments/cov_transport_sweep.R`, `packages/randMBC/R/experiment_runner.R`.         | `[done]` |
| `08_cov_transport_climate_shaped` | Climate-shaped synthetic covariance validation and joint-vs-independent basis study.  | `experiments/randmbc_synthetic_validation.R`, `packages/randMBC/R/problem_ensemble.R`. | `[done]` |
| `09_climate_smoke_test`           | Real-data smoke test using CCCma fallback or future Central Europe data.              | `experiments/benchmark_randmbc.R`, `packages/randMBC/R/rand_mbc.R`, `src/MBC/`.        | `[wip]`  |

## Current Done / In Progress / TODO Snapshot

### Done

- Octave least-squares sketching prototypes exist for Gaussian, Rademacher, and SRHT.
- Mixed-precision and refinement prototype paths exist in Octave and `rSketchLS`.
- `rSketchLS` supports vector RHS, matrix RHS, mixed precision, conditioning studies, and experiment outputs.
- `randMBC` supports randomized covariance approximation, covariance transport, synthetic operator ensembles, and benchmark helpers.
- Synthetic covariance-transport sweeps and focused randomized-transport validation scripts already run and write machine-readable outputs.
- Core thesis chapters for mixed precision, randomized least squares, and covariance transport are drafted.

### In Progress

- Numerical-experiments chapter still needs final tables, figures, and cleaned interpretation.
- `randMBC` diagnostics and benchmark comparison surface are usable but still being hardened.
- Climate application is currently a smoke-test / benchmark stage, not yet a full case study.
- Reproducibility conventions across all experiments are converging but not yet fully uniform.

### TODO

- Add a single standardized 01-09 script layer under `experiments/` with shared output contract.
- Add real Central Europe climate data and metadata once available.
- Finish the mathematical background chapter and tighten theorem-to-experiment crosswalks.
- Promote the climate chapter from stub/smoke-test status to a supervisor-ready case study.
- Consolidate figures and tables into thesis-ready assets under a stable naming convention.
