#!/usr/bin/env bash

set -eou pipefail

if [ -z "${ENABLE_MODULES:-}" ]; then
  echo "No modules set to enable in ENABLE_MODULES"
  exit 1
fi

jq '."minimum-stability" = "dev"' composer.json > composer.json.tmp
mv composer.json.tmp composer.json

if [ "$LINT" -eq 1 ]; then
  cp web/core/phpcs.xml.dist .
  PHPCS_STANDARD=Drupal
  if [ "$DRUPAL_PRACTICE" -eq 1 ]; then
    PHPCS_STANDARD="Drupal,DrupalPractice"
  fi
  for MODULE in $ENABLE_MODULES; do
    INFO_FILE=$(find web -type f -name "$MODULE.info.yml")
    if [ "$INFO_FILE" = "" ]; then
      continue
    fi
    DIR=$(dirname "$INFO_FILE")
    php vendor/bin/phpcs \
        --standard="$PHPCS_STANDARD" \
        --extensions=php,module,inc,install,test,profile,theme \
        "$DIR"
  done
fi

echo "Starting test server"
drush rs --quiet "$SIMPLETEST_BASE_URL" &
until curl -s "$SIMPLETEST_BASE_URL"; do sleep 1; done > /dev/null

DIR=""
composer config --no-interaction allow-plugins true
for MODULE in $ENABLE_MODULES; do
  INFO_FILE=$(find web -type f -name "$MODULE.info.yml")
  if [ "$INFO_FILE" = "" ]; then
    composer require "drupal/$MODULE" --no-interaction
    continue
  fi

  DIR=$(dirname "$INFO_FILE")
  COMPOSER_JSON="$DIR/composer.json"
  if [ -f "$COMPOSER_JSON" ]; then
    # Read dependencies into an array, one per line
    mapfile -t dep_array < <(jq -r '.require | to_entries[] | "\(.key):\(.value)"' "$COMPOSER_JSON")
    if [ ${#dep_array[@]} -gt 0 ]; then
      echo "Dependencies for $MODULE: ${dep_array[*]}"
      echo "Running composer require with ${#dep_array[@]} dependencies"
      composer require "${dep_array[@]}"
    else
      echo "No dependencies found for $MODULE"
    fi
  else
    composer require "drupal/$MODULE" --no-interaction
  fi
done

echo "Running phpunit"

# Build phpunit arguments
phpunit_args=(--debug)
[ -n "${TEST_SUITE:-}" ] && phpunit_args+=(--testsuite "$TEST_SUITE")

# if the module defines its own phpunit.xml, use it
if [ -f "$DIR/phpunit.xml" ]; then
  cp "$DIR/phpunit.xml" "$DRUPAL_DIR/web/core/"
  cd "$DRUPAL_DIR/web/core"
  "$DRUPAL_DIR"/vendor/bin/phpunit "${phpunit_args[@]}"
# otherwise, use drupal core's default phpunit.xml
else
  vendor/bin/phpunit \
    -c "$DRUPAL_DIR"/web/core/phpunit.xml.dist \
    "${phpunit_args[@]}" \
    "$DIR"
fi
