#!/bin/bash
# set -eou pipefail

SCRIPT_ROOT=$(realpath $(dirname "${BASH_SOURCE[0]}"))
SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")

GITHUB_USER=${GITHUB_USER:-1gtm}
PR_BRANCH=generic-repo-refresher # -$(date +%s)
COMMIT_MSG="Update repository config"

REPO_ROOT=/tmp/generic-repo-refresher

refresh() {
    echo "refreshing repository: $1"
    sudo rm -rf $REPO_ROOT
    mkdir -p $REPO_ROOT
    pushd $REPO_ROOT
    git clone --no-tags --no-recurse-submodules --depth=1 https://${GITHUB_USER}:${GITHUB_TOKEN}@$1.git
    cd $(ls -b1)
    git checkout -b $PR_BRANCH

    # https://github.com/GoogleContainerTools/distroless/pull/335
    # https://github.com/GoogleContainerTools/distroless/blob/70f4a32ab305eec38d9d1c6e5bce2e3a9b92f877/base/BUILD#L10
    sed -i '/nobody:nobody/d' Dockerfile
    sed -i 's|USER 65535:65535|USER nobody|g' Dockerfile
    sed -i '/nobody:nobody/d' Dockerfile.*
    sed -i 's|USER 65535:65535|USER nobody|g' Dockerfile.*
    sed -i 's|gcr.io/distroless/static-debian10:nonroot|gcr.io/distroless/static:nonroot|g' Makefile
    sed -i 's|gcr.io/distroless/static-debian10|gcr.io/distroless/static:nonroot|g' Makefile

    sed -i 's/busybox:1.31.1/busybox:latest/g' Makefile
    sed -i 's/alpine:3.11/alpine:latest/g' Makefile
    sed -i 's/alpine:3.10/alpine:latest/g' Makefile
    sed -i 's/debian:stretch/debian:buster/g' Makefile
    sed -i 's/debian:stretch/debian:bullseye/g' Dockerfile.in || true
    sed -i 's/debian:stretch/debian:bullseye/g' Dockerfile.dbg || true
    sed -i 's/debian:buster/debian:bullseye/g' Dockerfile.in || true
    sed -i 's/debian:buster/debian:bullseye/g' Dockerfile.dbg || true
    sed -i 's/gcr.io\/distroless\/base/gcr.io\/distroless\/base-debian10/g' Makefile
    sed -i 's/gcr.io\/distroless\/base-debian10-debian10/gcr.io\/distroless\/base-debian10/g' Makefile
    sed -i 's/gcr.io\/distroless\/static/gcr.io\/distroless\/static-debian10/g' Makefile
    sed -i 's/gcr.io\/distroless\/static-debian10-debian10/gcr.io\/distroless\/static-debian10/g' Makefile
    sed -i 's/chart-testing:v3.0.0/chart-testing:v3.4.0/g' Makefile
    sed -i 's/?=\ 1.15/?=\ 1.16/g' Makefile
    sed -i 's|verify-modules verify-gen|verify-gen verify-modules|g' Makefile
    make gen fmt || true
    rm -rf hack/kubernetes/storageclass
    if test -f "hack/kubernetes/kind.yaml"; then
        cp $GITHUB_WORKSPACE/kind.yaml hack/kubernetes/kind.yaml
    fi

    $GITHUB_WORKSPACE/hack/scripts/docker_buildx_fixer.py $(pwd)

    # if grep -q "Apache" hack/scripts/update-release-tracker.sh &> /dev/null; then
    #     cp $GITHUB_WORKSPACE/hack/scripts/update-release-tracker/apache.sh hack/scripts/update-release-tracker.sh
    # fi
    # if grep -q "AppsCode-Community" hack/scripts/update-release-tracker.sh &> /dev/null; then
    #     cp $GITHUB_WORKSPACE/hack/scripts/update-release-tracker/community.sh hack/scripts/update-release-tracker.sh
    # fi
    # if grep -q "AppsCode-Free-Trial" hack/scripts/update-release-tracker.sh &> /dev/null; then
    #     cp $GITHUB_WORKSPACE/hack/scripts/update-release-tracker/enterprise.sh hack/scripts/update-release-tracker.sh
    # fi

    pushd .github/workflows/ && {
        # update engineerd/setup-kind
        sed -i 's|jetstack/cert-manager/releases/download/v1.2.0/|jetstack/cert-manager/releases/download/v1.4.1/|g' *
        sed -i 's|engineerd/setup-kind@v0.4.0|engineerd/setup-kind@v0.5.0|g' *
        sed -i 's|version: v0.10.0|version: v0.11.1|g' *
        sed -i 's|\[v1.14.10, v1.15.12, v1.16.15, v1.17.17, v1.18.15, v1.19.7, v1.20.2\]|\[v1.16.15, v1.17.17, v1.18.15, v1.19.7, v1.20.2, v1.21.1\]|g' *
        sed -i 's|(v1.14.10 v1.16.15 v1.18.15 v1.20.2)|(v1.16.15 v1.18.15 v1.21.1)|g' *
        # update GO
        sed -i 's/Go\ 1.15/Go\ 1.16/g' *
        sed -i 's/go-version:\ 1.15/go-version:\ 1.16/g' *
        sed -i 's/go-version:\ ^1.15/go-version:\ ^1.16/g' *
        sed -i 's|/gh-tools/releases/download/v0.2.10/|/gh-tools/releases/download/v0.2.12/|g' *
        sed -i 's|/release-automaton/releases/download/v0.0.35/|/release-automaton/releases/download/v0.0.36/|g' *
        sed -i 's|/hugo-tools/releases/download/v0.2.20/|/hugo-tools/releases/download/v0.2.21/|g' *
        popd
    }
    [ -z "$2" ] || (
        echo "$2"
        $2 || true
    )
    git add --all
    if git diff --exit-code -s HEAD; then
        echo "Repository $1 is up-to-date."
    else
        if [[ "$1" == *"stashed"* ]]; then
            git commit -a -s -m "$COMMIT_MSG" -m "/cherry-pick"
        else
            git commit -a -s -m "$COMMIT_MSG"
        fi
        git push -u origin $PR_BRANCH -f
        hub pull-request \
            --labels automerge \
            --message "$COMMIT_MSG" \
            --message "Signed-off-by: $(git config --get user.name) <$(git config --get user.email)>" || true
        # gh pr create \
        #     --base master \
        #     --fill \
        #     --label automerge \
        #     --reviewer tamalsaha
    fi
    popd
}

if [ "$#" -ne 1 ]; then
    echo "Illegal number of parameters"
    echo "Correct usage: $SCRIPT_NAME <path_to_repos_list>"
    exit 1
fi

if [ -x $GITHUB_TOKEN ]; then
    echo "Missing env variable GITHUB_TOKEN"
    exit 1
fi

# ref: https://linuxize.com/post/how-to-read-a-file-line-by-line-in-bash/#using-file-descriptor
while IFS=, read -r -u9 repo cmd; do
    if [ -z "$repo" ]; then
        continue
    fi
    refresh "$repo" "$cmd"
    echo "################################################################################"
done 9<$1
