//
//  ProgressPhoto+DuplicateDetection.swift
//  UzoFitness
//
//  Created by Kosi Uzodinma on 7/4/25.
//

import Foundation

extension ProgressPhoto {
    /// Returns true if this photo is considered a duplicate of another (same assetIdentifier and angle).
    func isDuplicate(of other: ProgressPhoto) -> Bool {
        return self.assetIdentifier == other.assetIdentifier && self.angle == other.angle
    }
    
    /// Static helper for duplicate detection
    static func isDuplicate(candidate: (assetIdentifier: String, angle: PhotoAngle), existing: ProgressPhoto) -> Bool {
        return candidate.assetIdentifier == existing.assetIdentifier && candidate.angle == existing.angle
    }
} 