#!/usr/bin/env bash
# Build Adv360 Pro firmware locally. Needs only docker.
#
#   ./build.sh          both halves
#   ./build.sh left     left half only (faster; use when only the left changed)
#
# Output: firmware/<timestamp>-<commit>-{left,right}-clique.uf2
# Both halves are built with ZMK Studio enabled on the left ("clique"),
# so this keymap and Kinesis's runtime editor coexist.

set -euo pipefail
cd "$(dirname "$0")"

BUILD_RIGHT=true
[[ "${1:-}" == "left" ]] && BUILD_RIGHT=false

# Stamps the version macro (date-branch-commit) into config/version.dtsi
bin/get_version_local.sh clique > /dev/null
trap 'git checkout -- config/version.dtsi 2>/dev/null || true' EXIT

docker build --tag zmk --file Dockerfile .
docker run --rm --name zmk \
    -v "$PWD/firmware:/app/firmware" \
    -v "$PWD/config:/app/config:ro" \
    -e TIMESTAMP="$(date -u +%Y%m%d%H%M)" \
    -e COMMIT="$(git rev-parse --short HEAD)" \
    -e BUILD_RIGHT="$BUILD_RIGHT" \
    -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" \
    zmk \
    sh -c './build.sh && chown -R "$HOST_UID:$HOST_GID" /app/firmware'

echo
echo "Built:"
ls -t firmware/*.uf2 | head -2
