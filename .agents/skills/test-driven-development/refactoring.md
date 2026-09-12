# Refactor candidates

Apply [codebase-design](../codebase-design/SKILL.md) after the behavior test
passes. Extraction is a decision, not an automatic response to size or repetition.

- **Duplication:** share code when it describes the same responsibility and
  sharing makes callers easier to understand. Keep unrelated lookalikes separate.
- **Long methods:** clarify names and control flow first. Keep helpers local;
  extract a coherent responsibility when the reader can understand it independently.
- **Line limits:** preserve configured limits. Use a documented, targeted increase
  when splitting would scatter a cohesive implementation.
- **Forwarding modules:** combine them or give them a real responsibility.
- **Scattered contracts:** keep a schema and its inferred type with the domain owner.
- **Tests:** verify public behavior, including required completion and failure;
  do not expose or test private helpers to justify the refactor.

Ask: what will the reader no longer need to understand after this split?
Keep changes within the requested scope.
