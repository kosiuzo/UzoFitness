# UzoFitnessCore Migration Plan

This document outlines the step-by-step process to create and integrate a new `UzoFitnessCore` module for sharing models, protocols, and business logic between your iOS and watchOS apps, as required by your WatchAppIntegrationPlan.md.

---

## 1. Create the UzoFitnessCore Swift Package

- In Xcode, go to **File > New > Package...**
- Name it `UzoFitnessCore`.
- Place it at the root of your repo (sibling to `UzoFitness/`).

**Checklist:**
- [x] Create UzoFitnessCore Swift Package
- [ ] Add UzoFitnessCore to your Xcode project as a local package

---

## 2. Move and Refactor Models

- **Move all files from `UzoFitness/Models/`** (including subfolders like `Extensions/`) to `UzoFitnessCore/Sources/UzoFitnessCore/Models/` and `UzoFitnessCore/Sources/UzoFitnessCore/Extensions/`.
- **Ensure all models conform to `Codable`** (add conformance if missing).
- **Move model protocols** (e.g., `Identified`, `Timestamped`) to `UzoFitnessCore/Sources/UzoFitnessCore/Protocols/`.
- **Refactor all references in your main app and other targets to import and use the models, extensions, and protocols from the new local package (`UzoFitnessCore`) instead of their old locations.**
- **Build the project to ensure all references are updated and everything compiles successfully.**

**Checklist:**
- [x] Move all model files to UzoFitnessCore
- [x] Move all model extensions to UzoFitnessCore
- [x] Move model protocols to UzoFitnessCore
- [x] Ensure all models conform to Codable
- [x] Refactor all references in the app to use UzoFitnessCore
    - [x] UzoFitness/Persistence/PersistenceController.swift
    - [x] UzoFitness/ViewModels/LibraryViewModel.swift
    - [x] UzoFitness/ViewModels/LoggingViewModel.swift
    - [x] UzoFitness/ViewModels/ProgressViewModel.swift
    - [x] UzoFitness/ViewModels/HistoryViewModel.swift
    - [x] (Any other ViewModels or files referencing models)
    - [x] (Any SwiftUI Views referencing models directly)
- [x] Build the project to verify

---

## 3. Move and Refactor Service Protocols

- **Create `Services/` in UzoFitnessCore**.
- **Move or create protocols** for all business logic/services that need to be shared:
    - `HealthStoreProtocol`
    - `WorkoutSessionServiceProtocol`
    - `PhotoServiceProtocol`
    - Any other service interfaces needed for sync, timer, etc.
- **Move only protocol definitions and pure logic** (no UIKit/SwiftUI or platform-specific code).

**Checklist:**
- [x] Create Services directory in UzoFitnessCore
- [x] Move HealthStoreProtocol to UzoFitnessCore
- [x] Move PhotoServiceProtocol to UzoFitnessCore
- [x] Move other service protocols to UzoFitnessCore
- [x] Refactor references to use protocols from UzoFitnessCore
- [x] Build the project to verify

**Status:** ✅ **COMPLETED** - All service protocols have been successfully moved to UzoFitnessCore and the project builds successfully. The following protocols were moved:
- HealthStoreProtocol
- PhotoServiceProtocol  
- FileSystemServiceProtocol
- ImagePickerServiceProtocol
- DataPersistenceServiceProtocol
- QueryExecutorProtocol
- CalendarProtocol
- HealthKitTypeFactoryProtocol

All references have been updated to use the protocols from UzoFitnessCore, and compilation errors have been resolved.

---

## 4. Move Non-UI Utilities

- **Move `Logger.swift` and other non-UI helpers** to `UzoFitnessCore/Sources/UzoFitnessCore/Utilities/`.
- **Remove or refactor any UIKit/SwiftUI dependencies** from these utilities.

**Checklist:**
- [x] Move Logger.swift to UzoFitnessCore
- [x] Move other non-UI utilities to UzoFitnessCore
- [x] Refactor references to use utilities from UzoFitnessCore
- [x] Build the project to verify

