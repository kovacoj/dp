# R Package Ecosystem Survey

This document tracks R packages and method families that may be relevant
benchmarks for `randMBC`. `MBC` is the first reference package because it is
directly tied to multivariate climate bias correction, but the benchmark
ecosystem is broader than a single package.

The thesis framing is:

> Develop and analyze a randomized mixed-precision covariance/dependence
> correction method, implement it as an R package, and benchmark it against
> relevant existing R packages where appropriate.

The survey distinguishes three layers:

- Marginal correction: univariate distribution adjustment.
- Dependence correction: multivariate rank, correlation, covariance, or
  transport adjustment.
- Computational bottleneck: the operation where randomized or mixed-precision
  numerical linear algebra could plausibly help.

## Candidate Packages and Method Families

| Package or family | Main methods | Input/output shape | Marginal correction | Dependence correction | Covariance/correlation used | Rank reordering used | Computational bottleneck | Meaningful benchmark for randMBC? | Benchmark plan | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `MBC` | QDM, MBCp, MBCr, MBCn, R2D2 | Historical model, future model, historical reference panels | QDM-style univariate correction | Pearson/Spearman correlation matching, multivariate transform, rank resampling | Yes for MBCp/MBCr-style dependence targets | Yes in rank-based methods and R2D2-style restoration | Iterative multivariate dependence correction and repeated transforms | Yes, first baseline | Compare statistical diagnostics and runtime against QDM-only, MBCp/MBCr/MBCn where feasible | Reference package already vendored in `src/MBC/`; not the only target |
| Quantile-mapping packages | Empirical or parametric quantile mapping | Usually univariate or variable-wise panels | Primary focus | Usually none or limited | Usually no | Sometimes | Sorting, interpolation, distribution fitting | Partial | Use as marginal-only baselines if package interfaces fit the data | Useful to isolate whether dependence correction adds value |
| Climate post-processing packages | Bias correction, downscaling, ensemble calibration | Climate station/grid time series | Often yes | Varies by package | Varies | Varies | Data reshaping, distribution fitting, repeated calibration | Maybe | Survey package-by-package before adopting | Candidate set should be expanded from literature review |
| Dependence/rank-reordering packages | Schaake shuffle, rank resampling, copula-like corrections | Multivariate samples | Usually external | Rank/dependence restoration | Sometimes via correlation targets | Yes | Sorting and rank assignment | Maybe | Compare final dependence diagnostics if methods expose suitable APIs | Good conceptual comparison for rank-restoration step |
| Covariance/correlation alignment tools | Whitening/coloring, covariance matching, Procrustes-like transforms | Numeric matrices or latent panels | No | Linear covariance alignment | Yes | No by default | Covariance formation, eigendecomposition, matrix square roots | Yes if APIs are usable | Compare full covariance transport with randomized low-rank transport | Closest numerical-linear-algebra baseline |
| Randomized matrix packages | Randomized SVD/eigendecomposition | Numeric matrices | No | No direct climate correction | Supports covariance approximation | No | Matrix products and small decompositions | Indirect | Use as backend/reference for covariance approximation quality | Includes packages such as `rSVD` already present as reference material |

## Benchmark Relevance

A package is a strong benchmark target when it satisfies at least one of these
conditions:

- It performs both marginal and dependence correction on multivariate climate
  data.
- It exposes a dependence-correction step that can be compared with randomized
  covariance transport.
- It provides a full deterministic covariance/correlation baseline.
- It provides a marginal-only baseline that helps isolate the value of
  dependence correction.

Packages are weak benchmark targets when they only solve unrelated
post-processing tasks, require incompatible data layouts, or do not expose enough
diagnostics to compare dependence behavior.

## Diagnostics to Record

For each adopted benchmark, record:

- Marginal quantile error.
- Pearson and Spearman correlation error.
- Energy score or another multivariate distributional score when feasible.
- Spatial or temporal dependence diagnostics when the data layout supports them.
- Runtime and memory estimates.
- Failure modes, including singular covariance estimates, unstable transforms,
  and sensitivity to sample size.

## Open Survey Tasks

- Add concrete package candidates from climate post-processing literature.
- Check installation and license constraints for each candidate.
- Record minimal runnable examples for the packages that remain viable.
- Decide which baselines belong in the thesis experiments and which remain
  background context.
