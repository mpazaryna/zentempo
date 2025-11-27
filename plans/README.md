# Plans

This directory contains planning documents, design specifications, and architectural decisions for the Zentempo application.

## Purpose

The `plans/` folder is specifically designed for:
- **Living project documentation** that evolves with development
- **Design decisions** and architectural choices
- **Feature specifications** before and during implementation
- **Implementation strategies** and technical approaches
- **Project roadmaps** and future enhancements

## Why Separate from Docs?

This separation provides clarity for both human developers and AI coding assistants:
- **plans/** = Internal, evolving project planning and decision documents
- **docs/** = External, stable user-facing documentation

## Structure

```
plans/
├── README.md           (this file)
├── spec.md            (main project specification)
├── features/          (individual feature plans)
├── decisions/         (architectural decision records)
├── implementation/    (technical implementation details)
└── archive/          (completed or deprecated plans)
```

## For AI Assistants

When working with AI coding tools like Claude Code:
- Reference this folder for understanding project goals and constraints
- Check here first for implementation decisions and rationale
- Use these documents to maintain consistency with project vision

## Key Documents

- `spec.md` - Core project specification and requirements
- Feature plans - Detailed specifications for individual features
- Decision records - Why certain technical choices were made

## Contributing

When adding new plans:
1. Use clear, descriptive filenames
2. Include creation date in the document
3. Update this README if adding new categories
4. Move completed plans to `archive/` with date prefix