FROM rocker/r-ver:4.4.1

ARG UID=1000
ARG GID=1000
ARG USERNAME=dev

ENV DEBIAN_FRONTEND=noninteractive
ENV CRAN_REPO=https://cloud.r-project.org

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    libcurl4-openssl-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libgit2-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libpng-dev \
    libssl-dev \
    libxml2-dev \
    littler \
    less \
    pkg-config \
    tini \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid ${GID} ${USERNAME} \
    && useradd --uid ${UID} --gid ${GID} --create-home --shell /bin/bash ${USERNAME}

RUN R -q -e "install.packages(c('devtools','languageserver','Matrix','energy','FNN','testthat','roxygen2'), repos = Sys.getenv('CRAN_REPO'))"

USER ${USERNAME}
WORKDIR /workspace

ENTRYPOINT ["tini", "--"]
CMD ["bash"]
