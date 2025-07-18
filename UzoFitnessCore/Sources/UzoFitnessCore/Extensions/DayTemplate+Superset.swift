//
//  DayTemplate+Superset.swift
//  UzoFitness
//
//  Created by Kosi Uzodinma on 6/21/25.
//


import Foundation
import SwiftData

// MARK: - DayTemplate Superset Extension
extension DayTemplate {
    /// Returns the 1-based position of a given superset in this day template.
    /// - Parameter supersetID: The UUID of the superset to locate.
    /// - Returns: The superset’s index (1-based) if found, otherwise nil.
    public func getSupersetNumber(for supersetID: UUID) -> Int? {
        // Gather all superset IDs on this day
        let allIDs = exerciseTemplates.compactMap { $0.supersetID }
        // Remove duplicates
        let uniqueIDs = Set(allIDs)
        // Sort deterministically by string form
        let sortedIDs = uniqueIDs.sorted { $0.uuidString < $1.uuidString }
        // Find the index and convert to 1-based
        guard let zeroBasedIndex = sortedIDs.firstIndex(of: supersetID) else {
            return nil
        }
        return zeroBasedIndex + 1
    }
}
