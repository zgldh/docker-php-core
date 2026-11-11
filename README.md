# docker-php-core

PHP **8.5.12 FPM** for **linux/amd64**.

```sh
docker pull zgldh/docker-php-core:8.5.12-fpm
```

## Included components

- PHP extensions: bcmath, GD (JPEG/FreeType), zip, PDO MySQL/PostgreSQL,
  sockets, pcntl, plus the official image's mbstring, tokenizer, XML and OPcache.
  PHP 8.5 includes OPcache in the PHP binary; do not load `opcache.so` separately.
- ev **1.2.3**, event **3.2.0**, Redis **6.3.0**, Swoole **6.2.5**.
- wasmer-php **1.1.0** (`wasm`).
- Composer **2**, Supercronic **0.2.51**, Supervisor, cron, zip and unzip.
- Composer retains the existing Aliyun Packagist mirror configuration.

## Build and verify

```sh
sh build.sh
```

The build script derives the image tag and expected PHP version from the
Dockerfile. Tests check the exact PHP and PECL extension versions, extension
loading without startup warnings, basic extension operations, Wasm compilation,
function calls, PHP callbacks, memory growth and floating-point access, FPM
configuration, Composer/Supervisor/Supercronic, and PHP's soft/hard memory-limit
behavior.

To run the same tests against an existing image:

```sh
docker run --rm --entrypoint sh -v "$PWD/tests:/tests:ro" \
  zgldh/docker-php-core:8.5.12-fpm /tests/smoke.sh 8.5.12
```

## Publish

The GitHub Actions workflow builds and verifies pull requests without publishing.
Pushing a version tag builds, verifies and publishes the matching Docker Hub tag:

```sh
git tag -a 8.5.12-fpm -m "PHP 8.5.12 FPM"
git push origin master
git push origin 8.5.12-fpm
```

The version tag must match the `FROM php:` version in the Dockerfile. Manual
workflow dispatch follows the same rule. Publishing uses the repository secret
`DOCKER_HUB_ACCESS_TOKEN` for Docker Hub user `zgldh`. Existing historical tags
are not rebuilt or moved, and this workflow does not change the `latest` tag.

## Upgrade notes

This replaces PHP 8.1.2. Applications must be checked against the PHP migration
guides and the Swoole/Redis major-version changes before deployment. In
particular, remove application-provided `zend_extension=opcache.so` settings.

Wasmer 1.1.0 bundles an old native runtime and upstream only tested PHP 8.0/8.1.
This repository supplies a small source patch correcting PHP parameter types in
`MemoryView::setF32`, `MemoryView::setF64` and `wasm_limits_new`, including the
float32 conversion before writing memory. Its basic operations are tested against
PHP 8.5.12; application-specific Wasm workloads still need validation. The bundled
runtime restricts this image to linux/amd64.

References:

- [PHP 8.5.12 release](https://www.php.net/releases/8_5_12.php)
- [PHP 8.5 migration guide](https://www.php.net/manual/en/migration85.php)
- [Swoole 6.2.5 release](https://pecl.php.net/rest/r/swoole/6.2.5.xml)
- [Wasmer PHP 1.1.0](https://github.com/wasmerio/wasmer-php/tree/1.1.0)

## Other tags

- [`8.1.2-fpm`](https://github.com/zgldh/docker-php-core/tree/8.1.2-fpm)
  — previous PHP 8.1 image.
- [`7.4.33-fpm-cve-2026-109618-109619`](https://github.com/zgldh/docker-php-core/tree/7.4.33-fpm-cve-2026-109618-109619)
  — hardened PHP 7.4 image: `php:7.4.33-fpm` with the official PHP 7.4
  backport for CVE-2026-109618 / CVE-2026-109619, plus the extension set of
  the previous `7.4.28-fpm` image. Sources, vendored patch and verification
  notes live on the `7.4-cve-2026-109618-109619` branch.
