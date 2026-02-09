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
		-scheme PlannerApp \
		-destination 'platform=iOS Simulator,name=iPhone 17' \
		-configuration Debug

test-macos:
	xcodebuild test \
		-scheme PlannerApp \
		-destination 'platform=macOS' \
		-configuration Debug

test: test-ios test-macos
