---
name: coding-standards
description: Use when writing, reviewing, or refactoring TS/JS/React/Node code for readability, modular file organization, computational complexity, type safety, testing, and maintainability.
---

# Coding Standards & Best Practices

Universal coding standards applicable across all projects.

## When to Activate

- Starting a new project or module
- Reviewing code for quality and maintainability
- Refactoring existing code to follow conventions
- Enforcing naming, formatting, or structural consistency
- Setting up linting, formatting, or type-checking rules
- Onboarding new contributors to coding conventions

## Code Quality Principles

### 1. Readability First

- Code is read more than written
- Clear variable and function names
- Self-documenting code preferred over comments
- Consistent formatting

### 2. KISS (Keep It Simple, Stupid)

- Simplest solution that works
- Avoid over-engineering
- Do not hide algorithmic blowups behind “premature optimization”
- Easy to understand > clever code, but scalable enough for expected input sizes

### 3. DRY (Don't Repeat Yourself)

- Extract common logic into functions
- Create reusable components
- Share utilities across modules
- Avoid copy-paste programming

### 4. YAGNI (You Aren't Gonna Need It)

- Don't build features before they're needed
- Avoid speculative generality
- Add complexity only when required
- Start simple, refactor when needed

### 5. Complexity Is a Design Constraint

- Know the expected input size and write code whose Big-O behavior fits it
- Avoid accidental `O(n²)` work in render paths, request handlers, CLIs over repo files, reconciliation loops, and migrations
- Build indexes (`Map`, `Set`, grouped objects) once when code repeatedly searches the same collection
- Prefer streaming, pagination, batching, and bounded concurrency for untrusted or large inputs
- Optimize asymptotic shape first; micro-optimizations come only after measurement
- Document non-obvious complexity choices when the simple-looking code is deliberately avoided

## TypeScript/JavaScript Standards

### Variable Naming

```typescript
// ✅ GOOD: Descriptive names
const marketSearchQuery = "election";
const isUserAuthenticated = true;
const totalRevenue = 1000;

// ❌ BAD: Unclear names
const q = "election";
const flag = true;
const x = 1000;
```

### Fluent Naming

```typescript
// ✅ GOOD: Fluent naming
private readonly searchCustomers = inject(SearchCustomersUseCase);

public searchCustomersBy(filters: SearchFilters) {
  return this.searchCustomers.by(filters); // ✅ GOOD - fluent
}

// ❌ BAD: Unclear names
public searchCustomers(searchFilters: SearchFilters) {
  return this.searchCustomers.search(searchFilters); // ❌ BAD - can't read it as fluent
}
```

### Function Naming

```typescript
// ✅ GOOD: Verb-noun pattern
async function fetchMarketData(marketId: string) {}
function calculateSimilarity(a: number[], b: number[]) {}
function isValidEmail(email: string): boolean {}

// ❌ BAD: Unclear or noun-only
async function market(id: string) {}
function similarity(a, b) {}
function email(e) {}
```

### Immutability by Default

Use immutable updates at API, state, props, cache, and shared-data boundaries. Local mutation is acceptable only when it is private to the function, improves clarity or performance, and cannot leak to callers.

```typescript
// ✅ GOOD: Preserve caller-owned data
const updatedUser = {
  ...user,
  name: "New Name",
};

const updatedArray = [...items, newItem];

// ✅ GOOD: Local mutation that cannot leak
const byId = new Map<string, User>();
for (const user of users) {
  byId.set(user.id, user);
}

// ❌ BAD: Mutates caller-owned data
user.name = "New Name";
items.push(newItem);
```

### Error Handling

```typescript
// ✅ GOOD: Comprehensive error handling
async function fetchData(url: string) {
  try {
    const response = await fetch(url);

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }

    return await response.json();
  } catch (error) {
    console.error("Fetch failed:", error);
    throw new Error("Failed to fetch data");
  }
}

// ❌ BAD: No error handling
async function fetchData(url) {
  const response = await fetch(url);
  return response.json();
}
```

### Async/Await Best Practices

