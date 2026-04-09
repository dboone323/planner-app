#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "Running autonomous verification and repair checks from: ${ROOT_DIR}"
cd "${ROOT_DIR}"

if ! command -v shellcheck >/dev/null 2>&1; then
  echo "shellcheck is required but was not found in PATH."
  exit 1
fi

failure_count=0

echo "Validating shell script syntax..."
while IFS= read -r -d '' script; do
  if ! bash -n "${script}"; then
    echo "Syntax validation failed: ${script}"
    failure_count=$((failure_count + 1))
  fi
done < <(find scripts Tools/ProjectScripts -type f -name '*.sh' -print0 2>/dev/null || true)

echo "Running shellcheck (severity=error)..."
while IFS= read -r -d '' script; do
  if ! shellcheck --severity=error "${script}"; then
    echo "ShellCheck failed: ${script}"
    failure_count=$((failure_count + 1))
  fi
done < <(find scripts Tools/ProjectScripts -type f -name '*.sh' -print0 2>/dev/null || true)

if [[ ${failure_count} -gt 0 ]]; then
  echo "Verification completed with ${failure_count} failure(s)."
  exit 1
fi

echo "Verification completed successfully. No repair actions were required."
