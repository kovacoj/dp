# Diploma Thesis Workspace

This repository is the working directory for a diploma thesis on randomized numerical linear algebra and mixed-precision arithmetic, with a climate-model application as a later case study.

## Current Focus

The main mathematical and numerical themes are:

- randomized sketching for linear algebra problems
- randomized least squares
- structured sketches such as SRHT
- mixed-precision effects on stability, accuracy, and speed

The climate-model material is important, but it is an application target rather than the conceptual center of the thesis.

## Repository Map

- `notebooks/`
  Exploratory Python notebooks for randomized numerical linear algebra experiments.

- `src/randLS.m`
  MATLAB experiment for randomized least squares with higher-precision arithmetic.

- `src/rSVD/`
  External R package implementing randomized low-rank matrix decompositions. Useful as background and reference material.

- `src/MBC/`
  External R package for multivariate climate-model bias correction. This is the main application-side reference.

- `literature/`
  Papers and reference material for randNLA and related methods.

- `styles/`
  Plot styling resources.

- `thesis/`
  LaTeX thesis infrastructure. At the moment this is still mostly the upstream template and needs to be adapted into the actual manuscript.

## Near-Term Goals

- build up the missing mathematical analysis background
- turn exploratory experiments into reproducible numerical studies
- create R packages implementing the thesis algorithms
- evaluate whether mixed precision provides real gains in runtime, memory, or scalability without unacceptable loss of accuracy
- connect the final methods to the climate-model use case

## Working Plan

The concrete thesis roadmap lives in `docs/thesis-roadmap.md`.
