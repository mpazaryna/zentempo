# Changelog Details

This directory contains detailed information about changes in each version of Zentempo.

## Structure

```
changelog/
├── README.md           (this file)
├── unreleased/        (changes not yet released)
│   ├── features.md    (new features in development)
│   ├── fixes.md       (bug fixes in development)
│   └── breaking.md    (breaking changes if any)
└── v0.1.0/           (version-specific details)
    └── release-notes.md
```

## Purpose

While the root `CHANGELOG.md` provides a high-level overview following [Keep a Changelog](https://keepachangelog.com/) format, this directory contains:

- **Detailed implementation notes** for significant changes
- **Technical context** for architectural decisions
- **Migration guides** for breaking changes
- **Extended examples** and usage scenarios
- **Screenshots and media** demonstrating new features

## Why This Structure?

With AI-driven development, changes happen rapidly and the root CHANGELOG can become overwhelming. This structure allows:

1. **Root CHANGELOG.md** - Clean, scannable summary for users
2. **docs/changelog/** - Rich details for those who need them

## For AI Assistants

When making changes:
1. Update the root `CHANGELOG.md` with a concise summary
2. Add detailed notes here if the change is significant
3. Include technical context that helps future AI assistants understand the "why"

## Version Folders

Each version folder may contain:
- `release-notes.md` - Detailed release notes
- `features.md` - New feature documentation
- `fixes.md` - Bug fix details
- `breaking.md` - Breaking changes and migration guides
- `technical.md` - Technical implementation notes
- `media/` - Screenshots, demos, etc.