### Pick Three, Keep Many

Parallelize your investigation using sub-agents. Spawn 3 sub-agents, each with a distinct angle — e.g., different code quality dimensions, different areas of the codebase, or different heuristics. Each sub-agent works independently and should return multiple findings (with file paths, line numbers, and evidence) or a recommendation to `noop`. Unlike Pick Three, Keep One, this pattern keeps multiple strong findings.

**How to spawn sub-agents:** Use the `Task` tool with `agentType: "general-purpose"`. Each sub-agent prompt must be **fully self-contained**:

- The full task description and objective (restate it, don't summarize)
- All repository context, conventions, and constraints you've gathered
- Any relevant findings from your initial exploration
- The quality gate criteria and output format you expect
- The specific angle that distinguishes this sub-agent from the others

**Wait for all 3 sub-agents to complete.** Do not proceed until every sub-agent has returned its result.

**Merge and deduplicate findings** from all sub-agents:
- Group findings by the code pattern or issue they describe
- Remove clear duplicates
- Combine evidence from multiple sub-agents on the same finding (stronger evidence)
- Discard findings that don't pass the rigor quality gate

**Select the findings that pass the quality gate** and proceed to report them.
