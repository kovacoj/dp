FROM python:3.13-slim

ARG UID=1000
ARG GID=1000
ARG USERNAME=dev

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    git \
    less \
    tini \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid ${GID} ${USERNAME} \
    && useradd --uid ${UID} --gid ${GID} --create-home --shell /bin/bash ${USERNAME}

RUN pip install --no-cache-dir uv jupyterlab

USER ${USERNAME}
WORKDIR /workspace

ENTRYPOINT ["tini", "--"]
CMD ["bash"]
