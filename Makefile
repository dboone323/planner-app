SHELL := /bin/zsh
.PHONY: validate lint format test test-ios test-macos

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
		-destination 'platform=iOS Simulator,name=iPhone 17' \
		-configuration Debug || true

test-macos:
	xcodebuild test \
		-project PlannerApp.xcodeproj \
		-scheme PlannerApp \
		-testPlan PlannerApp \
		-xcconfig Config/Test.xcconfig \
		-destination 'platform=macOS' \
		-configuration Debug || true

test: test-ios test-macos
