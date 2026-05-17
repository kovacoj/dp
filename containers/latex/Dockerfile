FROM texlive/texlive:latest

ARG UID=1000
ARG GID=1000
ARG USERNAME=dev

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    biber \
    ghostscript \
    inkscape \
    less \
    perl \
    tini \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid ${GID} ${USERNAME} \
    && useradd --uid ${UID} --gid ${GID} --create-home --shell /bin/bash ${USERNAME}

USER ${USERNAME}
WORKDIR /workspace/thesis

ENTRYPOINT ["tini", "--"]
CMD ["bash"]
