#!/usr/bin/env bash

set -eou pipefail

if [ "$LINT" -eq 1 ]; then
  cp web/core/phpcs.xml.dist .
  if [ -v ENABLE_MODULES ]; then
    for MODULE in $ENABLE_MODULES; do
      INFO_FILE=$(find web -type f -name "$MODULE.info.yml")
      if [ "$INFO_FILE" = "" ]; then
        continue
      fi
      DIR=$(dirname "$INFO_FILE")

      php vendor/bin/phpcs \
          --standard=Drupal \
          --extensions=php,module,inc,install,test,profile,theme \
          "$DIR"
      if [ "$DRUPAL_PRACTICE" -eq 1 ]; then
        php vendor/bin/phpcs \
          --standard=DrupalPractice \
          --extensions=php,module,inc,install,test,profile,theme \
          "$DIR"
      fi
    done
  fi
fi

echo "Starting test server"
drush rs --quiet "$SIMPLETEST_BASE_URL" &
until curl -s "$SIMPLETEST_BASE_URL"; do true; done > /dev/null

# test
if [ -v ENABLE_MODULES ]; then
  composer config --no-interaction allow-plugins true
  for MODULE in $ENABLE_MODULES; do
    INFO_FILE=$(find web -type f -name "$MODULE.info.yml")
    if [ "$INFO_FILE" = "" ]; then
      composer require "drupal/$MODULE" --no-interaction --yes
      continue
    fi

    DIR=$(dirname "$INFO_FILE")
    COMPOSER_JSON="$DIR/composer.json"
    if [ -f "$COMPOSER_JSON" ]; then
      dependencies=$(jq -r '.require | to_entries[] | "\(.key):\(.value)"' "$COMPOSER_JSON")
      if [ -n "$dependencies" ]; then
        echo "Dependencies for $MODULE: $dependencies"
        for dependency in $dependencies; do
          echo "Running composer require $dependency"
          composer require "$dependency"
        done
      else
        echo "No dependencies found for $MODULE"
      fi
    else
      composer require "drupal/$MODULE" --no-interaction --yes
    fi
  done

  echo "Running phpunit"
  if [ -f "$DIR/phpunit.xml" ]; then
    cp "$DIR/phpunit.xml" "$DRUPAL_DIR/web/core/"
    cd "$DRUPAL_DIR/web/core"
    "$DRUPAL_DIR"/vendor/bin/phpunit --debug
  else
    vendor/bin/phpunit -c web/core/phpunit.xml.dist --debug "$DIR"
  fi
fi
