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
    libgsl-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libpng-dev \
    libssl-dev \
    libuv1-dev \
    libxml2-dev \
    littler \
    less \
    pkg-config \
    tini \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    if getent group "${GID}" >/dev/null; then \
        GROUP_NAME="$(getent group "${GID}" | cut -d: -f1)"; \
    else \
        groupadd --gid "${GID}" "${USERNAME}"; \
        GROUP_NAME="${USERNAME}"; \
    fi; \
    if id -u "${USERNAME}" >/dev/null 2>&1; then \
        usermod --uid "${UID}" --gid "${GID}" "${USERNAME}"; \
    elif getent passwd "${UID}" >/dev/null; then \
        EXISTING_USER="$(getent passwd "${UID}" | cut -d: -f1)"; \
        usermod --login "${USERNAME}" --home "/home/${USERNAME}" --move-home --gid "${GID}" "${EXISTING_USER}"; \
    else \
        useradd --uid "${UID}" --gid "${GROUP_NAME}" --create-home --shell /bin/bash "${USERNAME}"; \
    fi

RUN R -q -e "pkgs <- c('FNN','testthat','roxygen2','remotes'); install.packages(pkgs, repos = Sys.getenv('CRAN_REPO')); missing <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]; if (length(missing) > 0) stop(sprintf('Missing R packages after install: %s', paste(missing, collapse = ', ')))"

USER ${USERNAME}
WORKDIR /workspace

ENTRYPOINT ["tini", "-s", "--"]
CMD ["bash"]
