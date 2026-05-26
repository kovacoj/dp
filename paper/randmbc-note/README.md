# randMBC Supervisor Note

This directory contains a short standalone note on `randMBC` intended for supervisor review.

The note is written in the same mathematical and expository style as the thesis, so that it can later be folded into the thesis with minimal rewriting. It should be read as a narrow project note rather than as package documentation.

Current draft:

- `paper.tex`
- `chapters/Paper.tex`

Compatibility wrapper:

- `randmbc-note.tex`

Related code and results:

- `packages/randMBC/`
- `experiments/randmbc_synthetic_validation.R`
- `results/randmbc_synthetic_validation.csv`
- `results/randmbc_synthetic_validation.rds`
- `results/randmbc_synthetic_validation_summary.csv`
- `figures/randmbc_cov_error_vs_rank.pdf`
- `figures/randmbc_transport_error_vs_rank.pdf`
- `experiments/benchmark_randmbc.R`
- `experiments/output/randmbc-benchmark.csv`
- `experiments/output/randmbc-benchmark-summary.csv`
- `experiments/output/randmbc-benchmark-plots.pdf`

Build from inside this directory with:

```sh
latexmk paper
```
