#!/bin/bash
# set -eou pipefail

SCRIPT_ROOT=$(realpath $(dirname "${BASH_SOURCE[0]}"))
SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")

GITHUB_USER=${GITHUB_USER:-1gtm}
PR_BRANCH=grr #generic-repo-refresher # -$(date +%s)
COMMIT_MSG="Test against Kubernetes 1.24.0"

REPO_ROOT=/tmp/generic-repo-refresher

refresh() {
    echo "refreshing repository: $1"
    sudo rm -rf $REPO_ROOT
    mkdir -p $REPO_ROOT
    pushd $REPO_ROOT
    git clone --no-tags --no-recurse-submodules --depth=1 https://${GITHUB_USER}:${GITHUB_TOKEN}@$1.git
    cd $(ls -b1)
    git checkout -b $PR_BRANCH

    sed -i 's/busybox:1.31.1/busybox:latest/g' Makefile
    # sed -i 's/alpine:3.11/alpine:latest/g' Makefile
    sed -i 's/alpine:3.10/alpine:latest/g' Makefile
    # sed -i 's/debian:stretch/debian:buster/g' Makefile
    sed -i 's/debian:buster/debian:bullseye/g' Makefile
    # sed -i 's/debian:stretch/debian:bullseye/g' Dockerfile.in || true
    # sed -i 's/debian:stretch/debian:bullseye/g' Dockerfile.dbg || true
    sed -i 's/debian:buster/debian:bullseye/g' Dockerfile.in || true
    sed -i 's/debian:buster/debian:bullseye/g' Dockerfile.dbg || true
    # sed -i 's/chart-testing:v3.0.0/chart-testing:v3.4.0/g' Makefile
    # sed -i 's/chart-testing:v3.4.0/chart-testing:v3.5.1/g' Makefile
    sed -i 's/chart-testing:v3.5.0/chart-testing:v3.5.1/g' Makefile
    # sed -i 's/?=\ 1.15/?=\ 1.16/g' Makefile
    # sed -i 's/?=\ 1.16/?=\ 1.17/g' Makefile
    # sed -i 's/?=\ 1.17/?=\ 1.18/g' Makefile
    sed -i 's/?=\ 1.18/?=\ 1.19/g' Makefile
    sed -i 's|appscode/gengo:release-1.24|appscode/gengo:release-1.25|g' Makefile
    sed -i 's|verify-modules verify-gen|verify-gen verify-modules|g' Makefile

    # https://github.com/GoogleContainerTools/distroless/pull/335
    # https://github.com/GoogleContainerTools/distroless/blob/70f4a32ab305eec38d9d1c6e5bce2e3a9b92f877/base/BUILD#L10
    # sed -i '/nobody:nobody/d' Dockerfile
    # sed -i 's|USER 65535:65535|USER nobody|g' Dockerfile
    # sed -i '/nobody:nobody/d' Dockerfile.*
    # sed -i 's|USER 65535:65535|USER nobody|g' Dockerfile.*

    # DO NOT use nonroot base imge
    # This causes https://github.com/tektoncd/triggers/issues/781
    # or, https://githubmemory.com/repo/confluentinc/kafka-images/issues/76
    # sed -i 's|gcr.io/distroless/static-debian10:nonroot|gcr.io/distroless/static:nonroot|g' Makefile
    # sed -i 's|gcr.io/distroless/static-debian10|gcr.io/distroless/static:nonroot|g' Makefile

    sed -i 's|gcr.io/distroless/static:nonroot|gcr.io/distroless/static-debian10|g' Makefile
    sed -i 's|gcr.io/distroless/static-debian10|gcr.io/distroless/static-debian11|g' Makefile
    sed -i 's|gcr.io/distroless/base-debian10|gcr.io/distroless/base-debian11|g' Makefile

    make gen fmt || true
    rm -rf hack/kubernetes/storageclass
    if test -f "hack/kubernetes/kind.yaml"; then
        cp $GITHUB_WORKSPACE/kind.yaml hack/kubernetes/kind.yaml
    fi

    $GITHUB_WORKSPACE/hack/scripts/docker_buildx_fixer.py $(pwd)
    # $GITHUB_WORKSPACE/hack/scripts/ci_concurrency_fixer.py $(pwd)
    # $GITHUB_WORKSPACE/hack/scripts/ci_concurrency_fixer.py $(pwd)

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
        # hugo
        sed -i 's|0.99.1|0.104.0|g' *

        # update engineerd/setup-kind
        sed -i 's|jetstack/cert-manager/releases/download/v1.5.3/|cert-manager/cert-manager/releases/download/v1.9.1/|g' *

        sed -i 's|engineerd/setup-kind@v0.4.0|engineerd/setup-kind@v0.5.0|g' *
        # KIND
        sed -i 's|version: v0.14.0|version: v0.16.0|g' *
        # sed -i 's|\[v1.16.15, v1.17.17, v1.18.15, v1.19.7, v1.20.2, v1.21.1\]|\[v1.16.15, v1.17.17, v1.18.19, v1.19.11, v1.20.7, v1.21.2, v1.22.0\]|g' *
        # sed -i 's|(v1.16.15 v1.18.15 v1.21.1)|(v1.16.15 v1.18.19 v1.20.7 v1.22.0)|g' *
        # sed -i 's|\[v1.16.15, v1.17.17, v1.18.19, v1.19.11, v1.20.7, v1.21.2, v1.22.0\]|\[v1.16.15, v1.18.19, v1.19.11, v1.20.7, v1.21.2, v1.22.4, v1.23.3\]|g' *
        # sed -i 's|(v1.16.15 v1.18.19 v1.20.7 v1.22.0)|(v1.19.11 v1.21.2 v1.23.3)|g' *
        # sed -i 's|\[v1.16.15, v1.18.19, v1.19.11, v1.20.7, v1.21.2, v1.22.4, v1.23.0\]|\[v1.16.15, v1.18.19, v1.19.11, v1.20.7, v1.21.2, v1.22.4, v1.23.3\]|g' *
        # sed -i 's|(v1.19.11 v1.21.2 v1.23.0)|(v1.19.11 v1.21.2 v1.23.3)|g' *

        #sed -i 's|\[v1.16.15, v1.18.19, v1.19.11, v1.20.7, v1.21.2, v1.22.4, v1.23.3\]|\[v1.18.20, v1.19.16, v1.20.15, v1.21.12, v1.22.9, v1.23.6, v1.24.0\]|g' *
        #sed -i 's|\[v1.18.19, v1.19.11, v1.20.7, v1.21.2, v1.22.4, v1.23.3\]|\[v1.18.20, v1.19.16, v1.20.15, v1.21.12, v1.22.9, v1.23.6, v1.24.0\]|g' *
        sed -i 's|\[v1.18.20, v1.19.16, v1.20.15, v1.21.12, v1.22.9, v1.23.6, v1.24.0\]|\[v1.18.20, v1.19.16, v1.20.15, v1.21.14, v1.22.15, v1.23.12, v1.24.6, v1.25.2\]|g' *

        # sed -i 's|\[v1.19.11, v1.20.7, v1.21.2, v1.22.4, v1.23.3\]|\[v1.19.16, v1.20.15, v1.21.12, v1.22.9, v1.23.6, v1.24.0\]|g' *
        sed -i 's|\[v1.19.16, v1.20.15, v1.21.12, v1.22.9, v1.23.6, v1.24.0\]|\[v1.18.20, v1.19.16, v1.20.15, v1.21.14, v1.22.15, v1.23.12, v1.24.6, v1.25.2\]|g' *

        # sed -i 's|\[v1.14.10, v1.16.9, v1.18.8, v1.19.1\]|\[v1.18.20, v1.20.15, v1.22.9, v1.24.0\]|g' *
        sed -i 's|\[v1.18.20, v1.20.15, v1.22.9, v1.24.0\]|\[v1.18.20, v1.20.15, v1.22.15, v1.24.6, v1.25.2\]|g' *

        # sed -i 's|(v1.19.11 v1.21.2 v1.23.3)|(v1.18.20 v1.20.15 v1.22.9 v1.24.0)|g' *
        sed -i 's|(v1.18.20 v1.20.15 v1.22.9 v1.24.0)|(v1.18.20 v1.20.15 v1.22.15 v1.24.6 v1.25.2)|g' *

        # update GO
        sed -i 's/Go\ 1.18/Go\ 1.19/g' *
        sed -i 's/go-version:\ 1.18/go-version:\ 1.19/g' *
        sed -i 's/go-version:\ ^1.18/go-version:\ ^1.19/g' *
        sed -i "s/node-version:\ '14'/node-version:\ '16'/g" *
        sed -i "s/node-version:\ 14.x/node-version:\ '16'/g" *
        sed -i 's|/gh-tools/releases/download/v0.2.12/|/gh-tools/releases/download/v0.2.13/|g' *
        sed -i 's|/release-automaton/releases/download/v0.0.36/|/release-automaton/releases/download/v0.0.37/|g' *
        sed -i 's|/hugo-tools/releases/download/v0.2.21/|/hugo-tools/releases/download/v0.2.23/|g' *
        popd
    }
    [ -f go.mod ] && {
        sed -i 's|ioutil.ReadFile|os.ReadFile|g' `grep 'ioutil.ReadFile' -rl *`
        sed -i 's|ioutil.WriteFile|os.WriteFile|g' `grep 'ioutil.WriteFile' -rl *`
        sed -i 's|ioutil.ReadAll|io.ReadAll|g' `grep 'ioutil.ReadAll' -rl *`
        sed -i 's|ioutil.TempDir|os.MkdirTemp|g' `grep 'ioutil.TempDir' -rl *`
        sed -i 's|ioutil.TempFile|os.CreateTemp|g' `grep 'ioutil.TempFile' -rl *`

        go get github.com/modern-go/reflect2@v1.0.2
        go get github.com/json-iterator/go@v1.1.12
        go mod tidy
        go mod vendor
    }
    make gen || true
    make fmt || true
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
    sleep 60
done 9<$1
