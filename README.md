# drupal-ci

Drupal docker images to easily run linters and phpunit tests.

e.g. to test the module in Drupal 11.0 in php 8.3 you can run

```
MODULE=foo
docker run --rm \
  --volume $(pwd):/var/www/drupal/web/modules/contrib/$MODULE \
  --env ENABLE_MODULES=$MODULE \
 lehighlts/drupal-ci:11.0-php8.3
```

## Settings

You can pass some environment variables to the docker image

| Env Var Name       | Explanation                                                                                      |
|------------------- |------------------------------------------------------------------------------------------------- |
| `ENABLE_MODULES`  | The name of the module to enable (e.g. ENABLE_MODULES=turnstile_protect)                          |
| `LINT`            | 1/0 - whether to run code sniffer with `Drupal` standard on the `ENABLE_MODULES` codebase         |
| `DRUPAL_PRACTICE` | 1/0 - whether to run code sniffer with `DrupalPractice` standard on the `ENABLE_MODULES` codebase |
