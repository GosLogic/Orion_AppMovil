#!/usr/bin/env bash
# Actualiza los 6 microservicios Orion con git pull.
# Uso:
#   ./scripts/pull_microservices.sh
#   ./scripts/pull_microservices.sh --branch develop
#   ./scripts/pull_microservices.sh --root "/c/ruta/proyecto fundamentos"

set -uo pipefail

SERVICES_ROOT=""
BRANCH=""
REBASE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root|-r)
      SERVICES_ROOT="$2"
      shift 2
      ;;
    --branch|-b)
      BRANCH="$2"
      shift 2
      ;;
    --rebase)
      REBASE="--rebase"
      shift
      ;;
    *)
      echo "Opcion desconocida: $1" >&2
      exit 1
      ;;
  esac
done

MICROSERVICES=(
  "orion-iam-service"
  "orion-dispatch-service"
  "orion-fleet-service"
  "orion-maintenance-service"
  "orion-telemetry-service"
  "orion-notification-service"
)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -z "$SERVICES_ROOT" ]]; then
  SERVICES_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
fi

if [[ ! -d "$SERVICES_ROOT" ]]; then
  echo "No existe la carpeta de servicios: $SERVICES_ROOT" >&2
  exit 1
fi

echo "=== Orion — git pull de microservicios ==="
echo "Raiz: $SERVICES_ROOT"
[[ -n "$BRANCH" ]] && echo "Rama objetivo: $BRANCH"
echo

ok=0
failed=()

for name in "${MICROSERVICES[@]}"; do
  repo_path="$SERVICES_ROOT/$name"
  echo "[$name]"

  if [[ ! -d "$repo_path" ]]; then
    echo "  SKIP — carpeta no encontrada"
    failed+=("$name (no existe)")
    continue
  fi

  if [[ ! -d "$repo_path/.git" ]]; then
    echo "  SKIP — no es un repositorio git"
    failed+=("$name (sin .git)")
    continue
  fi

  (
    cd "$repo_path"
    current_branch="$(git rev-parse --abbrev-ref HEAD)"
    echo "  Rama actual: $current_branch"

    if [[ -n "$BRANCH" && "$BRANCH" != "$current_branch" ]]; then
      git checkout "$BRANCH"
    fi

    git pull $REBASE
    short="$(git rev-parse --short HEAD)"
    echo "  OK — commit $short"
  ) && ok=$((ok + 1)) || failed+=("$name")

  echo
done

echo "=== Resumen ==="
echo "Exitosos: $ok / ${#MICROSERVICES[@]}"
if [[ ${#failed[@]} -gt 0 ]]; then
  echo "Fallidos: ${failed[*]}"
  exit 1
fi

echo "Todos los microservicios actualizados."
exit 0