```typescript
// ✅ GOOD: Parallel execution when possible
const [users, markets, stats] = await Promise.all([fetchUsers(), fetchMarkets(), fetchStats()]);

// ❌ BAD: Sequential when unnecessary
const users = await fetchUsers();
const markets = await fetchMarkets();
const stats = await fetchStats();
```

### Type Safety

```typescript
// ✅ GOOD: Proper types
interface Market {
  id: string;
  name: string;
  status: "active" | "resolved" | "closed";
  created_at: Date;
}

function getMarket(id: string): Promise<Market> {
  // Implementation
}

// ❌ BAD: Using 'any'
function getMarket(id: any): Promise<any> {
  // Implementation
}
```

## API Design Standards

### REST API Conventions

```
GET    /api/markets              # List all markets
GET    /api/markets/:id          # Get specific market
POST   /api/markets              # Create new market
PUT    /api/markets/:id          # Update market (full)
PATCH  /api/markets/:id          # Update market (partial)
DELETE /api/markets/:id          # Delete market

# Query parameters for filtering
GET /api/markets?status=active&limit=10&offset=0
```

## File Organization

Keep files small enough that an agent or human can hold the whole module in context. Large files are usually a boundary smell, not a badge of simplicity.

### Module Boundaries

- One file should have one primary responsibility: resource contract, provider lifecycle, HTTP client, schema, pure selection logic, UI component, hook, or test helper
- Split when a file mixes trust-boundary decoding, business rules, I/O clients, UI rendering, and orchestration
- Prefer a directory with focused siblings plus `index.ts` over a “god file” with many unrelated sections
- Keep pure helpers separate from I/O so they can be tested without mocks
- Keep public APIs narrow; use barrel exports intentionally, not as a dump of internals
- Do not create tiny files for every three-line helper. Split around concepts and dependency boundaries, not line-count alone

### Size Heuristics

These are review triggers, not hard limits:

- ~150-250 lines: check whether the file still has one clear responsibility
- ~300+ lines: strongly consider extracting types, schemas, clients, pure helpers, or subcomponents
- ~50+ line function: split unless it is a flat declarative table/config or a simple provider lifecycle body
- 4+ levels of nesting: flatten with guard clauses or extracted helpers

### File Naming

```
components/Button.tsx          # PascalCase for components
hooks/useAuth.ts              # camelCase with 'use' prefix
lib/formatDate.ts             # camelCase for utilities
types/market.types.ts         # camelCase with .types suffix
```

## Comments & Documentation

### When to Comment

```typescript
// ✅ GOOD: Explain WHY, not WHAT
// Use exponential backoff to avoid overwhelming the API during outages
const delay = Math.min(1000 * Math.pow(2, retryCount), 30000);

// Build an index once to avoid repeated O(n) scans
const byId = new Map(items.map((item) => [item.id, item]));

// ❌ BAD: Stating the obvious
// Increment counter by 1
count++;

// Set name to user's name
name = user.name;
```

### JSDoc for Public APIs

````typescript
/**
 * Searches markets using semantic similarity.
 *
 * @param query - Natural language search query
 * @param limit - Maximum number of results (default: 10)
 * @returns Array of markets sorted by similarity score
 * @throws {Error} If OpenAI API fails or Redis unavailable
 *
 * @example
 * ```typescript
 * const results = await searchMarkets('election', 5)
 * console.log(results[0].name) // "Trump vs Biden"
 * ```
 */
export async function searchMarkets(query: string, limit: number = 10): Promise<Market[]> {
  // Implementation
}
````

## Performance & Computational Complexity

### Algorithmic Shape

```typescript
// ❌ BAD: O(n²) lookup inside a loop
const enriched = orders.map((order) => ({
  ...order,
  customer: customers.find((customer) => customer.id === order.customerId),
}));

// ✅ GOOD: O(n + m), explicit index
const customersById = new Map(customers.map((customer) => [customer.id, customer]));
const enriched = orders.map((order) => ({
  ...order,
  customer: customersById.get(order.customerId),
}));
```

Use comments for complexity only when the tradeoff is non-obvious, e.g. “pre-index by id because this runs for every page render over thousands of rows.”

