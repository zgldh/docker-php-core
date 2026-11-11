#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")"
tag="$(sed -n 's/^FROM php:\([^ ]*\).*/\1/p' Dockerfile)"
image="zgldh/docker-php-core:$tag"
docker build --platform linux/amd64 -t "$image" .
docker run --rm --entrypoint sh -v "$PWD/tests:/tests:ro" "$image" /tests/smoke.sh "${tag%-fpm}"
