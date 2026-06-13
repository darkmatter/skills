# ESLint guardrails for UI component architecture

Lint can't enforce "this should have been reused," but it can enforce the
boundaries that keep the architecture honest. These rules nudge the behavior
mechanically so it doesn't rely on the model remembering. Add the ones that fit;
the boundary rule (banning app imports inside `@repo/ui`) is the most valuable.

Assumes a flat-config (`eslint.config.js`) ESLint 9 setup. Adapt globs to the
repo's actual layout.

## 1. Ban app imports inside `@repo/ui` (the important one)

A shared UI primitive must stay presentational. This rule stops `packages/ui`
from importing app code (`@/...`, routers, stores, API clients), which is the
single clearest signal of a leaky, over-coupled extraction.

```js
// eslint.config.js
import boundaries from "eslint-plugin-boundaries";

export default [
  {
    files: ["packages/ui/**/*.{ts,tsx}"],
    rules: {
      "no-restricted-imports": [
        "error",
        {
          patterns: [
            {
              group: ["@/*"],
              message:
                "@repo/ui must not import app code. Keep primitives presentational; pass data as props.",
            },
            {
              group: ["@repo/api", "@repo/db", "**/stores/*", "**/routes/*"],
              message: "No app stores/routes/data layers inside @repo/ui.",
            },
          ],
        },
      ],
    },
  },
];
```

`eslint-plugin-boundaries` is a heavier but more expressive alternative if you
want to model `app → ui` as a one-way dependency across the whole monorepo.

## 2. Flag raw hex colors in app JSX

Pushes styling onto theme tokens instead of magic hex values scattered through
`className`. This catches `bg-[#0a0a0a]` / `text-[#4ade80]` arbitrary values.

```js
{
  files: ["apps/**/*.{tsx}"],
  rules: {
    "no-restricted-syntax": [
      "warn",
      {
        selector: "Literal[value=/\\[#([0-9a-fA-F]{3,8})\\]/]",
        message: "Avoid raw hex in className; use a theme token (e.g. bg-surface, text-positive).",
      },
    ],
  },
}
```

Tune to taste — some teams allow arbitrary values in `@repo/ui` itself (where the
tokens are defined) but ban them in apps.

## 3. Cap JSX nesting depth

A blunt proxy for "this screen is a wall of divs and needs decomposition." When a
file trips it, the fix is almost always to extract a component.

```js
{
  files: ["apps/**/*.{tsx}"],
  rules: {
    "react/jsx-max-depth": ["warn", { max: 6 }],
  },
}
```

Start permissive (6–8) and tighten once the codebase is decomposed; setting it
too low on a legacy screen just produces noise.

## 4. Tailwind class hygiene (optional)

`eslint-plugin-tailwindcss` (or the newer `eslint-plugin-better-tailwindcss`)
catches contradicting classes, enforces ordering, and flags unknown utilities.
Doesn't enforce reuse, but keeps the inline styling that remains tidy.

```js
import tailwind from "eslint-plugin-tailwindcss";

export default [...tailwind.configs["flat/recommended"]];
```

## Rollout note

Land these as `warn` first, not `error`, on an existing codebase — a hard error
on day one blocks every build over pre-existing screens. Burn down the warnings,
then promote the boundary rule (rule 1) to `error` since new violations there are
always real architecture leaks.