### Memoization

```typescript
import { useMemo, useCallback } from "react";

// ✅ GOOD: Memoize expensive computations
const sortedMarkets = useMemo(() => {
  return [...markets].sort((a, b) => b.volume - a.volume);
}, [markets]);

// ✅ GOOD: Memoize callbacks
const handleSearch = useCallback((query: string) => {
  setSearchQuery(query);
}, []);
```

### Lazy Loading

```typescript
import { lazy, Suspense } from 'react'

// ✅ GOOD: Lazy load heavy components
const HeavyChart = lazy(() => import('./HeavyChart'))

export function Dashboard() {
  return (
    <Suspense fallback={<Spinner />}>
      <HeavyChart />
    </Suspense>
  )
}
```

### Database Queries

```typescript
// ✅ GOOD: Select only needed columns
const { data } = await supabase.from("markets").select("id, name, status").limit(10);

// ❌ BAD: Select everything
const { data } = await supabase.from("markets").select("*");
```

## Testing Standards

### Test Structure (AAA Pattern)

```typescript
test("calculates similarity correctly", () => {
  // Arrange
  const vector1 = [1, 0, 0];
  const vector2 = [0, 1, 0];

  // Act
  const similarity = calculateCosineSimilarity(vector1, vector2);

  // Assert
  expect(similarity).toBe(0);
});
```

### Test Naming

```typescript
// ✅ GOOD: Descriptive test names
test("returns empty array when no markets match query", () => {});
test("throws error when OpenAI API key is missing", () => {});
test("falls back to substring search when Redis unavailable", () => {});

// ❌ BAD: Vague test names
test("works", () => {});
test("test search", () => {});
```

## Code Smell Detection

Watch for these anti-patterns:

### 1. Large Files and Long Functions

Large files make review, agent edits, and tests less reliable. Split around concepts and dependency boundaries before the file becomes a grab bag.

```typescript
// ❌ BAD: One file owns resource type, HTTP client, wire schemas, selection, and lifecycle
// src/Provider/GpuInstance.ts (800 lines)

// ✅ GOOD: Focused siblings with explicit boundaries
// src/Provider/GpuInstance.ts          # resource contract
// src/Provider/GpuInstanceProvider.ts  # lifecycle
// src/Provider/Client.ts               # HTTP service
// src/Provider/Wire.ts                 # schemas
// src/Provider/Selection.ts            # pure logic
```

### 2. Long Functions

```typescript
// ❌ BAD: Function > 50 lines
function processMarketData() {
  // 100 lines of code
}

// ✅ GOOD: Split into smaller functions
function processMarketData() {
  const validated = validateData();
  const transformed = transformData(validated);
  return saveData(transformed);
}
```

### 3. Deep Nesting

```typescript
// ❌ BAD: 5+ levels of nesting
if (user) {
  if (user.isAdmin) {
    if (market) {
      if (market.isActive) {
        if (hasPermission) {
          // Do something
        }
      }
    }
  }
}

// ✅ GOOD: Early returns
if (!user) return;
if (!user.isAdmin) return;
if (!market) return;
if (!market.isActive) return;
if (!hasPermission) return;

// Do something
```

### 4. Magic Numbers

```typescript
// ❌ BAD: Unexplained numbers
if (retryCount > 3) {
}
setTimeout(callback, 500);

// ✅ GOOD: Named constants
const MAX_RETRIES = 3;
const DEBOUNCE_DELAY_MS = 500;

if (retryCount > MAX_RETRIES) {
}
setTimeout(callback, DEBOUNCE_DELAY_MS);
```

### 5. Accidental Quadratic Work

```typescript
// ❌ BAD: Repeated scan
for (const file of files) {
  const owner = owners.find((owner) => owner.path === file.path);
  // ...
}

// ✅ GOOD: Build the lookup once
const ownersByPath = new Map(owners.map((owner) => [owner.path, owner]));
for (const file of files) {
  const owner = ownersByPath.get(file.path);
  // ...
}
```

**Remember**: Code quality is not negotiable. Clear, modular, complexity-aware code enables rapid development and confident refactoring.
