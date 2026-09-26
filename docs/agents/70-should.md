## Should

- **Readability first** — clear names, self-documenting code, consistent formatting
- **KISS / DRY / YAGNI** — simplest solution that works; don't build ahead of need
- **Complexity is a design constraint** — know input size, write code whose Big-O fits. Pre-index with `Map`/`Set` when repeatedly searching. Optimize asymptotic shape first; micro-opts only after measurement
- **Immutability at boundaries** — API, state, props, cache, shared data. Local mutation OK only when private to the function and cannot leak
- **Size checks** — retain configured line limits; when adding a new file limit, start at 300 nonblank, noncomment lines and use documented file-specific caps when justified. Reduce nesting with clear control flow; extraction must satisfy the module design rules above.
- **Comments explain WHY** — not WHAT. Named constants over magic numbers
- **Type safety** — proper types, no `any`. Schema-decode unknown data at trust boundaries. Typed errors handled by tag, not thrown
- **No accidental quadratic** — build indexes once, avoid `.find()` inside loops, use streaming/pagination for large inputs
- **React/JSX** — function components + hooks (classes only for error boundaries); keep private components local unless extraction improves understanding or reuse; stable unique `key` (never array index for dynamic lists); defaults via destructuring, not `defaultProps`; required `alt` + valid ARIA roles, no `accessKey`; `useRef` not string refs; share logic via custom hooks, not mixins/HOCs. Adapted from [Airbnb React](https://github.com/airbnb/javascript/tree/master/react)
- **Prefer a preview branch via PR over pushing to main** — either way, test the change live: "add a button to page Y" is not done until it is loaded in a browser; "on production" means tested in a browser on production
