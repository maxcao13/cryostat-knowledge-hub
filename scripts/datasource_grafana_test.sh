#!/bin/bash

POD_NAME=${POD_NAME:-"cryostat-pod"}
DATASOURCE_PORT=${DATASOURCE_PORT:-"8080"}
GRAFANA_PORT=${GRAFANA_PORT:-"3000"}
HOST=${HOST:-"localhost"}

IMAGE_TAG_BASE=${IMAGE_TAG_BASE:-"quay.io/cryostat"}
LOCAL_IMAGE_VERSION=${LOCAL_IMAGE_VERSION:-"latest"}

DATASOURCE_IMG_NAME=${DATASOURCE_IMG_NAME:-"jfr-datasource"}
DATASOURCE_IMG="${IMAGE_TAG_BASE}/${DATASOURCE_IMG_NAME}:${LOCAL_IMAGE_VERSION}"

GRAFANA_IMG_NAME=${GRAFANA_IMG_NAME:-"cryostat-grafana-dashboard"}
GRAFANA_IMG="${IMAGE_TAG_BASE}/${GRAFANA_IMG_NAME}:${LOCAL_IMAGE_VERSION}"


# Clean up function to kill and remove pod
function cleanup() {
    echo "[INFO] Clean up pod ${POD_NAME}"
    podman pod kill ${POD_NAME}
    podman pod rm ${POD_NAME}
}

function createPod() {
    podman pod create \
        --replace \
        --hostname cryostat \
        --name ${POD_NAME} \
        --publish "${DATASOURCE_PORT}:${DATASOURCE_PORT}" \
        --publish "${GRAFANA_PORT}:${GRAFANA_PORT}"
}

function runJfrDatasource() {
    podman run \
        --name jfr-datasource \
        --pod ${POD_NAME} \
        --rm -d "${DATASOURCE_IMG}"
}

function runGrafana() {
    podman run \
        --name grafana \
        --pod ${POD_NAME} \
        --env GF_INSTALL_PLUGINS=grafana-simple-json-datasource \
        --env GF_AUTH_ANONYMOUS_ENABLED=true \
        --env JFR_DATASOURCE_URL="http://${HOST}:${DATASOURCE_PORT}" \
        --rm -d "${GRAFANA_IMG}"
}

function errorHandler() {
  cleanup
  exit 0
}

# Clean up resources if there is an error
trap errorHandler ERR

if [[ ${1} = "clean" ]]; then
  cleanup
  exit 0
fi

echo "[INFO] Creating pod ${POD_NAME}"
createPod

echo "[INFO] Creating datasource container with ${DATASOURCE_IMG} "
runJfrDatasource

echo "[INFO] Creating grafana container with ${GRAFANA_IMG} "
runGrafana