**Status:** ✅ **COMPLETED** - All non-UI utilities have been successfully moved to UzoFitnessCore and the project builds successfully. The following utilities were moved:
- Logger.swift (already moved)
- DateFormatters.swift (new shared DateFormatter extensions)
- FormattingUtilities.swift (new shared formatting functions for weight, volume, time, etc.)

All references have been updated to use the utilities from UzoFitnessCore, and compilation errors have been resolved. The formatting utilities provide reusable functions for weight, volume, time, and duration formatting that can be shared between iOS and watchOS apps.

---

## 5. Refactor ViewModels for Shared Logic (Optional/Advanced)

- **If any ViewModel contains pure business logic**, extract that logic into a new file in Core (e.g., `WorkoutSessionLogic.swift`).
- **Define protocols for ViewModels** in Core if you want to enforce shared interfaces.
- **Keep UI-specific ViewModel code in the iOS/watchOS targets.**

**Checklist:**
- [ ] Identify shared logic in ViewModels
- [ ] Extract shared logic to UzoFitnessCore
- [ ] Define ViewModel protocols in UzoFitnessCore (if needed)
- [ ] Refactor references to use shared logic/protocols
- [ ] Build the project to verify

---

## 6. Update Imports and References

- In your iOS app, **replace imports** of moved files with `import UzoFitnessCore`.
- **Update all references** to moved types, protocols, and helpers.
- **Add UzoFitnessCore as a dependency** to your iOS target (and later, your watchOS target).

**Checklist:**
- [ ] Replace imports in iOS app
- [ ] Update all references to moved code
- [ ] Add UzoFitnessCore as a dependency to iOS target
- [ ] Add UzoFitnessCore as a dependency to watchOS target (when created)
- [ ] Build the project to verify

---

## 7. Prepare for Watch App Integration

- **Ensure all shared models and protocols are available in Core**.
- **Implement platform-specific service classes** (e.g., `HealthKitManager`, `PhotoService`) in each target, conforming to the protocols in Core.
- **Sync logic** (e.g., for marking sets complete, starting timers) should use the shared models and protocols.

**Checklist:**
- [ ] Confirm all shared models/protocols are in Core
- [ ] Implement platform-specific service classes in each target
- [ ] Refactor sync logic to use shared models/protocols
- [ ] Build and test both targets

---

## 8. Test the Migration

- **Build and run the iOS app** to ensure everything compiles and works.
- **Write unit tests** for shared logic in Core.
- **Prepare for watchOS target** by confirming all needed types are available in Core.

**Checklist:**
- [ ] Build and run iOS app
- [ ] Write unit tests for shared logic
- [ ] Confirm all needed types are available for watchOS
- [ ] Build and test watchOS target (when created)

---

## Example: UzoFitnessCore Structure

```
UzoFitnessCore/
└── Sources/
    └── UzoFitnessCore/
        ├── Models/
        │   ├── WorkoutSession.swift
        │   ├── Exercise.swift
        │   └── ...
        ├── Extensions/
        │   ├── Exercise+Validation.swift
        │   └── ...
        ├── Protocols/
        │   ├── Identified.swift
        │   ├── Timestamped.swift
        │   └── ...
        ├── Services/
        │   ├── HealthStoreProtocol.swift
        │   ├── WorkoutSessionServiceProtocol.swift
        │   └── ...
        └── Utilities/
            ├── Logger.swift
            └── ...
```

---

## 9. Update Xcode Project and Package.swift

- **Add UzoFitnessCore as a dependency** to your iOS app target.
- **Update your `Package.swift`** in the root if you want to use local package references.

**Checklist:**
- [ ] Add UzoFitnessCore as a dependency to iOS app target
- [ ] Update root Package.swift if needed
- [ ] Build the project to verify

---

## 10. Document the Migration

- **Update your README and internal docs** to reflect the new structure and usage.

**Checklist:**
- [ ] Update README
- [ ] Update internal documentation
- [ ] Communicate changes to team 