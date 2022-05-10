#!/usr/bin/env bash

echo -e "Arguments passed in: '$0', '$1'\n"

# Checking we can invoke our 'package'...
case "$1" in
    start)
        # Use 'exec' so called script subsumes the PID of this script, hopefully
        # to become PID 1 in this container.
        exec pkg.sh
        ;;
    help)
        # Fall through to next option
        ;;&
    *)
        echo "Usage: $0 {help|start}"
        ;;
esac
