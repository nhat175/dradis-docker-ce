FROM ruby:2.3-slim

ENV RAILS_ENV=production \
    APT_ARGS="-y --no-install-recommends --no-upgrade -o Dpkg::Options::=--force-confnew"

# Copy ENTRYPOINT script
ADD docker-entrypoint.sh /entrypoint.sh
ADD ssl_patch.patch /ssl_patch.patch

RUN apt-get update && \
# Install requirements
    DEBIAN_FRONTEND=noninteractive \
    apt-get install $APT_ARGS \
      gcc \
      git \
      g++ \
      build-essential \
      libsqlite3-dev \
      make \
      nodejs \
      patch \
      libmysqlclient-dev \
      # libv8-dev \
      wget && \
# Install Dradis
# sed -i 's/^# *\(.*execjs\)/\1/' Gemfile && \
    cd /opt && \
    git clone https://github.com/dradis/dradis-ce.git && \
    cd dradis-ce && \
    # rm -f Gemfile.lock && \
    ruby bin/setup && \
    bundle exec rake assets:precompile && \
# Entrypoint:
    chmod +x /entrypoint.sh && \
# Create dradis user:
    groupadd -r dradis-ce && \
    useradd -r -g dradis-ce -d /opt/dradis-ce dradis-ce && \
    mkdir -p /dbdata && \
    chown -R dradis-ce:dradis-ce /opt/dradis-ce/ /dbdata/ && \
    patch -p1 -i /ssl_patch.patch && \
# Clean up:
    apt-get remove -y --purge \
      gcc \
      g++ \
      build-essential \
      libsqlite3-dev \
      make \
      patch \
      libmysqlclient-dev \
      wget && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install $APT_ARGS \
      libsqlite3-0  \
      libmysqlclient18 && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get autoremove -y && \
    rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/* && \
    rm -f /dbdata/production.sqlite3

WORKDIR /opt/dradis-ce

VOLUME /dbdata

EXPOSE 3000

ENTRYPOINT ["/entrypoint.sh"]
