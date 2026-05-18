# Experiments

This directory contains runnable benchmark and experiment scripts that connect thesis code to thesis-ready result tables.

- `benchmark_randmbc.R`
  First benchmark slice for issue `#13`: compares a deterministic full covariance-transport baseline, selected `src/MBC` references (`MBCp`, `MBCr`), and the randomized `randMBC` backend on synthetic climate-shaped data. Writes a raw CSV, a summary CSV, and a PDF of quick comparison plots under `experiments/output/`.

- `randmbc_benchmark_helpers.R`
  Shared helpers for synthetic data generation, deterministic covariance transport, `src/MBC` reference fits, diagnostics, plotting, and result-table assembly.

Generated outputs should be written under `experiments/output/`, which is ignored by git.
