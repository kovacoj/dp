# Research Lab Evaluation

This note evaluates whether the `research-lab` module should become part of the
thesis contribution.

## What It Does

`research-lab` is an agent-first literature-search laboratory. Its reusable
pieces are:

- retrieval from scholarly and web sources;
- candidate ranking and reranking;
- brief parsing;
- run history and artifact storage;
- report and bibliography generation;
- an MCP layer that can write runs under this repository's `research/`
  directory.

The existing thesis workspace already uses this shape:

- `research/briefs/` contains research briefs;
- `research/runs/` contains generated run artifacts;
- `research/runs/index.sqlite3` indexes the run history;
- run folders contain `brief.json`, `queries.json`, `candidates.json`,
  `report.md`, and `references.bib`.

## Fit for This Thesis

The module is useful infrastructure for literature review, source discovery, and
reproducible research notes. It is not a natural core contribution for this
thesis, because the thesis contribution is numerical:

- randomized covariance approximation;
- regularized covariance transport;
- mixed-precision perturbation analysis;
- R package implementation and experiments;
- climate-model post-processing as the application layer.

`research-lab` does not manage numerical experiment grids, statistical
diagnostics, covariance-transport sweeps, or package benchmarks. Those belong in
the thesis packages and experiment scripts, not in the literature-search module.

## Decision

Treat `research-lab` as supporting infrastructure, not as a thesis contribution.

It should be cited internally as a reproducibility aid for literature review if
needed, but the thesis should not claim it as part of the original method. The
practical contribution should remain:

```text
randMBC/rSketchLS-style implementations
+ theorem-driven experiments
+ reproducible result tables and figures
```

## Standard Workflow

Use `research-lab` when a thesis section needs literature support:

1. Write or update a focused brief under `research/briefs/`.
2. Run a search through the CLI or MCP integration.
3. Inspect `report.md` and `references.bib` in the generated run directory.
4. Promote only relevant, verified references into
   `thesis/preamble/bibliography.bib`.
5. Summarize findings in thesis text or docs; do not treat raw run reports as
   final thesis prose.

## Minimal Run Status

No new run is required for this decision. The repository already contains
multiple completed runs under `research/runs/`, including searches for
mixed-precision arithmetic, randomized least squares, and multivariate climate
bias correction. These demonstrate that the module works as literature-review
infrastructure.

## Implications

- Keep `research-lab` separate from `packages/rSketchLS/` and future
  `randMBC` code.
- Do not route numerical benchmark orchestration through `research-lab`.
- Build experiment reproducibility around package tests, experiment runners,
  result schemas, and thesis figures instead.
- Use `research-lab` to find and review papers when theory or application
  sections need stronger citations.
