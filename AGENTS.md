# Thesis Context

This repository is the workspace for a diploma thesis on randomized numerical linear algebra and mixed-precision arithmetic, with climate-model workflows as a later application rather than the main theoretical focus.

## Main Thesis Direction

The thesis is centered on the mathematical and numerical side of:

- randomized sketching
- randomized least squares
- structured random transforms such as SRHT
- mixed-precision arithmetic
- stability, conditioning, accuracy, and performance tradeoffs

The climate-model material is important, but it is the downstream application layer, not the conceptual center of the work.

## Intended Thesis Framing

Working title:

Randomized Numerical Linear Algebra in Mixed Precision, with an Application to Climate Models

The broad thesis arc is:

1. mathematical background and theory
2. randomized algorithms for linear algebra problems
3. mixed-precision analysis and experiments
4. implementation in original R packages
5. climate-model application at the end

## Current State

The repository already contains:

- exploratory notebook work on randomized numerical linear algebra
- a MATLAB/Octave least-squares experiment
- external reference packages for randNLA and climate bias correction
- literature PDFs
- a LaTeX thesis template based on TeXtured
- a containerized development setup for Python, R, Octave, and LaTeX

The repository does not yet contain a finished mathematical analysis or a finished thesis manuscript.

## Important Topics

Primary topics:

- overdetermined least-squares problems
- subspace embeddings
- Gaussian sketches
- structured sketches
- residual and solution-error behavior
- conditioning of sketched systems
- floating-point and mixed-precision effects

Secondary/application topics:

- multivariate climate-model bias correction
- randomized transformations in climate workflows
- practical computational gains or limits in application settings

## Key Directories

- `notebooks/`
  Exploratory Python work, currently the clearest record of ongoing randNLA experiments.

- `src/octave/`
  Thesis-owned MATLAB/Octave prototypes, experiment drivers, and helpers for randomized least-squares and mixed-precision experiments.

- `src/rSVD/`
  External R package for randomized matrix decompositions. This is background and reference material, not the main original contribution.

- `src/MBC/`
  External R package for multivariate climate-model bias correction. This is the main application-side reference.

- `packages/rSketchLS/`
  Initial scaffold for the first original R package meant to hold thesis algorithms.

- `literature/`
  Papers and reference material related to randNLA and adjacent methods.

- `thesis/`
  Thesis manuscript infrastructure based on the TeXtured LaTeX template.

- `containers/`
  Docker-based development environments for Python, R, Octave, and LaTeX.

## Planned Outputs

The thesis should eventually produce:

- a mathematical treatment of the chosen randomized methods
- reproducible numerical experiments
- at least one original R package implementing the core methods
- an evaluation of mixed-precision tradeoffs
- a focused climate-model application chapter or case study

## Current Open Gaps

The largest missing pieces are:

- mathematical background write-up
- explicit theorem/proof inventory
- benchmark cleanup and standardization
- package-quality implementation beyond the current scaffold
- actual thesis text replacing the template/manual content

## Application Role of Climate Models

Climate-model code and references are here to support the final application phase of the thesis.

The main role of this application is to test whether the randomized and mixed-precision methods are useful in a realistic workflow. Useful outcomes are not limited to raw speedup; they may also include reduced memory use, acceptable lower-precision behavior, or clearer understanding of failure regimes.
