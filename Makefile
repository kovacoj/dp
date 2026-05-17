COMPOSE := docker compose -f containers/compose.yaml

.PHONY: containers-build python-shell python-sync r-shell octave-shell latex-shell thesis jupyter jupyter-down

containers-build:
	$(COMPOSE) build

python-shell:
	$(COMPOSE) run --rm python bash

python-sync:
	$(COMPOSE) run --rm python uv sync

r-shell:
	$(COMPOSE) run --rm r R

octave-shell:
	$(COMPOSE) run --rm octave octave --no-gui

latex-shell:
	$(COMPOSE) run --rm latex bash

thesis:
	$(COMPOSE) run --rm latex latexmk thesis

jupyter:
	$(COMPOSE) up jupyter

jupyter-down:
	$(COMPOSE) down
