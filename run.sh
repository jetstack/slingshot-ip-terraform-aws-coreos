#!/bin/sh

discover () {
    cat <<EOF
provider:
  type: infrastructure
  version: 1
commands:
  apply:
    execs:
      -
        - vagrant
        - up
    type: host
    parameterFile: parameters.yaml
    resultFile: output.yaml
    persistPaths:
      - .vagrant/
    workingDirContent: !!binary |
$(tar -C vagrant -czf - . | base64 | awk '{print "      "$1}')
EOF
}

if [ "$1" = "discover" ]; then
    discover
else
    echo "please provide a valid command" > /dev/stderr
    exit 1
fi

