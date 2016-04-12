#!/bin/sh

discover () {
    cat <<EOF
provider:
  type: infrastructure
  version: 1
commands:
  apply:
    type: hostCommand
    output: output.yml
    pwdContent: generic: !binary |
$(tar -C vagrant -czf - . | base64 | awk '{print "      "$1}')
EOF
}

if [ "$1" = "discover" ]; then
    discover
else
    echo "please provide a valid command"
    exit 1
fi

