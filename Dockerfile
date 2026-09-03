# syntax=docker/dockerfile:1
# Imagen de desarrollo: sirve la aplicación con Puma contra el PostgreSQL del compose.
ARG RUBY_VERSION=3.4.9
FROM docker.io/library/ruby:$RUBY_VERSION-slim

# Dependencias del sistema: cabeceras de PostgreSQL para compilar `pg` y Node para
# construir el CSS de Bootstrap con Dart Sass.
RUN apt-get update -qq \
 && apt-get install --no-install-recommends -y \
      build-essential ca-certificates curl postgresql-client git \
      libjemalloc2 libyaml-dev pkg-config libpq-dev tzdata \
 && curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
 && apt-get install --no-install-recommends -y nodejs \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /rails

ENV RAILS_ENV=development \
    BUNDLE_PATH=/usr/local/bundle \
    LD_PRELOAD=libjemalloc.so.2

# Las dependencias se instalan antes de copiar el código para aprovechar la caché
# de capas de Docker.
COPY Gemfile Gemfile.lock ./
RUN bundle install && rm -rf "$BUNDLE_PATH"/ruby/*/cache

COPY package.json package-lock.json ./
RUN npm ci

COPY . .
RUN chmod +x bin/*

EXPOSE 3000
ENTRYPOINT ["/rails/bin/docker-entrypoint"]
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]
