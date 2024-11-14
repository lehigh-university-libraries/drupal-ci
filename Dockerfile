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

ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

RUN chmod +x /usr/local/bin/install-php-extensions && \
    install-php-extensions @composer \
      gd \
      zip

RUN apk update \
  && apk add --no-cache \
      bash==5.2.26-r0 \
      curl==8.11.0-r2 \
      git==2.45.2-r0 \
      jq==1.7.1-r0 \
      yq==4.44.1-r2 \
      zip==3.0-r12

RUN composer create-project drupal/recommended-project:$DRUPAL_VERSION . && \
  composer require "drupal/core-dev:$DRUPAL_VERSION" drush/drush && \
  ln -s /var/www/drupal/vendor/bin/drush /usr/local/bin/drush && \
  composer require drupal/coder && \
  drush si --db-url=${SIMPLETEST_DB} --yes

COPY scripts .

ENTRYPOINT ["/var/www/drupal/docker-entrypoint.sh"]
