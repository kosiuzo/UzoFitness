# Workout Template JSON Import Implementation Tasks

## 1. UI Integration  
- [ ] Add **+** button to the top-right of the Workout Templates list view  
  - [ ] Use system navigation bar item with accent color  
  - [ ] Wire tap action to present system `.json` file picker  

## 2. Data Transfer Objects (DTOs)  
- [ ] Define `WorkoutTemplateImportDTO: Codable` with fields (`id?`, `name`, `summary`, `createdAt`, `days: [DayImportDTO]`)  
- [ ] Define `DayImportDTO: Codable` with (`dayIndex`, `name`, `exercises: [ExerciseImportDTO]`)  
- [ ] Define `ExerciseImportDTO: Codable` with (`id?`, `name`, `sets`, `reps`, `weight`, `supersetGroup?`)  
- [ ] Add validation methods on DTOs to check required fields and ranges  

## 3. Model Updates & Codable Conformance  
- [ ] Ensure `WorkoutTemplate`, `DayTemplate`, and `ExerciseTemplate` conform to `Codable`  
- [ ] Add or update `CodingKeys` and nested container code to match the JSON schema  
- [ ] Write unit tests to verify model encode/decode round-trip  

## 4. Import Service & Parsing  
- [ ] Create `WorkoutTemplateImportService` with method `import(from url: URL)`  
  - [ ] Load file into `Data` asynchronously  
  - [ ] Decode `WorkoutTemplateImportDTO` with JSONDecoder (ISO8601 date strategy)  
  - [ ] Run `dto.validate()` and collect errors  
- [ ] Map DTOs to core model instances, preserving provided `id` when present  

## 5. Persistence & Concurrency  
- [ ] In `WorkoutTemplateImportService`, save mapped models to persistence (SwiftData/Core Data) on a background context  
- [ ] Handle create vs. update logic:  
  - [ ] If imported `id` matches existing template, prompt overwrite or skip  
  - [ ] Otherwise insert new template  

## 6. UI Feedback & Error Handling  
- [ ] On validation or decode failure, present an alert listing each field error (e.g., “Missing `days` array”, “Exercise `sets` must be >0”)  
- [ ] On duplicate-ID conflict, present choice: Overwrite / Skip  
- [ ] On successful import, dismiss picker and show toast:  
  > “Imported 1 template with X days.”  
- [ ] Ensure alerts and toasts follow minimalist styling and accessibility  

## 7. Dependency Injection  
- [ ] Register `WorkoutTemplateImportService` and JSON decoder in DI container  
- [ ] Inject service into Workout Templates list view model  

## 8. Testing  
- [ ] **Unit tests** for DTO decoding & validation:  
  - [ ] Valid sample JSON decodes without errors  
  - [ ] Missing/invalid fields produce expected validation messages  
- [ ] **Integration tests** for `WorkoutTemplateImportService`:  
  - [ ] Simulated file import creates or updates templates in persistence  
  - [ ] Error cases surface correct alerts  
- [ ] **UI tests** (optional):  
  - [ ] Tap **+**, select a valid JSON file, assert template appears in list  
  - [ ] Select malformed JSON, assert error alert displays  

## 9. QA & Manual Validation  
- [ ] Manually import a well-formed JSON file—verify template, days, and exercises appear correctly  
- [ ] Import JSON missing required fields—confirm alert lists missing items  
- [ ] Import with existing template ID—test overwrite and skip paths  
- [ ] Validate VoiceOver reads alerts and toast messages  