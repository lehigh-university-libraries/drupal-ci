ARG PHP_VERSION=8.3
FROM php:${PHP_VERSION}-fpm-alpine3.23

ARG \
  DRUPAL_VERSION=11.2.x \
  TARGETARCH

ENV \
  DRUPAL_VERSION=$DRUPAL_VERSION \
  COMPOSER_MEMORY_LIMIT=-1 \
  DRUPAL_DIR=/var/www/drupal \
  SIMPLETEST_DB=sqlite://localhost/default \
  LINT=1 \
  DRUPAL_PRACTICE=1 \
  SIMPLETEST_BASE_URL=http://127.0.0.1:8282

WORKDIR $DRUPAL_DIR

ARG \
    # renovate: datasource=repology depName=alpine_3_23/bash
    BASH_VERSION=5.3.3-r1 \
    # renovate: datasource=repology depName=alpine_3_23/curl
    CURL_VERSION=8.17.0-r1 \
    # renovate: datasource=repology depName=alpine_3_23/git
    GIT_VERSION=2.52.0-r0 \
    # renovate: datasource=repology depName=alpine_3_23/jq
    JQ_VERSION=1.8.1-r0 \
    # renovate: datasource=repology depName=alpine_3_23/yq-go
    YQ_VERSION=4.49.2-r2 \
    # renovate: datasource=repology depName=alpine_3_23/zip
    ZIP_VERSION=3.0-r13

RUN --mount=type=cache,id=apk-${PHP_VERSION}-${TARGETARCH},sharing=locked,target=/var/cache/apk \
    apk update && \
    apk add --no-cache \
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

RUN --mount=type=cache,id=composer-${DRUPAL_VERSION}-${TARGETARCH},sharing=locked,target=/root/.composer/cache \
    composer create-project \
      drupal/recommended-project:$DRUPAL_VERSION . && \
    composer require -W \
      "drupal/core-dev:$DRUPAL_VERSION" \
      drush/drush && \
    ln -s /var/www/drupal/vendor/bin/drush /usr/local/bin/drush && \
    composer require drupal/coder && \
    composer require --dev \
      dmore/chrome-mink-driver \
      behat/mink && \
    drush si --db-url=${SIMPLETEST_DB} --yes

COPY scripts .

ENTRYPOINT ["/var/www/drupal/docker-entrypoint.sh"]
