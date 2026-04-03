#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <env-file> <templates-dir>" >&2
  exit 1
fi

ENV_FILE=$(realpath "$1")
TEMPLATES_DIR=$(realpath "$2")
SELF_PATH=$(realpath "$0")

KUBE_TEMPLATE="$TEMPLATES_DIR/qbit-pod.kube"
POD_TEMPLATE="$TEMPLATES_DIR/qbit-vpn.yaml.template"

DEST_SYSTEMD_DIR=/var/lib/qbit/.config/containers/systemd
DEST_K8S_DIR=/var/lib/qbit/.config/containers/k8s

DEST_KUBE="$DEST_SYSTEMD_DIR/qbit-pod.kube"
DEST_POD="$DEST_K8S_DIR/qbit-pod.yaml"

TEMPLATES=(
  "$KUBE_TEMPLATE"
  "$POD_TEMPLATE"
)

[[ -f "$ENV_FILE" ]] || {
  echo "Error: file not found: $ENV_FILE" >&2
  exit 1
}

for f in "${TEMPLATES[@]}"; do
  [[ "$f" != "$SELF_PATH" ]] || {
    echo "Error: template path resolves to this script: $f" >&2
    exit 1
  }
  [[ -f "$f" ]] || {
    echo "Error: file not found: $f" >&2
    exit 1
  }
done

for cmd in envsubst sudo realpath sort grep cat mkdir install; do
  command -v "$cmd" >/dev/null 2>&1 || {
    echo "Error: required command not found: $cmd" >&2
    exit 1
  }
done

mapfile -t placeholders < <(
  for template in "${TEMPLATES[@]}"; do
    envsubst -v "$(cat "$template")"
  done | sort -u
)

declare -A env_keys=()
while IFS='=' read -r key _; do
  [[ "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || continue
  env_keys["$key"]=1
done < <(
  grep -v '^[[:space:]]*#' "$ENV_FILE" | grep '=' || true
)

missing=()
for var in "${placeholders[@]}"; do
  [[ -n "${env_keys[$var]:-}" ]] || missing+=("$var")
done

if (( ${#missing[@]} > 0 )); then
  echo "Error: these placeholders do not have values in $ENV_FILE:" >&2
  printf '  - %s\n' "${missing[@]}" >&2
  exit 1
fi

for dir in "$DEST_SYSTEMD_DIR" "$DEST_K8S_DIR"; do
  if [[ ! -d "$dir" ]]; then
    read -r -p "Create $dir? [y/N] " reply
    [[ "$reply" =~ ^[Yy]$ ]] || {
      echo "Aborted: $dir is required." >&2
      exit 1
    }
    sudo mkdir -p "$dir"
  fi
done

render_to() {
  local template=$1
  local dest=$2
  local mode=$3

  (
    set -a
    # shellcheck disable=SC1090
    source "$ENV_FILE"
    set +a
    envsubst < "$template"
  ) | sudo install -m "$mode" /dev/stdin "$dest"
}

render_to "$KUBE_TEMPLATE" "$DEST_KUBE" 0644
render_to "$POD_TEMPLATE" "$DEST_POD" 0600

echo "Installed:"
echo "  $DEST_KUBE"
echo "  $DEST_POD"
echo
echo "Next:"
echo "  sudo systemctl daemon-reload"
echo "  sudo systemctl enable --now qbit-pod.service"
echo "  sudo systemctl status qbit-pod.service"
