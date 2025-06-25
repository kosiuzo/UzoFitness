# PRD: Workout Template JSON Import

## 1. Introduction / Overview

The **Workout Template JSON Import** feature enables fitness enthusiasts to bulk-create or update workout templates by supplying a structured JSON payload. This accelerates setup for new programs by reducing manual entry and leverages the existing model architecture (e.g., `WorkoutTemplate`, `DayTemplate`, `ExerciseTemplate`) for seamless Codable-based serialization/deserialization.

## 2. Goals

1. Define a clear JSON schema representing workout templates, days, exercises, and superset groups.
2. Allow users to import a JSON file via a “+” button in the Workout Templates screen.
3. Parse and validate the JSON against the app’s models, creating or updating templates.
4. Surface import errors with actionable messages.
5. Maintain minimalist UI consistency with the rest of the app.

## 3. User Stories

* **Bulk Template Creation**

  * *As a fitness enthusiast, I want to upload a JSON file defining my 4‑day split so I can start logging immediately without numerous taps.*
* **Validation Feedback**

  * *As a user, I want to see clear errors if my JSON is missing required fields (e.g., day names or exercise reps) so I can correct it quickly.*
* **Superset Support**

  * *As a user, I want to group exercises into supersets in my JSON so the import reflects those relationships in the logging UI.*

## 4. Functional Requirements

1. **Import Trigger**

   * Add a **+** button in the top-right of the Workout Templates list view.
   * Tapping it opens a system file picker restricted to `.json` files.
2. **JSON Schema**

   ```json
   {
     "id": "UUID-string",             // optional; generate if missing
     "name": "Template Name",
     "summary": "Brief description",
     "createdAt": "ISO8601 timestamp",
     "days": [
       {
         "dayIndex": 1,
         "name": "Leg Day",
         "exercises": [
           {
             "id": "UUID-string",
             "name": "Squat",
             "sets": 3,
             "reps": 8,
             "weight": 185.0,
             "supersetGroup": null     // or integer group ID
           },
           // ... more exercises
         ]
       },
       // ... more days
     ]
   }
   ```
3. **Model Codable Conformance**

   * Ensure `WorkoutTemplate`, `DayTemplate`, and `ExerciseTemplate` conform to `Codable`.
   * Add any missing coding keys or nested containers to match the schema.
4. **Parsing & Persistence**

   * Read the selected JSON file into `Data`.
   * Decode into `WorkoutTemplateImportDTO` intermediate structs if needed.
   * Map DTOs to model instances, preserving existing IDs when provided.
   * Save to persistence (SwiftData/Core Data) within a background context.
5. **Error Handling**

   * Detect schema mismatches (missing fields, wrong types) and present an alert listing each issue.
   * Handle duplicate template names or IDs by prompting to overwrite or skip.
6. **Success Feedback**

   * On successful import, dismiss the picker and display a toast: “Imported 1 template with X days.”
   * Automatically refresh the workout templates list.

## 5. Non-Goals

* Editing JSON in-app—imports are one-shot operations.
* Supporting formats other than JSON (e.g. CSV, XML).
* Real-time import progress for very large files (expected small payloads).

## 6. Design Considerations

* **Minimalist UI:** The **+** button should use the system accent color and sit flush in the navigation bar.
* **Error Messaging:** Alerts should be concise, listing only field names or line numbers where parsing failed.
* **Accessibility:** Ensure the file picker is accessible via VoiceOver and that alerts are announced.

## 7. Technical Considerations

* **DTO vs. Model:** Consider using separate import DTOs (`Codable` structs) to protect the core model from breaking changes.
* **Concurrency:** Decode & save on a background queue to avoid blocking the main thread.
* **Dependency Injection:** Supply the JSON parser and persistence service via the existing DI container.
* **Model Validation:** Implement `validate()` methods on DTOs to enforce business rules (e.g., at least one exercise per day).

## 8. Success Metrics

* **Usability:** ≥90% of users who try import succeed on first attempt.
* **Reliability:** 0 import-related crashes in QA and early releases.
* **Adoption:** ≥30% of new power users use JSON import within first week.

## 9. Open Questions

* Should we support importing multiple templates from a single JSON array?
* Do we need a preview screen before finalizing the import?
* How do we handle versioning if we evolve the JSON schema over time?

---

*End of Document*
