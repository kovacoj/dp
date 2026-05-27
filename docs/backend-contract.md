# Backend Contract

This document states the mathematical contract shared by the thesis text,
`randMBC`-style implementations, and any future R, MATLAB, Python, or Rust
backends.

The backend is not merely an implementation detail for the `MBC` package. It is
an implementation layer for the thesis method:

> randomized mixed-precision covariance transport for multivariate dependence
> correction.

## Core Mathematical Objects

Historical model, future model, and historical reference data are first mapped
to a latent dependence representation. In that space, let

```text
Z_X in R^{n x p}
Z_Y in R^{n x p}
Z_f in R^{m x p}
```

where `Z_X` is the corrected historical model latent panel, `Z_Y` is the
reference latent panel, and `Z_f` is the future model latent panel.

The empirical covariance operators are

```text
C_X = (1 / n) Z_X^T Z_X
C_Y = (1 / n) Z_Y^T Z_Y
```

For a regularization parameter `lambda > 0`, define

```text
A_lambda = C_X + lambda I
B_lambda = C_Y + lambda I
T_lambda = A_lambda^{-1/2} B_lambda^{1/2}
```

The corrected latent future data are

```text
Z_f,corr = Z_f T_lambda
```

Backends approximate this operation.

## Approximation Contract

A backend may use randomized low-rank approximation, lower precision arithmetic,
or both. Its computed covariance approximation must be interpretable as

```text
C_hat = C + E_rand + E_fp
```

where:

- `E_rand` is randomized approximation or truncation error.
- `E_fp` is finite-precision arithmetic error.

The corresponding approximate transport is

```text
T_hat_lambda =
  (C_hat_X + lambda I)^{-1/2}
  (C_hat_Y + lambda I)^{1/2}
```

The thesis theory and experiments evaluate

```text
||T_lambda - T_hat_lambda||_2
||Z_f T_lambda - Z_f T_hat_lambda||_F
```

and relate these errors to rank, oversampling, regularization, spectra, and unit
roundoff.

## Backend Responsibilities

Every backend should expose or record:

- Input dimensions `n`, `m`, and `p`.
- Target rank and oversampling.
- Sketch family and random seed.
- Regularization parameter `lambda`.
- Precision format by arithmetic stage.
- Rounding mode when applicable.
- Whether the full covariance was formed.
- Estimated condition numbers or smallest eigenvalues of regularized operators.
- Covariance approximation error when a reference is available.
- Transport error when a reference is available.
- Runtime and memory estimates.

## Required Invariants

Backends must preserve these invariants:

- `lambda > 0` whenever an inverse square root is computed.
- The returned transform maps `p` latent variables to `p` latent variables.
- The corrected latent matrix has the same shape as the future latent input.
- Randomized runs are reproducible from recorded seeds.
- Lower-precision results remain diagnosable against a double-precision
  reference for small and medium test cases.

## Benchmark Role

Benchmarks should test the theorem structure, not only runtime. A useful
benchmark varies:

- rank, to change randomized approximation error;
- precision, to change finite-precision error;
- `lambda`, to change inverse-square-root conditioning;
- covariance spectrum, to change problem difficulty;
- sample size and feature dimension, to change accumulation and memory cost.

The expected interpretation is regime-based. Lower precision is useful when
finite-precision error is hidden by randomized approximation or statistical
tolerance. It is unsafe when rounding error is amplified by ill-conditioned
regularized inverse square roots.
