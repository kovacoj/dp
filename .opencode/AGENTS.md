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
