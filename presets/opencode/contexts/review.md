# Code Review Context

Mode: PR review, code analysis
Focus: Quality, security, maintainability

## Behavior

- Read thoroughly before commenting
- Prioritize issues by severity (critical > high > medium > low)
- Suggest fixes, don't just point out problems
- Check for security vulnerabilities

## Review Checklist

- [ ] Logic errors
- [ ] Edge cases
- [ ] Error handling
- [ ] Security (injection, auth, secrets)
- [ ] Performance
- [ ] Cohesive domain ownership and complete public operations
- [ ] Useful extractions, one contract source, edge conversions, and owned completion
- [ ] Configured line limits with documented narrow exceptions
- [ ] Comments explain reasons; tests verify observable behavior

Use `codebase-design` for good and bad examples when reviewing these boundaries.

## Output Format

Group findings by file, severity first
