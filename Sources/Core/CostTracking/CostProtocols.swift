// MARK: - Cost Tracking Protocols

import Foundation

/// Any source that emits cost data.
public protocol CostSource: AnyObject {
    var onCostEntry: ((CostEntry) -> Void)? { get set }
}

/// Aggregates costs at multiple levels: session → project → fleet.
public protocol CostAggregating: AnyObject {
    func record(_ entry: CostEntry)
    func totalCost(forSession sessionId: String) -> Decimal
    func totalCost(forProject projectId: String) -> Decimal
    func fleetTotalCost() -> Decimal
    func costHistory(from: Date, to: Date) -> [CostEntry]
    func dailyCost(forDate date: Date) -> Decimal

    var onCostUpdate: (() -> Void)? { get set }
}
