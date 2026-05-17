# Containers

This directory contains the Docker-based development environment for the thesis workspace.

The setup assumes a WSL + Docker Desktop workflow where local installation is restricted and the repo is developed through containers instead.

## Layout

- `compose.yaml`: multi-service entry point
- `python/`: Python and notebook environment
- `r/`: R environment for package development and experiments
- `octave/`: Octave environment for MATLAB-compatible numerical work
- `latex/`: LaTeX environment for the thesis document
- `../bin/`: convenience wrapper scripts around `docker compose`
- `../Makefile`: short targets for the most common commands

## Why Octave Instead of MATLAB

MATLAB cannot be distributed as a normal public Docker image because of MathWorks licensing and registry restrictions. This setup therefore provides an Octave container for MATLAB-like workflows.

If you later get access to a company-managed MATLAB container or license server, a separate `matlab/` service can be added alongside `octave/`.

## First-Time Setup

1. Make sure Docker Desktop is installed and WSL integration is enabled for this distro.
2. Copy `.env.example` to `.env` if you want explicit control over `UID`, `GID`, and `USERNAME`.
3. Build the images:

```sh
docker compose -f containers/compose.yaml build
```

## Common Commands

Open a shell in the Python container:

```sh
docker compose -f containers/compose.yaml run --rm python bash
```

or:

```sh
./bin/python-shell
```

Install or sync Python dependencies with `uv`:

```sh
docker compose -f containers/compose.yaml run --rm python uv sync --frozen
```

or:

```sh
./bin/python-sync --frozen
```

Open an R shell:

```sh
docker compose -f containers/compose.yaml run --rm r R
```

or:

```sh
./bin/r-shell
```

Open Octave:

```sh
docker compose -f containers/compose.yaml run --rm octave octave --no-gui
```

or:

```sh
./bin/octave-shell
```

Build the thesis PDF:

```sh
docker compose -f containers/compose.yaml run --rm latex latexmk thesis
```

or:

```sh
./bin/latex-build
```

Start JupyterLab:

```sh
docker compose -f containers/compose.yaml up jupyter
```

or:

```sh
./bin/jupyter
```

JupyterLab will be available on `http://localhost:8888`.

## Make Targets

You can also use:

```sh
make containers-build
make python-shell
make python-sync
make r-shell
make octave-shell
make latex-shell
make thesis
make jupyter
```

## Suggested Workflow

- use `python` for notebooks and numerical experiments
- use `r` for package development in `packages/`
- use `octave` for MATLAB-style prototyping and validation
- use `latex` for everything under `thesis/`

## Notes

- The repo is bind-mounted into `/workspace` in all services.
- The LaTeX container starts in `/workspace/thesis`.
- The Python container includes `uv`, but project dependencies are intentionally synced by command rather than hardcoded into image build steps.
- The Jupyter service uses the Python image and runs `uv sync` before starting JupyterLab.
- The R container preinstalls common package-development and thesis-relevant packages, but you can still install more interactively.
