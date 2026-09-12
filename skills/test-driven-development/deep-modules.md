# Deep Modules

From "A Philosophy of Software Design":

Follow [codebase-design](../codebase-design/SKILL.md) for the shared rules.

**Deep module** = small interface that hides substantial complexity. Depth is
not a line count; a long file can still expose too much internal knowledge.

```
┌─────────────────────┐
│   Small Interface   │  ← Few methods, simple params
├─────────────────────┤
│                     │
│                     │
│  Deep Implementation│  ← Complex logic hidden
│                     │
│                     │
└─────────────────────┘
```

**Shallow module** = large interface + little implementation (avoid)

```
┌─────────────────────────────────┐
│       Large Interface           │  ← Many methods, complex params
├─────────────────────────────────┤
│  Thin Implementation            │  ← Just passes through
└─────────────────────────────────┘
```

When designing interfaces, ask:

- Can I reduce the number of methods?
- Can I simplify the parameters?
- Can I hide more complexity inside?
- Does the operation own completion, errors, and cleanup?
- Does a split remove knowledge from the reader, or just add navigation?
