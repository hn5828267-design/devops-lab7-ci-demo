#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
docker compose down --remove-orphans
echo 'Lab7 containers removed; volumes retained.'
