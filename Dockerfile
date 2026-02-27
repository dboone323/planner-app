# syntax=docker/dockerfile:1.5
# planner-app - Linux source image for split-platform CI

FROM swift:6.2 AS builder

WORKDIR /app

# Resolve dependencies for Linux-side validation; app compilation remains on macOS CI.
COPY Package.* ./
RUN --mount=type=cache,target=/root/.swiftpm,id=swiftpm \
    swift package resolve

COPY . .

FROM swift:6.2-slim

LABEL maintainer="tools-automation"
LABEL description="Planner App source workspace (Linux tooling image)"
LABEL org.opencontainers.image.source="https://github.com/tools-automation/planner-app"
LABEL org.opencontainers.image.documentation="https://github.com/tools-automation/planner-app/wiki"

WORKDIR /workspace

RUN groupadd -r planneruser && useradd -r -g planneruser -u 1001 planneruser

COPY --from=builder --chown=planneruser:planneruser /app /workspace

USER planneruser

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD test -f /workspace/Package.swift || exit 1

CMD ["/bin/sh", "-lc", "echo 'planner-app source container ready (macOS builds app binaries)'; sleep infinity"]
