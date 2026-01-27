#!/usr/bin/env bash
set -e

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <path_to_env_file> <path_to_yaml_file>"
    exit 1
fi

ENV_PATH=$(realpath "$1")
YAML_PATH=$(realpath "$2")

if [ ! -f "$ENV_PATH" ]; then
    echo "Error: Environment file not found at $ENV_PATH"
    exit 1
fi

if [ ! -f "$YAML_PATH" ]; then
    echo "Error: YAML file not found at $YAML_PATH"
    exit 1
fi

echo "🚀 Deploying Pod..."
echo "📂 Env:  $ENV_PATH"
echo "📄 YAML: $YAML_PATH"

sudo sh -c "set -a; source '$ENV_PATH'; set +a; envsubst < '$YAML_PATH'" | podman play kube --replace -

# --- STATUS ---
if [ "${PIPESTATUS[1]}" -eq 0 ]; then
    echo "✅ Success! Pod is up."
else
    echo "Failed to play kube manifest."
    exit 1
fi
