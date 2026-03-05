# PlannerApp: Agentic Grounding (Feb 2026)

## Purpose

PlannerApp is a productivity suite featuring autonomous schedule optimization and task prioritization.

## Core Objectives

1. **Schedule Optimization**: Intelligently arrange tasks to maximize user productivity based on historical patterns.
2. **Contextual Prioritization**: Automatically adjust task importance based on deadlines and project dependencies.

## Agent Instructions

- **User Preference First**: Always respect manually set priorities and time blocks.
- **Proactive Planning**: Suggest scheduling optimizations when gaps are detected in the timeline.

## Constraints

- Must use `SharedKit` for cross-project data consistency.
- Adhere to the `BaseAgent` execution pattern.

## March 2026 Code Standards

- **No Stubs/Mocks**: Do not use placeholders, mocks, or stubs in implementation or testing.
- **Production Ready**: Every new line of code must be real, working, and production-ready.
- **End-to-End Testing**: Use real working and tested code to verify behavior natively to avoid down-the-line problems.
- **Modern Standards**: Adhere strictly to the latest ecosystem standards (Swift 6.2 concurrency, Python 3.13).
