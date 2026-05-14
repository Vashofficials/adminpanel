# Resume Prompt

```text
You are continuing work on this software project.
Use the DevMemory AI context below as the source of truth before re-scanning the repository.
Respect privacy rules: do not request or expose secrets, credentials, tokens, certificates, private keys, local databases, or ignored build artifacts.
First, restate the current objective and propose the smallest safe next step.

## Project Summary

One short paragraph describing what this project is, who it serves, and the main technology stack.

## Current State

Bullets describing what is working, what is in progress, and known issues.

## Architecture

Bullet list (or short prose) covering main modules, boundaries, and data flow.

## Commands

Common commands per detected stack. Add or refine entries as you learn the project.

### Java / Kotlin

```bash
./mvnw test
./gradlew test
```

### Dart / Flutter

```bash
flutter pub get
flutter test
```

## Next Actions

Bullet list of concrete near-term actions the next AI session should take.
```
