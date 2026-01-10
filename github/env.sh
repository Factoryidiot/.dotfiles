#!/usr/bin/env bash
if [ -f "/run/agenix/secrets/github" ]; then
    export GITHUB_TOKEN=$(cat "/run/agenix/secrets/github_token")
fi
