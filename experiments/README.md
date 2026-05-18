# Experiments

This directory contains runnable benchmark and experiment scripts that connect thesis code to thesis-ready result tables.

- `randmbc_synthetic_validation.R`
  Synthetic latent-data validation for issue `#28`: compares full covariance transport against randomized covariance transport in double and simulated single precision across several spectral regimes. It also compares independent source/target low-rank subspaces against a joint reduced basis shared by both covariance operators. Writes machine-readable outputs under `results/` and figures under `figures/`.

- `benchmark_randmbc.R`
  First benchmark slice for issue `#13`: compares a deterministic full covariance-transport baseline, selected `src/MBC` references (`MBCp`, `MBCr`), and the randomized `randMBC` backend on synthetic climate-shaped data. Writes a raw CSV, a summary CSV, and a PDF of quick comparison plots under `experiments/output/`.

- `randmbc_benchmark_helpers.R`
  Shared helpers for synthetic data generation, deterministic covariance transport, `src/MBC` reference fits, diagnostics, plotting, and result-table assembly.

Legacy benchmark outputs from `benchmark_randmbc.R` are written under `experiments/output/`, which is ignored by git.

The focused covariance-transport validation writes its reproducible tables under `results/` and its figures under `figures/`. In addition to the raw CSV/RDS outputs, it writes an aggregated summary CSV keyed by spectral regime, basis mode, rank, oversampling, lambda, and precision. Its purpose is to identify regimes in which randomized covariance transport may become credible, rather than to force an immediate win-or-loss comparison against the deterministic baseline.

To rerun the focused covariance-transport validation from the repository root:

- `Rscript experiments/randmbc_synthetic_validation.R`
