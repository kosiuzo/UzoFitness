# Library Screen & ViewModel Integration PRD

## 1. Overview  
Enable a fitness enthusiast to fully manage their personal exercise catalog and workout templates/plans in a single **Library** screen. Using a segmented picker, users switch between **Workouts** and **Exercises**; they can CRUD items in each, configure per-day templates, group exercises into supersets, set rest days, and import bulk data via JSON.

---

## 2. Objectives  
- **Unified UI**: Single screen with “Workouts”/“Exercises” toggle  
- **Workout Templates & Plans**: Create, view, edit, delete templates and plans; mark an active plan  
- **Day-of-Week Prefill**: Auto-populate 7 day-templates (Mon–Sun) on new workout template  
- **Exercise Template Editing**: Adjust sets, reps, weight, rest time; assign to supersets  
- **Exercise Catalog**: Full CRUD for individual exercises (name, category, instructions)  
- **Bulk Import**: JSON import for exercises and workout templates, with clear schema and error feedback  
- **Minimalist Design**: Follow existing iOS minimalist style guidelines for spacing, typography, and color  

---

## 3. User Stories  
1. **Switch Context**  
   - As a user, I toggle between Workouts and Exercises to manage each separately.  
2. **Manage Exercises**  
   - As a user, I create, edit, and delete exercises with name, category, and instructions.  
3. **Build Workout Templates**  
   - As a user, I create a workout template and immediately see day-of-week slots (Mon…Sun).  
4. **Populate Days**  
   - As a user, I tap a day slot and add one or multiple exercises in one action.  
5. **Configure Exercise Templates**  
   - As a user, for each exercise in a day, I adjust sets, reps, weight, and rest time, and optionally assign it to a superset.  
6. **Mark Rest Days**  
   - As a user, I toggle a “Rest Day” flag for any day slot.  
7. **Create Workout Plans**  
   - As a user, I generate a workout plan from a template and see which plan is active.  
8. **Bulk Import**  
   - As a user, I tap “Import from JSON” under either tab, paste valid JSON, and bulk-create items; if JSON is malformed or missing required fields, I see a clear error with the expected schema.  

---

## 4. Functional Requirements

### 4.1 Segmented Picker  
- **LibraryView**  
  ```swift
  Picker("", selection: $viewModel.selectedSegment) {
    Text("Workouts").tag(LibrarySegment.workouts)
    Text("Exercises").tag(LibrarySegment.exercises)
  }
  .pickerStyle(SegmentedPickerStyle())

	•	LibraryViewModel

enum LibrarySegment { case workouts, exercises }
@Published var selectedSegment: LibrarySegment = .workouts



4.2 Exercises Tab
	•	View
	•	List bound to viewModel.exercises
	•	“+” button invokes viewModel.showCreateExercise()
	•	Each cell shows name, category; swipe-to-delete
	•	ViewModel

@Published var exercises: [Exercise] = []
func createExercise(name: String, category: String, instructions: String)
func updateExercise(_ exercise: Exercise)
func deleteExercise(_ exercise: Exercise)



4.3 Workouts Tab
	•	Workout Templates Section
	•	List bound to viewModel.workoutTemplates
	•	“+” button → viewModel.createWorkoutTemplate(name:)
	•	Workout Plans Section
	•	List bound to viewModel.workoutPlans
	•	Highlight plan where isActive == true
	•	“Create Plan” button → viewModel.createPlan(from: selectedTemplate)
	•	ViewModel

@Published var workoutTemplates: [WorkoutTemplate] = []
@Published var workoutPlans: [WorkoutPlan] = []
func createWorkoutTemplate(name: String)
func deleteWorkoutTemplate(_ tpl: WorkoutTemplate)
func createPlan(from template: WorkoutTemplate)



4.4 Day-of-Week Prefill
	•	On createWorkoutTemplate, the ViewModel:

let days = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
newTemplate.dayTemplates = days.map { DayTemplate(dayAcronym: $0) }



4.5 Day Detail & Exercise Templates
	•	DayDetailView
	•	Lists dayTemplate.exerciseTemplates
	•	“Add Exercise” button → single sheet allowing multi-select
	•	ViewModel

func addExercises(_ exercises: [Exercise], to day: DayTemplate)
func updateExerciseTemplate(_ et: ExerciseTemplate,
                            sets: Int, reps: Int,
                            weight: Double?, rest: TimeInterval,
                            supersetID: UUID?)
func toggleRestDay(_ day: DayTemplate, isRest: Bool)



4.6 Supersets
	•	Supersets identified by a shared supersetID: UUID on each ExerciseTemplate
	•	ViewModel helper:

func assignSuperset(_ groupID: UUID, to templates: [ExerciseTemplate])



4.7 JSON Import
	•	Schema
Exercises JSON

{
  "exercises": [
    {
      "name": "Goblet Squat",
      "category": "Legs",
      "instructions": "Feet shoulder-width …"
    }
  ]
}

Workout Templates JSON

{
  "templates": [
    {
      "name": "4-Day Split",
      "days": [
        {
          "day": "Mon",
          "restDay": false,
          "exercises": [
            {
              "name": "Bench Press",
              "supersetGroup": null,
              "sets": 4,
              "reps": 8,
              "rest": 90
            }
          ]
        }
      ]
    }
  ]
}


	•	ViewModel

enum ImportError: LocalizedError {
  case malformedJSON, missingField(String)
}

func importExercises(from data: Data) throws
func importWorkoutTemplates(from data: Data) throws

@Published var importErrorMessage: String?


	•	Error Handling
	•	malformedJSON → “Invalid JSON. Ensure it matches the schema…”
	•	missingField("name") → “Missing field ‘name’ in exercise object.”

⸻

5. Non-Functional Requirements
	•	Design: Adhere to minimalist iOS style (ample whitespace, SF font, light gray separators)
	•	Architecture: MVVM with SwiftData (or Core Data) for persistence
	•	Performance:
	•	Limit JSON imports to ~5 MB files
	•	Support up to 200 exercises per import batch
	•	Accessibility: VoiceOver labels on all buttons/fields; Dynamic Type support

⸻

6. Success Criteria
	•	✅ User can switch between Workouts/Exercises without errors
	•	✅ Full CRUD on exercises and workout templates
	•	✅ Day templates prefill correctly; rest-day toggle works
	•	✅ Exercise template edits (sets, reps, weight, rest, supersets) persist
	•	✅ Workout plans can be created from templates and marked active
	•	✅ JSON import succeeds when valid and surfaces clear errors when invalid

⸻

7. Out of Scope
	•	Multi-user/template sharing or syncing
	•	Offline JSON editing beyond import flow
	•	Third-party integrations for template exchange

⸻

8. Dependencies & Next Steps
	1.	Finalize JSON schema and share sample files
	2.	Scaffold LibraryViewModel and stub methods
	3.	Build LibraryView UI panels and bind to ViewModel
	4.	Implement import parsers and error messaging
	5.	Write unit tests for each CRUD and import flow

