#!/usr/bin/env bash

CONFIG_FILE=".pre-commit-config-custom.yaml"

if [ -f "${CONFIG_FILE}" ]; then
    # If files were passed by pre-commit, forward them behind `--files`
    if [ $# -gt 0 ]; then
        exec pre-commit run -c ${CONFIG_FILE} --files "$@"
    else
        exec pre-commit run -c ${CONFIG_FILE}
    fi
fi
