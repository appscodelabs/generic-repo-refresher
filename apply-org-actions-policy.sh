#!/bin/bash
set -eou pipefail

SCRIPT_ROOT=$(realpath $(dirname "${BASH_SOURCE[0]}"))
SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")

ORG_LIST=${ORG_LIST:-${SCRIPT_ROOT}/org_list.txt}

if [ -z "${GITHUB_TOKEN:-}" ]; then
    echo "Missing env variable GITHUB_TOKEN"
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "Missing required command: jq"
    exit 1
fi

if [ ! -f "$ORG_LIST" ]; then
    echo "Org list file not found: $ORG_LIST"
    echo "Correct usage: ORG_LIST=<path_to_org_list> $SCRIPT_NAME"
    exit 1
fi

apply_org_policy() {
    local org="$1"
    echo "Applying actions policy to org: $org"

    echo "  - setting fork-pr-contributor-approval=all_external_contributors"
    curl -fsSL \
        -X PUT \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${GITHUB_TOKEN}" \
        -H "X-GitHub-Api-Version: 2026-03-10" \
        "https://api.github.com/orgs/${org}/actions/permissions/fork-pr-contributor-approval" \
        -d '{"approval_policy":"all_external_contributors"}' \
        || echo "    [warn] failed to set fork-pr-contributor-approval for $org"

    echo "  - setting default_workflow_permissions=read, can_approve_pull_request_reviews=false"
    curl -fsSL \
        -X PUT \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${GITHUB_TOKEN}" \
        -H "X-GitHub-Api-Version: 2026-03-10" \
        "https://api.github.com/orgs/${org}/actions/permissions/workflow" \
        -d '{"default_workflow_permissions":"read","can_approve_pull_request_reviews":false}' \
        || echo "    [warn] failed to set workflow permissions for $org"

    echo "  - setting sha_pinning_required=true"
    local current body
    if current=$(curl -fsSL \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${GITHUB_TOKEN}" \
        -H "X-GitHub-Api-Version: 2026-03-10" \
        "https://api.github.com/orgs/${org}/actions/permissions"); then
        body=$(echo "$current" | jq -c '{enabled_repositories, allowed_actions, sha_pinning_required: true} | with_entries(select(.value != null))')
        curl -fsSL \
            -X PUT \
            -H "Accept: application/vnd.github+json" \
            -H "Authorization: Bearer ${GITHUB_TOKEN}" \
            -H "X-GitHub-Api-Version: 2026-03-10" \
            "https://api.github.com/orgs/${org}/actions/permissions" \
            -d "$body" \
            || echo "    [warn] failed to set sha_pinning_required for $org"
    else
        echo "    [warn] failed to read actions permissions for $org"
    fi
}

while IFS= read -r -u9 org || [ -n "$org" ]; do
    org="${org//[$'\t\r\n ']/}"
    if [ -z "$org" ]; then
        continue
    fi
    apply_org_policy "$org"
    echo "################################################################################"
done 9<"$ORG_LIST"
