import Combine
import Foundation
import HealthKit
import HealthQuestCore

/// Wrapper for core HealthKitService to maintain compatibility in PlannerApp
@MainActor
public class HealthKitManager: ObservableObject {
    public static let shared = HealthKitManager()
    private let coreService = HealthKitService.shared
    private var cancellables = Set<AnyCancellable>()

    @Published public var isAuthorized = false
    @Published public var stepCount: Int = 0
    @Published public var activeEnergyBurned: Double = 0.0
    @Published public var exerciseMinutes: Int = 0

    private init() {
        // Bind to core service properties
        coreService.$isAuthorized
            .assign(to: \.isAuthorized, on: self)
            .store(in: &cancellables)
        
        coreService.$stepCount
            .assign(to: \.stepCount, on: self)
            .store(in: &cancellables)
            
        coreService.$activeEnergyBurned
            .assign(to: \.activeEnergyBurned, on: self)
            .store(in: &cancellables)
            
        coreService.$exerciseMinutes
            .assign(to: \.exerciseMinutes, on: self)
            .store(in: &cancellables)
    }

    public func requestAuthorization() async throws {
        try await coreService.requestAuthorization()
    }

    public func fetchTodayStats() async {
        await coreService.fetchTodayStats()
    }

    public func logWorkout(
        type: HKWorkoutActivityType,
        startDate: Date,
        endDate: Date,
        energyBurned: Double? = nil
    ) async throws {
        try await coreService.logWorkout(
            type: type,
            startDate: startDate,
            endDate: endDate,
            energyBurned: energyBurned
        )
    }
}
