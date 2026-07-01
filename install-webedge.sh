#!/usr/bin/env bash
set -euo pipefail

# Defaults. Override them inline, for example:
# EDGE_REGION=Bilbao IMAGE_REF=ghcr.io/miguelmsa1/edgebasico-demo:latest bash install-and-run.sh
IMAGE_REF="${IMAGE_REF:-ghcr.io/miguelmsa1/edgebasico-demo:latest}"
EDGE_REGION="${EDGE_REGION:-Bilbao}"
CONTAINER_NAME="${CONTAINER_NAME:-smartedge-demo}"
HOST_PORT="${HOST_PORT:-80}"

if [ "$(id -u)" -ne 0 ]; then
  exec sudo -E bash "$0" "$@"
fi

if ! command -v apt-get >/dev/null 2>&1; then
  echo "This installer expects an Ubuntu/Debian VM with apt-get." >&2
  exit 1
fi

. /etc/os-release
if [ "${ID}" != "ubuntu" ]; then
  echo "This script follows Docker's Ubuntu repository installation. Detected OS: ${ID}." >&2
  echo "Use an Ubuntu image for this VM, or adapt the Docker repo URL for your OS." >&2
  exit 1
fi

echo "[1/6] Installing Docker repository prerequisites..."
apt-get update
apt-get install -y ca-certificates curl gnupg ufw

echo "[2/6] Adding Docker official GPG key and apt repository..."
install -m 0755 -d /etc/apt/keyrings
if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
fi
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${VERSION_CODENAME}") stable" \
  > /etc/apt/sources.list.d/docker.list

echo "[3/6] Installing Docker Engine and Compose plugin..."
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker

echo "[4/6] Configuring firewall..."
ufw allow OpenSSH
ufw allow "${HOST_PORT}/tcp"
ufw --force enable

if [ -n "${REGISTRY_HOST:-}" ] && [ -n "${REGISTRY_USER:-}" ] && [ -n "${REGISTRY_TOKEN:-}" ]; then
  echo "[5/6] Logging in to private registry ${REGISTRY_HOST}..."
  echo "${REGISTRY_TOKEN}" | docker login "${REGISTRY_HOST}" -u "${REGISTRY_USER}" --password-stdin
else
  echo "[5/6] Skipping registry login. Assuming image is public: ${IMAGE_REF}"
fi

echo "[6/6] Pulling and running ${IMAGE_REF}..."
docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true
docker pull "${IMAGE_REF}"
docker run -d \
  --name "${CONTAINER_NAME}" \
  --restart unless-stopped \
  -p "${HOST_PORT}:80" \
  -e EDGE_REGION="${EDGE_REGION}" \
  "${IMAGE_REF}"

echo
echo "Smart Edge demo deployed."
echo "Container: ${CONTAINER_NAME}"
echo "Image: ${IMAGE_REF}"
echo "Region: ${EDGE_REGION}"
echo "Port: ${HOST_PORT}"
echo
docker ps --filter "name=${CONTAINER_NAME}"
