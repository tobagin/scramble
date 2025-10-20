<!-- OPENSPEC:START -->
# OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:
- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:
- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->

### = Project Awareness & Context
- **Always read `PLANNING.md`** at the start of a new conversation to understand the project's architecture, goals, style, and constraints.
- **Check `TASK.md`** before starting a new task. If the task isn't listed, add it with a brief description and today's date.
- **Use consistent naming conventions, file structure, and architecture patterns** as described in `PLANNING.md`.

### >� Code Structure & Modularity
- **Never create a file longer than 500 lines of code.** If a file approaches this limit, refactor by splitting it into modules or helper files.
- **Organize code into clearly separated modules**, grouped by feature or responsibility.
- **Use clear, consistent imports** (prefer relative imports within packages).

### >� Testing & Reliability
- **Always create Pytest unit tests for new features** (functions, classes, routes, etc).
- **After updating any logic**, check whether existing unit tests need to be updated. If so, do it.
- **Tests should live in a `/tests` folder** mirroring the main app structure.
  - Include at least:
    - 1 test for expected use
    - 1 edge case
    - 1 failure case

###  Task Completion
- **Mark completed tasks in `TASK.md`** immediately after finishing them.
- Add new sub-tasks or TODOs discovered during development to `TASK.md` under a "Discovered During Work" section.

### =� Style & Conventions
- **Use Vala** as the primary language for this GTK4/LibAdwaita application.
- **Follow GNOME coding standards**, use proper Vala conventions, and Blueprint for UI definitions.
- **Use `GExiv2` for metadata handling** and `GdkPixbuf` for image loading.
- Write **documentation comments for every public method** using Vala documentation format:
  ```vala
  /**
   * Brief summary.
   *
   * @param param1 Description.
   * @return Description.
   */
  ```

### =� Documentation & Explainability
- **Update `README.md`** when new features are added, dependencies change, or setup steps are modified.
- **Comment non-obvious code** and ensure everything is understandable to a mid-level developer.
- When writing complex logic, **add an inline `// Reason:` comment** explaining the why, not just the what.

### >� AI Behavior Rules
- **Never assume missing context. Ask questions if uncertain.**
- **Never hallucinate libraries or functions**  only use known, verified Vala/GTK packages.
- **Always confirm file paths and module names** exist before referencing them in code or tests.
- **Never delete or overwrite existing code** unless explicitly instructed to or if part of a task from `TASK.md`.
- build dev using ./build.sh --dev and prod using ./build.sh

### =� Image Format Support (Current + HEIF/HEIC)
- **Supported formats**: JPEG, PNG, TIFF, WebP, **HEIF, HEIC** (new)
- **Metadata extraction**: GExiv2 with BMFF support enabled for HEIF/HEIC
- **Image loading**: GdkPixbuf with heif-gdk-pixbuf loader for transparent HEIF support
- **Format detection**: File extension and MIME type based
- **HEIF sequences**: Multi-image containers supported with primary image display
- **Dependencies**: libheif, libde265 (HEIC decoder) bundled in Flatpak

### =' HEIF/HEIC Implementation Notes
- **Flatpak changes**: Added libheif and libde265 modules to manifest
- **GExiv2 config**: Changed `EXIV2_ENABLE_BMFF=OFF` to `EXIV2_ENABLE_BMFF=ON`
- **File filters**: Added .heif/.heic extensions and MIME types
- **Format detection**: Extended `is_supported_format()` function
- **Metadata handling**: Same GExiv2 API works for HEIF as other formats
- **Image display**: Transparent GdkPixbuf integration, no code changes needed

# important-instruction-reminders
Do what has been asked; nothing more, nothing less.
NEVER create files unless they're absolutely necessary for achieving your goal.
ALWAYS prefer editing an existing file to creating a new one.
NEVER proactively create documentation files (*.md) or README files. Only create documentation files if explicitly requested by the User.