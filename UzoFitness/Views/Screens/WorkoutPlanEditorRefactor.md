Here is the updated and complete PRD for the Workout Template Editor Redesign, incorporating:
	•	Rest Day toggle logic ✅
	•	Multi-exercise adding ✅
	•	New layout structure (Workout name, per-day editing, Add Day) ✅
	•	Clean, minimalist iOS feel based on the latest wireframe ✅

⸻

📄 PRD: Workout Template Editor Redesign

1. Overview

This feature revamps the Workout Template Editor to support faster workout creation and a cleaner, more intuitive UI. It adopts a vertical scroll layout showing all days, supports inline editing, rest day toggles, and multi-exercise additions—optimized for minimalist design and thumb-friendly iOS interaction.

⸻

2. Goals
	•	Create an intuitive, single-screen interface for managing a full workout template.
	•	Allow inline editing of days, exercises, and rest states without navigating away.
	•	Support multi-select exercise additions.
	•	Eliminate friction and clutter through minimalist layout and smooth transitions.

⸻

3. User Stories
	•	As a user, I want to quickly see and edit my workout plan without tapping into separate screens, so I can stay focused.
	•	As a user, I want to toggle a workout day as a Rest Day so that I don’t have to delete exercises manually.
	•	As a user, I want to add multiple exercises at once to speed up workout creation.
	•	As a user, I want to reorder or remove exercises easily to keep my plan flexible.

⸻

4. Functional Requirements

4.1 Workout Header
	•	The editor screen must include editable fields:
	•	Workout Name (non-empty, unique)
	•	Description (optional)
	•	“Cancel” and “Save” buttons must be pinned to the top navigation bar.

4.2 Day Template Display
	•	Each day should display:
	•	Weekday label (e.g., “Monday”)
	•	Rest Day toggle aligned to the right
	•	A container stack of exercise rows (if not a rest day)
	•	An optional Notes field (inline text editor)
	•	Exercise rows must show:
	•	Exercise name
	•	Summary of sets x reps
	•	Pencil/edit icon on right side
	•	Optional: Swipe to delete or context menu for reordering
	•	A visible “Add Exercise” button must appear below exercise rows (if isRest == false).

4.3 Rest Day Toggle Behavior
	•	Toggling the switch ON sets isRest = true:
	•	Hide all exercise rows and Add Exercise button.
	•	Replace with “Rest Day” label (visually muted).
	•	Toggling OFF restores previously added exercises.
	•	On first toggle ON only, show confirmation alert:
	•	Title: “Mark as Rest Day?”
	•	Message: “This will hide all exercises for this day. You can toggle again to bring them back.”
	•	Buttons: “Continue” (confirm), “Cancel” (revert toggle)

4.4 Add Exercise Flow
	•	Tap on “Add Exercise” opens a modal or sheet with:
	•	Scrollable list of all available exercises
	•	Checkmark-based multi-select capability
	•	After confirmation:
	•	All selected exercises are appended to the day’s exerciseTemplates
	•	Each row appears with default values (e.g., 3 sets × 8 reps)

4.5 Add Day Functionality
	•	“Add Day” button appears at the bottom of the screen.
	•	Adds a new day to the plan (defaults to next available weekday).
	•	Newly added day includes:
	•	Editable weekday (e.g., via picker or automatically sequential)
	•	Rest Day toggle, Notes field, and empty exercise list

4.6 Editing Exercises
	•	Tapping the pencil icon opens an inline or modal editor:
	•	Set count (stepper)
	•	Reps (stepper)
	•	Weight (optional)
	•	Rest (slider or text field)
	•	All inputs must update the ExerciseTemplate immediately on save.

⸻

5. Visual Design Requirements
	•	Use .systemGray6 for section backgrounds and separation.
	•	Exercise rows and day sections must have at least 16px vertical spacing.
	•	All text must use system fonts (San Francisco) with clear weight/size hierarchy.
	•	Icons must use SF Symbols only.
	•	Card corners: cornerRadius = 12-16.
	•	No unnecessary shadows, borders, or gradients.
	•	Transitions should use default SwiftUI .transition(.opacity.combined(with: .move)) where needed.

⸻

6. Non-Goals
	•	No superset grouping or drag-and-drop reordering in this version.
	•	No support for advanced programming logic (e.g., alternating days, progressions).

⸻

7. Success Criteria
	•	✅ The editor shows all workout days vertically with clear grouping.
	•	✅ User can edit workout name and description inline.
	•	✅ User can toggle a day to/from Rest mode with a confirmation (once).
	•	✅ User can add multiple exercises at once.
	•	✅ Each exercise shows a clean summary row with edit button.
	•	✅ No crashes or layout shifts when toggling between rest and workout mode.

Wireframe:
image.png