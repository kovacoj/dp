FROM ubuntu:24.04

ARG UID=1000
ARG GID=1000
ARG USERNAME=dev

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    gnuplot-nox \
    git \
    less \
    octave \
    tini \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid ${GID} ${USERNAME} \
    && useradd --uid ${UID} --gid ${GID} --create-home --shell /bin/bash ${USERNAME}

USER ${USERNAME}
WORKDIR /workspace

ENTRYPOINT ["tini", "--"]
CMD ["bash"]
