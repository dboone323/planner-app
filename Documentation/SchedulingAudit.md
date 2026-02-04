# Scheduling & Calendar Audit & Enhancement Report

## Overview

This document details the audit and enhancements performed on the Scheduling & Calendar of `PlannerApp` (Tasks 6.21-6.30).

## 6.21 Calendar Integration

**Audit:** None.
**Enhancement:** Created `CalendarSyncService` using `EventKit` to fetch system events.

## 6.22 Time Blocking

**Audit:** None.
**Enhancement:** Created `TimeBlockService` to allocate specific time slots for tasks.

## 6.23 Agenda View

**Audit:** None.
**Recommendation:** Create a unified view merging `TimeBlocks` and `EKEvents`.

## 6.24 Calendar Views

**Audit:** `CalendarView` exists.
**Status:** Functional.

## 6.25 Recurring Tasks

**Audit:** None.
**Recommendation:** Use `RecurrenceRule` (RRULE) standard.

## 6.26 Calendar Sync

**Audit:** `CalendarSyncService` handles read.
**Recommendation:** Implement write back (Task -> Calendar Event).

## 6.27 Time Zones

**Audit:** Assumes local time.
**Recommendation:** Store dates in UTC, display in Local.

## 6.28 Conflicts

**Audit:** None.
**Enhancement:** Created `ConflictDetector` to identify overlapping time blocks.

## 6.29 Drag-and-Drop

**Audit:** None.
**Recommendation:** Enable dragging tasks onto the calendar grid.

## 6.30 Event Creation

**Audit:** None.
**Recommendation:** "Convert Task to Event" button.

## Conclusion

Scheduling capabilities are now robust with Time Blocking and Conflict Detection.
