# Thesis Roadmap

## Working Title

Randomized Numerical Linear Algebra in Mixed Precision, with an Application to Climate Models

## Scope

This thesis should be centered on the mathematics and numerics of randomized numerical linear algebra, not on climate science itself.

Primary topics:

- randomized sketching and subspace embeddings
- randomized least-squares methods
- structured random transforms such as SRHT
- mixed-precision arithmetic and numerical stability

Secondary topic:

- climate-model bias correction as an application domain, especially where randomized transforms or large linear-algebra workloads appear

## Current Situation

What already exists in the repo:

- exploratory notebook work on random projections and randomized least squares
- a MATLAB randomized least-squares experiment
- external reference packages `rSVD` and `MBC`
- literature collection
- thesis LaTeX infrastructure

What is missing:

- a clear mathematical analysis backlog
- reproducible benchmark suites
- package-quality implementations of the thesis methods
- a clean separation between core methods and application code
- an actual manuscript outline mapped to completed work

## Thesis Questions

The work should answer some combination of these questions:

1. Which randomized sketching methods are most suitable for overdetermined least-squares problems in this project?
2. How do Gaussian and structured sketches compare in accuracy, conditioning, and computational cost?
3. Which parts of these algorithms tolerate lower precision well, and which parts do not?
4. Does mixed precision give a real advantage in runtime, memory footprint, or scalability for the targeted problem sizes?
5. How do these methods transfer to a climate-model application setting?

## Workstreams

### 1. Mathematical Background

This is currently underdeveloped and should be built deliberately.

Minimum theory backlog:

- least-squares problems and normal equations
- QR-based least-squares solvers
- subspace embeddings
- Johnson-Lindenstrauss style norm preservation
- sketched least squares and residual guarantees
- Gaussian sketches
- SRHT / structured sketches
- basic floating-point model
- mixed-precision error propagation
- conditioning of sketched systems

Deliverables:

- a written theory outline
- a list of lemmas/theorems to include in the thesis
- explicit links between each theorem and the numerical experiments that test it

### 2. Numerical Experiments

Convert exploratory notebook work into reproducible studies.

Core experiment families:

- norm preservation under random projection
- consistent least-squares systems
- noisy/inconsistent least-squares systems
- error and residual as functions of sketch size `s`
- conditioning of `SA`
- Gaussian vs SRHT
- precision sweep: `float64`, `float32`, and lower precision where feasible
- mixed-precision placement studies:
  - sketch generation precision
  - sketched matrix multiplication precision
  - least-squares solve precision
  - iterative refinement or high-precision correction

Metrics:

- relative residual
- solution error
- condition number
- runtime
- memory usage if measurable
- failure/instability regimes

### 3. R Package Development

The thesis should likely produce one or more original R packages, not just notebooks.

Recommended packaging strategy:

#### Package A: core randNLA methods

Purpose:

- implement the thesis algorithms cleanly in R
- expose a stable interface for experiments and examples

Candidate functionality:

- Gaussian sketch generator
- SRHT sketch generator
- sketched least-squares solver
- mixed-precision variants or precision-control interface
- benchmark helpers
- diagnostics for residuals and conditioning

Possible names:

- `rSketchLS`
- `mpRandNLA`
- `rMixedSketch`

#### Package B: climate-facing application layer

Purpose:

- apply or integrate the methods in a climate-model workflow
- keep application logic separate from core math kernels

This package could:

- wrap selected `MBC` workflows
- add accelerated solvers or randomized preprocessing
- benchmark whether the randNLA methods help in realistic climate tasks

This second package may turn out to be too much for the thesis timeline, so it should be treated as optional unless the application work becomes central.

### 4. Climate Application

Use `src/MBC/` as the application anchor.

Possible roles for the application chapter:

- show where random transformations already appear in climate workflows
- identify linear-algebra bottlenecks or scaling issues
- test whether the new package is useful in a realistic setting
- discuss practical gains even if they are not purely speed gains

Important: the application does not need to show a dramatic speedup to be valuable. Other legitimate outcomes include:

- reduced memory use
- acceptable accuracy at lower precision
- improved scalability for larger problems
- better understanding of where mixed precision fails
- evidence that structured sketches are competitive with Gaussian ones

## Recommended Milestones

### Milestone 1: Theory Inventory

- assemble the exact mathematical statements the thesis needs
- identify missing proofs/derivations
- map literature to thesis sections

### Milestone 2: Benchmark Cleanup

- extract notebook experiments into reproducible scripts/functions
- standardize metrics and datasets
- save plots and tables systematically

### Milestone 3: First R Package

- create package skeleton
- implement sketch generators and least-squares routines
- add tests against trusted reference solvers
- add simple benchmarks

### Milestone 4: Mixed-Precision Study

- design precision variants
- quantify tradeoffs
- identify numerically safe and unsafe regimes

### Milestone 5: Climate Application

- define one focused application question
- integrate the core package with climate-side workflow
- evaluate practical benefit or limitation

### Milestone 6: Thesis Write-Up

- write theory and methods chapters from the stabilized package/benchmark code
- write application chapter last

## Suggested Immediate Next Steps

1. Decide the first original R package name and scope.
2. Extract the notebook's randomized least-squares code into plain functions.
3. Write a short theory note listing the exact results you need for sketching and mixed precision.
4. Define the first benchmark matrix families and metric suite.
5. Delay the broader climate integration until the core method package is stable.

## Suggested Thesis Chapter Structure

1. Introduction
2. Mathematical Background
3. Randomized Sketching Methods
4. Mixed-Precision Arithmetic and Error Analysis
5. Randomized Least Squares in Mixed Precision
6. Numerical Experiments
7. Climate-Model Application
8. Conclusion

## Repository Gaps To Address Soon

- the root `README.md` was missing the actual project narrative
- there is no dedicated package directory yet for original R code
- the current `thesis/` directory is still mainly template content
- mixed-precision experiments are not yet clearly separated from general randNLA experiments

## Recommended Directory Evolution

One reasonable next structure is:

```text
docs/
  thesis-roadmap.md
  theory-notes.md
notebooks/
  rNLA.ipynb
  mixed-precision.ipynb
src/
  randLS.m
packages/
  rSketchLS/
  climateRandNLA/   # optional later
thesis/
  ...
```
