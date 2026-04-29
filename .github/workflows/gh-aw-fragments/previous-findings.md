## Previous Findings

Before filing a new issue, check for issues this agent has already filed on the target repository.

Use `list_issues` with search for the title prefix to find previous findings:
- If your finding closely matches an open or recently-closed issue, call `noop` instead of filing a duplicate
- Only file a new issue when the finding is genuinely distinct from all previous findings
- Look at the target_repo's existing issues, not the control repo's

**Example check:**
```
list_issues: repo="${{ inputs.target_repo }}", state="all", search="in:title \"[YOUR-PREFIX]\""
```
