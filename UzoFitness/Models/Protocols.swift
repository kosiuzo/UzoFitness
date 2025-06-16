import Foundation

/// Gives every model a UUID `id` + native Identifiable/Hashable conformance.
protocol Identified: Identifiable, Hashable {
  var id: UUID { get set }
}

/// Gives any model a creation timestamp.
protocol Timestamped {
  var createdAt: Date { get set }
}

/// Convenience to avoid hard-coding your entity names.
extension Identified {
  static var entityName: String {
    String(describing: Self.self)
  }
}
