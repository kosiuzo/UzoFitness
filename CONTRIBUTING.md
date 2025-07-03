# Contributing to UzoFitness

Thank you for taking the time to contribute! This guide explains how to set up the project, run tests and follow our coding conventions.

## Development setup

1. **Requirements**
   - Xcode **15.4** or later
   - An iOS 17 simulator or device (e.g. *iPhone 15*)

2. **Run the app**
   - Open `UzoFitness.xcodeproj` in Xcode and hit **Run (⌘R)**, **or**
   - Build from the command line:
     ```bash
     xcodebuild -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0'
     ```

3. **Execute the test suite**
   - From Xcode use **Product → Test (⌘U)**, **or**
   - Via command line:
     ```bash
     xcodebuild test -scheme UzoFitness -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0'
     ```

## Coding standards

- Code should compile under Swift 5 and follow the Swift API Design Guidelines.
- Run [`swiftformat`](https://github.com/nicklockwood/SwiftFormat) and [`swiftlint`](https://github.com/realm/SwiftLint) before committing:
  ```bash
  swiftformat .
  swiftlint
  ```
- Keep pull requests focused and self‑contained.

## Pull request process

1. Fork the repo and create a feature branch.
2. Ensure `swiftformat` and `swiftlint` produce no warnings or errors.
3. Run the full test suite with `xcodebuild test`.
4. Submit your pull request describing the changes and referencing any issues.
5. One team member will review and merge when ready.

Thanks again for contributing!
