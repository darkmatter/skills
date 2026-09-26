## Readability and module design

Keep each capability together, make it simple to use, and split it only when the split improves understanding.

1. **Organize by domain, then role:** keep models, services, adapters, and workflows under their owning domain, adding role directories when useful.
2. **Keep related implementation together:** colocate the operations, private helpers, queries, and mappings readers must understand together.
3. **Expose complete operations:** let callers request an outcome through a small interface that owns the required steps and ordering.
4. **Make extraction earn its place:** extract only to hide complexity or enable useful reuse; keep simple private helpers local.
5. **Define each data contract once:** colocate a schema with its inferred type when runtime validation is needed.
6. **Convert execution models at the edge:** adapt external APIs once and use one execution model within the module.
7. **Own work through completion:** finish required work, propagate failure, and clean up before reporting success, or explicitly transfer responsibility.
8. **Keep line limits with narrow exceptions:** follow configured caps and split at meaningful responsibilities; document a file-specific cap or exception when a split would scatter cohesive code.
9. **Comment on reasons and invariants:** explain constraints and decisions the code cannot express clearly.
10. **Test observable behavior:** exercise outcomes through the public interface instead of asserting private calls or creating a test for every helper.

For package design, extraction decisions, or readability review, use the `codebase-design` skill for good and bad examples when it is installed; these rules also apply when it is unavailable.
