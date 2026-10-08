# Anthropic's OSS Scanner (https://github.com/anthropics/oss-scanner) builds
# this with the checkout as context, then scans `/src` offline as root.
# `/src` is a default-prefix Linux Homebrew owned by an unprivileged `linuxbrew`
# user, with Portable Ruby, every bundler gem group and the signed JSON API
# cached so `brew tests` runs offline.
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    bzip2 ca-certificates curl file g++ gh git gpg less locales make openssh-client patch procps sudo unzip xz-utils \
  && localedef -i en_US -f UTF-8 en_US.UTF-8 \
  && rm -rf /var/lib/apt/lists/*

# `HOMEBREW_NO_AUTO_UPDATE` stops `brew` moving /src to the latest release tag.
ENV LANG=en_US.UTF-8 \
  PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}" \
  HOMEBREW_NO_ANALYTICS=1 \
  HOMEBREW_NO_AUTO_UPDATE=1 \
  HOMEBREW_NO_ENV_HINTS=1

COPY . /src
WORKDIR /src

# `threat_model.md` points here for Homebrew's organisation-wide security policy.
ADD https://raw.githubusercontent.com/Homebrew/.github/HEAD/SECURITY.md /opt/homebrew-security-policy.md

# The scanner runs as root, and `git` refuses a checkout owned by another user.
# Like a macOS administrator, `linuxbrew` may use `sudo` but only with a
# password, which it lacks.
RUN chmod 0644 /opt/homebrew-security-policy.md \
  && useradd --create-home --shell /bin/bash linuxbrew \
  && echo 'linuxbrew ALL=(ALL) ALL' >/etc/sudoers.d/linuxbrew \
  && chmod 0440 /etc/sudoers.d/linuxbrew \
  && ln -s /src /home/linuxbrew/.linuxbrew \
  && chown -R linuxbrew:linuxbrew /src \
  && git config --system --add safe.directory /src

USER linuxbrew
# Fetching `hello`'s metadata caches the signed JSON API for offline use.
# `install-bundler-gems` turns developer mode on, so turn it off again.
RUN brew install-bundler-gems --groups=all \
  && brew info hello \
  && { git config --unset-all homebrew.devcmdrun || true; } \
  && brew config
