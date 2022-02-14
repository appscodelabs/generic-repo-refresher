#!/usr/bin/env python3

import os
import sys
import ruamel.yaml
from pprint import pprint
from ruamel.yaml.error import CommentMark
from ruamel.yaml import YAML

CM = ruamel.yaml.comments.CommentedMap
CT = ruamel.yaml.CommentToken


def fix(repo_root):
    # repo_root = "/Users/tamal/go/src/kubedb.dev/elasticsearch"
    directory = os.path.join(repo_root, ".github", "workflows")

    for filename in os.listdir(directory):
        if not filename.endswith(".yml"):
            continue

        with open(os.path.join(directory, filename), 'r+') as f:
            yaml = ruamel.yaml.YAML(typ='rt')
            yaml.preserve_quotes = True
            yaml.width = 4096
            data = yaml.load(f)
            # print(data.ca)

            # concurrency:
            #   group: '${{ github.workflow }}-${{ github.head_ref || github.ref }}'
            #   cancel-in-progress: true
            
            onIdx = -1
            idx = -1
            for key in data:
                idx = idx + 1
                if key == 'on':
                    onIdx = idx
                    data['on']['workflow_dispatch'] = None
                    break

            ccIdx = -1
            idx = -1
            for key in data:
                idx = idx + 1
                if key == 'concurrency':
                    ccIdx = idx
                    break

            e1 = CM({
                'group': '${{ github.workflow }}-${{ github.head_ref || github.ref }}',
                'cancel-in-progress': True
            })
            if ccIdx != -1:
                data['concurrency'] = e1
            else:
                data.insert(onIdx + 1, 'concurrency', e1)

            f.seek(0)
            f.truncate(0)
            yaml.indent(mapping=2, sequence=4, offset=2)
            yaml.dump(data, f)


if __name__ == "__main__":
    fix(sys.argv[1], *sys.argv[2:])
