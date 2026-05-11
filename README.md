# generic-repo-refresher

## apply-org-actions-policy.sh

Applies GitHub Actions security policies at the **org level** for every org listed in `org_list.txt`:

- `fork-pr-contributor-approval` → `all_external_contributors`
- `default_workflow_permissions` → `read`
- `can_approve_pull_request_reviews` → `false`

Usage:

```bash
GITHUB_TOKEN=<your-token> ./apply-org-actions-policy.sh
```

Override the org list path with `ORG_LIST=/path/to/list.txt`.

The token needs `admin:org` scope (classic PAT) or `Administration: write` at the org level (fine-grained PAT).
