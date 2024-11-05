ARG BUILD_IMAGE=ubuntu:bionic-20210512
ARG PLATFORM=linux/amd64

FROM --platform=${PLATFORM} ${BUILD_IMAGE} AS build

ARG UID=${UID}
ARG GID=${GID}
ARG TZ="America/Toronto"
ARG PYTHON_VERSION="3.11.9"
ARG PYTHON_DIR="/usr/local/factoryengine/python"
ARG PYTHON_BUILD_DIR="/usr/local/factoryengine/build"

ENV TZ=${TZ} \
  PYTHON_VERSION=${PYTHON_VERSION} \
  PYTHON_DIR=${PYTHON_DIR} \
  PYTHON_BUILD_DIR=${PYTHON_BUILD_DIR} \
  APT_CMD="$(which apt-get)" \
  YUM_CMD="$(which yum)" \
  DNF_CMD="$(which dnf)" \
  ZYPPER_CMD="$(which zypper)" \
  APK_CMD="$(which apk)"

# Create a user to run the build process
RUN groupadd -o -g ${GID} factoryengine
RUN useradd -o -u ${UID} -g ${GID} -s /bin/sh -d /home/factoryengine -m factoryengine

RUN if [ -n "${APT_CMD}" ]; then \
  apt-get update && apt-get install -y tzdata; \
  elif [ -n "${YUM_CMD}" ]; then \
    yum install -y tzdata; \
  elif [ -n "${DNF_CMD}" ]; then \
    dnf install -y tzdata; \
  else \
    echo "Package manager not supported."; exit 1; \
  fi

RUN echo "${TZ}" > /etc/timezone \
  && ln -fsn "/usr/share/zoneinfo/${TZ}" /etc/localtime \
  && dpkg-reconfigure --frontend noninteractive tzdata

RUN if [ -n "${APT_CMD}" ]; then \
  apt-get install -y \
    build-essential \
    checkinstall \
    libncursesw5-dev \
    libssl-dev \
    libsqlite3-dev \
    tk-dev \
    libgdbm-dev \
    libc6-dev \
    libbz2-dev \
    libffi-dev \
    software-properties-common \
    python3-launchpadlib \
    wget; \
  elif [ -n "${YUM_CMD}" ]; then \
    yum groupinstall 'Development Tools' -y && yum install -y \
      gcc \
      ncurses-devel \
      openssl-devel \
      bzip2-devel \
      libffi-devel \
      glibc-devel \
      sqlite-devel \
      zlib-devel; \
  elif [ -n "${DNF_CMD}" ]; then \
    dnf groupinstall 'Development Tools' -y && dnf install -y \
      gcc \
      ncurses-devel \
      openssl-devel \
      bzip2-devel \
      libffi-devel \
      glibc-devel \
      sqlite-devel \
      zlib-devel; \
  elif [ -n "${ZYPPER_CMD}" ]; then \
    echo "Zypper is not supported yet in our system."; exit 1; \
  elif [ -n "${APK_CMD}" ]; then \
    apk add --no-cache gcc gcompat musl-dev \
      sqlite-dev \
      zlib-dev; echo "apk is not yet supported."; exit 1; \
  else \
    echo "Unknown package manager"; exit 1; \
  fi

# If running Ubuntu Version 20.04 or later, install the following dependencies
RUN if [ -n "${APT_CMD}" ] && [ "$(grep '^ID=' /etc/os-release | awk -F'=' '{print $2}')" != "ubuntu" ] || [ dpkg --compare-versions "$(grep '^VERSION=' /etc/os-release | sed -n 's/VERSION="\([0-9]*\.[0-9]*\.[0-9]*\).*/\1/p')" lt '20.04' ]; then \
  apt-get install -y libgdbm-compat-dev; \
fi

# Create the build directory for Python and give permissions to the user
RUN mkdir -p "${PYTHON_BUILD_DIR}" && chown -R ${UID}:${GID} "${PYTHON_BUILD_DIR}"
RUN mkdir -p "${PYTHON_DIR}" && chown -R ${UID}:${GID} "${PYTHON_DIR}"

USER factoryengine
WORKDIR ${PYTHON_BUILD_DIR}

# Download the Python source code
RUN wget "https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz"
RUN tar -xvf "Python-${PYTHON_VERSION}.tgz" -C "${PYTHON_BUILD_DIR}" --strip-components=1

# Build Python from source
RUN ./configure --prefix="${PYTHON_DIR}" --enable-shared
RUN make -j$(nproc)
RUN make install -j$(nproc)

WORKDIR ${PYTHON_DIR}

# Next, create the symlink for `python` inside `${PYTHON_DIR}/`
RUN ln -s ./bin/python3 ./python

RUN mkdir -p /home/factoryengine/out

# Now, tar the 4 folders and symlink
RUN tar cvf - ./bin ./include ./lib ./share ./python | gzip -9  - > "/home/factoryengine/out/Python-${PYTHON_VERSION}-$(grep '^ID=' /etc/os-release | awk -F'=' '{print $2}')_$(grep -oP '^VERSION="\d+.*$' /etc/os-release | sed -n 's/VERSION="\([0-9]*\)\..*/\1/p')_$(uname -m).tar.gz"

WORKDIR /home/factoryengine