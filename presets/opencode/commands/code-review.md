---
description: Review code for quality, security, and maintainability
agent: code-reviewer
subtask: true
---

# Code Review Command

Review code changes for quality, security, and maintainability: $ARGUMENTS

## Your Task

1. **Get changed files**: Run `git diff --name-only HEAD`
2. **Analyze each file** for issues
3. **Generate structured report**
4. **Provide actionable recommendations**

## Check Categories

Apply the shared `AGENTS.md` readability rules and use `codebase-design` for examples when available; organization follows domain then role.

### Security Issues (CRITICAL)

- [ ] Hardcoded credentials, API keys, tokens
- [ ] SQL injection vulnerabilities
- [ ] XSS vulnerabilities
- [ ] Missing input validation
- [ ] Insecure dependencies
- [ ] Path traversal risks
- [ ] Authentication/authorization flaws

### Code Quality (HIGH)

- [ ] Related implementation scattered across forwarding modules
- [ ] Public operations leave ordering, failure, or required completion to callers
- [ ] Extractions hide no complexity and enable no useful reuse
- [ ] Configured line limits exceeded without documented narrow exceptions
- [ ] Duplicate contracts or repeated internal execution-model conversions
- [ ] Nesting depth > 4 levels
- [ ] Missing error handling
- [ ] console.log statements
- [ ] TODO/FIXME comments
- [ ] Public contracts or important invariants are unclear; comments only restate the code

### Best Practices (MEDIUM)

- [ ] Mutation patterns (use immutable instead)
- [ ] Unnecessary complexity
- [ ] Changed observable behavior lacks regression coverage through the public interface
- [ ] Accessibility issues (a11y)
- [ ] Performance concerns

### Style (LOW)

- [ ] Inconsistent naming
- [ ] Unclear public types; use schema inference when a runtime contract already exists
- [ ] Formatting issues

## Report Format

For each issue found:

```
**[SEVERITY]** file.ts:123
Issue: [Description]
Fix: [How to fix]
```

## Decision

- **CRITICAL or HIGH issues**: Block commit, require fixes
- **MEDIUM issues**: Recommend fixes before merge
- **LOW issues**: Optional improvements

---

**IMPORTANT**: Never approve code with security vulnerabilities!
