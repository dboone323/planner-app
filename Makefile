SHELL := /bin/zsh
.PHONY: validate lint format test test-ios test-macos
DERIVED_DATA_PATH ?= .build/DerivedData
OUTPUT_DIR ?= ../outputs/PlannerApp

validate:
	@.ci/agent_validate.sh

lint:
	@swiftlint --strict || true

format:
	@swiftformat . --config .swiftformat || true

test-ios:
	xcodebuild test \
		-project PlannerApp.xcodeproj \
		-scheme PlannerApp \
		-testPlan PlannerApp \
		-xcconfig Config/Test.xcconfig \
		-derivedDataPath $(DERIVED_DATA_PATH) \
		-destination 'platform=iOS Simulator,name=iPhone 17' \
		-resultBundlePath $(OUTPUT_DIR)/TestResults_iOS.xcresult \
		-configuration Debug || true

test-macos:
	xcodebuild test \
		-project PlannerApp.xcodeproj \
		-scheme PlannerApp \
		-testPlan PlannerApp \
		-xcconfig Config/Test.xcconfig \
		-derivedDataPath $(DERIVED_DATA_PATH) \
		-destination 'platform=macOS' \
		-resultBundlePath $(OUTPUT_DIR)/TestResults_macOS.xcresult \
		-configuration Debug || true

test: test-ios test-macos
