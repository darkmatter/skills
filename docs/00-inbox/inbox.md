# Inbox

This file contains a list of items to be addressed and applied to this repository.

## Codebase Structure

- Philosophy is based on clarity and common conventions.
- Aim for one-word file and directory names.
  - When it feels impossible to avoid compound words, consider using a subdirectory, e.g. `users/feed.ts` over `user-feed.ts`.
- Typescript/JS: Always use kebab-case over camelCase.
- Use `lib.ts` for any shared utility functions or types. Let it grow and _then_ refactor when it's obvious how to split it. If it is not obvious, it's probablye pre-mature.
- Strive for as few top-level directories as possible. Don't clutter with config, environment variables, or other non-code files. The following should cover 99% of files that can be placed in the root directory:
- Always prefer the plural form of a word over the singular form (users, not user).
-

## Top-Level Directories

The goals of toplevel directories are as follows:

1. Make it obvious where something belongs.
2. Define a limited, static set of directories that cover 99% of files.
3. Follow conventions

Depending on whether or not the repo is a monorepo, the top-level may also contain `apps` and `packages` directories.

```files
.
├── apps
├── packages
├── src
├── docs
├── scripts
├── lib
│   ├── docker
│   ├── configs
│   ├── typescript
│   ├── tailwind
│   └── secrets
├── flake.lock
├── flake.nix
```

## Evolution of Source Files

Inside source, the only directory you need reafactor code in is `lib`. Don't think too much about it, and don't prematurely split it into subdirectories. As 'lib' grows, it should naturally be obvious what to call the new feature directory.

Example:

1. Initial state

```files
.
└── foo.ts
```

2. After refactoring

```files
.
├── foo.ts
└── bar.ts
```

3. After further refactoring

```files
.
├── foo.ts
└── lib
    ├── index.ts
    └── bar.ts
```

4. After further refactoring

```files
.
├── module.ts
├── lib
│   ├── foo.ts
│   ├── bar
│   │   ├── index.ts
│   │   └── bar.ts
│   ├── typescript
│   ├── tailwind
│   └── secrets
├── flake.lock
├── flake.nix
```
