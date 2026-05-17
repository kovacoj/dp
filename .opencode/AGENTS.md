# Project OpenCode Instructions

This project contains a diploma thesis manuscript, supporting code, local literature, and a `research-lab` MCP server.

## When writing thesis text

1. Read the relevant thesis files first:
   - `thesis/thesis.tex`
   - target chapter file in `thesis/chapters/`
   - `thesis/preamble/data.tex`
   - `AGENTS.md`
2. Inspect the local `literature/` folder before searching externally.
3. Prefer local PDFs and local notes when they already cover the needed topic.
4. Use the `research-lab` MCP server when:
   - local literature is too thin,
   - you need a broader survey,
   - you want newer papers,
   - you want a reproducible search artifact under `research/runs/`.

## Source-handling rules

1. Do not invent citations, bibliographic metadata, or claims.
2. If you use a new external source in the manuscript, add it to `thesis/preamble/bibliography.bib` before citing it.
3. Prefer claims you can tie to either:
   - a local PDF in `literature/`, or
   - a source surfaced and summarized through `research-lab`.
4. Distinguish clearly between:
   - background facts,
   - standard textbook-level material,
   - paper-specific claims,
   - your own synthesis.

## Writing rules

1. Write polished thesis prose, not notes.
2. Prefer clear section structure over long undifferentiated blocks.
3. Keep the main conceptual center on randomized numerical linear algebra and mixed precision.
4. Treat climate-model material primarily as an application unless the user explicitly asks otherwise.
5. Make the prose readable for a mathematically literate reader, not only for a domain specialist.

## Mathematical style and notation

The user prefers a mathematically mature style influenced by numerical analysis, functional analysis, and differential geometry.

When writing thesis prose or choosing notation:

1. Default to a numerical-analysis viewpoint: stability, conditioning, perturbation, approximation, operator behavior, and algorithmic consequences should be foregrounded.
2. Prefer functional-analysis-flavored notation and language where it clarifies the argument, even in finite-dimensional linear algebra.
3. It is acceptable, and often desirable, to speak of linear maps, operators, adjoints, inner-product spaces, induced norms, and subspaces rather than using only matrix-calculus phrasing.
4. When discussing least-squares problems, embeddings, or projections, geometric language is welcome if it sharpens intuition.
5. Differential-geometric wording may be used when it genuinely clarifies geometric structure, but it should not become decorative or distract from the numerical-analysis core.
6. Preserve contact with computation: do not let abstract notation obscure dimensions, conditioning, floating-point effects, or implementational consequences.
7. Use notation consistently once introduced, and prefer conceptual economy over constant switching between matrix and operator viewpoints.

## Concrete notation preferences

1. When natural, write spaces such as \(\R^d\) as finite-dimensional inner-product spaces and describe matrices as representations of linear operators.
2. Use adjoint language when appropriate, especially when it is more natural than purely coordinate-based transpose language.
3. Prefer operator norm and induced norm terminology when discussing stability and conditioning.
4. For least-squares problems, keep both the geometric and computational viewpoints visible: approximation in a normed or inner-product space, but also explicit residuals, conditioning, and solver behavior.
5. Avoid gratuitously abstract notation if it hides the algorithm being analyzed.

## Suggested mixed-precision workflow

When asked to write or improve the mixed-precision chapter:

1. Read `thesis/chapters/MixedPrecision.tex`.
2. Inspect relevant files in `literature/`.
3. If needed, use `research-lab` MCP tools to create a brief and run a focused literature search on mixed-precision arithmetic, floating-point error analysis, low-precision linear algebra, and numerical stability.
4. Read the generated report and extract only the claims that are useful for this thesis.
5. Update the chapter and bibliography surgically.

## MCP usage

Available MCP server: `research-lab`

Useful tools include:
- `research_lab_create_brief`
- `research_lab_run_search`
- `research_lab_run_from_brief`
- `research_lab_list_runs`
- `research_lab_read_report`
- `research_lab_review_run`

Default artifact location:
- `research/runs/`
