# QML Static Analysis Specification

## Purpose

Define Qt 6/KDE QML analysis for this non-CMake Plasma package while preserving behavior and translation extraction.

## Requirements

### Requirement: Non-CMake Language-Server Resolution

The repository MUST provide `.qmlls.ini` that disables CMake calls and declares the Qt/KDE QML import path. Import resolution MUST NOT require a CMake project or build metadata.

#### Scenario: Imports resolve in the package checkout

- GIVEN the repository is opened without a CMake build tree
- WHEN the language server analyzes `contents/ui`
- THEN configured Qt and KDE module imports resolve without CMake calls

#### Scenario: CMake metadata is absent

- GIVEN no `CMakeLists.txt` or CMake cache exists
- WHEN language-server configuration is evaluated
- THEN analysis remains configured and MUST NOT report missing CMake metadata as a prerequisite

### Requirement: Explicit Lint Diagnostic Policy

`.qmllint.ini` MUST keep import, missing-property, unresolved-alias, uncreatable-type, incompatible-type, required-property, and read-only-property diagnostics strict. `UnqualifiedAccess` MUST remain visible as a warning and MUST NOT be globally disabled.

#### Scenario: Fixable structural defect

- GIVEN `contents/ui` contains a configured structural defect
- WHEN `./scripts/lint-qml.sh` runs
- THEN the command fails and identifies the defect

#### Scenario: Intentional context-property access

- GIVEN only a documented Plasma context-property warning remains
- WHEN `./scripts/lint-qml.sh` runs
- THEN `UnqualifiedAccess` remains visible without failing solely for that warning

### Requirement: Bound UI Components

Affected QML documents under `contents/ui` MUST use bound component behavior, qualify outer-object access, and declare required delegate inputs such as `index` and consumed model roles. The resulting UI scope MUST have zero fixable structural warnings.

#### Scenario: Delegate consumes injected data

- GIVEN a delegate uses `index` or a model role
- WHEN static analysis inspects the delegate
- THEN that input is explicitly required and outer access is qualified

#### Scenario: Configuration QML is encountered

- GIVEN a QML file is under `contents/config`
- WHEN this change is reviewed
- THEN the file MUST remain outside the modernization scope

### Requirement: Translation and Plasma Warning Preservation

Existing KDE `i18n` and `i18np` call shapes MUST remain unchanged. Documentation MUST identify the intentional Plasma context-property warning baseline separately from fixable structural diagnostics.

#### Scenario: Translation-bearing expression is modernized

- GIVEN a changed `contents/ui` expression contains `i18n` or `i18np`
- WHEN the structural change is reviewed
- THEN the translation function and argument shape remain extraction-compatible

#### Scenario: Warning baseline is inspected

- GIVEN lint emits an accepted Plasma context-property warning
- WHEN a maintainer consults the documented baseline
- THEN the warning is identifiable and no structural warning is accepted through that baseline

### Requirement: Regression Verification

The change MUST pass `./scripts/run-qml-tests.sh`, `./scripts/lint-qml.sh`, and `git diff --check`. Existing harness coverage MUST continue to verify package behavior and the external `codexbar` CLI boundary, including exact argv where currently asserted.

#### Scenario: Complete verification succeeds

- GIVEN the modernization is complete
- WHEN all three required commands run
- THEN each exits successfully and existing harnesses retain their assertions

#### Scenario: Runtime or CLI regression occurs

- GIVEN a change alters covered UI behavior or CLI invocation
- WHEN the existing QML harness suite runs
- THEN verification fails rather than accepting the structural modernization

### Requirement: Contributor Guidance and Boundaries

README/tooling guidance MUST explain editor setup, lint policy, accepted warning baseline, and required verification. Guidance MUST target the Qt 6 KDE ecosystem and MUST NOT require Qt 6.11-only behavior, CMake integration, translation API substitution, provider/auth/fetching changes, or `contents/config` modernization.

#### Scenario: Contributor follows documented workflow

- GIVEN a contributor uses a compatible Qt 6 KDE environment
- WHEN they follow the README tooling steps
- THEN they can resolve imports, run lint, distinguish baseline warnings, and execute verification

#### Scenario: Proposed work crosses a boundary

- GIVEN a proposed edit affects an excluded subsystem or requires Qt 6.11-only behavior
- WHEN scope is assessed
- THEN it MUST be rejected from this change or deferred to a follow-up
