//
//  Utils.swift
//  
//
//  Created by Marcin Mucha on 22/06/2022.
//

import Foundation

@discardableResult
func retryAsync<T>(
    shouldRetry: @escaping (Error) -> Bool,
    delayPolicy: DelayPolicy = .immediate,
    attemptsLeft: Int,
    currentAttempt: Int = 0,
    attempt: @escaping () async throws -> T
) async throws -> T {
    let delayTime = delayPolicy.delay(for: currentAttempt)
    do {
        if delayTime > 0, currentAttempt > 0 {
            try await Task.sleep(nanoseconds: UInt64(delayTime * 1e+9))
            return try await attempt()
        } else {
            return try await attempt()
        }
    } catch {
        guard shouldRetry(error), attemptsLeft > 0, !(error is CancellationError) else {
            throw error
        }

        return try await retryAsync(
            shouldRetry: shouldRetry,
            delayPolicy: delayPolicy,
            attemptsLeft: attemptsLeft - 1,
            currentAttempt: currentAttempt + 1,
            attempt: attempt
        )
    }
}

enum DelayPolicy {
    case immediate
    case constant(time: TimeInterval)
    case exponential(initial: TimeInterval, multiplier: Double, maxDelay: TimeInterval)
    case custom(closure: (Int) -> TimeInterval)

    func delay(for attempt: Int) -> TimeInterval {
        guard attempt > 0 else { return 0.0 }
        switch self {
        case .immediate: return 0.0
        case .constant(let time): return time
        case .exponential(let initial, let multiplier, let maxDelay):
            let delay = initial * pow(multiplier, Double(attempt - 1))
            return min(maxDelay, delay)
        case .custom(let closure): return closure(attempt)
        }
    }
}
