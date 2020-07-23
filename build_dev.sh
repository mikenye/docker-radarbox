#!/usr/bin/env bash
set -xe

git checkout dev

REPO=mikenye
IMAGE=radarbox
PLATFORMS="linux/amd64,linux/arm/v7,linux/arm64"

# Colours
NOCOLOR='\033[0m'
LIGHTPURPLE='\033[1;35m'

# Save current dir
pushd .

# Firstly we need to build the mlat-client:armhf deb
echo -e "${LIGHTPURPLE}========== Building mlat-client:armhf ==========${NOCOLOR}"
docker context use arm32v7
cd ./mlat-builder
docker build . -t mlat-builder:latest

# Copy deb out of mlat-builder
echo -e "${LIGHTPURPLE}========== Copy mlat-client:armhf out of image ==========${NOCOLOR}"
mkdir -p output
rm -v ./output/*.deb || true
MLAT_BUILDER_CONTAINER_ID=$(timeout 300s docker run -d --rm mlat-builder sleep 300)
FILE_TO_COPY=$(docker exec "${MLAT_BUILDER_CONTAINER_ID}" bash -c "ls /src/mlat-client*.deb")
docker cp "${MLAT_BUILDER_CONTAINER_ID}:${FILE_TO_COPY}" ./output/
docker kill "${MLAT_BUILDER_CONTAINER_ID}"
docker rm "${MLAT_BUILDER_CONTAINER_ID}" || true

# Return to previous directory
popd 

# Return to original build contexts
docker context use x86_64
export DOCKER_CLI_EXPERIMENTAL="enabled"
docker buildx use homecluster

# Build & push development
echo -e "${LIGHTPURPLE}========== Building ${REPO}/${IMAGE}:latest ==========${NOCOLOR}"
docker buildx build -t "${REPO}/${IMAGE}:development" --compress --push --platform "${PLATFORMS}" .
