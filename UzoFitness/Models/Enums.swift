import Foundation

enum ExerciseCategory: String, Codable, CaseIterable {
  case strength = "strength"
  case cardio = "cardio"
  case mobility = "mobility"
  case balance = "balance"
}

enum Weekday: Int, Codable, CaseIterable {
  case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
}

enum PhotoAngle: String, Codable, CaseIterable {
  case front = "front"
  case side = "side"
  case back = "back"
}
