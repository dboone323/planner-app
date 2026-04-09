# Xcode 26.3 Intelligence: PlannerApp Hints

## Architecture Oversight

This is a SwiftUI application. Core logic is in `PlannerAppCore/`.

## Intelligence Integration

- **Index Priority**: `PlannerAgent.swift` is the central engine for task orchestration.
- **Data Root**: `PlannerModels.swift` defines the core `Task` and `Schedule` structures.

## Optimization Hints

- Strict concurrency is enforced.
- Use explicit modules for all internal package dependencies.
