#!/bin/bash
# set -eou pipefail

SCRIPT_ROOT=$(realpath $(dirname "${BASH_SOURCE[0]}"))
SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}")

GITHUB_USER=${GITHUB_USER:-1gtm}
PR_BRANCH=gha-up #generic-repo-refresher # -$(date +%s)
COMMIT_MSG="Test against k8s 1.33"

REPO_ROOT=/tmp/gha-up

refresh() {
    echo "refreshing repository: $1"
    rm -rf $REPO_ROOT
    mkdir -p $REPO_ROOT
    pushd $REPO_ROOT
    git clone --no-tags --no-recurse-submodules --depth=1 https://${GITHUB_USER}:${GITHUB_TOKEN}@$1.git
    cd $(ls -b1)
    git checkout -b $PR_BRANCH

    sed -i 's|debian:bullseye|debian:12|g' Dockerfile.in
    sed -i 's|debian:bookworm|debian:12|g' Dockerfile.in

    sed -i 's|debian:bullseye|debian:12|g' Dockerfile.dbg
    sed -i 's|debian:bookworm|debian:12|g' Dockerfile.dbg
    sed -i 's|FROM appscode/dlv:1.*|FROM ghcr.io/appscode/dlv:1.24|g' Dockerfile.dbg
    sed -i 's|FROM ghcr.io/appscode/dlv:1.*|FROM ghcr.io/appscode/dlv:1.24|g' Dockerfile.dbg

    sed -i 's/?=\ 1.23/?=\ 1.24/g' Makefile

    sed -i 's|--skip-dirs-use-default|--exclude-dirs-use-default|g' Makefile
    sed -i 's|--skip-dirs|--exclude-dirs|g' Makefile
    sed -i 's|--skip-files|--exclude-files|g' Makefile

    # sed -i 's|?= appscode/gengo:release-1.20|?= ghcr.io/appscode/gengo:release-1.25|g' Makefile
    # sed -i 's|?= appscode/gengo:release-1.21|?= ghcr.io/appscode/gengo:release-1.25|g' Makefile
    # sed -i 's|?= appscode/gengo:release-1.24|?= ghcr.io/appscode/gengo:release-1.25|g' Makefile
    sed -i 's|?= appscode/gengo:release-1.25|?= ghcr.io/appscode/gengo:release-1.29|g' Makefile

    sed -i 's|chart-testing:v3.5.1|chart-testing:v3.11.0|g' Makefile
    sed -i 's|chart-testing:v3.8.0|chart-testing:v3.11.0|g' Makefile

    sed -i 's|"vendor contrib libbuild"|".go vendor contrib libbuild"|g' Makefile
    sed -i 's|"vendor contrib libbuild library"|".go vendor contrib libbuild library"|g' Makefile

    # sed -i 's/busybox:1.31.1/busybox:latest/g' Makefile
    # sed -i 's/alpine:3.11/alpine:latest/g' Makefile
    # sed -i 's/alpine:3.10/alpine:latest/g' Makefile
    # sed -i 's/debian:stretch/debian:buster/g' Makefile
    # sed -i 's/debian:buster/debian:bullseye/g' Makefile
    # sed -i 's/debian:stretch/debian:bullseye/g' Dockerfile.in || true
    # sed -i 's/debian:stretch/debian:bullseye/g' Dockerfile.dbg || true
    # sed -i 's/debian:buster/debian:bullseye/g' Dockerfile.in || true
    # sed -i 's/debian:buster/debian:bullseye/g' Dockerfile.dbg || true
    # sed -i 's/chart-testing:v3.0.0/chart-testing:v3.4.0/g' Makefile
    # sed -i 's/chart-testing:v3.4.0/chart-testing:v3.5.1/g' Makefile
    # sed -i 's/chart-testing:v3.5.0/chart-testing:v3.5.1/g' Makefile
    # sed -i 's/?=\ 1.15/?=\ 1.16/g' Makefile
    # sed -i 's/?=\ 1.16/?=\ 1.17/g' Makefile
    # sed -i 's/?=\ 1.17/?=\ 1.18/g' Makefile
    # sed -i 's/?=\ 1.18/?=\ 1.19/g' Makefile
    # sed -i 's|appscode/gengo:release-1.24|appscode/gengo:release-1.25|g' Makefile
    # sed -i 's|verify-modules verify-gen|verify-gen verify-modules|g' Makefile

    # https://github.com/GoogleContainerTools/distroless/pull/335
    # https://github.com/GoogleContainerTools/distroless/blob/70f4a32ab305eec38d9d1c6e5bce2e3a9b92f877/base/BUILD#L10
    # sed -i '/nobody:nobody/d' Dockerfile
    # sed -i 's|USER 65535:65535|USER nobody|g' Dockerfile
    # sed -i '/nobody:nobody/d' Dockerfile.*
    # sed -i 's|USER 65535:65535|USER nobody|g' Dockerfile.*

    # ref: https://stackoverflow.com/a/30717770

    # sed -i 's|USER nobody|USER 65534|g' Dockerfile || true
    # sed -i 's|USER nobody|USER 65534|g' Dockerfile.* || true
    # find . -type f -name 'Dockerfile*' -exec sed -i 's|USER nobody|USER 65534|g' {} \;

    # DO NOT use nonroot base imge
    # This causes https://github.com/tektoncd/triggers/issues/781
    # or, https://githubmemory.com/repo/confluentinc/kafka-images/issues/76
    # sed -i 's|gcr.io/distroless/static-debian10:nonroot|gcr.io/distroless/static:nonroot|g' Makefile
    # sed -i 's|gcr.io/distroless/static-debian10|gcr.io/distroless/static:nonroot|g' Makefile

    # sed -i 's|gcr.io/distroless/static:nonroot|gcr.io/distroless/static-debian10|g' Makefile
    # sed -i 's|gcr.io/distroless/static-debian10|gcr.io/distroless/static-debian11|g' Makefile
    # sed -i 's|gcr.io/distroless/base-debian10|gcr.io/distroless/base-debian11|g' Makefile

    # Use bookworm base image
    sed -i 's|gcr.io/distroless/static-debian11|gcr.io/distroless/static-debian12|g' Makefile
    sed -i 's|gcr.io/distroless/base-debian11|gcr.io/distroless/base-debian12|g' Makefile
    sed -i 's|debian:bullseye|debian:12|g' Makefile
    sed -i 's|debian:bookworm|debian:12|g' Makefile

    # make gen fmt || true
    # rm -rf hack/kubernetes/storageclass
    # if test -f "hack/kubernetes/kind.yaml"; then
    #     cp $GITHUB_WORKSPACE/kind.yaml hack/kubernetes/kind.yaml
    # fi

    # $GITHUB_WORKSPACE/hack/scripts/docker_buildx_fixer.py $(pwd)
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

    # sed -i 's|k8sVersions=(v1.26.3)|k8sVersions=(v1.32.2)|g' hack/scripts/generate-test-matrix.sh || true
    sed -i 's|k8sVersions=(v1.32.2)|k8sVersions=(v1.33.1)|g' hack/scripts/generate-test-matrix.sh || true

    [ -d .github/workflows ] && {
        pushd .github/workflows

        sed -i 's|actions/checkout@v[[:digit:]]\+|actions/checkout@v4|g' *
        sed -i 's|actions/setup-go@v[[:digit:]]\+|actions/setup-go@v5|g' *
        sed -i 's|actions/setup-node@v[[:digit:]]\+|actions/setup-node@v4|g' *
        sed -i 's|actions/setup-python@v[[:digit:]]\+|actions/setup-python@v5|g' *
        sed -i 's|actions/upload-artifact@v[[:digit:]]\+|actions/upload-artifact@v4|g' *
        sed -i 's|docker/setup-buildx-action@v[[:digit:]]\+|docker/setup-buildx-action@v3|g' *
        sed -i 's|docker/setup-qemu-action@v[[:digit:]]\+|docker/setup-qemu-action@v3|g' *

        go run $SCRIPT_ROOT/fix-ci.go *.yml

        sed -i 's|actions/checkout@v[[:digit:]]\+|actions/checkout@v1|g' cherry-pick.yml || true
        sed -i 's|actions/checkout@v[[:digit:]]\+|actions/checkout@v1|g' publish-oci.yml || true
        sed -i 's|actions/checkout@v[[:digit:]]\+|actions/checkout@v1|g' release.yml || true

        # kubectl
        sed -i 's|https://storage.googleapis.com/kubernetes-release/release/v1.17.0/bin/linux/amd64/kubectl|https://dl.k8s.io/release/v1.32.1/bin/linux/amd64/kubectl|g' *
        sed -i 's|https://storage.googleapis.com/kubernetes-release/release/v1.21.1/bin/linux/amd64/kubectl|https://dl.k8s.io/release/v1.32.1/bin/linux/amd64/kubectl|g' *
        sed -i 's|https://dl.k8s.io/release/v1.25.2/bin/linux/amd64/kubectl|https://dl.k8s.io/release/v1.32.1/bin/linux/amd64/kubectl|g' *

        #     # hugo
        #     sed -i 's|v0.100.2/hugo_extended_0.100.2_Linux-64bit.deb|v0.111.1/hugo_extended_0.111.1_linux-amd64.deb|g' *

        #     # update engineerd/setup-kind
        #     sed -i 's|cert-manager/cert-manager/releases/download/v1.9.1/|cert-manager/cert-manager/releases/download/v1.11.0/|g' *

        #     # sed -i 's|engineerd/setup-kind@v0.4.0|engineerd/setup-kind@v0.5.0|g' *
        # KIND
        # sed -i 's|version: v0.17.0|version: v0.24.0|g' *
        # sed -i 's|version: v0.20.0|version: v0.27.0|g' *
        # sed -i 's|version: v0.25.0|version: v0.27.0|g' *
        sed -i 's|version: v0.27.0|version: v0.29.0|g' *

        # sed -i 's|\[v1.18.20, v1.19.16, v1.20.15, v1.21.14, v1.22.15, v1.23.12, v1.24.6, v1.25.2\]|\[v1.20.15, v1.21.14, v1.22.15, v1.23.13, v1.24.7, v1.25.3, v1.26.0\]|g' *
        # sed -i 's|\[v1.18.20, v1.20.15, v1.22.15, v1.24.6, v1.25.2\]|\[v1.20.15, v1.22.15, v1.24.7, v1.26.0\]|g' *
        # sed -i 's|(v1.18.20 v1.20.15 v1.22.15 v1.24.6 v1.25.2)|(v1.20.15 v1.22.15 v1.24.7 v1.26.0)|g' *

        # sed -i 's|\[v1.20.15, v1.21.14, v1.22.15, v1.23.13, v1.24.7, v1.25.3, v1.26.0\]|\[v1.19.16, v1.20.15, v1.21.14, v1.22.17, v1.23.17, v1.24.12, v1.25.8, v1.26.3, v1.27.0\]|g' *
        # sed -i 's|\[v1.20.15, v1.22.15, v1.24.7, v1.26.0\]|\[v1.19.16, v1.21.14, v1.23.17, v1.25.8, v1.27.0\]|g' *
        # sed -i 's|(v1.20.15 v1.22.15 v1.24.7 v1.26.0)|(v1.19.16 v1.21.14 v1.23.17 v1.25.8 v1.27.0)|g' *

        # sed -i 's|\[v1.19.16, v1.20.15, v1.21.14, v1.22.17, v1.23.17, v1.24.12, v1.25.8, v1.26.3, v1.27.0\]|\[v1.19.16, v1.20.15, v1.21.14, v1.22.17, v1.23.17, v1.24.12, v1.25.8, v1.26.3, v1.27.1\]|g' *
        # sed -i 's|\[v1.21.14, v1.22.17, v1.23.17, v1.24.12, v1.25.8, v1.26.3, v1.27.0\]|\[v1.21.14, v1.22.17, v1.23.17, v1.24.12, v1.25.8, v1.26.3, v1.27.1\]|g' *
        # sed -i 's|\[v1.19.16, v1.21.14, v1.23.17, v1.25.8, v1.27.0\]|\[v1.19.16, v1.21.14, v1.23.17, v1.25.8, v1.27.1\]|g' *
        # sed -i 's|(v1.19.16 v1.21.14 v1.23.17 v1.25.8 v1.27.0)|(v1.19.16 v1.21.14 v1.23.17 v1.25.8 v1.27.1)|g' *

        # sed -i 's|(v1.20.15 v1.22.15 v1.24.7 v1.26.0)|(v1.26.15 v1.31.0)|g' *
        # sed -i 's|\[v1.19.16, v1.20.15, v1.21.14, v1.22.17, v1.23.17, v1.24.12, v1.25.8, v1.26.3, v1.27.1\]|\[v1.26.15, v1.27.16, v1.28.12, v1.29.7, v1.30.3, v1.31.0\]|g' *
        # sed -i 's|\[v1.20.15, v1.21.14, v1.22.17, v1.23.17, v1.24.12, v1.25.8, v1.26.3, v1.27.1, v1.28.0, v1.29.0\]|\[v1.26.15, v1.27.16, v1.28.12, v1.29.7, v1.30.3, v1.31.0\]|g' *
        # sed -i 's|\[v1.20.15, v1.21.14, v1.22.17, v1.23.17, v1.24.12, v1.25.8, v1.26.3, v1.27.1, v1.28.0\]|\[v1.26.15, v1.27.16, v1.28.12, v1.29.7, v1.30.3, v1.31.0\]|g' *
        # sed -i 's|\[v1.21.14, v1.22.17, v1.23.17, v1.24.12, v1.25.8, v1.26.3, v1.27.1, v1.28.0, v1.29.0\]|\[v1.26.15, v1.27.16, v1.28.12, v1.29.7, v1.30.3, v1.31.0\]|g' *
        # sed -i 's|\[v1.25.16, v1.26.15, v1.27.13, v1.28.9, v1.29.4, v1.30.0\]|\[v1.26.15, v1.27.16, v1.28.12, v1.29.7, v1.30.3, v1.31.0\]|g' *
        # sed -i 's|\[v1.27.3\]|\[v1.30.3\]|g' *

        # sed -i 's|(v1.26.15 v1.31.0)|(v1.29.14 v1.32.2)|g' *
        sed -i 's|(v1.29.14 v1.32.2)|(v1.29.14 v1.33.1)|g' *

        # sed -i 's|\[v1.26.15, v1.27.16, v1.28.9, v1.29.7, v1.30.3, v1.31.0\]|\[v1.29.14, v1.30.10, v1.31.6, v1.32.2\]|g' *
        # sed -i 's|\[v1.26.15, v1.27.16, v1.28.12, v1.29.7, v1.30.3, v1.31.0\]|\[v1.29.14, v1.30.10, v1.31.6, v1.32.2\]|g' *
        sed -i 's|\[v1.29.14, v1.30.10, v1.31.6, v1.32.2\]|\[v1.29.14, v1.30.13, v1.31.9, v1.32.5, v1.33.1\]|g' *

        # sed -i 's|(v1.29.14 v1.32.2)|(v1.26.15 v1.32.2)|g' *
        sed -i 's|(v1.26.15 v1.32.2)|(v1.28.15 v1.33.1)|g' *

        # sed -i 's|\[v1.29.14, v1.30.10, v1.31.6, v1.32.2\]|\[v1.26.15, v1.27.16, v1.28.15, v1.29.14, v1.30.10, v1.31.6, v1.32.2\]|g' *
        sed -i 's|\[v1.26.15, v1.27.16, v1.28.15, v1.29.14, v1.30.10, v1.31.6, v1.32.2\]|\[v1.28.15, v1.29.14, v1.30.13, v1.31.9, v1.32.5, v1.33.1\]|g' *

        # sed -i 's|\[v1.26.15, v1.27.16, v1.28.15, v1.29.14, v1.30.10, v1.31.6, v1.32.2\]|\[v1.26.15, v1.28.15, v1.30.10, v1.32.2\]|g' *
        sed -i 's|\[v1.26.15, v1.28.15, v1.30.10, v1.32.2\]|\[v1.28.15, v1.30.13, v1.32.5, v1.33.1\]|g' *

        # sed -i 's|\[v1.22.0\]|\[v1.32.2\]|g' *
        # sed -i 's|\[v1.25.3\]|\[v1.32.2\]|g' *
        # sed -i 's|\[v1.29.0\]|\[v1.32.2\]|g' *
        # sed -i 's|\[v1.30.3\]|\[v1.32.2\]|g' *
        sed -i 's|\[v1.32.2\]|\[v1.33.1\]|g' *

        sed -i 's|ubuntu-20.04|ubuntu-24.04|g' *
        sed -i 's|ubuntu-latest|ubuntu-24.04|g' *

        sed -i 's|pip3 install|pipx install|g' *

        # update GO
        sed -i 's/Go\ 1.20/Go\ 1.24/g' *
        sed -i "s/go-version:\ 1.20/go-version:\ '1.24'/g" *
        sed -i "s/go-version:\ ^1.20/go-version:\ '1.24'/g" *
        sed -i "s/go-version:\ '1.20'/go-version:\ '1.24'/g" *

        sed -i 's/Go\ 1.21/Go\ 1.24/g' *
        sed -i "s/go-version:\ 1.21/go-version:\ '1.24'/g" *
        sed -i "s/go-version:\ ^1.21/go-version:\ '1.24'/g" *
        sed -i "s/go-version:\ '1.21'/go-version:\ '1.24'/g" *

        sed -i 's/Go\ 1.22/Go\ 1.24/g' *
        sed -i "s/go-version:\ 1.22/go-version:\ '1.24'/g" *
        sed -i "s/go-version:\ ^1.22/go-version:\ '1.24'/g" *
        sed -i "s/go-version:\ '1.22'/go-version:\ '1.24'/g" *

        sed -i 's/Go\ 1.23/Go\ 1.24/g' *
        sed -i "s/go-version:\ 1.23/go-version:\ '1.24'/g" *
        sed -i "s/go-version:\ ^1.23/go-version:\ '1.24'/g" *
        sed -i "s/go-version:\ '1.23'/go-version:\ '1.24'/g" *

        # update node
        # sed -i "s|node-version:\ '16'|node-version:\ '18'|g" *

        #     sed -i "s/node-version:\ '14'/node-version:\ '16'/g" *
        #     sed -i "s/node-version:\ 14.x/node-version:\ '16'/g" *
        #     # sed -i 's|/gh-tools/releases/download/v0.2.12/|/gh-tools/releases/download/v0.2.13/|g' *
        #     # sed -i 's|/release-automaton/releases/download/v0.0.36/|/release-automaton/releases/download/v0.0.37/|g' *
        #     # sed -i 's|/hugo-tools/releases/download/v0.2.21/|/hugo-tools/releases/download/v0.2.23/|g' *
        popd
    }

    make fmt || true

    # [ -f go.mod ] && {
    #     go mod tidy
    #     go mod vendor
    # }

    # [ -f go.mod ] && {
    #     sed -i 's|ioutil.ReadFile|os.ReadFile|g' `grep 'ioutil.ReadFile' -rl *`
    #     sed -i 's|ioutil.WriteFile|os.WriteFile|g' `grep 'ioutil.WriteFile' -rl *`
    #     sed -i 's|ioutil.ReadAll|io.ReadAll|g' `grep 'ioutil.ReadAll' -rl *`
    #     sed -i 's|ioutil.TempDir|os.MkdirTemp|g' `grep 'ioutil.TempDir' -rl *`
    #     sed -i 's|ioutil.TempFile|os.CreateTemp|g' `grep 'ioutil.TempFile' -rl *`

    #     go mod edit \
    #         -require=github.com/modern-go/reflect2@v1.0.2 \
    #         -require=github.com/json-iterator/go@v1.1.12 \
    #         -require=golang.org/x/net@v0.7.0 \
    #         -require=golang.org/x/crypto@v0.6.0 \
    #         -require=go.bytebuilders.dev/license-proxyserver@v0.0.3
    #         # -require=kmodules.xyz/resource-metadata@v0.15.0

    #     go mod tidy
    #     go mod vendor
    # }
    # # make gen || true
    # make fmt || true
    # [ -z "$2" ] || (
    #     echo "$2"
    #     $2 || true
    # )
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
    # sleep 10
done 9<$1
