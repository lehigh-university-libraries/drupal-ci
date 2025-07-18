ARG PHP_VERSION=8.3
FROM php:${PHP_VERSION}-fpm-alpine3.20

ARG DRUPAL_VERSION=11.0.x
ENV DRUPAL_VERSION=$DRUPAL_VERSION
ENV COMPOSER_MEMORY_LIMIT=-1
ENV DRUPAL_DIR=/var/www/drupal
ENV SIMPLETEST_DB=sqlite://localhost/default
ENV LINT=1
ENV DRUPAL_PRACTICE=1
ENV SIMPLETEST_BASE_URL=http://127.0.0.1:8282

WORKDIR $DRUPAL_DIR

ARG \
    # renovate: datasource=repology depName=alpine_3_20/bash
    BASH_VERSION=5.2.26-r0 \
    # renovate: datasource=repology depName=alpine_3_20/curl
    CURL_VERSION=8.12.1-r0 \
    # renovate: datasource=repology depName=alpine_3_20/git
    GIT_VERSION=2.45.4-r0 \
    # renovate: datasource=repology depName=alpine_3_20/jq
    JQ_VERSION=1.7.1-r0 \
    # renovate: datasource=repology depName=alpine_3_20/yq-python
    YQ_VERSION=4.44.1-r2 \
    # renovate: datasource=repology depName=alpine_3_20/zip
    ZIP_VERSION=3.0-r12

RUN apk update \
  && apk add --no-cache \
      bash=="${BASH_VERSION}" \
      curl=="${CURL_VERSION}" \
      git=="${GIT_VERSION}" \
      jq=="${JQ_VERSION}" \
      yq=="${YQ_VERSION}" \
      zip=="${ZIP_VERSION}"

ADD --chmod=0755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN install-php-extensions @composer \
      gd \
      zip

RUN composer create-project drupal/recommended-project:$DRUPAL_VERSION . && \
  composer require "drupal/core-dev:$DRUPAL_VERSION" drush/drush && \
  ln -s /var/www/drupal/vendor/bin/drush /usr/local/bin/drush && \
  composer require drupal/coder && \
  composer require --dev dmore/chrome-mink-driver behat/mink && \
  drush si --db-url=${SIMPLETEST_DB} --yes && \
  jq '."minimum-stability" = "dev"' composer.json > composer.json.tmp && \
  mv composer.json.tmp composer.json

COPY scripts .

ENTRYPOINT ["/var/www/drupal/docker-entrypoint.sh"]
