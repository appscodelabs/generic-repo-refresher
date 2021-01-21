#!/usr/bin/env python3

import os
import sys
import ruamel.yaml
from pprint import pprint
from ruamel.yaml.error import CommentMark

CM = ruamel.yaml.comments.CommentedMap
CT = ruamel.yaml.CommentToken


def fix(repo_root):
    # repo_root = "/home/tamal/go/src/stash.appscode.dev/stash"
    directory = os.path.join(repo_root, ".github", "workflows")

    for filename in os.listdir(directory):
        if not filename.endswith(".yml"):
            continue

        with open(os.path.join(directory, filename), 'r+') as f:
            yaml = ruamel.yaml.YAML(typ='rt')
            yaml.preserve_quotes = True
            yaml.width = 4096
            data = yaml.load(f)
            for job in data['jobs']:
                for i, step in enumerate(data['jobs'][job]['steps']):
                    if 'name' in data['jobs'][job]['steps'][i].keys() and data['jobs'][job]['steps'][i]['name'] == 'Available platforms':
                        data['jobs'][job]['steps'].pop(i)
                        break

                for i, step in enumerate(data['jobs'][job]['steps']):
                    if 'id' in step.keys() and step['id'] == 'buildx':
                        data['jobs'][job]['steps'].pop(i)

                        # add blank line before
                        data['jobs'][job]['steps'][i].ca.comment = [
                            None, [CT('\n', CommentMark(0), None)]]

                        e1 = CM({
                            'name': 'Set up Docker Buildx',
                            'uses': 'docker/setup-buildx-action@v1'
                        })
                        # e1.yaml_set_start_comment('\n')
                        e1.ca.comment = [
                            None, [CT('\n', CommentMark(0), None)]]
                        data['jobs'][job]['steps'].insert(i, e1)

                        e2 = CM({
                            'name': 'Available platforms',
                            'run': 'echo ${{steps.qemu.outputs.platforms}}'
                        })
                        e2.ca.comment = [
                            None, [CT('\n', CommentMark(0), None)]]
                        data['jobs'][job]['steps'].insert(i, e2)

                        data['jobs'][job]['steps'].insert(i, CM({
                            'name': 'Set up QEMU',
                            'id': 'qemu',
                            'uses': 'docker/setup-qemu-action@v1'
                        }))

                        break
            f.seek(0)
            f.truncate(0)
            yaml.indent(mapping=2, sequence=4, offset=2)
            yaml.dump(data, f)


if __name__ == "__main__":
    fix(sys.argv[1], *sys.argv[2:])
