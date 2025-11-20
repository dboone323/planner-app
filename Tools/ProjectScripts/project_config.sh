#!/bin/bash
# Project configuration for PlannerApp

export ENABLE_AUTO_BUILD=true
export ENABLE_AI_ENHANCEMENT=true
export ENABLE_AUTO_TEST=true
export PROJECT_NAME="PlannerApp"
SETUP_PATH="$(git rev-parse --show-toplevel 2>/dev/null)/scripts/setup_paths.sh"
if [[ -f "${SETUP_PATH}" ]]; then
	# shellcheck disable=SC1090
	source "${SETUP_PATH}"
fi

export PROJECT_DIR="${PROJECT_DIR:-${WORKSPACE_ROOT}/PlannerApp}"
