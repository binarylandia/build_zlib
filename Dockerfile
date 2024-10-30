ARG DOCKER_BASE_IMAGE
FROM $DOCKER_BASE_IMAGE

ARG DOCKER_BASE_IMAGE
ENV DOCKER_BASE_IMAGE="${DOCKER_BASE_IMAGE}"

SHELL ["bash", "-euxo", "pipefail", "-c"]

RUN set -euxo pipefail >/dev/null \
&& if [[ "$DOCKER_BASE_IMAGE" != centos* ]] && [[ "$DOCKER_BASE_IMAGE" != *manylinux2014* ]]; then exit 0; fi \
&& echo -e "[buildlogs-c7.2009.u]\nname=https://buildlogs.centos.org/c7.2009.u.x86_64/\nbaseurl=https://buildlogs.centos.org/c7.2009.u.x86_64/\nenabled=1\ngpgcheck=0\n\n[buildlogs-c7.2009.00]\nname=https://buildlogs.centos.org/c7.2009.00.x86_64/\nbaseurl=https://buildlogs.centos.org/c7.2009.00.x86_64/\nenabled=1\ngpgcheck=0" > /etc/yum.repos.d/buildlogs.repo \
&& echo -e "[llvm-toolset]\nname=https://buildlogs.centos.org/c7-llvm-toolset-13.0.x86_64/\nbaseurl=https://buildlogs.centos.org/c7-llvm-toolset-13.0.x86_64/\nenabled=1\ngpgcheck=0" > /etc/yum.repos.d/llvm-toolset.repo \
&& sed -i "s/enabled=1/enabled=0/g" "/etc/yum/pluginconf.d/fastestmirror.conf" \
&& sed -i "s/enabled=1/enabled=0/g" "/etc/yum/pluginconf.d/ovl.conf" \
&& yum clean all \
&& yum -y install dnf epel-release \
&& dnf install -y \
  bash \
  ca-certificates \
  curl \
  gcc \
  git \
  make \
  sudo \
  tar \
  xz \
&& dnf clean all \
&& rm -rf /var/cache/yum

RUN set -euxo pipefail >/dev/null \
&& if [[ "$DOCKER_BASE_IMAGE" != debian* ]] && [[ "$DOCKER_BASE_IMAGE" != ubuntu* ]]; then exit 0; fi \
&& export DEBIAN_FRONTEND=noninteractive \
&& apt-get update -qq --yes \
&& apt-get install -qq --no-install-recommends --yes \
  bash \
  ca-certificates \
  curl \
  gcc \
  git \
  make \
  sudo \
  tar \
  xz-utils \
>/dev/null \
&& rm -rf /var/lib/apt/lists/* \
&& apt-get clean autoclean >/dev/null \
&& apt-get autoremove --yes >/dev/null

RUN set -euxo pipefail >/dev/null \
&& curl -fsSL "https://github.com/binarylandia/build_gcc-musl-cross/releases/download/gcc-9.4.0-musl-1.2.5-20241028071857/gcc-9.4.0-musl-1.2.5-x86_64-unknown-linux-musl-20241028071857.tar.xz" | tar -C "/usr" -xJ \
&& which x86_64-unknown-linux-musl-gcc \
&& /usr/bin/x86_64-unknown-linux-musl-gcc -v

ARG USER=user
ARG GROUP=user
ARG UID
ARG GID

ENV USER=$USER
ENV GROUP=$GROUP
ENV UID=$UID
ENV GID=$GID
ENV TERM="xterm-256color"
ENV HOME="/home/${USER}"

COPY docker/files /

RUN set -euxo pipefail >/dev/null \
&& /create-user \
&& sed -i /etc/sudoers -re 's/^%sudo.*/%sudo ALL=(ALL:ALL) NOPASSWD: ALL/g' \
&& sed -i /etc/sudoers -re 's/^root.*/root ALL=(ALL:ALL) NOPASSWD: ALL/g' \
&& sed -i /etc/sudoers -re 's/^#includedir.*/## **Removed the include directive** ##"/g' \
&& echo "%sudo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
&& echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
&& touch ${HOME}/.hushlogin \
&& chown -R ${UID}:${GID} "${HOME}"


USER ${USER}
